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

  test('a field of the wrong shape reads as null without losing the rest', () {
    final r = UploadResult.fromJson(
      Map<String, dynamic>.from(json)
        ..['tags'] = 'holiday'
        ..['width'] = {'value': 1}
        ..['context'] = ['not', 'a', 'map']
        ..['created_at'] = 20260930,
    );

    expect(r.tags, isNull);
    expect(r.width, isNull);
    expect(r.context, isNull);
    expect(r.createdAt, isNull);
    expect(r.publicId, 'sample');
    expect(r.raw['tags'], 'holiday');
  });

  test('a list of objects skips the entries that are not objects', () {
    final r = UploadResult.fromJson(
      withField('eager', [
        {'transformation': 'w_100', 'secure_url': 'https://a'},
        'not an object',
        42,
        {'transformation': 'w_200'},
      ]),
    );

    expect(r.eager!.map((e) => e['transformation']), ['w_100', 'w_200']);
  });

  test('a number where text is expected reads as its text', () {
    final r = UploadResult.fromJson(
      Map<String, dynamic>.from(json)
        ..['public_id'] = 1234
        ..['tags'] = [1, 'b'],
    );

    expect(r.publicId, '1234');
    expect(r.tags, ['1', 'b']);
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

  test('parses the versioning, naming and add-on fields', () {
    const r = UploadResult.fromJson({
      'version': 1571218330,
      'version_id': '98f52566f43d8e516a486958a45c1eb9',
      'signature': 'abcdef0123',
      'type': 'upload',
      'etag': 'abc123',
      'placeholder': false,
      'url': 'http://res.cloudinary.com/demo/image/upload/v1/sample.jpg',
      'folder': 'trips',
      'asset_folder': 'trips/2026',
      'display_name': 'Beach',
      'original_filename': 'IMG_0001',
      'delete_token': 'tok',
      'pages': 3,
      'context': {
        'custom': {'alt': 'Beach'},
      },
      'metadata': {'rating': 5},
      'moderation': [
        {'kind': 'manual', 'status': 'pending'},
      ],
      'eager': [
        {'transformation': 'w_100', 'width': 100},
      ],
      'info': {
        'detection': {'captioning': 'done'},
      },
    });

    expect(r.version, 1571218330);
    expect(r.versionId, '98f52566f43d8e516a486958a45c1eb9');
    expect(r.signature, 'abcdef0123');
    expect(r.type, 'upload');
    expect(r.etag, 'abc123');
    expect(r.placeholder, isFalse);
    expect(r.url, startsWith('http://'));
    expect(r.folder, 'trips');
    expect(r.assetFolder, 'trips/2026');
    expect(r.displayName, 'Beach');
    expect(r.originalFilename, 'IMG_0001');
    expect(r.deleteToken, 'tok');
    expect(r.pages, 3);
    expect(r.context, {
      'custom': {'alt': 'Beach'},
    });
    expect(r.metadata, {'rating': 5});
    expect(r.moderation, [
      {'kind': 'manual', 'status': 'pending'},
    ]);
    expect(r.eager!.single['transformation'], 'w_100');
    expect(r.info, {
      'detection': {'captioning': 'done'},
    });
  });

  test('string booleans and decimals coerce, other strings do not', () {
    const on = UploadResult.fromJson({
      'placeholder': 'true',
      'duration': '12.5',
    });
    const off = UploadResult.fromJson({'placeholder': 'false'});
    const junk = UploadResult.fromJson({'placeholder': 'yes', 'duration': 'x'});

    expect(on.placeholder, isTrue);
    expect(on.duration, 12.5);
    expect(off.placeholder, isFalse);
    expect(junk.placeholder, isNull);
    expect(junk.duration, isNull);
  });

  test('archive, sprite, text and explode results read their fields', () {
    const archive = ArchiveResult.fromJson({
      'public_id': 'bundle.zip',
      'secure_url': 'https://res.cloudinary.com/demo/raw/upload/bundle.zip',
      'url': 'http://res.cloudinary.com/demo/raw/upload/bundle.zip',
      'bytes': 2048,
      'resource_count': 4,
    });
    expect(archive.publicId, 'bundle.zip');
    expect(archive.secureUrl, startsWith('https://'));
    expect(archive.url, startsWith('http://'));
    expect(archive.bytes, 2048);
    expect(archive.resourceCount, 4);

    const sprite = SpriteResult.fromJson({
      'public_id': 'sprite',
      'version': 7,
      'secure_url': 'https://res.cloudinary.com/demo/image/sprite/v7/s.png',
      'url': 'http://res.cloudinary.com/demo/image/sprite/v7/s.png',
      'secure_css_url': 'https://res.cloudinary.com/demo/image/sprite/v7/s.css',
      'image_infos': {
        'a': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
      },
    });
    expect(sprite.publicId, 'sprite');
    expect(sprite.version, 7);
    expect(sprite.secureUrl, endsWith('s.png'));
    expect(sprite.url, startsWith('http://'));
    expect(sprite.secureCssUrl, endsWith('s.css'));
    expect(sprite.imageInfos!['a'], {
      'x': 0,
      'y': 0,
      'width': 10,
      'height': 10,
    });

    const text = TextResult.fromJson({
      'width': 120,
      'height': 24,
      'public_id': 'text/hello',
      'secure_url': 'https://res.cloudinary.com/demo/image/text/hello.png',
    });
    expect(text.width, 120);
    expect(text.height, 24);
    expect(text.publicId, 'text/hello');
    expect(text.secureUrl, endsWith('hello.png'));

    const explode = ExplodeResult.fromJson({
      'status': 'processing',
      'batch_id': 'b1',
    });
    expect(explode.status, 'processing');
    expect(explode.batchId, 'b1');
  });
}
