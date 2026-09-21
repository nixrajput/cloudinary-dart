import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

/// `!` separates ACL entries and `~` separates token fields. A caller-supplied
/// value containing either used to splice extra entries or fields into a
/// validly-signed token, widening what it grants.
void main() {
  const key = '00112233FF99';

  test('a bang inside one ACL entry cannot split it', () {
    // The canonical multi-tenant pattern: an untrusted id inside the ACL.
    const t = AuthToken(
      key: key,
      acl: '/image/upload/x!/*!y/*',
      expiration: 2000000000,
    );

    final token = t.generate();
    final acl = RegExp(r'acl=([^~]*)').firstMatch(token)!.group(1)!;

    expect(acl, isNot(contains('!')), reason: 'a raw ! would add ACL entries');
    expect(acl, contains('%21'));
  });

  test('several ACLs still join with a real separator', () {
    const t = AuthToken(
      key: key,
      aclList: ['/image/*', '/video/*'],
      expiration: 2000000000,
    );

    expect(t.generate(), contains('acl=%2fimage%2f*!%2fvideo%2f*'));
  });

  test('a tilde in ip cannot splice a new field', () {
    const t = AuthToken(
      key: key,
      acl: '/image/*',
      ip: '203.0.113.9~acl=%2f*',
      expiration: 2000000000,
    );

    final token = t.generate();
    final fields = token.split('=').first == '__cld_token__'
        ? token.substring('__cld_token__='.length).split('~')
        : token.split('~');

    // ip, exp, acl, hmac - four fields, not five.
    expect(fields, hasLength(4));
    expect(fields.where((f) => f.startsWith('acl=')), hasLength(1));
  });

  test('an ordinary token is unchanged', () {
    const t = AuthToken(key: key, acl: '/image/*', expiration: 1311061272);
    expect(
      t.generate(),
      '__cld_token__=exp=1311061272~acl=%2fimage%2f*'
      '~hmac=552289a953dabe291181c67c32a82dd2ab15010fada5322e3ce85deef1edfdcc',
    );
  });
}
