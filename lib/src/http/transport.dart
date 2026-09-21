import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/signature.dart';
import '../config/cloudinary_config.dart';
import '../exceptions.dart';
import 'file_source.dart';
import 'http_date.dart';
import 'multipart.dart';
import 'progress.dart';
import 'retry_policy.dart';

/// Which Cloudinary API version a request targets.
enum ApiVersion {
  /// The `v1_1` base used by the Upload, Admin and Search APIs.
  v1_1('v1_1'),

  /// The `v2` base used by newer endpoints.
  v2('v2');

  const ApiVersion(this.segment);

  /// The path segment for this version.
  final String segment;
}

/// Sends requests to Cloudinary and turns failures into typed exceptions.
///
/// Wraps an injectable [http.Client], which is the seam tests use: pass a
/// `MockClient` and no network is touched.
class CloudinaryTransport {
  /// Creates a transport.
  ///
  /// When [client] is omitted an internal one is created and closed by
  /// [close]. A client passed in is left alone, because closing a caller's
  /// client would break other users of it.
  CloudinaryTransport({
    required this.config,
    http.Client? client,
    this.retry = const RetryPolicy(),
    this.timeout = const Duration(seconds: 60),
    this.host = 'api.cloudinary.com',
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  /// Credentials and signing options.
  final CloudinaryConfig config;

  /// Retry behaviour for transient failures.
  final RetryPolicy retry;

  /// Per-attempt timeout.
  final Duration timeout;

  /// API hostname, overridable for testing against a stand-in.
  final String host;

  final http.Client _client;
  final bool _ownsClient;

  /// The underlying client, for request types built elsewhere in the package.
  http.Client get client => _client;

  /// Builds an absolute API URI from path [segments].
  ///
  /// The path is handed to [Uri.https] unencoded, which escapes what needs
  /// escaping while leaving `/` as a real separator. Pre-encoding here would
  /// double-escape, turning a space into `%2520`. A segment may therefore
  /// contain slashes, which is what nested folder paths and folder-qualified
  /// public IDs rely on.
  Uri buildUri(
    List<String> segments, {
    Map<String, dynamic>? query,
    ApiVersion version = ApiVersion.v1_1,
  }) {
    final path = [version.segment, config.cloudName, ...segments].join('/');

    return Uri.https(host, '/$path', _stringifyQuery(query));
  }

  /// Adds `timestamp`, `signature` and `api_key` to a copy of [params].
  ///
  /// Requires local signing capability, checked before the request leaves.
  Map<String, dynamic> signParams(Map<String, dynamic> params) {
    config.requireSigning();

    final signable = stripUnsignedParams(params)
      ..removeWhere((_, v) => v == null)
      ..['timestamp'] = cloudinaryTimestamp();

    return {
      ...params,
      'timestamp': signable['timestamp'],
      'signature': signRequest(
        signable,
        config.apiSecret,
        version: config.signatureVersion,
        algorithm: config.signatureAlgorithm,
      ),
      'api_key': config.apiKey,
    };
  }

  /// Sends a request and returns the decoded JSON body.
  Future<Map<String, dynamic>> send({
    required String method,
    required List<String> segments,
    Map<String, dynamic>? query,
    Map<String, dynamic>? form,
    bool signed = false,
    bool basicAuth = false,
    bool json = false,
    ApiVersion version = ApiVersion.v1_1,
  }) async {
    config.validate();
    if (basicAuth) config.requireSigning();

    final body = signed ? signParams(form ?? const {}) : form;
    final uri = buildUri(segments, query: query, version: version);

    final response = await _sendWithRetry(() {
      final request = http.Request(method, uri);
      if (basicAuth) {
        final creds = base64.encode(
          utf8.encode('${config.apiKey}:${config.apiSecret}'),
        );
        request.headers['authorization'] = 'Basic $creds';
      }
      if (body != null && body.isNotEmpty) {
        if (json) {
          request.headers['content-type'] = 'application/json; charset=utf-8';
          request.body = jsonEncode(_jsonSafe(body));
        } else {
          request.headers['content-type'] =
              'application/x-www-form-urlencoded; charset=utf-8';
          request.bodyFields = _stringifyQuery(body)!;
        }
      }
      return request;
    });

    return _decode(response);
  }

  /// Sends a multipart upload and returns the decoded JSON body.
  ///
  /// A [CloudinaryUrlSource] is sent as a plain `file` field rather than a
  /// file part, because Cloudinary fetches it server-side.
  ///
  /// Multipart uploads are never retried: the body is a one-shot stream, and
  /// replaying a partially-sent upload risks a duplicate asset.
  Future<Map<String, dynamic>> sendMultipart({
    required List<String> segments,
    required Map<String, dynamic> fields,
    CloudinaryFileSource? file,
    CloudinaryProgressCallback? onProgress,
    bool signed = false,
    ApiVersion version = ApiVersion.v1_1,
  }) async {
    config.validate();

    final formFields = <String, dynamic>{...fields};
    if (file is CloudinaryUrlSource) formFields['file'] = file.url;

    final prepared = signed ? signParams(formFields) : formFields;
    final uri = buildUri(segments, version: version);

    final request = ProgressMultipartRequest(
      'POST',
      uri,
      onProgress: onProgress,
    );
    prepared.forEach((key, value) {
      if (value == null) return;
      request.fields[key] = value is Iterable
          ? value.join(',')
          : value.toString();
    });

    switch (file) {
      case CloudinaryBytesSource(:final bytes, :final filename):
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename:
                filename ?? DateTime.now().millisecondsSinceEpoch.toString(),
          ),
        );
      case CloudinaryPathSource(:final path, :final filename):
        try {
          request.files.add(
            await http.MultipartFile.fromPath('file', path, filename: filename),
          );
        } on UnsupportedError {
          throw const CloudinaryConfigException(
            'Uploading from a file path needs dart:io, which is unavailable '
            'on this platform. Use CloudinaryFileSource.bytes instead.',
          );
        }
      case CloudinaryUrlSource():
      case null:
        break;
    }

    http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      );
    } on CloudinaryException {
      rethrow;
    } on TimeoutException catch (e) {
      throw CloudinaryTransportException(
        'Upload timed out after $timeout.',
        cause: e,
      );
    } catch (e) {
      throw CloudinaryTransportException(
        'Could not reach Cloudinary: $e',
        cause: e,
      );
    }

    return _decode(response);
  }

  Future<http.Response> _sendWithRetry(http.Request Function() build) async {
    var attempt = 0;
    while (true) {
      attempt++;
      http.Response response;
      try {
        final streamed = await _client.send(build()).timeout(timeout);
        response = await http.Response.fromStream(streamed);
      } on CloudinaryException {
        rethrow;
      } on TimeoutException catch (e) {
        if (attempt >= retry.maxAttempts) {
          throw CloudinaryTransportException(
            'Request timed out after $timeout.',
            cause: e,
          );
        }
        await Future<void>.delayed(retry.delayFor(attempt));
        continue;
      } catch (e) {
        if (attempt >= retry.maxAttempts) {
          throw CloudinaryTransportException(
            'Could not reach Cloudinary: $e',
            cause: e,
          );
        }
        await Future<void>.delayed(retry.delayFor(attempt));
        continue;
      }

      if (attempt < retry.maxAttempts &&
          retry.shouldRetry(response.statusCode)) {
        await Future<void>.delayed(
          retry.delayFor(attempt, retryAfter: _retryAfter(response)),
        );
        continue;
      }
      return response;
    }
  }

  /// Decodes a response, mapping any non-2xx status to a typed exception.
  Map<String, dynamic> _decode(http.Response response) {
    final status = response.statusCode;
    Map<String, dynamic> parsed;
    try {
      final decoded = response.body.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body);
      parsed = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'result': decoded};
    } on FormatException {
      throw CloudinaryApiException(
        message: status >= 200 && status < 300
            ? 'Cloudinary returned a non-JSON body.'
            : 'Cloudinary returned a non-JSON error body.',
        statusCode: status,
        raw: {'body': response.body},
      );
    }

    if (status >= 200 && status < 300) return parsed;

    final message = _errorMessage(parsed) ?? 'Cloudinary request failed.';
    throw switch (status) {
      401 || 403 => CloudinaryAuthException(
        message: message,
        statusCode: status,
        raw: parsed,
      ),
      404 => CloudinaryNotFoundException(message: message, raw: parsed),
      420 || 429 => CloudinaryRateLimitException(
        message: message,
        statusCode: status,
        raw: parsed,
        limit: _intHeader(response, 'x-featureratelimit-limit'),
        remaining: _intHeader(response, 'x-featureratelimit-remaining'),
        resetAt: _dateHeader(response, 'x-featureratelimit-reset'),
      ),
      _ => CloudinaryApiException(
        message: message,
        statusCode: status,
        raw: parsed,
      ),
    };
  }

  static String? _errorMessage(Map<String, dynamic> body) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    if (error is String) return error;
    if (body['message'] is String) return body['message'] as String;
    return null;
  }

  static int? _intHeader(http.Response r, String name) =>
      int.tryParse(r.headers[name] ?? '');

  static DateTime? _dateHeader(http.Response r, String name) {
    final raw = r.headers[name];
    if (raw == null) return null;
    return parseHttpDate(raw) ?? DateTime.tryParse(raw);
  }

  static Duration? _retryAfter(http.Response r) {
    final raw = r.headers['retry-after'];
    if (raw == null) return null;
    final seconds = int.tryParse(raw);
    if (seconds != null) return Duration(seconds: seconds);
    final at = parseHttpDate(raw);
    if (at == null) return null;
    final delta = at.difference(DateTime.now());
    return delta.isNegative ? Duration.zero : delta;
  }

  /// Renders values as the strings Cloudinary expects on the wire.
  static Map<String, String>? _stringifyQuery(Map<String, dynamic>? input) {
    if (input == null) return null;
    final out = <String, String>{};
    for (final entry in input.entries) {
      final value = entry.value;
      if (value == null) continue;
      out[entry.key] = value is Iterable ? value.join(',') : '$value';
    }
    return out.isEmpty ? null : out;
  }

  static Map<String, dynamic> _jsonSafe(Map<String, dynamic> input) => {
    for (final e in input.entries)
      if (e.value != null) e.key: e.value,
  };

  /// Closes the internally created client, if this transport made one.
  void close() {
    if (_ownsClient) _client.close();
  }
}
