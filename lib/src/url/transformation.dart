import 'transformation_enums.dart';

/// One transformation component set, serialized as `w_100,h_150,c_fill`.
///
/// Components are held by their Cloudinary short key and emitted in
/// alphabetical key order, which is what Cloudinary's own SDKs produce.
/// Anything without a typed setter goes through [raw].
class Transformation {
  /// Creates an empty transformation.
  Transformation();

  final Map<String, String> _components = {};
  final List<String> _raw = [];

  /// Sets the output width. A string allows `auto` and expressions.
  void width(Object value) => _components['w'] = '$value';

  /// Sets the output height.
  void height(Object value) => _components['h'] = '$value';

  /// Sets the crop mode.
  void crop(CropMode mode) => _components['c'] = mode.wireName;

  /// Sets the gravity used when cropping.
  void gravity(Gravity value) => _components['g'] = value.wireName;

  /// Sets the aspect ratio, for example `16:9`.
  void aspectRatio(String value) => _components['ar'] = value;

  /// Sets output quality.
  void quality(Quality value) => _components['q'] = value.wireName;

  /// Sets an explicit numeric quality between 1 and 100.
  void qualityValue(int value) => _components['q'] = '$value';

  /// Sets the delivery format.
  void format(DeliveryFormat value) => _components['f'] = value.wireName;

  /// Applies a named effect.
  void effect(Effect value) => _components['e'] = value.wireName;

  /// Applies an effect with an argument, such as `blur:300`.
  void effectValue(Effect value, Object argument) =>
      _components['e'] = '${value.wireName}:$argument';

  /// Sets the device pixel ratio.
  void dpr(Object value) => _components['dpr'] = '$value';

  /// Sets corner rounding. Use `max` for a circle.
  void radius(Object value) => _components['r'] = '$value';

  /// Sets opacity from 0 to 100.
  void opacity(int value) => _components['o'] = '$value';

  /// Rotates by degrees, or by a named mode such as `auto_right`.
  void angle(Object value) => _components['a'] = '$value';

  /// Sets the background, accepting `#rrggbb` or a colour name.
  void background(String value) => _components['b'] = _color(value);

  /// Sets the colour used by effects and text.
  void color(String value) => _components['co'] = _color(value);

  /// Sets a border, such as `2px_solid_black`.
  void border(String value) => _components['bo'] = value;

  /// Sets the horizontal offset.
  void x(Object value) => _components['x'] = '$value';

  /// Sets the vertical offset.
  void y(Object value) => _components['y'] = '$value';

  /// Sets the zoom factor.
  void zoom(Object value) => _components['z'] = '$value';

  /// Selects a page or frame.
  void page(Object value) => _components['pg'] = '$value';

  /// Overlays another asset.
  void overlay(String value) => _components['l'] = value;

  /// Places another asset underneath.
  void underlay(String value) => _components['u'] = value;

  /// Applies a stored named transformation.
  void named(String value) => _components['t'] = value;

  /// Sets the video codec.
  void videoCodec(String value) => _components['vc'] = value;

  /// Sets the audio codec.
  void audioCodec(String value) => _components['ac'] = value;

  /// Sets the bit rate.
  void bitRate(Object value) => _components['br'] = '$value';

  /// Sets the adaptive streaming profile.
  void streamingProfile(String value) => _components['sp'] = value;

  /// Sets the start offset for video.
  void startOffset(Object value) => _components['so'] = '$value';

  /// Sets the end offset for video.
  void endOffset(Object value) => _components['eo'] = '$value';

  /// Sets the duration for video.
  void duration(Object value) => _components['du'] = '$value';

  /// Sets flags. Multiple flags join with a dot, which is Cloudinary's
  /// separator for this parameter alone.
  void flags(List<Flag> values) =>
      _components['fl'] = values.map((f) => f.wireName).join('.');

  /// Appends a component verbatim, for anything without a typed setter.
  ///
  /// Raw components are emitted last, in the order added.
  void raw(String component) => _raw.add(component);

  /// Whether nothing has been set.
  bool get isEmpty => _components.isEmpty && _raw.isEmpty;

  /// Serializes to Cloudinary's comma-separated short form.
  String serialize() {
    final keys = _components.keys.toList()..sort();
    return [
      for (final key in keys) '${key}_${_components[key]}',
      ..._raw,
    ].join(',');
  }

  static String _color(String value) =>
      value.startsWith('#') ? 'rgb:${value.substring(1)}' : value;

  @override
  String toString() => serialize();
}

/// Several transformations applied in order, joined with `/`.
class TransformationChain {
  /// Creates a chain from [transformations].
  TransformationChain(this.transformations);

  /// The transformations, applied left to right.
  final List<Transformation> transformations;

  /// Whether every stage is empty.
  bool get isEmpty => transformations.every((t) => t.isEmpty);

  /// Serializes each stage and joins them with `/`.
  String serialize() => transformations
      .where((t) => !t.isEmpty)
      .map((t) => t.serialize())
      .join('/');

  @override
  String toString() => serialize();
}
