import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

Cloudinary signedWith(MockClient client) => Cloudinary.signed(
  cloudName: 'demo',
  apiKey: 'k',
  apiSecret: 's',
  client: client,
);

void main() {
  test('signed upload posts to the resource-type upload path', () async {
    late Uri seen;
    final c = signedWith(
      MockClient((req) async {
        seen = req.url;
        return http.Response(jsonEncode({'public_id': 'x'}), 200);
      }),
    );

    await c.upload.upload(
      file: CloudinaryFileSource.bytes(Uint8List.fromList([1, 2, 3])),
      resourceType: CloudinaryResourceType.video,
      folder: 'clips',
    );

    expect(seen.path, '/v1_1/demo/video/upload');
  });

  test('resource type defaults to auto', () async {
    late Uri seen;
    final c = signedWith(
      MockClient((req) async {
        seen = req.url;
        return http.Response(jsonEncode({'public_id': 'x'}), 200);
      }),
    );

    await c.upload.upload(
      file: const CloudinaryFileSource.url('https://example.com/a.png'),
    );

    expect(seen.path, '/v1_1/demo/auto/upload');
  });

  test('named options are sent under their Cloudinary names', () async {
    late String body;
    final c = signedWith(
      MockClient((req) async {
        body = req.body;
        return http.Response(jsonEncode({'public_id': 'x'}), 200);
      }),
    );

    await c.upload.upload(
      file: const CloudinaryFileSource.url('https://example.com/a.png'),
      publicId: 'pid',
      folder: 'f',
      displayName: 'Nice Name',
      tags: ['a', 'b'],
      overwrite: true,
      useFilename: false,
    );

    expect(body, contains('public_id'));
    expect(body, contains('display_name'));
    expect(body, contains('use_filename'));
    expect(body, contains('a,b'));
  });

  test('extraParams can override a named option', () async {
    late String body;
    final c = signedWith(
      MockClient((req) async {
        body = req.body;
        return http.Response(jsonEncode({'public_id': 'x'}), 200);
      }),
    );

    await c.upload.upload(
      file: const CloudinaryFileSource.url('https://example.com/a.png'),
      folder: 'original',
      extraParams: {'folder': 'overridden'},
    );

    expect(body, contains('overridden'));
    expect(body, isNot(contains('original')));
  });

  test('unsigned upload sends the preset and no credentials', () async {
    late String body;
    final c = Cloudinary.unsigned(
      cloudName: 'demo',
      client: MockClient((req) async {
        body = req.body;
        return http.Response(jsonEncode({'public_id': 'x'}), 200);
      }),
    );

    await c.upload.unsignedUpload(
      file: const CloudinaryFileSource.url('https://example.com/a.png'),
      uploadPreset: 'my_preset',
    );

    expect(body, contains('my_preset'));
    expect(body, isNot(contains('name="signature"')));
    expect(body, isNot(contains('name="api_key"')));
  });

  test('unsigned upload rejects an empty preset before sending', () async {
    var called = false;
    final c = Cloudinary.unsigned(
      cloudName: 'demo',
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      c.upload.unsignedUpload(
        file: const CloudinaryFileSource.url('https://example.com/a.png'),
        uploadPreset: '',
      ),
      throwsA(isA<CloudinaryConfigException>()),
    );
    expect(called, isFalse);
  });

  test('a signed upload from an unsigned client throws', () async {
    var called = false;
    final c = Cloudinary.unsigned(
      cloudName: 'demo',
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      c.upload.upload(
        file: const CloudinaryFileSource.url('https://example.com/a.png'),
      ),
      throwsA(isA<CloudinaryConfigException>()),
    );
    expect(called, isFalse);
  });

  test('context values escape = and |', () {
    expect(
      encodeContext({'alt': 'a=b|c', 'caption': 'plain'}),
      r'alt=a\=b\|c|caption=plain',
    );
  });

  test('an api error surfaces as a typed exception', () async {
    final c = signedWith(
      MockClient(
        (_) async => http.Response('{"error":{"message":"too large"}}', 400),
      ),
    );

    await expectLater(
      c.upload.upload(
        file: const CloudinaryFileSource.url('https://example.com/a.png'),
      ),
      throwsA(
        isA<CloudinaryApiException>().having(
          (e) => e.message,
          'message',
          'too large',
        ),
      ),
    );
  });
}
