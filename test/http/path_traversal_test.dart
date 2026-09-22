import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// A `..` inside a caller-supplied segment used to walk out of the
/// `/v1_1/<cloud>` scope, re-aiming an authenticated Admin request at another
/// endpoint. Uri collapses dot segments, so they must never reach it.
void main() {
  CloudinaryTransport transport() => CloudinaryTransport(
    config: const CloudinaryConfig(
      cloudName: 'mycloud',
      apiKey: 'k',
      apiSecret: 's',
    ),
    client: MockClient((_) async => http.Response('{}', 200)),
  );

  test('a normal segment still builds', () {
    expect(
      transport().buildUri([
        'resources',
        'image',
        'upload',
        'photo',
      ]).toString(),
      'https://api.cloudinary.com/v1_1/mycloud/resources/image/upload/photo',
    );
  });

  test('a traversal in a public id is rejected', () {
    expect(
      () => transport().buildUri([
        'resources',
        'image',
        'upload',
        '../../../../config',
      ]),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });

  test('a traversal split across segments is rejected', () {
    expect(
      () =>
          transport().buildUri(['folders', 'a', '..', '..', 'upload_presets']),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });

  test('a single dot is rejected too', () {
    expect(
      () => transport().buildUri(['folders', 'a', '.', 'b']),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });

  test('a folder path with real separators still works', () {
    expect(
      transport().buildUri(['folders', 'trips/2026']).path,
      '/v1_1/mycloud/folders/trips/2026',
    );
  });

  test('dots inside a name are fine', () {
    expect(
      transport().buildUri(['resources', 'image', 'upload', 'a..b.jpg']).path,
      '/v1_1/mycloud/resources/image/upload/a..b.jpg',
    );
  });

  test('the admin api surfaces it end to end', () async {
    final c = Cloudinary.signed(
      cloudName: 'mycloud',
      apiKey: 'k',
      apiSecret: 's',
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await expectLater(
      c.admin.folders.delete('../resources/image/upload'),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });
}
