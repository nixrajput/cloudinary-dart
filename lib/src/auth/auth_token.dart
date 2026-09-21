import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../exceptions.dart';

/// Characters Cloudinary percent-escapes when building an auth token.
final RegExp _unsafe = RegExp('[ "#%&\'/:;<=>?@\\[\\]^`{|}~]+');

/// Percent-escapes [value] the way Cloudinary's token signer does, using
/// lowercase hex escapes.
///
/// Cloudinary uppercases the hex during escaping and then lowercases the whole
/// escape sequence, so `/` becomes `%2f` rather than `%2F`. The server
/// reproduces this exact string when it verifies the HMAC, so the casing is
/// load-bearing.
String escapeTokenComponent(String value) =>
    value.replaceAllMapped(_unsafe, (m) {
      final buffer = StringBuffer();
      for (final unit in m.group(0)!.codeUnits) {
        buffer.write('%${unit.toRadixString(16).padLeft(2, '0')}');
      }
      return buffer.toString();
    });

/// A signed `__cld_token__` granting time-limited access to delivery URLs.
///
/// Supply either [acl] (a path pattern, or several joined internally with
/// `!`) or [url] (one exact path), and either [expiration] or [duration].
///
/// ```dart
/// final url = cloudinary.url.image('private.jpg').authToken(
///   AuthToken(key: 'your-token-key', acl: '/image/*', duration: 3600),
/// ).build();
/// ```
class AuthToken {
  /// Creates an auth token description.
  const AuthToken({
    required this.key,
    this.acl,
    this.aclList,
    this.url,
    this.startTime,
    this.expiration,
    this.duration,
    this.ip,
    this.tokenName = '__cld_token__',
  });

  /// The token key from your Cloudinary settings, as a hex string.
  final String key;

  /// A single ACL path pattern, such as `/image/*`.
  final String? acl;

  /// Several ACL patterns, joined with `!` before signing.
  final List<String>? aclList;

  /// One exact URL path to authorize, used when no ACL is given.
  final String? url;

  /// Token validity start, in UNIX seconds.
  final int? startTime;

  /// Token expiry, in UNIX seconds.
  final int? expiration;

  /// Validity window in seconds, measured from [startTime] or from now.
  final int? duration;

  /// The single client IP address the token is restricted to.
  final String? ip;

  /// The query parameter name. Cloudinary's default is `__cld_token__`.
  final String tokenName;

  /// Builds the token string, ready to append to a delivery URL as a query.
  ///
  /// Throws [CloudinarySignatureException] when neither an ACL nor a URL is
  /// given, when neither an expiration nor a duration is given, or when [key]
  /// is not valid hex.
  String generate() {
    final effectiveAcl = _effectiveAcl();
    if (effectiveAcl == null && (url == null || url!.isEmpty)) {
      throw const CloudinarySignatureException(
        'An auth token needs either an acl or a url.',
      );
    }

    final exp = _resolveExpiration();

    final parts = <String>[
      if (ip != null) 'ip=$ip',
      if (startTime != null) 'st=$startTime',
      'exp=$exp',
      if (effectiveAcl != null) 'acl=${escapeTokenComponent(effectiveAcl)}',
    ];

    // The URL is signed but never emitted: the server already knows which URL
    // it is serving, and including it would double the token length.
    final toSign = <String>[
      ...parts,
      if (effectiveAcl == null && url != null)
        'url=${escapeTokenComponent(url!)}',
    ];

    final digest = Hmac(
      sha256,
      _decodeHexKey(key),
    ).convert(utf8.encode(toSign.join('~'))).toString();

    return '$tokenName=${[...parts, 'hmac=$digest'].join('~')}';
  }

  String? _effectiveAcl() {
    final list = aclList;
    if (list != null && list.isNotEmpty) return list.join('!');
    if (acl != null && acl!.isNotEmpty) return acl;
    return null;
  }

  int _resolveExpiration() {
    if (expiration != null) return expiration!;
    if (duration == null) {
      throw const CloudinarySignatureException(
        'An auth token needs either an expiration or a duration.',
      );
    }
    final start = startTime ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    return start + duration!;
  }

  static List<int> _decodeHexKey(String hex) {
    if (hex.isEmpty || hex.length.isOdd) {
      throw const CloudinarySignatureException(
        'The auth token key must be a non-empty hex string of even length.',
      );
    }
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final byte = int.tryParse(hex.substring(i, i + 2), radix: 16);
      if (byte == null) {
        throw const CloudinarySignatureException(
          'The auth token key must be a hex string.',
        );
      }
      bytes.add(byte);
    }
    return bytes;
  }
}
