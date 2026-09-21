import 'dart:async';
import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:cloudinary/src/http/transport.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Exercises paths the focused suites leave untouched: every optional upload
/// parameter, the transport's edge cases, and the config copy helpers.
void main() {
  group('upload passes every optional parameter', () {
    test('signed upload', () async {
      late String body;
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
        client: MockClient((req) async {
          body = req.body;
          return http.Response(jsonEncode({'public_id': 'x'}), 200);
        }),
      );

      await c.upload.upload(
        file: const CloudinaryFileSource.url('https://example.com/a.png'),
        publicId: 'pid',
        folder: 'f',
        assetFolder: 'af',
        displayName: 'dn',
        tags: ['t1', 't2'],
        context: {'alt': 'a'},
        overwrite: true,
        invalidate: true,
        useFilename: true,
        uniqueFilename: false,
        transformation: 'w_100',
        eager: 'w_200',
        eagerAsync: true,
        notificationUrl: 'https://hook.example.com',
        extraParams: {'moderation': 'manual'},
      );

      for (final field in [
        'public_id',
        'folder',
        'asset_folder',
        'display_name',
        'tags',
        'context',
        'overwrite',
        'invalidate',
        'use_filename',
        'unique_filename',
        'transformation',
        'eager',
        'eager_async',
        'notification_url',
        'moderation',
      ]) {
        expect(body, contains(field), reason: '$field was not sent');
      }
    });

    test('unsigned upload', () async {
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
        uploadPreset: 'p',
        publicId: 'pid',
        folder: 'f',
        tags: ['t'],
        context: {'alt': 'a'},
        extraParams: {'custom': 'v'},
      );

      expect(body, contains('upload_preset'));
      expect(body, contains('custom'));
    });

    test('explicit, rename, text and archive optional parameters', () async {
      final captured = <String>[];
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
        client: MockClient((req) async {
          captured.add(req.body);
          return http.Response(jsonEncode({'public_id': 'x'}), 200);
        }),
      );

      await c.upload.explicit(
        publicId: 'p',
        eagerAsync: true,
        tags: ['t'],
        notificationUrl: 'https://hook.example.com',
        extraParams: {'custom': 1},
      );
      await c.upload.rename(
        fromPublicId: 'a',
        toPublicId: 'b',
        type: 'upload',
        toType: 'private',
        overwrite: true,
        invalidate: true,
        extraParams: {'custom': 1},
      );
      await c.upload.destroy(
        publicId: 'p',
        type: 'upload',
        extraParams: {'custom': 1},
      );
      await c.upload.text(
        text: 'hi',
        publicId: 'p',
        fontSize: 12,
        fontColor: 'red',
        fontWeight: 'bold',
        background: 'white',
        opacity: 80,
        extraParams: {'custom': 1},
      );
      await c.upload.createArchive(
        publicIds: ['a'],
        targetPublicId: 'zip',
        mode: 'create',
        async: true,
        notificationUrl: 'https://hook.example.com',
        extraParams: {'custom': 1},
      );
      await c.upload.multi(
        urls: ['https://example.com/a.png'],
        transformation: 'w_10',
        format: 'gif',
        async: true,
        notificationUrl: 'https://hook.example.com',
      );
      await c.upload.generateSprite(
        urls: ['https://example.com/a.png'],
        transformation: 'w_10',
        async: true,
        notificationUrl: 'https://hook.example.com',
      );
      await c.upload.explode(
        publicId: 'p',
        transformation: 'pg_all',
        notificationUrl: 'https://hook.example.com',
      );
      await c.upload.destroyByAssetId(assetId: 'aid', invalidate: true);
      await c.upload.createZip(
        publicIds: ['a'],
        targetPublicId: 'z',
        mode: 'create',
      );

      expect(captured, hasLength(10));
      expect(captured.every((b) => b.isNotEmpty), isTrue);
    });
  });

  group('transport edges', () {
    CloudinaryTransport transport(
      http.Response Function(http.Request) handler, {
      RetryPolicy retry = RetryPolicy.none,
      Duration timeout = const Duration(seconds: 60),
    }) => CloudinaryTransport(
      config: const CloudinaryConfig(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
      ),
      client: MockClient((req) async => handler(req)),
      retry: retry,
      timeout: timeout,
    );

    test('the v2 base path is reachable', () {
      final t = transport((_) => http.Response('{}', 200));
      final uri = t.buildUri(['analysis'], version: ApiVersion.v2);
      expect(uri.path, '/v2/demo/analysis');
    });

    test('a JSON array body is wrapped under result', () async {
      final t = transport((_) => http.Response('[1,2]', 200));
      final json = await t.send(method: 'GET', segments: ['x']);
      expect(json['result'], [1, 2]);
    });

    test('an error body with a plain string error', () {
      final t = transport(
        (_) => http.Response('{"error":"plain message"}', 400),
      );
      expect(
        () => t.send(method: 'GET', segments: ['x']),
        throwsA(
          isA<CloudinaryApiException>().having(
            (e) => e.message,
            'message',
            'plain message',
          ),
        ),
      );
    });

    test('an error body with a top-level message', () {
      final t = transport((_) => http.Response('{"message":"top"}', 400));
      expect(
        () => t.send(method: 'GET', segments: ['x']),
        throwsA(
          isA<CloudinaryApiException>().having(
            (e) => e.message,
            'message',
            'top',
          ),
        ),
      );
    });

    test('an error body with nothing recognisable falls back', () {
      final t = transport((_) => http.Response('{}', 400));
      expect(
        () => t.send(method: 'GET', segments: ['x']),
        throwsA(
          isA<CloudinaryApiException>().having(
            (e) => e.message,
            'message',
            contains('failed'),
          ),
        ),
      );
    });

    test('403 maps to an auth exception', () {
      final t = transport(
        (_) => http.Response('{"error":{"message":"no"}}', 403),
      );
      expect(
        () => t.send(method: 'GET', segments: ['x'], basicAuth: true),
        throwsA(isA<CloudinaryAuthException>()),
      );
    });

    test('420 is treated as a rate limit', () {
      final t = transport(
        (_) => http.Response('{"error":{"message":"slow"}}', 420),
      );
      expect(
        () => t.send(method: 'GET', segments: ['x'], basicAuth: true),
        throwsA(isA<CloudinaryRateLimitException>()),
      );
    });

    test('a numeric Retry-After is honoured', () async {
      var calls = 0;
      final t = CloudinaryTransport(
        config: const CloudinaryConfig(
          cloudName: 'demo',
          apiKey: 'k',
          apiSecret: 's',
        ),
        client: MockClient((_) async {
          calls++;
          return calls == 1
              ? http.Response('{}', 503, headers: {'retry-after': '0'})
              : http.Response('{"ok":true}', 200);
        }),
        retry: const RetryPolicy(
          maxAttempts: 2,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      expect((await t.send(method: 'GET', segments: ['x']))['ok'], isTrue);
      expect(calls, 2);
    });

    test('an unparseable Retry-After falls back to the backoff', () async {
      var calls = 0;
      final t = CloudinaryTransport(
        config: const CloudinaryConfig(
          cloudName: 'demo',
          apiKey: 'k',
          apiSecret: 's',
        ),
        client: MockClient((_) async {
          calls++;
          return calls == 1
              ? http.Response('{}', 503, headers: {'retry-after': 'soon'})
              : http.Response('{"ok":true}', 200);
        }),
        retry: const RetryPolicy(
          maxAttempts: 2,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      await t.send(method: 'GET', segments: ['x']);
      expect(calls, 2);
    });

    test('a timeout maps to a transport exception', () {
      final t = CloudinaryTransport(
        config: const CloudinaryConfig(cloudName: 'demo'),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return http.Response('{}', 200);
        }),
        retry: RetryPolicy.none,
        timeout: const Duration(milliseconds: 1),
      );

      expect(
        () => t.send(method: 'GET', segments: ['x']),
        throwsA(isA<CloudinaryTransportException>()),
      );
    });

    test('a transport failure retries before giving up', () async {
      var calls = 0;
      final t = CloudinaryTransport(
        config: const CloudinaryConfig(cloudName: 'demo'),
        client: MockClient((_) async {
          calls++;
          throw const FormatException('boom');
        }),
        retry: const RetryPolicy(
          maxAttempts: 2,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      await expectLater(
        t.send(method: 'GET', segments: ['x']),
        throwsA(isA<CloudinaryTransportException>()),
      );
      expect(calls, 2);
    });

    test('a JSON request with no body sends no content type', () async {
      late http.Request seen;
      final t = transport((req) {
        seen = req;
        return http.Response('{}', 200);
      });

      await t.send(method: 'POST', segments: ['x'], json: true, form: {});
      expect(seen.body, isEmpty);
    });
  });

  group('config helpers', () {
    test('CloudinaryConfig.copyWith replaces each field', () {
      const base = CloudinaryConfig(cloudName: 'a');
      final copy = base.copyWith(
        cloudName: 'b',
        apiKey: 'k',
        apiSecret: 's',
        signatureVersion: 1,
        signatureAlgorithm: CloudinarySignatureAlgorithm.sha256,
      );

      expect(copy.cloudName, 'b');
      expect(copy.apiKey, 'k');
      expect(copy.canSign, isTrue);
      expect(copy.signatureVersion, 1);
      expect(copy.signatureAlgorithm, CloudinarySignatureAlgorithm.sha256);
      expect(base.copyWith().cloudName, 'a');
    });

    test('UrlConfig.copyWith replaces each field', () {
      const base = UrlConfig();
      final copy = base.copyWith(
        secure: false,
        privateCdn: true,
        cname: 'c',
        secureDistribution: 'd',
        cdnSubdomain: true,
        shorten: true,
        useRootPath: true,
        forceVersion: false,
      );

      expect(copy.secure, isFalse);
      expect(copy.privateCdn, isTrue);
      expect(copy.cname, 'c');
      expect(copy.secureDistribution, 'd');
      expect(copy.cdnSubdomain, isTrue);
      expect(copy.shorten, isTrue);
      expect(copy.useRootPath, isTrue);
      expect(copy.forceVersion, isFalse);
      expect(base.copyWith().secure, isTrue);
    });

    test('fromEnvironment throws when the variable is unset', () {
      // CLOUDINARY_URL is not set in the test environment.
      expect(
        Cloudinary.fromEnvironment,
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });

  group('search query remaining builders', () {
    test('fields and ttl', () {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
      );

      final q = c.search
          .query()
          .fields('public_id')
          .fields('public_id')
          .fields('bytes')
          .ttl(60);

      expect(q.toJson()['fields'], ['public_id', 'bytes']);
      expect(q.toUrl(), contains('/60/'));
    });

    test('maxResults, withField and aggregate entry points', () {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
      );

      expect(c.search.maxResults(5).toJson()['max_results'], 5);
      expect(c.search.withField('context').toJson()['with_field'], ['context']);
      expect(c.search.aggregate('format').toJson()['aggregate'], ['format']);
      expect(
        c.search.sortBy('created_at', SortDirection.desc).toJson()['sort_by'],
        [
          {'created_at': 'desc'},
        ],
      );
    });
  });

  group('file sources and url extras', () {
    test('every file source variant constructs', () {
      expect(
        const CloudinaryFileSource.url('https://x/a.png'),
        isA<CloudinaryUrlSource>(),
      );
      expect(
        const CloudinaryFileSource.path('/tmp/a.png'),
        isA<CloudinaryPathSource>(),
      );
    });

    test('transformChain and raw video url options', () {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 'abcd',
      );

      final url = c.url
          .video('clip')
          .transformChain(
            TransformationChain([
              Transformation()..width(100),
              Transformation()..effect(Effect.sepia),
            ]),
          )
          .format('mp4')
          .build();

      expect(url, contains('/video/upload/w_100/e_sepia/clip.mp4'));
    });

    test('a url suffix is appended to the source', () {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 'abcd',
      );

      expect(
        c.url.image('sample').urlSuffix('my-photo').build(),
        endsWith('/sample/my-photo'),
      );
    });
  });
}
