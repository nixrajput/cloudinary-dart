import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'signature_algorithm.dart';

/// Returns the current UNIX time in seconds, which is what Cloudinary
/// expects.
///
/// Cloudinary rejects a request whose timestamp sits too far from its own
/// clock, so sending milliseconds here makes every signed request fail.
int cloudinaryTimestamp() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// Builds the canonical string Cloudinary signs.
///
/// Parameters sort by key, null and empty values drop out, and iterables join
/// with commas. Signature [version] 2 and above escapes `&` within each pair,
/// which is what stops a parameter value from smuggling additional parameters
/// into the signed string.
String stringToSign(Map<String, dynamic> params, {int version = 2}) {
  final pairs = <MapEntry<String, String>>[];
  for (final entry in params.entries) {
    final value = entry.value;
    if (value == null) continue;
    final rendered = value is Iterable ? value.join(',') : '$value';
    if (rendered.isEmpty) continue;
    pairs.add(MapEntry(entry.key, rendered));
  }

  // Sort by key. Sorting the joined "key=value" strings instead diverges
  // whenever one key is a prefix of another, because '=' orders differently
  // against digits than it does against letters.
  pairs.sort((a, b) => a.key.compareTo(b.key));

  return pairs
      .map((p) {
        final pair = '${p.key}=${p.value}';
        return version >= 2 ? pair.replaceAll('&', '%26') : pair;
      })
      .join('&');
}

/// Signs [params] with [apiSecret], returning a lowercase hex digest.
String signRequest(
  Map<String, dynamic> params,
  String apiSecret, {
  int version = 2,
  CloudinarySignatureAlgorithm algorithm = CloudinarySignatureAlgorithm.sha1,
}) {
  final payload = utf8.encode(
    stringToSign(params, version: version) + apiSecret,
  );
  final digest = switch (algorithm) {
    CloudinarySignatureAlgorithm.sha1 => sha1.convert(payload),
    CloudinarySignatureAlgorithm.sha256 => sha256.convert(payload),
  };
  return digest.toString();
}

/// Parameters Cloudinary excludes from the signature of an upload request.
///
/// `file` may be binary, and the other three are transport or routing
/// concerns rather than signed content.
const Set<String> unsignedUploadParams = {
  'file',
  'resource_type',
  'api_key',
  'cloud_name',
};

/// Returns a copy of [params] with the parameters Cloudinary never signs
/// removed.
Map<String, dynamic> stripUnsignedParams(Map<String, dynamic> params) => {
  for (final e in params.entries)
    if (!unsignedUploadParams.contains(e.key)) e.key: e.value,
};
