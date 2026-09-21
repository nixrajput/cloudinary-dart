import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

/// Golden vectors computed from Cloudinary's own signing algorithm
/// (`lib/utils/index.js` in cloudinary_npm: `api_string_to_sign` +
/// `api_sign_request`). They pin the three signing defects v1 shipped.
void main() {
  const secret = 'abcd';

  test('canonical example, v1 and v2 agree when no & is present', () {
    final params = {'public_id': 'sample_image', 'timestamp': 1315060510};

    expect(
      stringToSign(params, version: 1),
      'public_id=sample_image&timestamp=1315060510',
    );
    expect(
      signRequest(params, secret, version: 1),
      'b4ad47fb4e25c7bf5f92a20089f9db59bc302313',
    );
    expect(
      signRequest(params, secret, version: 2),
      'b4ad47fb4e25c7bf5f92a20089f9db59bc302313',
    );
  });

  test('sha256 produces a different digest', () {
    final params = {'public_id': 'sample_image', 'timestamp': 1315060510};

    expect(
      signRequest(
        params,
        secret,
        algorithm: CloudinarySignatureAlgorithm.sha256,
      ),
      'e3c44b54e67a3ecc918f5d7236ca5faa36250ea8a8cd6cbabfd2d6bb2453acac',
    );
  });

  // v1 of this package signed with version 1 semantics. A value containing
  // '&' then splits into extra parameters inside the signed string, so an
  // attacker controlling one value can append parameters the caller never
  // set. Version 2 escapes the '&' and closes it.
  test('version 2 escapes & so a value cannot inject parameters', () {
    final params = {'public_id': r'a&timestamp=9999', 'timestamp': 1315060510};

    expect(
      stringToSign(params, version: 1),
      'public_id=a&timestamp=9999&timestamp=1315060510',
      reason: 'unescaped: a second timestamp has been smuggled in',
    );
    expect(
      stringToSign(params, version: 2),
      'public_id=a%26timestamp=9999&timestamp=1315060510',
      reason: 'escaped: the value stays one parameter',
    );

    expect(
      signRequest(params, secret, version: 1),
      '7a7b28bbd3b05e6fa9bf84182b70d3b1c83fa1c2',
    );
    expect(
      signRequest(params, secret, version: 2),
      '3f4a17a19c6883055a3978f3502f93e346b94c3f',
    );
  });

  // v1 sorted the joined "key=value" strings. Cloudinary sorts by key. The
  // two diverge whenever one key is a prefix of another.
  test('parameters sort by key, not by the joined pair', () {
    final params = {'a1': 'x', 'a': 'z', 'timestamp': 1315060510};

    expect(stringToSign(params, version: 1), 'a=z&a1=x&timestamp=1315060510');
    expect(
      signRequest(params, secret, version: 1),
      'dccc12751c35a2aef846096dc84dec2ffcbd3e04',
    );
    // What sorting the joined strings would have produced instead.
    expect(
      signRequest(params, secret, version: 1),
      isNot('8cc4494cf7929a55014083025c5530f2947b5972'),
    );
  });

  test('lists join with commas and empty values drop out', () {
    final params = {
      'tags': ['a', 'b'],
      'empty': '',
      'nothing': null,
      'folder': 'f',
      'timestamp': 1315060510,
    };

    expect(stringToSign(params), 'folder=f&tags=a,b&timestamp=1315060510');
    expect(
      signRequest(params, secret),
      'f7216eeb243dacca877980bd214938840e608ea4',
    );
  });

  test('timestamp is UNIX seconds, not milliseconds', () {
    final now = cloudinaryTimestamp();
    final expected = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    expect((now - expected).abs(), lessThanOrEqualTo(2));
    expect(now.toString().length, lessThanOrEqualTo(10));
  });

  test('parameters Cloudinary never signs are stripped', () {
    final stripped = stripUnsignedParams({
      'file': 'binary',
      'resource_type': 'image',
      'api_key': 'k',
      'cloud_name': 'c',
      'public_id': 'keep',
      'timestamp': 1,
    });

    expect(stripped.keys, unorderedEquals(['public_id', 'timestamp']));
  });

  test('parameter order in the input map does not change the signature', () {
    final a = {'b': '2', 'a': '1', 'timestamp': 1315060510};
    final b = {'timestamp': 1315060510, 'a': '1', 'b': '2'};

    expect(signRequest(a, secret), signRequest(b, secret));
  });
}
