import '../enums/cloudinary_resource_type.dart';
import 'model_base.dart';

/// The result of an upload or an explicit re-processing call.
class UploadResult extends CloudinaryModel {
  /// Parses an upload response.
  const UploadResult.fromJson(super.json);

  /// The asset's public identifier.
  String? get publicId => readStr('public_id');

  /// Cloudinary's immutable asset identifier.
  String? get assetId => readStr('asset_id');

  /// Version number, which changes each time the asset is overwritten.
  int? get version => readInt('version');

  /// Opaque identifier for this particular version.
  String? get versionId => readStr('version_id');

  /// Signature Cloudinary computed for the stored asset.
  String? get signature => readStr('signature');

  /// Pixel width, for images and video.
  int? get width => readInt('width');

  /// Pixel height, for images and video.
  int? get height => readInt('height');

  /// Stored file format, such as `jpg`.
  String? get format => readStr('format');

  /// The asset's resource type, or null if Cloudinary reported a new one.
  CloudinaryResourceType? get resourceType =>
      readEnum('resource_type', CloudinaryResourceType.values);

  /// When the asset was created.
  DateTime? get createdAt => readDate('created_at');

  /// Tags attached to the asset.
  List<String>? get tags => readStrings('tags');

  /// Stored size in bytes.
  int? get bytes => readInt('bytes');

  /// Delivery type, such as `upload` or `authenticated`.
  String? get type => readStr('type');

  /// Entity tag for the stored bytes.
  String? get etag => readStr('etag');

  /// Whether this response describes a placeholder while processing runs.
  bool? get placeholder => readBool('placeholder');

  /// Insecure delivery URL.
  String? get url => readStr('url');

  /// HTTPS delivery URL. Prefer this one.
  String? get secureUrl => readStr('secure_url');

  /// The folder the asset was stored in.
  String? get folder => readStr('folder');

  /// The display-name folder, when using fixed folder mode.
  String? get assetFolder => readStr('asset_folder');

  /// Human-readable display name.
  String? get displayName => readStr('display_name');

  /// Original filename as uploaded.
  String? get originalFilename => readStr('original_filename');

  /// Token allowing an unsigned client to delete this upload.
  String? get deleteToken => readStr('delete_token');

  /// Duration in seconds, for video and audio.
  double? get duration => readDouble('duration');

  /// Number of pages or frames, for multi-page assets.
  int? get pages => readInt('pages');

  /// Contextual metadata attached to the asset.
  Map<String, dynamic>? get context => readObject('context');

  /// Structured metadata values attached to the asset.
  Map<String, dynamic>? get metadata => readObject('metadata');

  /// Moderation entries, when a moderation add-on ran.
  List<Map<String, dynamic>>? get moderation => readObjects('moderation');

  /// Eagerly generated derived assets.
  List<Map<String, dynamic>>? get eager => readObjects('eager');

  /// Additional add-on output, such as analysis results.
  Map<String, dynamic>? get info => readObject('info');
}
