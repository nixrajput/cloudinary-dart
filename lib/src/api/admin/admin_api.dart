import '../../http/transport.dart';
import 'account_api.dart';
import 'folders_api.dart';
import 'metadata_api.dart';
import 'resources_api.dart';
import 'streaming_profiles_api.dart';
import 'tags_api.dart';
import 'transformations_api.dart';
import 'upload_mappings_api.dart';
import 'upload_presets_api.dart';

/// The Cloudinary Admin API, grouped by resource family.
///
/// Reached as `cloudinary.admin`. Every call authenticates with HTTP basic
/// auth and therefore needs an API key and secret.
class AdminApi {
  /// Creates an admin API bound to [_transport].
  AdminApi(this._transport);

  final CloudinaryTransport _transport;

  AccountApi? _account;
  ResourcesApi? _resources;
  FoldersApi? _folders;
  TagsApi? _tags;
  TransformationsApi? _transformations;
  UploadPresetsApi? _uploadPresets;
  UploadMappingsApi? _uploadMappings;
  StreamingProfilesApi? _streamingProfiles;
  MetadataFieldsApi? _metadataFields;
  MetadataRulesApi? _metadataRules;

  /// Ping, usage, config and resource types.
  AccountApi get account => _account ??= AccountApi(_transport);

  /// Listing, updating, restoring and deleting assets.
  ResourcesApi get resources => _resources ??= ResourcesApi(_transport);

  /// Creating, renaming and deleting folders.
  FoldersApi get folders => _folders ??= FoldersApi(_transport);

  /// Listing tags.
  TagsApi get tags => _tags ??= TagsApi(_transport);

  /// Managing stored transformations.
  TransformationsApi get transformations =>
      _transformations ??= TransformationsApi(_transport);

  /// Managing upload presets.
  UploadPresetsApi get uploadPresets =>
      _uploadPresets ??= UploadPresetsApi(_transport);

  /// Managing upload mappings.
  UploadMappingsApi get uploadMappings =>
      _uploadMappings ??= UploadMappingsApi(_transport);

  /// Managing adaptive streaming profiles.
  StreamingProfilesApi get streamingProfiles =>
      _streamingProfiles ??= StreamingProfilesApi(_transport);

  /// Managing structured metadata field definitions.
  MetadataFieldsApi get metadataFields =>
      _metadataFields ??= MetadataFieldsApi(_transport);

  /// Managing structured metadata rules.
  MetadataRulesApi get metadataRules =>
      _metadataRules ??= MetadataRulesApi(_transport);
}
