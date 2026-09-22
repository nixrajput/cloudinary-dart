import '../enums/cloudinary_resource_type.dart';
import 'model_base.dart';

/// Reachability check result.
class PingResult extends CloudinaryModel {
  /// Parses a ping response.
  const PingResult.fromJson(super.json);

  /// Cloudinary's status word, `ok` when reachable.
  String? get status => readStr('status');

  /// Whether Cloudinary answered normally.
  bool get isOk => status == 'ok';
}

/// Storage, bandwidth and transformation usage for the environment.
class UsageReport extends CloudinaryModel {
  /// Parses a usage response.
  const UsageReport.fromJson(super.json);

  /// The plan name, such as `Free`.
  String? get plan => readStr('plan');

  /// When the current billing period ends.
  DateTime? get lastUpdated => readDate('last_updated');

  /// Credits consumed in the period.
  double? get creditsUsage => _nested('credits', 'usage');

  /// Credit allowance for the period.
  double? get creditsLimit => _nested('credits', 'limit');

  /// Percentage of the credit allowance used.
  double? get creditsUsedPercent => _nested('credits', 'used_percent');

  /// Stored bytes.
  double? get storageUsage => _nested('storage', 'usage');

  /// Delivered bytes.
  double? get bandwidthUsage => _nested('bandwidth', 'usage');

  /// Number of stored assets.
  int? get objectCount => _nested('objects', 'usage')?.toInt();

  /// Transformations performed.
  int? get transformations => _nested('transformations', 'usage')?.toInt();

  double? _nested(String group, String key) {
    final value = readObject(group)?[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Environment configuration, as the Admin API reports it.
class ConfigResult extends CloudinaryModel {
  /// Parses a config response.
  const ConfigResult.fromJson(super.json);

  /// The product environment name.
  String? get cloudName => readStr('cloud_name');

  /// When the environment was created.
  DateTime? get createdAt => readDate('created_at');

  /// Settings block, present when requested.
  Map<String, dynamic>? get settings => readObject('settings');
}

/// A stored asset as the Admin API describes it.
class AssetResource extends CloudinaryModel {
  /// Parses a resource object.
  const AssetResource.fromJson(super.json);

  /// The asset's public identifier.
  String? get publicId => readStr('public_id');

  /// Cloudinary's immutable asset identifier.
  String? get assetId => readStr('asset_id');

  /// Resource type, or null if Cloudinary reported an unfamiliar one.
  CloudinaryResourceType? get resourceType =>
      readEnum('resource_type', CloudinaryResourceType.values);

  /// Delivery type, such as `upload`.
  String? get type => readStr('type');

  /// Stored file format.
  String? get format => readStr('format');

  /// Version number.
  int? get version => readInt('version');

  /// Pixel width.
  int? get width => readInt('width');

  /// Pixel height.
  int? get height => readInt('height');

  /// Stored size in bytes.
  int? get bytes => readInt('bytes');

  /// When the asset was created.
  DateTime? get createdAt => readDate('created_at');

  /// Insecure delivery URL.
  String? get url => readStr('url');

  /// HTTPS delivery URL.
  String? get secureUrl => readStr('secure_url');

  /// Folder holding the asset.
  String? get folder => readStr('folder');

  /// Asset folder, in fixed folder mode.
  String? get assetFolder => readStr('asset_folder');

  /// Human-readable display name.
  String? get displayName => readStr('display_name');

  /// Tags attached to the asset.
  List<String>? get tags => readStrings('tags');

  /// Contextual metadata.
  Map<String, dynamic>? get context => readObject('context');

  /// Structured metadata values.
  Map<String, dynamic>? get metadata => readObject('metadata');

  /// Backup and access-control state.
  String? get accessMode => readStr('access_mode');

  /// Derived assets, when requested.
  List<Map<String, dynamic>>? get derived => readObjects('derived');

  /// Last access report data, when requested.
  DateTime? get lastAccess => readDate('accessed_at');
}

/// A page of assets, with a cursor for the next page.
class ResourceListResult extends CloudinaryModel {
  /// Parses a resource listing.
  const ResourceListResult.fromJson(super.json);

  /// The assets on this page.
  List<AssetResource> get resources => (readObjects('resources') ?? const [])
      .map(AssetResource.fromJson)
      .toList();

  /// Cursor for the next page, or null when this is the last one.
  String? get nextCursor => readStr('next_cursor');

  /// Total matches, when Cloudinary reports it.
  int? get totalCount => readInt('total_count');

  /// Rate limit ceiling reported alongside the results.
  int? get rateLimitAllowed => readInt('rate_limit_allowed');

  /// Rate limit remaining in the window.
  int? get rateLimitRemaining => readInt('rate_limit_remaining');
}

/// The outcome of a delete call, per public ID.
class DeleteResourcesResult extends CloudinaryModel {
  /// Parses a delete response.
  const DeleteResourcesResult.fromJson(super.json);

  /// Per-asset outcome, keyed by public ID, valued `deleted` or `not_found`.
  Map<String, dynamic> get deleted => readObject('deleted') ?? const {};

  /// Counts per outcome, when Cloudinary reports them.
  Map<String, dynamic>? get deletedCounts => readObject('deleted_counts');

  /// Whether more assets matched than were deleted in this call.
  bool get partial => readBool('partial') ?? false;

  /// Cursor to continue a partial deletion.
  String? get nextCursor => readStr('next_cursor');
}

/// A folder in the media library.
class Folder extends CloudinaryModel {
  /// Parses a folder object.
  const Folder.fromJson(super.json);

  /// The folder's own name.
  String? get name => readStr('name');

  /// Full path from the root.
  String? get path => readStr('path');

  /// External identifier, where one exists.
  String? get externalId => readStr('external_id');
}

/// A page of folders.
class FolderListResult extends CloudinaryModel {
  /// Parses a folder listing.
  const FolderListResult.fromJson(super.json);

  /// The folders on this page.
  List<Folder> get folders =>
      (readObjects('folders') ?? const []).map(Folder.fromJson).toList();

  /// Cursor for the next page.
  String? get nextCursor => readStr('next_cursor');

  /// Total folders matched.
  int? get totalCount => readInt('total_count');
}

/// A page of tags.
class TagListResult extends CloudinaryModel {
  /// Parses a tag listing.
  const TagListResult.fromJson(super.json);

  /// The tag names on this page.
  List<String> get tags => readStrings('tags') ?? const [];

  /// Cursor for the next page.
  String? get nextCursor => readStr('next_cursor');
}

/// A generic acknowledgement, used by endpoints that answer with a message.
class AdminAck extends CloudinaryModel {
  /// Parses an acknowledgement.
  const AdminAck.fromJson(super.json);

  /// Cloudinary's message, when present.
  String? get message => readStr('message');

  /// Whether Cloudinary reported success.
  bool get isOk => (readBool('success') ?? false) || message == 'ok';
}
