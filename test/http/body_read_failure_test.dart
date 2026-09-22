import 'dart:typed_data';

import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _config = CloudinaryConfig(
  cloudName: 'demo',
  apiKey: 'k',
  apiSecret: 's',
);

class _BodyDied implements Exception {
  const _BodyDied();
  @override
  String toString() => 'connection closed before the full body arrived';
}

/// Headers and a status arrive, then the connection drops mid-body.
Stream<List<int>> _dyingBody() async* {
  yield '{"error":{"mess'.codeUnits;
  throw const _BodyDied();
}

CloudinaryTransport _transport(
  int status, {
  Map<String, String> headers = const {},
  RetryPolicy retry = const RetryPolicy(maxAttempts: 1),
  void Function()? onSend,
}) => CloudinaryTransport(
  config: _config,
  retry: retry,
  client: MockClient.streaming((request, bodyStream) async {
    await bodyStream.drain<void>();
    onSend?.call();
    return http.StreamedResponse(_dyingBody(), status, headers: headers);
  }),
);

Future<void> _destroy(CloudinaryTransport t) => t.send(
  method: 'POST',
  segments: ['image', 'destroy'],
  signed: true,
  form: const {'public_id': 'x'},
);

void main() {
  group('a status survives a body that fails mid-read', () {
    test('401 still maps to an auth exception', () async {
      await expectLater(
        _destroy(_transport(401)),
        throwsA(
          isA<CloudinaryAuthException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('could not be')),
        ),
      );
    });

    test('429 still maps to a rate limit, headers and all', () async {
      await expectLater(
        _destroy(
          _transport(429, headers: {'x-featureratelimit-remaining': '0'}),
        ),
        throwsA(
          isA<CloudinaryRateLimitException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.remaining, 'remaining', 0),
        ),
      );
    });

    test('the read error is named in the message', () async {
      await expectLater(
        _destroy(_transport(500)),
        throwsA(
          isA<CloudinaryApiException>().having(
            (e) => e.message,
            'message',
            contains('connection closed before the full body arrived'),
          ),
        ),
      );
    });

    test('a 2xx stays a transport failure, never a half-read result', () async {
      await expectLater(
        _destroy(_transport(200)),
        throwsA(
          isA<CloudinaryTransportException>().having(
            (e) => e.cause,
            'cause',
            isA<_BodyDied>(),
          ),
        ),
      );
    });

    test('a throttled POST is still retried', () async {
      var sends = 0;
      final transport = _transport(
        429,
        retry: const RetryPolicy(maxAttempts: 3, baseDelay: Duration.zero),
        onSend: () => sends++,
      );
      await expectLater(
        _destroy(transport),
        throwsA(isA<CloudinaryRateLimitException>()),
      );
      expect(sends, 3, reason: 'a 429 says the server did not act');
    });

    test('a 503 does not replay a POST', () async {
      var sends = 0;
      final transport = _transport(
        503,
        retry: const RetryPolicy(maxAttempts: 3, baseDelay: Duration.zero),
        onSend: () => sends++,
      );
      await expectLater(
        _destroy(transport),
        throwsA(isA<CloudinaryApiException>()),
      );
      expect(sends, 1, reason: 'a POST may already have been applied');
    });

    test('multipart uploads take the same path', () async {
      await expectLater(
        _transport(401).sendMultipart(
          segments: ['image', 'upload'],
          fields: const {},
          file: CloudinaryFileSource.bytes(
            Uint8List.fromList([1, 2, 3]),
            filename: 'a.bin',
          ),
          signed: true,
        ),
        throwsA(isA<CloudinaryAuthException>()),
      );
    });
  });
}
