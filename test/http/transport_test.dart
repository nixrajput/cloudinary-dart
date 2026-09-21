import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:cloudinary/src/http/transport.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _signed = CloudinaryConfig(
  cloudName: 'demo',
  apiKey: 'key',
  apiSecret: 'secret',
);

CloudinaryTransport transportReturning(
  http.Response Function(http.Request) handler, {
  CloudinaryConfig config = _signed,
  RetryPolicy retry = RetryPolicy.none,
}) => CloudinaryTransport(
  config: config,
  client: MockClient((req) async => handler(req)),
  retry: retry,
);

void main() {
  group('uri building', () {
    test('builds the v1_1 path from segments', () async {
      late Uri seen;
      final t = transportReturning((req) {
        seen = req.url;
        return http.Response('{"ok":true}', 200);
      });

      await t.send(method: 'GET', segments: ['resources', 'image']);

      expect(seen.host, 'api.cloudinary.com');
      expect(seen.path, '/v1_1/demo/resources/image');
      expect(seen.scheme, 'https');
    });

    test(
      'query parameters are rendered and lists become repeated keys',
      () async {
        late Uri seen;
        final t = transportReturning((req) {
          seen = req.url;
          return http.Response('{}', 200);
        });

        await t.send(
          method: 'GET',
          segments: ['resources', 'image'],
          query: {
            'max_results': 10,
            'tags': ['a', 'b'],
            'skipped': null,
          },
        );

        expect(seen.queryParameters['max_results'], '10');
        // Cloudinary's own encoder appends [] to an array key and repeats it.
        expect(seen.queryParametersAll['tags[]'], ['a', 'b']);
        expect(seen.queryParameters.containsKey('skipped'), isFalse);
      },
    );
  });

  group('authentication', () {
    test('basic auth goes in the header, never the URL', () async {
      late http.Request seen;
      final t = transportReturning((req) {
        seen = req;
        return http.Response('{"ok":true}', 200);
      });

      await t.send(method: 'GET', segments: ['ping'], basicAuth: true);

      expect(
        seen.headers['authorization'],
        'Basic ${base64.encode(utf8.encode('key:secret'))}',
      );
      expect(seen.url.userInfo, isEmpty);
      expect(seen.url.toString(), isNot(contains('secret')));
    });

    test('signed requests carry api_key, timestamp and signature', () async {
      late http.Request seen;
      final t = transportReturning((req) {
        seen = req;
        return http.Response('{"ok":true}', 200);
      });

      await t.send(
        method: 'POST',
        segments: ['image', 'destroy'],
        form: {'public_id': 'sample'},
        signed: true,
      );

      final body = Uri.splitQueryString(seen.body);
      expect(body['api_key'], 'key');
      expect(body['public_id'], 'sample');
      expect(body['signature'], hasLength(40));
      expect(
        int.parse(body['timestamp']!).toString().length,
        lessThanOrEqualTo(10),
        reason: 'timestamp must be seconds, not milliseconds',
      );
    });

    test('a signed call without a secret throws before any request', () async {
      var called = false;
      final t = transportReturning((_) {
        called = true;
        return http.Response('{}', 200);
      }, config: const CloudinaryConfig(cloudName: 'demo'));

      await expectLater(
        t.send(method: 'POST', segments: ['image', 'destroy'], signed: true),
        throwsA(isA<CloudinaryConfigException>()),
      );
      expect(called, isFalse, reason: 'nothing may reach the network');
    });
  });

  group('error mapping', () {
    test('401 maps to CloudinaryAuthException', () {
      final t = transportReturning(
        (_) => http.Response('{"error":{"message":"bad key"}}', 401),
      );

      expect(
        () => t.send(method: 'GET', segments: ['ping'], basicAuth: true),
        throwsA(
          isA<CloudinaryAuthException>().having(
            (e) => e.message,
            'message',
            'bad key',
          ),
        ),
      );
    });

    test('404 maps to CloudinaryNotFoundException', () {
      final t = transportReturning(
        (_) => http.Response('{"error":{"message":"not found"}}', 404),
      );

      expect(
        () => t.send(method: 'GET', segments: ['ping'], basicAuth: true),
        throwsA(isA<CloudinaryNotFoundException>()),
      );
    });

    test('429 carries the rate limit headers', () {
      final t = transportReturning(
        (_) => http.Response(
          '{"error":{"message":"rate limited"}}',
          429,
          headers: {
            'x-featureratelimit-limit': '500',
            'x-featureratelimit-remaining': '0',
            'x-featureratelimit-reset': 'Wed, 03 Sep 2026 09:00:00 GMT',
          },
        ),
      );

      expect(
        () => t.send(method: 'GET', segments: ['ping'], basicAuth: true),
        throwsA(
          isA<CloudinaryRateLimitException>()
              .having((e) => e.limit, 'limit', 500)
              .having((e) => e.remaining, 'remaining', 0)
              .having((e) => e.resetAt, 'resetAt', DateTime.utc(2026, 9, 3, 9)),
        ),
      );
    });

    test('500 maps to the generic api exception with the raw body', () {
      final t = transportReturning(
        (_) => http.Response('{"error":{"message":"boom"},"extra":1}', 500),
      );

      expect(
        () => t.send(method: 'GET', segments: ['ping'], basicAuth: true),
        throwsA(
          isA<CloudinaryApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.raw['extra'], 'raw.extra', 1),
        ),
      );
    });

    test('a non-JSON body does not leak a FormatException', () {
      final t = transportReturning(
        (_) => http.Response('<html>oops</html>', 200),
      );

      expect(
        () => t.send(method: 'GET', segments: ['ping']),
        throwsA(isA<CloudinaryApiException>()),
      );
    });

    test('a socket failure maps to CloudinaryTransportException', () {
      final t = CloudinaryTransport(
        config: const CloudinaryConfig(cloudName: 'demo'),
        client: MockClient((_) async => throw const _Boom()),
        retry: RetryPolicy.none,
      );

      expect(
        () => t.send(method: 'GET', segments: ['ping']),
        throwsA(
          isA<CloudinaryTransportException>().having(
            (e) => e.cause,
            'cause',
            isA<_Boom>(),
          ),
        ),
      );
    });

    test('an empty body on 200 decodes to an empty map', () async {
      final t = transportReturning((_) => http.Response('', 200));
      expect(await t.send(method: 'GET', segments: ['ping']), isEmpty);
    });
  });

  group('retry', () {
    test('retries a 503 then succeeds', () async {
      var calls = 0;
      final t = CloudinaryTransport(
        config: _signed,
        client: MockClient((_) async {
          calls++;
          return calls < 3
              ? http.Response('{"error":{"message":"busy"}}', 503)
              : http.Response('{"ok":true}', 200);
        }),
        retry: const RetryPolicy(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      final result = await t.send(method: 'GET', segments: ['ping']);

      expect(calls, 3);
      expect(result['ok'], isTrue);
    });

    test('gives up after maxAttempts and throws the last failure', () async {
      var calls = 0;
      final t = CloudinaryTransport(
        config: _signed,
        client: MockClient((_) async {
          calls++;
          return http.Response('{"error":{"message":"busy"}}', 503);
        }),
        retry: const RetryPolicy(
          maxAttempts: 2,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      await expectLater(
        t.send(method: 'GET', segments: ['ping']),
        throwsA(isA<CloudinaryApiException>()),
      );
      expect(calls, 2);
    });

    test('does not retry a 500', () async {
      var calls = 0;
      final t = CloudinaryTransport(
        config: _signed,
        client: MockClient((_) async {
          calls++;
          return http.Response('{"error":{"message":"boom"}}', 500);
        }),
        retry: const RetryPolicy(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      await expectLater(
        t.send(method: 'GET', segments: ['ping']),
        throwsA(isA<CloudinaryApiException>()),
      );
      expect(calls, 1, reason: 'a 500 may have partially succeeded');
    });
  });

  group('client ownership', () {
    test('an injected client is not closed by close()', () async {
      final injected = MockClient((_) async => http.Response('{}', 200));
      final t = CloudinaryTransport(config: _signed, client: injected);

      t.close();

      // A closed MockClient throws on use; this must still work.
      final response = await injected.get(Uri.https('example.com', '/'));
      expect(response.statusCode, 200);
    });
  });
}

class _Boom implements Exception {
  const _Boom();
}
