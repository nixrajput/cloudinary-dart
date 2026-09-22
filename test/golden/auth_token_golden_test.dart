import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

/// Vectors computed from Cloudinary's `lib/auth_token.js`, including its
/// `escapeToLower` step, which is why `/image/*` appears as `%2fimage%2f*`.
void main() {
  const key = '00112233FF99';

  test('escaping uses lowercase hex and leaves safe characters alone', () {
    expect(escapeTokenComponent('/image/*'), '%2fimage%2f*');
    expect(
      escapeTokenComponent('/image/upload/sample.jpg'),
      '%2fimage%2fupload%2fsample.jpg',
    );
    expect(escapeTokenComponent('plain-name_1.jpg'), 'plain-name_1.jpg');
  });

  test('acl token', () {
    const t = AuthToken(key: key, acl: '/image/*', expiration: 1311061272);

    expect(
      t.generate(),
      '__cld_token__=exp=1311061272~acl=%2fimage%2f*'
      '~hmac=552289a953dabe291181c67c32a82dd2ab15010fada5322e3ce85deef1edfdcc',
    );
  });

  test('url token signs the url but does not emit it', () {
    const t = AuthToken(
      key: key,
      url: '/image/upload/sample.jpg',
      expiration: 1311061272,
    );

    final token = t.generate();
    expect(
      token,
      '__cld_token__=exp=1311061272'
      '~hmac=27906aa1053fd849ecd11f486e7f14ded6ed7c2d1dfff2edb36c2c164b54c984',
    );
    expect(token, isNot(contains('url=')));
  });

  test('ip and start time are included in order', () {
    const t = AuthToken(
      key: key,
      acl: '/image/*',
      startTime: 1311061172,
      expiration: 1311061272,
      ip: '10.0.0.1',
    );

    expect(
      t.generate(),
      '__cld_token__=ip=10.0.0.1~st=1311061172~exp=1311061272'
      '~acl=%2fimage%2f*'
      '~hmac=cf03276395af5c7de9dbe8462cbd7e01dc088854051421adc8d0352b4dda186d',
    );
  });

  test('duration derives expiration from start time', () {
    const t = AuthToken(
      key: key,
      acl: '/image/*',
      startTime: 1311061172,
      duration: 100,
    );

    expect(t.generate(), contains('exp=1311061272'));
  });

  test('several acls join with an exclamation mark', () {
    const t = AuthToken(
      key: key,
      aclList: ['/image/*', '/video/*'],
      expiration: 1311061272,
    );

    expect(t.generate(), contains('acl=%2fimage%2f*!%2fvideo%2f*'));
  });

  test('an acl wins over a url', () {
    const t = AuthToken(
      key: key,
      acl: '/image/*',
      url: '/image/upload/sample.jpg',
      expiration: 1311061272,
    );

    expect(t.generate(), contains('acl='));
    expect(t.generate(), isNot(contains('url=')));
  });

  test('a custom token name is honoured', () {
    const t = AuthToken(
      key: key,
      acl: '/image/*',
      expiration: 1311061272,
      tokenName: '__my_token__',
    );

    expect(t.generate(), startsWith('__my_token__='));
  });

  group('rejections', () {
    test('neither acl nor url', () {
      expect(
        () => const AuthToken(key: key, expiration: 1).generate(),
        throwsA(isA<CloudinarySignatureException>()),
      );
    });

    test('neither expiration nor duration', () {
      expect(
        () => const AuthToken(key: key, acl: '/image/*').generate(),
        throwsA(isA<CloudinarySignatureException>()),
      );
    });

    test('a non-hex key', () {
      expect(
        () =>
            const AuthToken(key: 'zzzz', acl: '/i/*', expiration: 1).generate(),
        throwsA(isA<CloudinarySignatureException>()),
      );
    });

    test('an odd-length key', () {
      expect(
        () =>
            const AuthToken(key: 'abc', acl: '/i/*', expiration: 1).generate(),
        throwsA(isA<CloudinarySignatureException>()),
      );
    });
  });
}
