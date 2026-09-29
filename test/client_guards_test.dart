import 'package:cloudinary/cloudinary.dart';
import 'package:cloudinary/src/config/environment_reader.dart';
import 'package:cloudinary/src/web_guard.dart';
import 'package:test/test.dart';

// The real guard runs in web_guard_test.dart on Chrome; this reaches the same
// decision on every platform through the flag the guard takes.
void main() {
  const signed = CloudinaryConfig(
    cloudName: 'demo',
    apiKey: 'key',
    apiSecret: 'secret',
  );
  const unsigned = CloudinaryConfig(cloudName: 'demo');

  test(
    'on the web a secret is refused unless allowed; unsigned always is not',
    () {
      expect(
        () => refuseSecretOnWeb(signed, allowSecretOnWeb: false, onWeb: true),
        throwsA(
          isA<CloudinaryConfigException>().having(
            (e) => e.message,
            'message',
            contains('Refusing to hold an API secret on the web'),
          ),
        ),
      );
      refuseSecretOnWeb(signed, allowSecretOnWeb: true, onWeb: true);
      refuseSecretOnWeb(unsigned, allowSecretOnWeb: false, onWeb: true);
      refuseSecretOnWeb(signed, allowSecretOnWeb: false, onWeb: false);
    },
  );

  group('fromEnvironment', () {
    setUp(() {
      final real = cloudinaryUrlReader;
      addTearDown(() => cloudinaryUrlReader = real);
    });

    test('builds a signing client from CLOUDINARY_URL', () {
      cloudinaryUrlReader = () => 'cloudinary://key:s%40cret@my-cloud';
      // Allowed, so this runs in the browser suites too; the guard itself is
      // tested above.
      final cloudinary = Cloudinary.fromEnvironment(
        urlConfig: const UrlConfig(shorten: true),
        allowSecretOnWeb: true,
      );
      addTearDown(cloudinary.close);
      expect(cloudinary.config.cloudName, 'my-cloud');
      expect(cloudinary.config.apiKey, 'key');
      expect(cloudinary.config.apiSecret, 's@cret');
      expect(cloudinary.url.image('a').build(), contains('/my-cloud/iu/'));
    });

    test('treats an empty CLOUDINARY_URL as unset', () {
      cloudinaryUrlReader = () => '';
      expect(
        Cloudinary.fromEnvironment,
        throwsA(
          isA<CloudinaryConfigException>().having(
            (e) => e.message,
            'message',
            contains('not set'),
          ),
        ),
      );
    });
  });
}
