import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

void main() {
  test('components sort by short key', () {
    final t = Transformation()
      ..height(150)
      ..width(100)
      ..crop(CropMode.fill);

    expect(t.serialize(), 'c_fill,h_150,w_100');
  });

  test('flags join with a dot', () {
    final t = Transformation()..flags([Flag.progressive, Flag.attachment]);
    expect(t.serialize(), 'fl_progressive.attachment');
  });

  test('a hex colour becomes rgb notation', () {
    final t = Transformation()..background('#3498db');
    expect(t.serialize(), 'b_rgb:3498db');
  });

  test('a named colour passes through', () {
    final t = Transformation()..color('red');
    expect(t.serialize(), 'co_red');
  });

  test('raw components append verbatim and last', () {
    final t = Transformation()
      ..width(100)
      ..raw('e_custom:42');

    expect(t.serialize(), 'w_100,e_custom:42');
  });

  test('an effect with an argument', () {
    final t = Transformation()..effectValue(Effect.blur, 300);
    expect(t.serialize(), 'e_blur:300');
  });

  test('auto values pass through as strings', () {
    final t = Transformation()
      ..width('auto')
      ..quality(Quality.autoGood)
      ..format(DeliveryFormat.auto);

    expect(t.serialize(), 'f_auto,q_auto:good,w_auto');
  });

  test('a chain joins with slashes', () {
    final chain = TransformationChain([
      Transformation()..width(100),
      Transformation()..effect(Effect.sepia),
    ]);

    expect(chain.serialize(), 'w_100/e_sepia');
  });

  test('empty stages drop out of a chain', () {
    final chain = TransformationChain([
      Transformation()..width(100),
      Transformation(),
    ]);

    expect(chain.serialize(), 'w_100');
  });

  test('an empty transformation serializes to an empty string', () {
    expect(Transformation().serialize(), isEmpty);
    expect(Transformation().isEmpty, isTrue);
  });

  test('gravity serializes its wire name', () {
    final t = Transformation()
      ..crop(CropMode.fill)
      ..gravity(Gravity.northEast);

    expect(t.serialize(), 'c_fill,g_north_east');
  });
}
