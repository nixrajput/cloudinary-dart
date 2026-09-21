/// Base for every parsed Cloudinary response.
///
/// Parsing is total: a missing or malformed field degrades to null rather
/// than throwing, and [raw] always holds the complete decoded body. That
/// combination keeps this package usable when Cloudinary adds a field, since
/// the new value is reachable through [raw] immediately rather than after a
/// release here.
abstract class CloudinaryModel {
  /// Wraps a decoded response body.
  const CloudinaryModel(this.raw);

  /// The full decoded response, including fields this package does not model.
  final Map<String, dynamic> raw;

  /// Reads [key] as a string, or null.
  String? str(String key) {
    final value = raw[key];
    if (value == null) return null;
    return value is String ? value : value.toString();
  }

  /// Reads [key] as an integer, or null.
  int? integer(String key) {
    final value = raw[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Reads [key] as a double, or null.
  double? decimal(String key) {
    final value = raw[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Reads [key] as a boolean, or null.
  bool? boolean(String key) {
    final value = raw[key];
    if (value is bool) return value;
    if (value is String) {
      if (value == 'true') return true;
      if (value == 'false') return false;
    }
    return null;
  }

  /// Reads [key] as a timestamp, or null when absent or unparseable.
  DateTime? date(String key) {
    final value = raw[key];
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  /// Reads [key] as a list of strings, or null.
  List<String>? strings(String key) {
    final value = raw[key];
    if (value is! List) return null;
    return value.map((e) => e.toString()).toList(growable: false);
  }

  /// Reads [key] as a nested object, or null.
  Map<String, dynamic>? object(String key) {
    final value = raw[key];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  /// Reads [key] as a list of objects, or null.
  List<Map<String, dynamic>>? objects(String key) {
    final value = raw[key];
    if (value is! List) return null;
    return value
        .whereType<Map<dynamic, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  /// Reads [key] as one of [values], matched on enum name, or null.
  ///
  /// An unrecognised value yields null rather than throwing, so a new
  /// Cloudinary enum member never breaks parsing. The original string stays
  /// reachable through [raw].
  T? enumOf<T extends Enum>(String key, List<T> values) {
    final value = raw[key];
    if (value is! String) return null;
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }

  @override
  String toString() => '$runtimeType($raw)';
}
