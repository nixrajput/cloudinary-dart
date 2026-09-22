import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'signature_algorithm.dart';

/// Verifies the signature Cloudinary sends with a webhook notification.
///
/// Cloudinary signs `body + timestamp + apiSecret`, sending the digest in the
/// `X-Cld-Signature` header and the timestamp in `X-Cld-Timestamp`. Pass the
/// **raw** request body: re-encoding a decoded JSON object changes the bytes
/// and the signature will not match.
///
/// Returns false rather than throwing, so a handler can reject a request
/// without exception handling. Payloads older than [validFor] are rejected
/// even when correctly signed, which limits replay.
///
/// ```dart
/// final ok = verifyNotificationSignature(
///   body: rawRequestBody,
///   timestamp: int.parse(headers['x-cld-timestamp']!),
///   signature: headers['x-cld-signature']!,
///   apiSecret: 'your-secret',
/// );
/// if (!ok) return Response.forbidden('bad signature');
/// ```
bool verifyNotificationSignature({
  required String body,
  required int timestamp,
  required String signature,
  required String apiSecret,
  Duration validFor = const Duration(seconds: 7200),
  CloudinarySignatureAlgorithm algorithm = CloudinarySignatureAlgorithm.sha1,
}) {
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  if (timestamp < nowSeconds - validFor.inSeconds) return false;

  final payload = utf8.encode('$body$timestamp$apiSecret');
  final expected = switch (algorithm) {
    CloudinarySignatureAlgorithm.sha1 => sha1.convert(payload),
    CloudinarySignatureAlgorithm.sha256 => sha256.convert(payload),
  }.toString();

  return _constantTimeEquals(expected, signature);
}

// Constant-time compare. The early length return is not a leak worth
// closing: digest length is fixed and public.
bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
