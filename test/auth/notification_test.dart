import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  const secret = 'abcd';
  const body = '{"public_id":"sample","version":1}';

  int now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
  String sign(int ts, {String payload = body}) =>
      sha1.convert(utf8.encode('$payload$ts$secret')).toString();

  test('accepts a fresh, correctly signed payload', () {
    final ts = now();
    expect(
      verifyNotificationSignature(
        body: body,
        timestamp: ts,
        signature: sign(ts),
        apiSecret: secret,
      ),
      isTrue,
    );
  });

  test('rejects a tampered body', () {
    final ts = now();
    expect(
      verifyNotificationSignature(
        body: '{"public_id":"attacker"}',
        timestamp: ts,
        signature: sign(ts),
        apiSecret: secret,
      ),
      isFalse,
    );
  });

  test('rejects a wrong secret', () {
    final ts = now();
    expect(
      verifyNotificationSignature(
        body: body,
        timestamp: ts,
        signature: sign(ts),
        apiSecret: 'wrong',
      ),
      isFalse,
    );
  });

  test('rejects a payload older than validFor', () {
    final old = now() - 8000;
    expect(
      verifyNotificationSignature(
        body: body,
        timestamp: old,
        signature: sign(old),
        apiSecret: secret,
      ),
      isFalse,
    );
  });

  test('a widened validFor accepts that same old payload', () {
    final old = now() - 8000;
    expect(
      verifyNotificationSignature(
        body: body,
        timestamp: old,
        signature: sign(old),
        apiSecret: secret,
        validFor: const Duration(hours: 4),
      ),
      isTrue,
    );
  });

  test('rejects a signature of the wrong length', () {
    final ts = now();
    expect(
      verifyNotificationSignature(
        body: body,
        timestamp: ts,
        signature: 'short',
        apiSecret: secret,
      ),
      isFalse,
    );
  });

  test('a replayed timestamp with a stale signature fails', () {
    final ts = now();
    expect(
      verifyNotificationSignature(
        body: body,
        timestamp: ts,
        signature: sign(ts - 1),
        apiSecret: secret,
      ),
      isFalse,
    );
  });

  test('sha256 verification works when Cloudinary is configured for it', () {
    final ts = now();
    final sig = sha256.convert(utf8.encode('$body$ts$secret')).toString();
    expect(
      verifyNotificationSignature(
        body: body,
        timestamp: ts,
        signature: sig,
        apiSecret: secret,
        algorithm: CloudinarySignatureAlgorithm.sha256,
      ),
      isTrue,
    );
  });
}
