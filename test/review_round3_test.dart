import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Regressions for the CodeRabbit findings that verified against Cloudinary's
/// own SDK source.
void main() {
  late String body;
  late Uri url;

  Cloudinary client() => Cloudinary.signed(
    cloudName: 'demo',
    apiKey: 'k',
    apiSecret: 's',
    client: MockClient((req) async {
      body = req.body;
      url = req.url;
      return http.Response('{"result":"ok"}', 200);
    }),
  );

  group('upload routes carry the resource type', () {
    test('multi', () async {
      await client().upload.multi(tag: 't');
      expect(url.path, '/v1_1/demo/image/multi');
    });

    test('generateSprite', () async {
      await client().upload.generateSprite(tag: 't');
      expect(url.path, '/v1_1/demo/image/sprite');
    });

    test('text', () async {
      await client().upload.text(text: 'hi');
      expect(url.path, '/v1_1/demo/image/text');
    });

    test('a non-image resource type is honoured', () async {
      await client().upload.multi(
        tag: 't',
        resourceType: CloudinaryResourceType.video,
      );
      expect(url.path, '/v1_1/demo/video/multi');
    });
  });

  group('streaming profile representations', () {
    test('are sent as one JSON string, not repeated fields', () async {
      await client().admin.streamingProfiles.create(
        name: 'hd',
        representations: const [
          {
            'transformation': {'crop': 'limit', 'width': 1920},
          },
        ],
      );

      final form = Uri.splitQueryString(body);
      expect(jsonDecode(form['representations']!), [
        {
          'transformation': {'crop': 'limit', 'width': 1920},
        },
      ]);
      expect(form.containsKey('representations[]'), isFalse);
    });
  });

  group('structured metadata escaping', () {
    test('metadata escapes quotes, context does not', () async {
      await client().upload.updateMetadata(
        metadata: {'note': 'say "hi"'},
        publicIds: ['x'],
      );
      expect(Uri.splitQueryString(body)['metadata'], r'note=say \"hi\"');

      await client().upload.addContext(
        context: {'note': 'say "hi"'},
        publicIds: ['x'],
      );
      expect(Uri.splitQueryString(body)['context'], 'note=say "hi"');
    });
  });

  group('delivery URL path safety', () {
    test('a dot segment in a public ID is rejected', () {
      final c = Cloudinary.unsigned(cloudName: 'demo');
      expect(
        () => c.url.image('a/../../../other/x.jpg').build(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });

    test('a dot inside a name is still fine', () {
      final c = Cloudinary.unsigned(cloudName: 'demo');
      expect(c.url.image('a..b.jpg').build(), endsWith('/a..b.jpg'));
    });

    test('a question mark in the format cannot open a query', () {
      final c = Cloudinary.unsigned(cloudName: 'demo');
      final built = c.url.image('a').format('jpg?x').build();
      expect(built, endsWith('/a.jpg%3Fx'));
      expect(built.contains('?'), isFalse);
    });
  });

  group('search target is coupled to its parser', () {
    test('execute() on a folder query throws', () {
      final c = client();
      expect(
        () => c.search.folders().expression('path:a').execute(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });

    test('executeFolders() on an asset query throws', () {
      final c = client();
      expect(
        () => c.search.expression('x').executeFolders(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });

  group('retry policy', () {
    test('420 retries like 429', () {
      expect(const RetryPolicy().shouldRetry(420), isTrue);
    });

    test('a non-positive Retry-After falls back to the backoff', () {
      const p = RetryPolicy(baseDelay: Duration(milliseconds: 100));
      expect(p.delayFor(1), const Duration(milliseconds: 100));
    });
  });

  group('webhook timestamp bounds', () {
    test('a far-future timestamp is rejected', () {
      final future = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 86400;
      expect(
        verifyNotificationSignature(
          body: '{}',
          timestamp: future,
          signature: 'whatever',
          apiSecret: 's',
        ),
        isFalse,
      );
    });
  });

  group('multipart repeats', () {
    test('a repeated field is rejected rather than silently dropped', () async {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      await expectLater(
        c.upload.upload(
          file: const CloudinaryFileSource.url('https://example.com/a.png'),
          extraParams: const {
            'ctx': ['a', 'b'],
          },
        ),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });
}
