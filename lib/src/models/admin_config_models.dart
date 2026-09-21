import 'model_base.dart';

/// A named, stored transformation.
class TransformationInfo extends CloudinaryModel {
  /// Parses a transformation object.
  const TransformationInfo.fromJson(super.json);

  /// The transformation's name.
  String? get name => readStr('name');

  /// Whether Cloudinary allows it to be used in a strict-transformation
  /// environment.
  bool? get allowed => readBool('allowed');

  /// Whether this is one of Cloudinary's built-in named transformations.
  bool? get named => readBool('named');

  /// How many derived assets exist for it.
  int? get usedBy => readInt('used');

  /// The transformation components.
  List<Map<String, dynamic>>? get info => readObjects('info');

  /// Derived assets produced by this transformation.
  List<Map<String, dynamic>>? get derived => readObjects('derived');
}

/// A page of stored transformations.
class TransformationListResult extends CloudinaryModel {
  /// Parses a transformation listing.
  const TransformationListResult.fromJson(super.json);

  /// The transformations on this page.
  List<TransformationInfo> get transformations =>
      (readObjects('transformations') ?? const [])
          .map(TransformationInfo.fromJson)
          .toList();

  /// Cursor for the next page.
  String? get nextCursor => readStr('next_cursor');
}

/// An upload preset: a saved set of upload options.
class UploadPreset extends CloudinaryModel {
  /// Parses an upload preset object.
  const UploadPreset.fromJson(super.json);

  /// The preset's name.
  String? get name => readStr('name');

  /// Whether the preset may be used without a signature.
  bool? get unsigned => readBool('unsigned');

  /// The upload options the preset applies.
  Map<String, dynamic>? get settings => readObject('settings');
}

/// A page of upload presets.
class UploadPresetListResult extends CloudinaryModel {
  /// Parses an upload preset listing.
  const UploadPresetListResult.fromJson(super.json);

  /// The presets on this page.
  List<UploadPreset> get presets =>
      (readObjects('presets') ?? const []).map(UploadPreset.fromJson).toList();

  /// Cursor for the next page.
  String? get nextCursor => readStr('next_cursor');
}

/// A mapping from a folder to a remote origin.
class UploadMapping extends CloudinaryModel {
  /// Parses an upload mapping object.
  const UploadMapping.fromJson(super.json);

  /// The mapped folder name.
  String? get folder => readStr('folder');

  /// The remote URL template assets are fetched from.
  String? get template => readStr('template');
}

/// A page of upload mappings.
class UploadMappingListResult extends CloudinaryModel {
  /// Parses an upload mapping listing.
  const UploadMappingListResult.fromJson(super.json);

  /// The mappings on this page.
  List<UploadMapping> get mappings => (readObjects('mappings') ?? const [])
      .map(UploadMapping.fromJson)
      .toList();

  /// Cursor for the next page.
  String? get nextCursor => readStr('next_cursor');
}

/// An adaptive streaming profile.
class StreamingProfile extends CloudinaryModel {
  /// Parses a streaming profile object.
  const StreamingProfile.fromJson(super.json);

  /// The profile's name.
  String? get name => readStr('name');

  /// Human-readable description.
  String? get displayName => readStr('display_name');

  /// Whether Cloudinary predefined this profile.
  bool? get predefined => readBool('predefined');

  /// The representations the profile encodes.
  List<Map<String, dynamic>>? get representations =>
      readObjects('representations');
}

/// A page of streaming profiles.
class StreamingProfileListResult extends CloudinaryModel {
  /// Parses a streaming profile listing.
  const StreamingProfileListResult.fromJson(super.json);

  /// The profiles on this page.
  List<StreamingProfile> get profiles =>
      (readObjects('data') ?? const []).map(StreamingProfile.fromJson).toList();
}

/// A structured metadata field definition.
class MetadataField extends CloudinaryModel {
  /// Parses a metadata field object.
  const MetadataField.fromJson(super.json);

  /// Stable identifier used in API calls.
  String? get externalId => readStr('external_id');

  /// Field type on the wire, such as `string` or `enum`.
  String? get type => readStr('type');

  /// Human-readable label.
  String? get label => readStr('label');

  /// Whether a value is required on upload.
  bool? get mandatory => readBool('mandatory');

  /// Default value applied when none is supplied.
  Object? get defaultValue => raw['default_value'];

  /// Allowed values, for enum and set fields.
  List<Map<String, dynamic>>? get datasource =>
      readObject('datasource')?['values'] is List
      ? (readObject('datasource')!['values'] as List)
            .whereType<Map<dynamic, dynamic>>()
            .map(Map<String, dynamic>.from)
            .toList()
      : null;
}

/// A dependency rule between structured metadata fields.
class MetadataRule extends CloudinaryModel {
  /// Parses a metadata rule object.
  const MetadataRule.fromJson(super.json);

  /// Stable identifier for the rule.
  String? get externalId => readStr('external_id');

  /// The field the rule applies to.
  String? get metadataFieldId => readStr('metadata_field_id');

  /// Rule name.
  String? get name => readStr('name');

  /// The condition that triggers the rule.
  Map<String, dynamic>? get condition => readObject('condition');

  /// What the rule does when it fires.
  Map<String, dynamic>? get result => readObject('result');
}

/// The type of a structured metadata field.
enum MetadataFieldType {
  /// Free text.
  string,

  /// Whole number.
  integer,

  /// Calendar date.
  date,

  /// Single choice from a datasource.
  ///
  /// Named [enumeration] because `enum` is a reserved word in Dart. The wire
  /// value is still `enum`, which [wireName] returns.
  enumeration,

  /// Multiple choices from a datasource.
  set;

  /// The value Cloudinary expects on the wire.
  String get wireName => this == MetadataFieldType.enumeration ? 'enum' : name;
}
