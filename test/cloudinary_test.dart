import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _FakeProvider implements SignatureProvider {
  @override
  Future<RemoteSignature> sign(Map<String, dynamic> params) async =>
      const RemoteSignature(
        signature: 'deadbeef',
        timestamp: 1,
        apiKey: 'k',
      );
}

void main() {
  group('construction', () {
    test('signed client rejects empty credentials', () {
      expect(
        () => Cloudinary.signed(cloudName: 'demo', apiKey: '', apiSecret: 's'),
        throwsA(isA<CloudinaryConfigException>()),
      );
      expect(
        () => Cloudinary.signed(cloudName: 'demo', apiKey: 'k', apiSecret: ''),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });

    test('signed client rejects an empty cloud name', () {
      expect(
        () => Cloudinary.signed(cloudName: '', apiKey: 'k', apiSecret: 's'),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });

    test('unsigned client needs only a cloud name', () {
      final c = Cloudinary.unsigned(cloudName: 'demo');
      expect(c.config.cloudName, 'demo');
      expect(c.config.canSign, isFalse);
      expect(c.canSign, isFalse);
    });

    test('fromUrl builds a signing client', () {
      final c = Cloudinary.fromUrl('cloudinary://k:s@demo');
      expect(c.config.cloudName, 'demo');
      expect(c.config.canSign, isTrue);
      expect(c.canSign, isTrue);
    });

    test('fromUrl rejects a malformed value', () {
      expect(
        () => Cloudinary.fromUrl('nope://x'),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });

  group('signing capability', () {
    test('unsigned client refuses a signed operation with a useful message',
        () {
      final c = Cloudinary.unsigned(cloudName: 'demo');
      expect(
        c.config.requireSigning,
        throwsA(
          isA<CloudinaryConfigException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Cloudinary.signed'), contains('SignatureProvider')),
          ),
        ),
      );
    });

    test('a provider client holds no secret but can sign', () {
      final c = Cloudinary.unsigned(
        cloudName: 'demo',
        signatureProvider: _FakeProvider(),
      );
      expect(c.config.apiSecret, isEmpty);
      expect(c.canSignRemotely, isTrue);
      expect(c.canSign, isTrue);
    });

    test('a local-secret client is not signing remotely', () {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
      );
      expect(c.canSignRemotely, isFalse);
      expect(c.canSign, isTrue);
    });
  });

  group('lifecycle', () {
    test('close leaves an injected client open', () async {
      final injected = MockClient((_) async => http.Response('{}', 200));
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
        client: injected,
      );

      c.close();

      final response = await injected.get(Uri.https('example.com', '/'));
      expect(response.statusCode, 200);
    });
  });

  group('secret redaction', () {
    test('config toString hides the secret', () {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 'top-secret',
      );
      expect(c.config.toString(), isNot(contains('top-secret')));
    });
  });
}
