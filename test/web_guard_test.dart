// The guard only runs on a JavaScript or Wasm runtime, so this suite does too.
@TestOn('browser')
library;

import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

void main() {
  test('a signing client refuses to construct on the web', () {
    expect(
      () => Cloudinary.signed(apiKey: 'k', apiSecret: 's', cloudName: 'demo'),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });
}
