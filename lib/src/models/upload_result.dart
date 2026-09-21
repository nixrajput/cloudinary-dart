import '../enums/cloudinary_resource_type.dart';
import 'model_base.dart';

/// The result of an upload or an explicit re-processing call.
class UploadResult extends CloudinaryModel {
  /// Parses an upload response.
  const UploadResult.fromJson(super.json);

  /// The asset's public identifier.
  String? get publicId => str('public_id');

  /// Cloudinary's immutable asset identifier.
  String? get assetId => str('asset_id');

  /// Version number, which changes each time the asset is overwritten.
  int? get version => integer('version');

  /// Opaque identifier for this particular version.
  String? get versionId => str('version_id');

  /// Signature Cloudinary computed for the stored asset.
  String? get signature => str('signature');

  /// Pixel width, for images and video.
  int? get width => integer('width');

  /// Pixel height, for images and video.
  int? get height => integer('height');

  /// Stored file format, such as `jpg`.
  String? get format => str('format');

  /// The asset's resource type, or null if Cloudinary reported a new one.
  CloudinaryResourceType? get resourceType =>
      enumOf('resource_type', CloudinaryResourceType.values);

  /// When the asset was created.
  DateTime? get createdAt => date('created_at');

  /// Tags attached to the asset.
  List<String>? get tags => strings('tags');

  /// Stored size in bytes.
  int? get bytes => integer('bytes');

  /// Delivery type, such as `upload` or `authenticated`.
  String? get type => str('type');

  /// Entity tag for the stored bytes.
  String? get etag => str('etag');

  /// Whether this response describes a placeholder while processing runs.
  bool? get placeholder => boolean('placeholder');

  /// Insecure delivery URL.
  String? get url => str('url');

  /// HTTPS delivery URL. Prefer this one.
  String? get secureUrl => str('secure_url');

  /// The folder the asset was stored in.
  String? get folder => str('folder');

  /// The display-name folder, when using fixed folder mode.
  String? get assetFolder => str('asset_folder');

  /// Human-readable display name.
  String? get displayName => str('display_name');

  /// Original filename as uploaded.
  String? get originalFilename => str('original_filename');

  /// Token allowing an unsigned client to delete this upload.
  String? get deleteToken => str('delete_token');

  /// Duration in seconds, for video and audio.
  double? get duration => decimal('duration');

  /// Number of pages or frames, for multi-page assets.
  int? get pages => integer('pages');

  /// Contextual metadata attached to the asset.
  Map<String, dynamic>? get context => object('context');

  /// Structured metadata values attached to the asset.
  Map<String, dynamic>? get metadata => object('metadata');

  /// Moderation entries, when a moderation add-on ran.
  List<Map<String, dynamic>>? get moderation => objects('moderation');

  /// Eagerly generated derived assets.
  List<Map<String, dynamic>>? get eager => objects('eager');

  /// Additional add-on output, such as analysis results.
  Map<String, dynamic>? get info => object('info');
}
