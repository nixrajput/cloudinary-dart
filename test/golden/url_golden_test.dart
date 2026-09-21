import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

/// Signature and shard vectors computed from Cloudinary's own algorithm:
/// base64 of the digest over `<to_sign><apiSecret>`, truncated, with `/`
/// and `+` swapped for `_` and `-`. Secret is `abcd` throughout.
void main() {
  Cloudinary demo({UrlConfig? url}) => Cloudinary.signed(
    cloudName: 'demo',
    apiKey: 'k',
    apiSecret: 'abcd',
    urlConfig: url ?? const UrlConfig(),
  );

  Transformation fill100x150() => Transformation()
    ..width(100)
    ..height(150)
    ..crop(CropMode.fill);

  group('basics', () {
    test('secure url on the shared cdn', () {
      expect(
        demo().url.image('sample.jpg').build(),
        'https://res.cloudinary.com/demo/image/upload/sample.jpg',
      );
    });

    test('transformation sits before the public id', () {
      expect(
        demo().url.image('sample.jpg').transform(fill100x150()).build(),
        'https://res.cloudinary.com/demo/image/upload'
        '/c_fill,h_150,w_100/sample.jpg',
      );
    });

    test('video and raw resource types', () {
      expect(
        demo().url.video('clip').build(),
        'https://res.cloudinary.com/demo/video/upload/clip',
      );
      expect(
        demo().url.raw('doc.txt').build(),
        'https://res.cloudinary.com/demo/raw/upload/doc.txt',
      );
    });

    test('delivery type changes the second segment', () {
      expect(
        demo().url
            .image('sample.jpg')
            .deliveryType(CloudinaryDeliveryType.authenticated)
            .build(),
        'https://res.cloudinary.com/demo/image/authenticated/sample.jpg',
      );
    });

    test('format appends an extension', () {
      expect(
        demo().url.image('sample').format('webp').build(),
        'https://res.cloudinary.com/demo/image/upload/sample.webp',
      );
    });

    test('an absolute http source is returned untouched', () {
      expect(
        demo().url.image('https://example.com/a.png').build(),
        'https://example.com/a.png',
      );
    });

    test('a space in the public id is percent-encoded', () {
      expect(
        demo().url.image('my sample.jpg').build(),
        'https://res.cloudinary.com/demo/image/upload/my%20sample.jpg',
      );
    });
  });

  group('signing', () {
    test('sha1 truncated to 8 characters', () {
      expect(
        demo().url.image('sample.jpg').signed().build(),
        'https://res.cloudinary.com/demo/image/upload'
        '/s--lGdq5NKO--/sample.jpg',
      );
    });

    test('a transformation is signed together with the source', () {
      expect(
        demo().url
            .image('sample.jpg')
            .transform(fill100x150())
            .signed()
            .build(),
        'https://res.cloudinary.com/demo/image/upload/s--pPjadawp--'
        '/c_fill,h_150,w_100/sample.jpg',
      );
    });

    test('a long signature uses sha256 truncated to 32', () {
      expect(
        demo().url.image('sample.jpg').signed(longSignature: true).build(),
        'https://res.cloudinary.com/demo/image/upload'
        '/s--ZpqZj1Oc4nbeNu4FrlHDZCbYtTcdr4st--/sample.jpg',
      );
    });

    test('signing without a secret throws', () {
      final c = Cloudinary.unsigned(cloudName: 'demo');
      expect(
        () => c.url.image('sample.jpg').signed().build(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });

  group('distribution', () {
    test('insecure drops to http on the shared cdn', () {
      expect(
        demo(
          url: const UrlConfig(secure: false),
        ).url.image('sample.jpg').build(),
        'http://res.cloudinary.com/demo/image/upload/sample.jpg',
      );
    });

    test('a private cdn moves the cloud name into the host', () {
      expect(
        demo(
          url: const UrlConfig(privateCdn: true),
        ).url.image('sample.jpg').build(),
        'https://demo-res.cloudinary.com/image/upload/sample.jpg',
      );
    });

    test('cdn sharding picks a subdomain from a crc32 of the source', () {
      // crc32('sample.jpg') = 3318385313; 3318385313 % 5 + 1 = 4
      expect(
        demo(
          url: const UrlConfig(cdnSubdomain: true),
        ).url.image('sample.jpg').build(),
        'https://res-4.cloudinary.com/demo/image/upload/sample.jpg',
      );
      // crc32('sample') = 4044060355; % 5 + 1 = 1
      expect(
        demo(
          url: const UrlConfig(cdnSubdomain: true),
        ).url.image('sample').build(),
        'https://res-1.cloudinary.com/demo/image/upload/sample',
      );
    });

    test('sharding is stable for a given source', () {
      final c = demo(url: const UrlConfig(cdnSubdomain: true));
      expect(
        c.url.image('sample.jpg').build(),
        c.url.image('sample.jpg').build(),
      );
    });

    test('a secure distribution host is used verbatim', () {
      expect(
        demo(
          url: const UrlConfig(secureDistribution: 'cdn.example.com'),
        ).url.image('sample.jpg').build(),
        'https://cdn.example.com/demo/image/upload/sample.jpg',
      );
    });

    test('a cname applies on insecure urls', () {
      expect(
        demo(
          url: const UrlConfig(secure: false, cname: 'cdn.example.com'),
        ).url.image('sample.jpg').build(),
        'http://cdn.example.com/demo/image/upload/sample.jpg',
      );
    });

    test('shorten rewrites image/upload to iu', () {
      expect(
        demo(
          url: const UrlConfig(shorten: true),
        ).url.image('sample.jpg').build(),
        'https://res.cloudinary.com/demo/iu/sample.jpg',
      );
    });

    test('useRootPath drops both type segments', () {
      expect(
        demo(
          url: const UrlConfig(useRootPath: true),
        ).url.image('sample.jpg').build(),
        'https://res.cloudinary.com/demo/sample.jpg',
      );
    });
  });

  group('versioning', () {
    test('a folder path gets v1 under forceVersion', () {
      expect(
        demo().url.image('folder/sample.jpg').build(),
        'https://res.cloudinary.com/demo/image/upload/v1/folder/sample.jpg',
      );
    });

    test('a flat public id gets no synthetic version', () {
      expect(demo().url.image('sample.jpg').build(), isNot(contains('/v1/')));
    });

    test('forceVersion off omits it', () {
      expect(
        demo(
          url: const UrlConfig(forceVersion: false),
        ).url.image('folder/sample.jpg').build(),
        'https://res.cloudinary.com/demo/image/upload/folder/sample.jpg',
      );
    });

    test('an explicit version always wins', () {
      expect(
        demo().url.image('sample.jpg').version(1234).build(),
        'https://res.cloudinary.com/demo/image/upload/v1234/sample.jpg',
      );
    });

    test('a source already carrying a version is left alone', () {
      expect(
        demo().url.image('v999/sample.jpg').build(),
        'https://res.cloudinary.com/demo/image/upload/v999/sample.jpg',
      );
    });
  });

  group('tokens and analytics', () {
    test('an auth token is appended as a query string', () {
      final url = demo().url
          .image('sample.jpg')
          .authToken(
            const AuthToken(
              key: '00112233FF99',
              acl: '/image/*',
              expiration: 1311061272,
            ),
          )
          .build();

      expect(url, contains('?__cld_token__='));
      expect(url, contains('exp=1311061272'));
    });

    test('no analytics parameter is ever added', () {
      expect(demo().url.image('sample.jpg').build(), isNot(contains('_a=')));
      expect(
        demo().url.image('sample.jpg').transform(fill100x150()).build(),
        isNot(contains('_a=')),
      );
    });
  });
}
