import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

/// Cloudinary's `finalize_source` keeps the URL suffix out of the signature
/// payload and puts the format extension after the suffix. Signing the
/// suffixed path produced a digest the server cannot reproduce, so every
/// signed SEO URL was rejected.
void main() {
  Cloudinary demo() =>
      Cloudinary.signed(cloudName: 'demo', apiKey: 'k', apiSecret: 'abcd');

  test('the format extension trails the suffix', () {
    expect(
      demo().url.image('sample').urlSuffix('my-page').format('jpg').build(),
      'https://res.cloudinary.com/demo/images/sample/my-page.jpg',
    );
  });

  test('the suffix is excluded from the signature payload', () {
    final withSuffix = demo().url
        .image('sample')
        .urlSuffix('my-page')
        .format('jpg')
        .signed()
        .build();
    final plain = demo().url.image('sample').format('jpg').signed().build();

    final sig = RegExp(r's--[^-]+--');
    expect(
      sig.firstMatch(withSuffix)!.group(0),
      sig.firstMatch(plain)!.group(0),
    );
  });

  test('a suffix alone does not force a synthetic version', () {
    expect(
      demo().url.image('sample').urlSuffix('my-page').build(),
      isNot(contains('/v1/')),
    );
  });

  test('a real folder path still forces a version', () {
    expect(
      demo().url.image('trips/sample').urlSuffix('my-page').build(),
      contains('/v1/'),
    );
  });

  test('a suffix containing a slash or dot is rejected', () {
    expect(
      () => demo().url.image('s').urlSuffix('a/b').build(),
      throwsA(isA<CloudinaryConfigException>()),
    );
    expect(
      () => demo().url.image('s').urlSuffix('a.b').build(),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });

  test('a transformation value containing a space is escaped', () {
    final url = demo().url
        .image('a.jpg')
        .transform(Transformation()..overlay('text:Arial_60:Hello World'))
        .build();

    expect(url, contains('Hello%20World'));
    expect(url.contains(' '), isFalse);
  });

  test('transformChain copies, so a shared chain is not mutated', () {
    final chain = TransformationChain([Transformation()..width(1)]);

    demo().url
        .image('a.jpg')
        .transformChain(chain)
        .transform(Transformation()..height(2))
        .build();

    expect(chain.transformations, hasLength(1));
  });
}
