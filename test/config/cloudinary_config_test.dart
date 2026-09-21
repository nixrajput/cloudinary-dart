import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

void main() {
  group('redaction', () {
    test('toString never leaks the secret', () {
      const c = CloudinaryConfig(
        cloudName: 'demo',
        apiKey: '123',
        apiSecret: 'super-secret-value',
      );
      expect(c.toString(), isNot(contains('super-secret-value')));
      expect(c.toString(), contains('<redacted>'));
      expect(c.toString(), contains('demo'));
    });

    test('an absent secret reads as none, not redacted', () {
      const c = CloudinaryConfig(cloudName: 'demo');
      expect(c.toString(), contains('apiSecret: <none>'));
    });
  });

  group('validation', () {
    test('empty cloudName is rejected', () {
      expect(
        () => const CloudinaryConfig(cloudName: '').validate(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });

    test('whitespace-only cloudName is rejected', () {
      expect(
        () => const CloudinaryConfig(cloudName: '   ').validate(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });

    test('an out-of-range signature version is rejected', () {
      expect(
        () => const CloudinaryConfig(
          cloudName: 'd',
          signatureVersion: 3,
        ).validate(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });

  group('signing capability', () {
    test('canSign is false without a secret', () {
      expect(const CloudinaryConfig(cloudName: 'demo').canSign, isFalse);
      expect(
        const CloudinaryConfig(cloudName: 'd', apiKey: 'k').canSign,
        isFalse,
      );
      expect(
        const CloudinaryConfig(
          cloudName: 'd',
          apiKey: 'k',
          apiSecret: 's',
        ).canSign,
        isTrue,
      );
    });

    test('requireSigning names the constructor to switch to', () {
      expect(
        () => const CloudinaryConfig(cloudName: 'demo').requireSigning(),
        throwsA(
          isA<CloudinaryConfigException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Cloudinary.signed'), contains('SignatureProvider')),
          ),
        ),
      );
    });
  });

  group('defaults', () {
    test('signature version 2 and sha1 are the defaults', () {
      const c = CloudinaryConfig(cloudName: 'demo');
      expect(c.signatureVersion, 2);
      expect(c.signatureAlgorithm, CloudinarySignatureAlgorithm.sha1);
    });

    test('url config defaults to secure with forced versions', () {
      const u = UrlConfig();
      expect(u.secure, isTrue);
      expect(u.forceVersion, isTrue);
      expect(u.privateCdn, isFalse);
      expect(u.shorten, isFalse);
    });
  });
}
