import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

/// Regressions for URL builder defects found in review.
void main() {
  Cloudinary demo() =>
      Cloudinary.signed(cloudName: 'demo', apiKey: 'k', apiSecret: 'abcd');

  group('transform chains', () {
    test('repeated transform() calls accumulate', () {
      final url = demo().url
          .image('x.jpg')
          .transform(Transformation()..width(100))
          .transform(Transformation()..effect(Effect.sepia))
          .build();

      expect(url, contains('/w_100/e_sepia/'));
    });

    test('a single transform still works', () {
      expect(
        demo().url
            .image('x.jpg')
            .transform(Transformation()..width(100))
            .build(),
        contains('/w_100/'),
      );
    });
  });

  group('signing order', () {
    test('the signature is computed over the escaped source', () {
      // sha1('my%20photo.jpg' + 'abcd'), base64url, first 8 chars.
      expect(
        demo().url.image('my photo.jpg').signed().build(),
        'https://res.cloudinary.com/demo/image/upload'
        '/s--m6nLvNOG--/my%20photo.jpg',
      );
    });

    test('a question mark cannot open a query string', () {
      final url = demo().url.image('a?b.jpg').build();
      expect(url, endsWith('/a%3Fb.jpg'));
      expect('?'.allMatches(url), isEmpty);
    });

    test('a hash cannot open a fragment', () {
      expect(demo().url.image('a#b.jpg').build(), endsWith('/a%23b.jpg'));
    });

    test('an auth token stays the only query parameter', () {
      final url = demo().url
          .image('a?b.jpg')
          .authToken(
            const AuthToken(
              key: '00112233FF99',
              acl: '/image/*',
              expiration: 2000000000,
            ),
          )
          .build();

      expect('?'.allMatches(url).length, 1);
      expect(url, contains('?__cld_token__='));
    });
  });

  group('remote sources', () {
    test('fetch embeds the remote URL in a Cloudinary path', () {
      expect(
        demo().url
            .image('https://example.com/a.jpg')
            .deliveryType(CloudinaryDeliveryType.fetch)
            .build(),
        'https://res.cloudinary.com/demo/image/fetch/https://example.com/a.jpg',
      );
    });

    test('a remote source gets no synthetic version', () {
      expect(
        demo().url
            .image('https://example.com/a.jpg')
            .deliveryType(CloudinaryDeliveryType.fetch)
            .build(),
        isNot(contains('/v1/')),
      );
    });

    test(
      'signing a passthrough source throws instead of dropping silently',
      () {
        expect(
          () => demo().url.image('https://evil.example/x.svg').signed().build(),
          throwsA(isA<CloudinaryConfigException>()),
        );
      },
    );

    test('an auth token on a passthrough source throws too', () {
      expect(
        () => demo().url
            .image('https://evil.example/x.svg')
            .authToken(
              const AuthToken(
                key: '00112233FF99',
                acl: '/image/*',
                expiration: 2000000000,
              ),
            )
            .build(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });

    test('an unsigned passthrough is still returned untouched', () {
      expect(
        demo().url.image('https://example.com/a.png').build(),
        'https://example.com/a.png',
      );
    });
  });

  group('seo url suffix', () {
    test('the suffix replaces the type segments', () {
      final url = demo().url.image('sample').urlSuffix('my-photo').build();

      expect(url, contains('/demo/images/'));
      expect(url, isNot(contains('/image/upload/')));
      expect(url, endsWith('/sample/my-photo'));
    });

    test('raw and video get their own plural', () {
      expect(
        demo().url.raw('doc').urlSuffix('readme').build(),
        contains('/demo/files/'),
      );
      expect(
        demo().url.video('clip').urlSuffix('trailer').build(),
        contains('/demo/videos/'),
      );
    });

    test('an unsupported type is rejected rather than mis-built', () {
      expect(
        () => demo().url
            .image('sample')
            .deliveryType(CloudinaryDeliveryType.fetch)
            .urlSuffix('x')
            .build(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });
}
