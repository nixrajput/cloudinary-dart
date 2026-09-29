import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

void main() {
  test('parses a CLOUDINARY_URL', () {
    final c = CloudinaryConfig.parse('cloudinary://my_key:my_secret@my_cloud');
    expect(c.cloudName, 'my_cloud');
    expect(c.apiKey, 'my_key');
    expect(c.apiSecret, 'my_secret');
    expect(c.canSign, isTrue);
  });

  test('rejects a non-cloudinary scheme', () {
    expect(
      () => CloudinaryConfig.parse('https://k:s@cloud'),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });

  test('a value that is not a URI is a config exception', () {
    expect(
      () => CloudinaryConfig.parse('cloudinary://k:s@my_cloud:port'),
      throwsA(
        isA<CloudinaryConfigException>().having(
          (e) => e.message,
          'message',
          contains('not a valid URI'),
        ),
      ),
    );
  });

  test('no CLOUDINARY_URL error ever repeats the secret', () {
    const secret = 'TOPSECRET';
    for (final url in [
      'cloudinary://key:$secret@cloud:port',
      'https://key:$secret@cloud',
      'cloudinary://key:$secret@',
    ]) {
      expect(
        () => CloudinaryConfig.parse(url),
        throwsA(
          isA<CloudinaryConfigException>().having(
            (e) => '$e ${e.message}',
            'text',
            isNot(contains(secret)),
          ),
        ),
        reason: url,
      );
    }
  });

  test('rejects a missing cloud name', () {
    expect(
      () => CloudinaryConfig.parse('cloudinary://k:s@'),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });

  test('percent-encoded credentials are decoded', () {
    final c = CloudinaryConfig.parse('cloudinary://k:se%2Fcret@cloud');
    expect(c.apiSecret, 'se/cret');
  });

  test('a url without credentials yields an unsigned config', () {
    final c = CloudinaryConfig.parse('cloudinary://@my_cloud');
    expect(c.cloudName, 'my_cloud');
    expect(c.canSign, isFalse);
  });
}
