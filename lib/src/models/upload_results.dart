import 'model_base.dart';

/// The outcome of a destroy or delete-by-token call.
class DestroyResult extends CloudinaryModel {
  /// Parses a destroy response.
  const DestroyResult.fromJson(super.json);

  /// Cloudinary's result word, `ok` or `not found`.
  String? get result => readStr('result');

  /// Whether the asset was actually removed.
  bool get isDeleted => result == 'ok';
}

/// A response listing the public IDs an operation touched.
///
/// Returned by the tag, context and metadata commands, which all report the
/// same shape.
class PublicIdsResult extends CloudinaryModel {
  /// Parses a response carrying affected public IDs.
  const PublicIdsResult.fromJson(super.json);

  /// The public IDs the call applied to.
  List<String> get publicIds => readStrings('public_ids') ?? const [];
}

/// A generated archive, either created in storage or returned as a URL.
class ArchiveResult extends CloudinaryModel {
  /// Parses an archive response.
  const ArchiveResult.fromJson(super.json);

  /// Public ID of the stored archive.
  String? get publicId => readStr('public_id');

  /// HTTPS URL of the archive.
  String? get secureUrl => readStr('secure_url');

  /// Insecure URL of the archive.
  String? get url => readStr('url');

  /// Archive size in bytes.
  int? get bytes => readInt('bytes');

  /// How many assets went into the archive.
  int? get fileCount => readInt('file_count');

  /// How many resources matched the selection.
  int? get resourceCount => readInt('resource_count');
}

/// A generated sprite sheet or multi-frame asset.
class SpriteResult extends CloudinaryModel {
  /// Parses a sprite or multi response.
  const SpriteResult.fromJson(super.json);

  /// Public ID of the generated asset.
  String? get publicId => readStr('public_id');

  /// Version of the generated asset.
  int? get version => readInt('version');

  /// HTTPS URL of the generated image.
  String? get secureUrl => readStr('secure_url');

  /// Insecure URL of the generated image.
  String? get url => readStr('url');

  /// HTTPS URL of the companion CSS, for sprites.
  String? get secureCssUrl => readStr('secure_css_url');

  /// Per-asset placement within the sprite.
  Map<String, dynamic>? get imageInfos => readObject('image_infos');
}

/// A text image generated from a string.
class TextResult extends CloudinaryModel {
  /// Parses a text response.
  const TextResult.fromJson(super.json);

  /// Rendered width in pixels.
  int? get width => readInt('width');

  /// Rendered height in pixels.
  int? get height => readInt('height');

  /// Public ID of the generated image.
  String? get publicId => readStr('public_id');

  /// HTTPS URL of the generated image.
  String? get secureUrl => readStr('secure_url');
}

/// The status of an asynchronous explode job.
class ExplodeResult extends CloudinaryModel {
  /// Parses an explode response.
  const ExplodeResult.fromJson(super.json);

  /// Job status, typically `processing`.
  String? get status => readStr('status');

  /// Identifier for polling the job.
  String? get batchId => readStr('batch_id');
}
