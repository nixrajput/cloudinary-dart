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

  test('image setters emit their short keys', () {
    final t = Transformation()
      ..aspectRatio('16:9')
      ..qualityValue(80)
      ..dpr('2.0')
      ..radius('max')
      ..opacity(50)
      ..angle(90)
      ..border('2px_solid_black')
      ..x(10)
      ..y(-5)
      ..zoom(1.5)
      ..page(2)
      ..underlay('bg')
      ..named('thumb');

    expect(
      t.serialize(),
      'a_90,ar_16:9,bo_2px_solid_black,dpr_2.0,o_50,pg_2,q_80,r_max,t_thumb,'
      'u_bg,x_10,y_-5,z_1.5',
    );
  });

  test('video setters emit their short keys', () {
    final t = Transformation()
      ..videoCodec('h264')
      ..audioCodec('aac')
      ..bitRate('500k')
      ..streamingProfile('hd')
      ..startOffset(2.5)
      ..endOffset(10)
      ..duration('30p');

    expect(t.serialize(), 'ac_aac,br_500k,du_30p,eo_10,so_2.5,sp_hd,vc_h264');
  });

  test('toString is the serialized form, for a stage and a chain', () {
    final stage = Transformation()
      ..width(100)
      ..crop(CropMode.fill);
    final chain = TransformationChain([stage, Transformation()..angle(90)]);

    expect('$stage', 'c_fill,w_100');
    expect('$chain', 'c_fill,w_100/a_90');
  });

  test('a chain is empty only when every stage is', () {
    expect(TransformationChain([]).isEmpty, isTrue);
    expect(
      TransformationChain([Transformation(), Transformation()]).isEmpty,
      isTrue,
    );
    expect(
      TransformationChain([Transformation(), Transformation()..width(1)])
          .isEmpty,
      isFalse,
    );
  });
}
