import 'dart:async';
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

void main() {
  test('reports monotonic progress ending at the content length', () async {
    final events = <List<int>>[];
    final transport = CloudinaryTransport(
      config: _config,
      client: MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value('{"public_id":"x"}'.codeUnits),
          200,
        );
      }),
    );

    await transport.sendMultipart(
      segments: ['image', 'upload'],
      fields: {'folder': 'test'},
      file: CloudinaryFileSource.bytes(
        Uint8List.fromList(List.filled(256 * 1024, 7)),
        filename: 'big.bin',
      ),
      signed: true,
      onProgress: (sent, total) => events.add([sent, total]),
    );

    expect(events, isNotEmpty);
    expect(events.last[0], events.last[1], reason: 'ends at 100%');
    expect(events.last[1], greaterThan(256 * 1024));
    for (var i = 1; i < events.length; i++) {
      expect(events[i][0], greaterThanOrEqualTo(events[i - 1][0]));
    }
  });

  test('no progress callback still uploads', () async {
    final transport = CloudinaryTransport(
      config: _config,
      client: MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value('{"public_id":"x"}'.codeUnits),
          200,
        );
      }),
    );

    final result = await transport.sendMultipart(
      segments: ['image', 'upload'],
      fields: const {},
      file: CloudinaryFileSource.bytes(Uint8List.fromList([1, 2, 3])),
      signed: true,
    );

    expect(result['public_id'], 'x');
  });

  test('a remote URL is a plain field, not a file part', () async {
    late String body;
    final transport = CloudinaryTransport(
      config: _config,
      client: MockClient((request) async {
        body = request.body;
        return http.Response('{"public_id":"x"}', 200);
      }),
    );

    await transport.sendMultipart(
      segments: ['image', 'upload'],
      fields: const {},
      file: const CloudinaryFileSource.url('https://example.com/a.png'),
      signed: true,
    );

    expect(body, contains('https://example.com/a.png'));
    expect(body, isNot(contains('filename=')));
  });

  test(
    'signed multipart carries signature, api_key and a seconds timestamp',
    () async {
      late String body;
      final transport = CloudinaryTransport(
        config: _config,
        client: MockClient((request) async {
          body = request.body;
          return http.Response('{"public_id":"x"}', 200);
        }),
      );

      await transport.sendMultipart(
        segments: ['image', 'upload'],
        fields: {'folder': 'f'},
        file: const CloudinaryFileSource.url('https://example.com/a.png'),
        signed: true,
      );

      expect(body, contains('name="signature"'));
      expect(body, contains('name="api_key"'));
      final ts = RegExp(r'name="timestamp"\r\n\r\n(\d+)').firstMatch(body);
      expect(ts, isNotNull);
      expect(ts!.group(1)!.length, lessThanOrEqualTo(10));
    },
  );

  test('unsigned multipart sends no signature', () async {
    late String body;
    final transport = CloudinaryTransport(
      config: const CloudinaryConfig(cloudName: 'demo'),
      client: MockClient((request) async {
        body = request.body;
        return http.Response('{"public_id":"x"}', 200);
      }),
    );

    await transport.sendMultipart(
      segments: ['image', 'upload'],
      fields: {'upload_preset': 'p'},
      file: const CloudinaryFileSource.url('https://example.com/a.png'),
    );

    expect(body, contains('upload_preset'));
    expect(body, isNot(contains('name="signature"')));
  });

  test('an error status still maps to a typed exception', () async {
    final transport = CloudinaryTransport(
      config: _config,
      client: MockClient(
        (_) async => http.Response('{"error":{"message":"too big"}}', 400),
      ),
    );

    await expectLater(
      transport.sendMultipart(
        segments: ['image', 'upload'],
        fields: const {},
        file: const CloudinaryFileSource.url('https://example.com/a.png'),
        signed: true,
      ),
      throwsA(
        isA<CloudinaryApiException>().having(
          (e) => e.message,
          'message',
          'too big',
        ),
      ),
    );
  });

  test(
    'a path source uploads the file under its own or a given name',
    () async {
      final bodies = <String>[];
      final transport = CloudinaryTransport(
        config: _config,
        client: MockClient((request) async {
          bodies.add(request.body);
          return http.Response('{"public_id":"x"}', 200);
        }),
      );

      for (final source in const [
        CloudinaryFileSource.path('pubspec.yaml'),
        CloudinaryFileSource.path('pubspec.yaml', filename: 'manifest.yaml'),
      ]) {
        await transport.sendMultipart(
          segments: ['image', 'upload'],
          fields: const {},
          file: source,
          signed: true,
        );
      }

      expect(bodies[0], contains('name="file"; filename="pubspec.yaml"'));
      expect(bodies[0], contains('name: cloudinary'));
      expect(bodies[1], contains('name="file"; filename="manifest.yaml"'));
    },
    testOn: 'vm',
  );

  test('an unreadable path is a transport exception naming it', () async {
    var sent = false;
    final transport = CloudinaryTransport(
      config: _config,
      client: MockClient((_) async {
        sent = true;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      transport.sendMultipart(
        segments: ['image', 'upload'],
        fields: const {},
        file: const CloudinaryFileSource.path('missing/photo.jpg'),
        signed: true,
      ),
      throwsA(
        isA<CloudinaryTransportException>()
            .having((e) => e.message, 'message', contains('missing/photo.jpg'))
            .having((e) => e.cause, 'cause', isA<Exception>()),
      ),
    );
    expect(sent, isFalse);
  }, testOn: 'vm');

  test('a path source on the web asks for bytes instead', () async {
    final transport = CloudinaryTransport(
      config: _config,
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    await expectLater(
      transport.sendMultipart(
        segments: ['image', 'upload'],
        fields: const {},
        file: const CloudinaryFileSource.path('photo.jpg'),
        signed: true,
      ),
      throwsA(
        isA<CloudinaryConfigException>().having(
          (e) => e.message,
          'message',
          contains('CloudinaryFileSource.bytes'),
        ),
      ),
    );
  }, testOn: 'browser');

  test(
    'an upload that outlives the timeout is a transport exception',
    () async {
      final transport = CloudinaryTransport(
        config: _config,
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return http.Response('{"public_id":"x"}', 200);
        }),
      );

      await expectLater(
        transport.sendMultipart(
          segments: ['image', 'upload'],
          fields: const {},
          file: const CloudinaryFileSource.url('https://example.com/a.png'),
          signed: true,
        ),
        throwsA(
          isA<CloudinaryTransportException>()
              .having((e) => e.message, 'message', contains('timed out'))
              .having((e) => e.cause, 'cause', isA<TimeoutException>()),
        ),
      );
    },
  );

  test('a failed upload is never retried', () async {
    var calls = 0;
    final transport = CloudinaryTransport(
      config: _config,
      retry: const RetryPolicy(maxAttempts: 3, baseDelay: Duration.zero),
      client: MockClient((_) async {
        calls++;
        throw http.ClientException('connection reset by peer');
      }),
    );

    await expectLater(
      transport.sendMultipart(
        segments: ['image', 'upload'],
        fields: const {},
        file: CloudinaryFileSource.bytes(Uint8List.fromList([1, 2, 3])),
        signed: true,
      ),
      throwsA(
        isA<CloudinaryTransportException>()
            .having((e) => e.message, 'message', contains('connection reset'))
            .having((e) => e.cause, 'cause', isA<http.ClientException>()),
      ),
    );
    expect(calls, 1, reason: 'a replayed upload can create a duplicate asset');
  });
}
