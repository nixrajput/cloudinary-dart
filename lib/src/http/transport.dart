import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/signature.dart';
import '../auth/signature_provider.dart';
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
    this.signatureProvider,
    this.retry = const RetryPolicy(),
    this.timeout = const Duration(seconds: 60),
    this.host = 'api.cloudinary.com',
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  /// Credentials and signing options.
  final CloudinaryConfig config;

  /// Signs requests remotely when the client holds no API secret.
  final SignatureProvider? signatureProvider;

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
    // Uri collapses dot segments, so a `..` reaching here would walk out of
    // the cloud-name scope and re-aim an authenticated request at another
    // endpoint. Public IDs and folder paths are caller data, so reject it.
    for (final part in segments.expand((s) => s.split('/'))) {
      if (part == '.' || part == '..') {
        throw CloudinaryConfigException(
          'Path segments must not contain "$part": it would change which '
          'Cloudinary endpoint the request reaches.',
        );
      }
    }

    final path = [version.segment, config.cloudName, ...segments].join('/');

    return Uri.https(host, '/$path', _stringifyQuery(query));
  }

  /// Adds `timestamp`, `signature` and `api_key` to a copy of [params].
  ///
  /// Requires local signing capability, checked before the request leaves.
  Future<Map<String, dynamic>> signParams(Map<String, dynamic> params) async {
    final provider = signatureProvider;

    final signable = stripUnsignedParams(params)
      ..removeWhere((_, v) => v == null);

    // A provider signs on a server that holds the secret, so it also owns the
    // timestamp: signing one value and sending another would not verify.
    if (provider != null) {
      final remote = await provider.sign(Map.unmodifiable(signable));
      return {
        ...params,
        'timestamp': remote.timestamp,
        'signature': remote.signature,
        'api_key': remote.apiKey,
      };
    }

    config.requireSigning();
    signable['timestamp'] = cloudinaryTimestamp();

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

    final body = signed ? await signParams(form ?? const {}) : form;
    final uri = buildUri(segments, query: query, version: version);

    final response = await _sendWithRetry(method, () {
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
          request.body = encodeForm(body);
        }
      }
      return request;
    });

    final (result, bodyReadError) = response;
    return _decode(result, bodyReadError: bodyReadError);
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

    final prepared = signed ? await signParams(formFields) : formFields;
    final uri = buildUri(segments, version: version);

    final request = ProgressMultipartRequest(
      'POST',
      uri,
      onProgress: onProgress,
    );
    // MultipartRequest.fields is a Map, so a repeated key would silently keep
    // only the last value while the signature covered every one of them.
    // Nothing in the Upload API needs repeats today, so say so rather than
    // send a body that disagrees with its own signature.
    for (final entry in CloudinaryTransport.flattenParams(prepared)) {
      if (request.fields.containsKey(entry.key)) {
        throw CloudinaryConfigException(
          'Multipart uploads cannot repeat the field "${entry.key}". Pass a '
          'single value, or join it yourself.',
        );
      }
      request.fields[entry.key] = entry.value;
    }

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
        } on Exception catch (e) {
          // A missing or unreadable file would otherwise escape as a raw
          // dart:io error, breaking the promise that every failure is a
          // CloudinaryException.
          throw CloudinaryTransportException(
            'Could not read the file at "$path": $e',
            cause: e,
          );
        }
      case CloudinaryUrlSource():
      case null:
        break;
    }

    (http.Response, Object?) read;
    try {
      read = await _client.send(request).then(_readBody).timeout(timeout);
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

    final (response, bodyReadError) = read;
    return _decode(response, bodyReadError: bodyReadError);
  }

  /// Reads [streamed] into a response, keeping the status line when the body
  /// fails.
  ///
  /// A connection that dies mid-body has still delivered a status and headers,
  /// and those alone decide whether the call retries and which exception it
  /// maps to. Discarding them turns a rate limit the server explicitly
  /// reported into an unclassified transport failure that a POST then refuses
  /// to retry. A 2xx is the exception: there the body *is* the result, so a
  /// truncated read cannot stand in for one and stays a transport failure.
  ///
  /// The returned record carries the read error alongside the response so the
  /// thrown exception can name it.
  static Future<(http.Response, Object?)> _readBody(
    http.StreamedResponse streamed,
  ) async {
    try {
      return (await http.Response.fromStream(streamed), null);
    } on CloudinaryException {
      rethrow;
    } catch (e) {
      final status = streamed.statusCode;
      if (status >= 200 && status < 300) {
        throw CloudinaryTransportException(
          'Cloudinary answered $status but the response body could not be '
          'read: $e',
          cause: e,
        );
      }
      return (
        http.Response(
          '',
          status,
          headers: streamed.headers,
          reasonPhrase: streamed.reasonPhrase,
        ),
        e,
      );
    }
  }

  /// HTTP methods safe to replay after a transport failure.
  ///
  /// A POST or DELETE may already have been applied when the connection
  /// dropped, so replaying it could rename twice or bill a second archive.
  /// A status-code retry is still allowed for those, because the server
  /// answered and told us it did not act.
  static const Set<String> _replayableMethods = {'GET', 'HEAD', 'OPTIONS'};

  Future<(http.Response, Object?)> _sendWithRetry(
    String method,
    http.Request Function() build,
  ) async {
    final replayable = _replayableMethods.contains(method.toUpperCase());
    var attempt = 0;
    while (true) {
      attempt++;
      (http.Response, Object?) read;
      try {
        read = await _client.send(build()).then(_readBody).timeout(timeout);
      } on CloudinaryException {
        rethrow;
      } on TimeoutException catch (e) {
        if (attempt >= retry.maxAttempts || !replayable) {
          throw CloudinaryTransportException(
            'Request timed out after $timeout.',
            cause: e,
          );
        }
        await Future<void>.delayed(retry.delayFor(attempt));
        continue;
      } catch (e) {
        if (attempt >= retry.maxAttempts || !replayable) {
          throw CloudinaryTransportException(
            'Could not reach Cloudinary: $e',
            cause: e,
          );
        }
        await Future<void>.delayed(retry.delayFor(attempt));
        continue;
      }

      final response = read.$1;
      final rateLimited =
          response.statusCode == 429 || response.statusCode == 420;
      if (attempt < retry.maxAttempts &&
          retry.shouldRetry(response.statusCode) &&
          (replayable || rateLimited)) {
        await Future<void>.delayed(
          retry.delayFor(attempt, retryAfter: _retryDelay(response)),
        );
        continue;
      }
      return read;
    }
  }

  Map<String, dynamic> _decode(
    http.Response response, {
    Object? bodyReadError,
  }) {
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

    final message =
        _errorMessage(parsed) ??
        (bodyReadError != null
            ? 'Cloudinary request failed. The response body could not be '
                  'read: $bodyReadError'
            : 'Cloudinary request failed.');
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

  /// How long to wait before repeating a throttled request.
  ///
  /// Cloudinary's Admin API signals feature rate limits with
  /// `X-FeatureRateLimit-Reset` rather than `Retry-After`, so retrying on the
  /// plain backoff would burn the remaining attempts against an hourly quota.
  static Duration? _retryDelay(http.Response r) {
    final after = _retryAfter(r);
    if (after != null) return after;

    final reset = _dateHeader(r, 'x-featureratelimit-reset');
    if (reset == null) return null;
    final delta = reset.difference(DateTime.now());
    // A stale reset date would otherwise retry instantly; fall back to the
    // computed backoff instead.
    return delta > Duration.zero ? delta : null;
  }

  static Duration? _retryAfter(http.Response r) {
    final raw = r.headers['retry-after'];
    if (raw == null) return null;
    final seconds = int.tryParse(raw);
    if (seconds != null) {
      return seconds > 0 ? Duration(seconds: seconds) : null;
    }
    final at = parseHttpDate(raw);
    if (at == null) return null;
    final delta = at.difference(DateTime.now());
    return delta > Duration.zero ? delta : null;
  }

  /// Flattens parameters the way Cloudinary's own encoder does.
  ///
  /// An iterable becomes repeated `key[]=a&key[]=b` pairs, matching
  /// `hashToParameters` in Cloudinary's SDKs. Comma-joining instead would
  /// make the server read one value literally named `a,b`. A parameter that
  /// must be comma-joined, such as an upload's `tags`, is joined by its
  /// caller and arrives here as a string.
  static List<MapEntry<String, String>> flattenParams(
    Map<String, dynamic>? input,
  ) {
    if (input == null) return const [];
    final out = <MapEntry<String, String>>[];
    for (final entry in input.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is Iterable) {
        final key = entry.key.endsWith('[]') ? entry.key : '${entry.key}[]';
        for (final item in value) {
          out.add(MapEntry(key, '$item'));
        }
      } else if (value is Map) {
        // Dart's toString would emit `{a: b}` and the signature would be
        // computed over that, so say so rather than sending nonsense.
        throw CloudinaryConfigException(
          'Parameter "${entry.key}" is a Map. Cloudinary takes structured '
          'values as strings, so encode it yourself (JSON, or the '
          'key=value|key=value form for context and metadata).',
        );
      } else {
        out.add(MapEntry(entry.key, '$value'));
      }
    }
    return out;
  }

  /// Query parameters for [Uri.https], which emits repeated keys for a list
  /// value.
  static Map<String, dynamic>? _stringifyQuery(Map<String, dynamic>? input) {
    final flat = flattenParams(input);
    if (flat.isEmpty) return null;

    final out = <String, dynamic>{};
    for (final entry in flat) {
      final existing = out[entry.key];
      if (existing == null) {
        out[entry.key] = entry.value;
      } else if (existing is List<String>) {
        existing.add(entry.value);
      } else {
        out[entry.key] = <String>[existing as String, entry.value];
      }
    }
    return out;
  }

  /// Form body, percent-encoded, preserving repeated keys.
  static String encodeForm(Map<String, dynamic>? input) => flattenParams(input)
      .map(
        (e) =>
            '${Uri.encodeQueryComponent(e.key)}='
            '${Uri.encodeQueryComponent(e.value)}',
      )
      .join('&');

  static Map<String, dynamic> _jsonSafe(Map<String, dynamic> input) => {
    for (final e in input.entries)
      if (e.value != null) e.key: e.value,
  };

  /// Closes the internally created client, if this transport made one.
  void close() {
    if (_ownsClient) _client.close();
  }
}
