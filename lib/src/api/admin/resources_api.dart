import '../../enums/cloudinary_resource_type.dart';
import '../../exceptions.dart';
import '../../http/transport.dart';
import '../../models/admin_models.dart';

/// Admin endpoints for listing, updating and deleting assets.
class ResourcesApi {
  /// Creates a resources API bound to [_transport].
  ResourcesApi(this._transport);

  final CloudinaryTransport _transport;

  Map<String, dynamic> _listQuery({
    String? nextCursor,
    int? maxResults,
    String? prefix,
    bool? tags,
    bool? context,
    bool? moderations,
    bool? metadata,
    String? direction,
    String? startAt,
    List<String>? fields,
  }) => {
    'next_cursor': ?nextCursor,
    'max_results': ?maxResults,
    'prefix': ?prefix,
    'tags': ?tags,
    'context': ?context,
    'moderations': ?moderations,
    'metadata': ?metadata,
    'direction': ?direction,
    'start_at': ?startAt,
    'fields': ?fields,
  };

  /// Lists assets of [resourceType], optionally narrowed to a delivery type.
  Future<ResourceListResult> list({
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? type,
    String? nextCursor,
    int? maxResults,
    String? prefix,
    bool? tags,
    bool? context,
    bool? moderations,
    bool? metadata,
    String? direction,
    String? startAt,
    List<String>? fields,
  }) async => ResourceListResult.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['resources', resourceType.name, ?type],
      query: _listQuery(
        nextCursor: nextCursor,
        maxResults: maxResults,
        prefix: prefix,
        tags: tags,
        context: context,
        moderations: moderations,
        metadata: metadata,
        direction: direction,
        startAt: startAt,
        fields: fields,
      ),
      basicAuth: true,
    ),
  );

  /// Lists assets carrying [tag].
  Future<ResourceListResult> listByTag(
    String tag, {
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? nextCursor,
    int? maxResults,
    bool? tags,
    bool? context,
    String? direction,
  }) async => ResourceListResult.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['resources', resourceType.name, 'tags', tag],
      query: _listQuery(
        nextCursor: nextCursor,
        maxResults: maxResults,
        tags: tags,
        context: context,
        direction: direction,
      ),
      basicAuth: true,
    ),
  );

  /// Lists assets whose context contains [key], optionally equal to [value].
  Future<ResourceListResult> listByContext(
    String key, {
    String? value,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? nextCursor,
    int? maxResults,
  }) async => ResourceListResult.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['resources', resourceType.name, 'context'],
      query: {
        'key': key,
        'value': ?value,
        'next_cursor': ?nextCursor,
        'max_results': ?maxResults,
      },
      basicAuth: true,
    ),
  );

  /// Lists assets by moderation [kind] and [status].
  Future<ResourceListResult> listByModeration({
    required String kind,
    required String status,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? nextCursor,
    int? maxResults,
  }) async => ResourceListResult.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['resources', resourceType.name, 'moderations', kind, status],
      query: _listQuery(nextCursor: nextCursor, maxResults: maxResults),
      basicAuth: true,
    ),
  );

  /// Lists assets in [assetFolder].
  Future<ResourceListResult> listByAssetFolder(
    String assetFolder, {
    String? nextCursor,
    int? maxResults,
  }) async => ResourceListResult.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['resources', 'by_asset_folder'],
      query: {
        'asset_folder': assetFolder,
        'next_cursor': ?nextCursor,
        'max_results': ?maxResults,
      },
      basicAuth: true,
    ),
  );

  /// Fetches several assets by asset ID.
  Future<ResourceListResult> listByAssetIds(List<String> assetIds) async =>
      ResourceListResult.fromJson(
        await _transport.send(
          method: 'GET',
          segments: ['resources', 'by_asset_ids'],
          query: {'asset_ids': assetIds},
          basicAuth: true,
        ),
      );

  /// Fetches several assets by public ID.
  Future<ResourceListResult> listByPublicIds(
    List<String> publicIds, {
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
  }) async => ResourceListResult.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['resources', resourceType.name, type],
      query: {'public_ids': publicIds},
      basicAuth: true,
    ),
  );

  /// Fetches one asset by public ID.
  Future<AssetResource> get(
    String publicId, {
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
    bool? colors,
    bool? faces,
    bool? exif,
    bool? pages,
    bool? cinemagraphAnalysis,
    bool? accessibilityAnalysis,
    bool? qualityAnalysis,
    int? maxResults,
  }) async => AssetResource.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['resources', resourceType.name, type, publicId],
      query: {
        'colors': ?colors,
        'faces': ?faces,
        'exif': ?exif,
        'pages': ?pages,
        'cinemagraph_analysis': ?cinemagraphAnalysis,
        'accessibility_analysis': ?accessibilityAnalysis,
        'quality_analysis': ?qualityAnalysis,
        'max_results': ?maxResults,
      },
      basicAuth: true,
    ),
  );

  /// Fetches one asset by asset ID.
  Future<AssetResource> getByAssetId(String assetId) async =>
      AssetResource.fromJson(
        await _transport.send(
          method: 'GET',
          segments: ['resources', assetId],
          basicAuth: true,
        ),
      );

  /// Updates an asset's tags, context, metadata or access control.
  Future<AssetResource> update(
    String publicId, {
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
    List<String>? tags,
    String? context,
    String? metadata,
    String? moderationStatus,
    String? assetFolder,
    String? displayName,
    Map<String, dynamic>? extraParams,
  }) async => AssetResource.fromJson(
    await _transport.send(
      method: 'POST',
      segments: ['resources', resourceType.name, type, publicId],
      form: {
        'tags': ?tags,
        'context': ?context,
        'metadata': ?metadata,
        'moderation_status': ?moderationStatus,
        'asset_folder': ?assetFolder,
        'display_name': ?displayName,
        ...?extraParams,
      },
      basicAuth: true,
    ),
  );

  /// Restores assets from backup.
  Future<Map<String, dynamic>> restore(
    List<String> publicIds, {
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
    List<String>? versions,
  }) => _transport.send(
    method: 'POST',
    segments: ['resources', resourceType.name, type, 'restore'],
    form: {'public_ids': publicIds, 'versions': ?versions},
    basicAuth: true,
  );

  /// Restores assets from backup, selected by asset ID.
  Future<Map<String, dynamic>> restoreByAssetIds(
    List<String> assetIds, {
    List<String>? versions,
  }) => _transport.send(
    method: 'POST',
    segments: ['resources', 'restore'],
    form: {'asset_ids': assetIds, 'versions': ?versions},
    basicAuth: true,
  );

  /// Deletes assets by public ID.
  Future<DeleteResourcesResult> delete(
    List<String> publicIds, {
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
    bool? invalidate,
    bool? keepOriginal,
    String? nextCursor,
  }) async => DeleteResourcesResult.fromJson(
    await _transport.send(
      method: 'DELETE',
      segments: ['resources', resourceType.name, type],
      form: {
        'public_ids': publicIds,
        'invalidate': ?invalidate,
        'keep_original': ?keepOriginal,
        'next_cursor': ?nextCursor,
      },
      basicAuth: true,
    ),
  );

  /// Deletes assets by asset ID.
  Future<DeleteResourcesResult> deleteByAssetIds(
    List<String> assetIds, {
    bool? invalidate,
  }) async => DeleteResourcesResult.fromJson(
    await _transport.send(
      method: 'DELETE',
      segments: ['resources'],
      form: {'asset_ids': assetIds, 'invalidate': ?invalidate},
      basicAuth: true,
    ),
  );

  /// Deletes every asset whose public ID starts with [prefix].
  Future<DeleteResourcesResult> deleteByPrefix(
    String prefix, {
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
    bool? invalidate,
    String? nextCursor,
  }) async => DeleteResourcesResult.fromJson(
    await _transport.send(
      method: 'DELETE',
      segments: ['resources', resourceType.name, type],
      form: {
        'prefix': prefix,
        'invalidate': ?invalidate,
        'next_cursor': ?nextCursor,
      },
      basicAuth: true,
    ),
  );

  /// Deletes every asset carrying [tag].
  Future<DeleteResourcesResult> deleteByTag(
    String tag, {
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    bool? invalidate,
  }) async => DeleteResourcesResult.fromJson(
    await _transport.send(
      method: 'DELETE',
      segments: ['resources', resourceType.name, 'tags', tag],
      form: {'invalidate': ?invalidate},
      basicAuth: true,
    ),
  );

  /// Deletes **every** asset of [resourceType] and [type].
  ///
  /// Cloudinary offers no undo for this. [confirm] must be true, which exists
  /// purely so the call cannot be made by accident or by autocomplete.
  Future<DeleteResourcesResult> deleteAll({
    required bool confirm,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
    bool? invalidate,
    String? nextCursor,
  }) async {
    if (!confirm) {
      throw const CloudinaryConfigException(
        'deleteAll removes every asset of this resource type and cannot be '
        'undone. Pass confirm: true if that is really what you want.',
      );
    }
    return DeleteResourcesResult.fromJson(
      await _transport.send(
        method: 'DELETE',
        segments: ['resources', resourceType.name, type],
        form: {
          'all': true,
          'invalidate': ?invalidate,
          'next_cursor': ?nextCursor,
        },
        basicAuth: true,
      ),
    );
  }

  /// Deletes backed-up versions of an asset.
  Future<Map<String, dynamic>> deleteBackedUpAssets({
    required String assetId,
    required List<String> versionIds,
  }) => _transport.send(
    method: 'DELETE',
    segments: ['resources', 'backup', assetId],
    form: {'versions': versionIds},
    basicAuth: true,
  );

  /// Deletes derived assets by their derived IDs.
  Future<Map<String, dynamic>> deleteDerived(List<String> derivedResourceIds) =>
      _transport.send(
        method: 'DELETE',
        segments: ['derived_resources'],
        form: {'derived_resource_ids': derivedResourceIds},
        basicAuth: true,
      );

  /// Deletes derived assets produced by specific transformations.
  Future<Map<String, dynamic>> deleteDerivedByTransformation({
    required List<String> publicIds,
    required String transformations,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
    bool keepOriginal = true,
    bool? invalidate,
  }) => _transport.send(
    method: 'DELETE',
    segments: ['resources', resourceType.name, type],
    form: {
      'public_ids': publicIds,
      'transformations': transformations,
      'keep_original': keepOriginal,
      'invalidate': ?invalidate,
    },
    basicAuth: true,
  );

  /// Relates [assetsToRelate] to the asset at [publicId].
  Future<Map<String, dynamic>> addRelated({
    required String publicId,
    required List<String> assetsToRelate,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
  }) => _transport.send(
    method: 'POST',
    segments: [
      'resources',
      'related_assets',
      resourceType.name,
      type,
      publicId,
    ],
    form: {'assets_to_relate': assetsToRelate},
    basicAuth: true,
  );

  /// Relates assets to the asset with [assetId].
  Future<Map<String, dynamic>> addRelatedByAssetId({
    required String assetId,
    required List<String> assetsToRelate,
  }) => _transport.send(
    method: 'POST',
    segments: ['resources', 'related_assets', assetId],
    form: {'assets_to_relate': assetsToRelate},
    basicAuth: true,
  );

  /// Removes relations from the asset at [publicId].
  Future<Map<String, dynamic>> deleteRelated({
    required String publicId,
    required List<String> assetsToUnrelate,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
  }) => _transport.send(
    method: 'DELETE',
    segments: [
      'resources',
      'related_assets',
      resourceType.name,
      type,
      publicId,
    ],
    form: {'assets_to_unrelate': assetsToUnrelate},
    basicAuth: true,
  );

  /// Removes relations from the asset with [assetId].
  Future<Map<String, dynamic>> deleteRelatedByAssetId({
    required String assetId,
    required List<String> assetsToUnrelate,
  }) => _transport.send(
    method: 'DELETE',
    segments: ['resources', 'related_assets', assetId],
    form: {'assets_to_unrelate': assetsToUnrelate},
    basicAuth: true,
  );

  /// Switches assets between public and authenticated access.
  ///
  /// Select with exactly one of [publicIds], [prefix] or [tag].
  Future<Map<String, dynamic>> updateAccessMode({
    required String accessMode,
    List<String>? publicIds,
    String? prefix,
    String? tag,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String type = 'upload',
    int? maxResults,
    String? nextCursor,
  }) {
    final selectors = [publicIds, prefix, tag].where((s) => s != null).length;
    if (selectors != 1) {
      throw const CloudinaryConfigException(
        'updateAccessMode needs exactly one of publicIds, prefix or tag.',
      );
    }
    return _transport.send(
      method: 'POST',
      segments: ['resources', resourceType.name, type, 'update_access_mode'],
      form: {
        'access_mode': accessMode,
        'public_ids': ?publicIds,
        'prefix': ?prefix,
        'tag': ?tag,
        'max_results': ?maxResults,
        'next_cursor': ?nextCursor,
      },
      basicAuth: true,
    );
  }
}
