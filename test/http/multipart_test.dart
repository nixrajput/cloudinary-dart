import 'dart:typed_data';

import 'package:cloudinary/cloudinary.dart';
import 'package:cloudinary/src/http/transport.dart';
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

  test('signed multipart carries signature, api_key and a seconds timestamp',
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
  });

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
      throwsA(isA<CloudinaryApiException>()
          .having((e) => e.message, 'message', 'too big')),
    );
  });
}
