import 'dart:convert';

/// Computes a CRC-32 checksum of [input]'s code units.
///
/// Cloudinary picks a CDN subdomain with `crc32(publicId) % 5 + 1`, so an
/// asset always maps to the same shard and stays cached there. The input is
/// hashed as UTF-8 bytes, matching the other SDKs: hashing UTF-16 code units
/// would shard a non-ASCII public ID differently and split the CDN cache. Implemented
/// here because `package:crypto` has no CRC-32 and pulling in an archive
/// library for one function would break the two-dependency budget.
int crc32(String input) {
  var crc = 0xFFFFFFFF;
  for (final byte in utf8.encode(input)) {
    crc ^= byte & 0xFF;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
