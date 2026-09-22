import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

void main() {
  const json = <String, dynamic>{
    'public_id': 'sample',
    'asset_id': 'abc',
    'version': 1571218330,
    'width': 864,
    'height': 576,
    'format': 'jpg',
    'resource_type': 'image',
    'created_at': '2026-09-01T10:00:00Z',
    'bytes': 120253,
    'type': 'upload',
    'etag': 'abc123',
    'secure_url': 'https://res.cloudinary.com/demo/image/upload/v1/sample.jpg',
    'url': 'http://res.cloudinary.com/demo/image/upload/v1/sample.jpg',
    'tags': ['a', 'b'],
    'a_field_cloudinary_added_last_week': 42,
  };

  test('parses the documented fields', () {
    const r = UploadResult.fromJson(json);

    expect(r.publicId, 'sample');
    expect(r.assetId, 'abc');
    expect(r.width, 864);
    expect(r.height, 576);
    expect(r.bytes, 120253);
    expect(r.format, 'jpg');
    expect(r.tags, ['a', 'b']);
    expect(r.createdAt, DateTime.utc(2026, 9, 1, 10));
    expect(r.resourceType, CloudinaryResourceType.image);
    expect(r.secureUrl, startsWith('https://'));
  });

  test('an unmodelled field stays reachable through raw', () {
    const r = UploadResult.fromJson(json);
    expect(r.raw['a_field_cloudinary_added_last_week'], 42);
  });

  /// Copies the fixture with one field overridden. A spread-and-override map
  /// literal cannot be const, because const evaluation rejects the duplicate
  /// key even though the later value wins at runtime.
  Map<String, dynamic> withField(String key, Object? value) =>
      Map<String, dynamic>.from(json)..[key] = value;

  test('a malformed date degrades to null without losing the rest', () {
    final r = UploadResult.fromJson(withField('created_at', 'not-a-date'));

    expect(r.createdAt, isNull);
    expect(r.publicId, 'sample');
    expect(r.raw['created_at'], 'not-a-date');
  });

  test('an unknown resource type does not throw', () {
    final r = UploadResult.fromJson(withField('resource_type', 'hologram'));

    expect(r.resourceType, isNull);
    expect(r.raw['resource_type'], 'hologram');
  });

  test('absent fields read as null', () {
    const r = UploadResult.fromJson(<String, dynamic>{});

    expect(r.publicId, isNull);
    expect(r.width, isNull);
    expect(r.tags, isNull);
    expect(r.createdAt, isNull);
  });

  test('numeric strings coerce, and duration reads as a double', () {
    const r = UploadResult.fromJson({'width': '100', 'duration': 12});

    expect(r.width, 100);
    expect(r.duration, 12.0);
  });
}
