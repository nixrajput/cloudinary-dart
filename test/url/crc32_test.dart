import 'package:cloudinary/cloudinary.dart';
import 'package:cloudinary/src/url/crc32.dart';
import 'package:test/test.dart';

void main() {
  test('matches known CRC-32 values', () {
    expect(crc32('sample.jpg'), 3318385313);
    expect(crc32('sample'), 4044060355);
  });

  test('hashes UTF-8 bytes, not UTF-16 code units', () {
    // 'é' is one UTF-16 unit (0xE9) but two UTF-8 bytes (0xC3 0xA9). Hashing
    // code units would shard this asset differently from every other SDK.
    expect(
      crc32('café.jpg'),
      crc32Bytes([0x63, 0x61, 0x66, 0xC3, 0xA9, 0x2E, 0x6A, 0x70, 0x67]),
    );
  });

  test('sharding stays stable for a given source', () {
    final c = Cloudinary.unsigned(
      cloudName: 'demo',
      urlConfig: const UrlConfig(cdnSubdomain: true),
    );
    expect(
      c.url.image('sample.jpg').build(),
      c.url.image('sample.jpg').build(),
    );
  });
}

/// Reference CRC-32 over explicit bytes, for the UTF-8 comparison.
int crc32Bytes(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b & 0xFF;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
