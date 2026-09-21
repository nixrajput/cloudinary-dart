import '../enums/cloudinary_resource_type.dart';
import '../exceptions.dart';
import '../http/file_source.dart';
import '../http/progress.dart';
import '../http/transport.dart';
import '../models/upload_result.dart';
import '../models/upload_results.dart';

/// The Cloudinary Upload API.
///
/// Reached as `cloudinary.upload`.
class UploadApi {
  /// Creates an upload API bound to [_transport].
  UploadApi(this._transport);

  final CloudinaryTransport _transport;

  /// Uploads an asset using your API secret to sign the request.
  ///
  /// Recommended for servers. In a client app prefer [unsignedUpload] with an
  /// upload preset, so no secret ships with the app.
  ///
  /// [extraParams] passes any Upload API parameter this signature does not
  /// name, and is merged last so it can override the others.
  Future<UploadResult> upload({
    required CloudinaryFileSource file,
    CloudinaryResourceType resourceType = CloudinaryResourceType.auto,
    String? publicId,
    String? folder,
    String? assetFolder,
    String? displayName,
    List<String>? tags,
    Map<String, String>? context,
    bool? overwrite,
    bool? invalidate,
    bool? useFilename,
    bool? uniqueFilename,
    String? transformation,
    String? eager,
    bool? eagerAsync,
    String? notificationUrl,
    Map<String, dynamic>? extraParams,
    CloudinaryProgressCallback? onProgress,
  }) async {
    final json = await _transport.sendMultipart(
      segments: [resourceType.name, 'upload'],
      fields: {
        if (publicId != null) 'public_id': publicId,
        if (folder != null) 'folder': folder,
        if (assetFolder != null) 'asset_folder': assetFolder,
        if (displayName != null) 'display_name': displayName,
        if (tags != null) 'tags': tags,
        if (context != null) 'context': encodeContext(context),
        if (overwrite != null) 'overwrite': overwrite,
        if (invalidate != null) 'invalidate': invalidate,
        if (useFilename != null) 'use_filename': useFilename,
        if (uniqueFilename != null) 'unique_filename': uniqueFilename,
        if (transformation != null) 'transformation': transformation,
        if (eager != null) 'eager': eager,
        if (eagerAsync != null) 'eager_async': eagerAsync,
        if (notificationUrl != null) 'notification_url': notificationUrl,
        ...?extraParams,
      },
      file: file,
      onProgress: onProgress,
      signed: true,
    );

    return UploadResult.fromJson(json);
  }

  /// Uploads an asset using an unsigned upload preset.
  ///
  /// Needs no API key or secret, which is what makes it safe in a client app.
  /// Configure the preset as unsigned in your Cloudinary settings first.
  Future<UploadResult> unsignedUpload({
    required CloudinaryFileSource file,
    required String uploadPreset,
    CloudinaryResourceType resourceType = CloudinaryResourceType.auto,
    String? publicId,
    String? folder,
    List<String>? tags,
    Map<String, String>? context,
    Map<String, dynamic>? extraParams,
    CloudinaryProgressCallback? onProgress,
  }) async {
    if (uploadPreset.isEmpty) {
      throw const CloudinaryConfigException(
        'unsignedUpload needs a non-empty uploadPreset. Create one in your '
        'Cloudinary settings and set its signing mode to unsigned.',
      );
    }

    final json = await _transport.sendMultipart(
      segments: [resourceType.name, 'upload'],
      fields: {
        'upload_preset': uploadPreset,
        if (publicId != null) 'public_id': publicId,
        if (folder != null) 'folder': folder,
        if (tags != null) 'tags': tags,
        if (context != null) 'context': encodeContext(context),
        ...?extraParams,
      },
      file: file,
      onProgress: onProgress,
    );

    return UploadResult.fromJson(json);
  }

  /// Applies operations to an already-uploaded asset, such as generating
  /// derived versions or running an add-on.
  Future<UploadResult> explicit({
    required String publicId,
    String type = 'upload',
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? eager,
    bool? eagerAsync,
    List<String>? tags,
    String? notificationUrl,
    Map<String, dynamic>? extraParams,
  }) async =>
      UploadResult.fromJson(await _transport.send(
        method: 'POST',
        segments: [resourceType.name, 'explicit'],
        signed: true,
        form: {
          'public_id': publicId,
          'type': type,
          if (eager != null) 'eager': eager,
          if (eagerAsync != null) 'eager_async': eagerAsync,
          if (tags != null) 'tags': tags,
          if (notificationUrl != null) 'notification_url': notificationUrl,
          ...?extraParams,
        },
      ));

  /// Renames an asset, optionally moving it between delivery types.
  Future<UploadResult> rename({
    required String fromPublicId,
    required String toPublicId,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? type,
    String? toType,
    bool? overwrite,
    bool? invalidate,
    Map<String, dynamic>? extraParams,
  }) async =>
      UploadResult.fromJson(await _transport.send(
        method: 'POST',
        segments: [resourceType.name, 'rename'],
        signed: true,
        form: {
          'from_public_id': fromPublicId,
          'to_public_id': toPublicId,
          if (type != null) 'type': type,
          if (toType != null) 'to_type': toType,
          if (overwrite != null) 'overwrite': overwrite,
          if (invalidate != null) 'invalidate': invalidate,
          ...?extraParams,
        },
      ));

  /// Permanently deletes an asset.
  ///
  /// Set [invalidate] to also purge CDN copies of the asset and everything
  /// derived from it.
  Future<DestroyResult> destroy({
    required String publicId,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? type,
    bool? invalidate,
    Map<String, dynamic>? extraParams,
  }) async {
    if (publicId.isEmpty) {
      throw const CloudinaryConfigException(
        'destroy needs a non-empty publicId.',
      );
    }
    return DestroyResult.fromJson(await _transport.send(
      method: 'POST',
      segments: [resourceType.name, 'destroy'],
      signed: true,
      form: {
        'public_id': publicId,
        if (type != null) 'type': type,
        if (invalidate != null) 'invalidate': invalidate,
        ...?extraParams,
      },
    ));
  }

  /// Deletes an asset by its immutable asset ID.
  Future<DestroyResult> destroyByAssetId({
    required String assetId,
    bool? invalidate,
  }) async =>
      DestroyResult.fromJson(await _transport.send(
        method: 'DELETE',
        segments: ['asset', assetId],
        signed: true,
        form: {if (invalidate != null) 'invalidate': invalidate},
      ));

  /// Adds [tag] to each of [publicIds].
  Future<PublicIdsResult> addTag({
    required String tag,
    required List<String> publicIds,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
  }) =>
      _tagCommand('add', tag, publicIds, resourceType);

  /// Removes [tag] from each of [publicIds].
  Future<PublicIdsResult> removeTag({
    required String tag,
    required List<String> publicIds,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
  }) =>
      _tagCommand('remove', tag, publicIds, resourceType);

  /// Replaces all tags on each of [publicIds] with [tag].
  Future<PublicIdsResult> replaceTag({
    required String tag,
    required List<String> publicIds,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
  }) =>
      _tagCommand('replace', tag, publicIds, resourceType);

  /// Removes every tag from each of [publicIds].
  Future<PublicIdsResult> removeAllTags({
    required List<String> publicIds,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
  }) =>
      _tagCommand('remove_all', null, publicIds, resourceType);

  Future<PublicIdsResult> _tagCommand(
    String command,
    String? tag,
    List<String> publicIds,
    CloudinaryResourceType resourceType,
  ) async =>
      PublicIdsResult.fromJson(await _transport.send(
        method: 'POST',
        segments: [resourceType.name, 'tags'],
        signed: true,
        form: {
          'command': command,
          if (tag != null) 'tag': tag,
          'public_ids': publicIds,
        },
      ));

  /// Adds contextual metadata to each of [publicIds].
  Future<PublicIdsResult> addContext({
    required Map<String, String> context,
    required List<String> publicIds,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
  }) async =>
      PublicIdsResult.fromJson(await _transport.send(
        method: 'POST',
        segments: [resourceType.name, 'context'],
        signed: true,
        form: {
          'command': 'add',
          'context': encodeContext(context),
          'public_ids': publicIds,
        },
      ));

  /// Removes all contextual metadata from each of [publicIds].
  Future<PublicIdsResult> removeAllContext({
    required List<String> publicIds,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
  }) async =>
      PublicIdsResult.fromJson(await _transport.send(
        method: 'POST',
        segments: [resourceType.name, 'context'],
        signed: true,
        form: {'command': 'remove_all', 'public_ids': publicIds},
      ));

  /// Sets structured metadata values on each of [publicIds].
  Future<PublicIdsResult> updateMetadata({
    required Map<String, String> metadata,
    required List<String> publicIds,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
  }) async =>
      PublicIdsResult.fromJson(await _transport.send(
        method: 'POST',
        segments: [resourceType.name, 'metadata'],
        signed: true,
        form: {
          'metadata': encodeContext(metadata),
          'public_ids': publicIds,
        },
      ));

  /// Splits a multi-page asset into separate derived assets.
  Future<ExplodeResult> explode({
    required String publicId,
    required String transformation,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? notificationUrl,
  }) async =>
      ExplodeResult.fromJson(await _transport.send(
        method: 'POST',
        segments: [resourceType.name, 'explode'],
        signed: true,
        form: {
          'public_id': publicId,
          'transformation': transformation,
          if (notificationUrl != null) 'notification_url': notificationUrl,
        },
      ));

  /// Builds an animated asset from assets sharing [tag], or from [urls].
  Future<SpriteResult> multi({
    String? tag,
    List<String>? urls,
    String? transformation,
    String? format,
    bool? async,
    String? notificationUrl,
  }) async {
    _requireTagOrUrls(tag, urls, 'multi');
    return SpriteResult.fromJson(await _transport.send(
      method: 'POST',
      segments: ['multi'],
      signed: true,
      form: {
        if (tag != null) 'tag': tag,
        if (urls != null) 'urls': urls,
        if (transformation != null) 'transformation': transformation,
        if (format != null) 'format': format,
        if (async != null) 'async': async,
        if (notificationUrl != null) 'notification_url': notificationUrl,
      },
    ));
  }

  /// Builds a sprite sheet from assets sharing [tag], or from [urls].
  Future<SpriteResult> generateSprite({
    String? tag,
    List<String>? urls,
    String? transformation,
    bool? async,
    String? notificationUrl,
  }) async {
    _requireTagOrUrls(tag, urls, 'generateSprite');
    return SpriteResult.fromJson(await _transport.send(
      method: 'POST',
      segments: ['sprite'],
      signed: true,
      form: {
        if (tag != null) 'tag': tag,
        if (urls != null) 'urls': urls,
        if (transformation != null) 'transformation': transformation,
        if (async != null) 'async': async,
        if (notificationUrl != null) 'notification_url': notificationUrl,
      },
    ));
  }

  /// Renders [text] as an image asset.
  Future<TextResult> text({
    required String text,
    String? publicId,
    String? fontFamily,
    int? fontSize,
    String? fontColor,
    String? fontWeight,
    String? background,
    double? opacity,
    Map<String, dynamic>? extraParams,
  }) async =>
      TextResult.fromJson(await _transport.send(
        method: 'POST',
        segments: ['text'],
        signed: true,
        form: {
          'text': text,
          if (publicId != null) 'public_id': publicId,
          if (fontFamily != null) 'font_family': fontFamily,
          if (fontSize != null) 'font_size': fontSize,
          if (fontColor != null) 'font_color': fontColor,
          if (fontWeight != null) 'font_weight': fontWeight,
          if (background != null) 'background': background,
          if (opacity != null) 'opacity': opacity,
          ...?extraParams,
        },
      ));

  /// Creates an archive of the selected assets.
  ///
  /// Select with [tag], [publicIds] or [prefix]. At least one is required.
  Future<ArchiveResult> createArchive({
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? tag,
    List<String>? publicIds,
    String? prefix,
    String? targetFormat,
    String? targetPublicId,
    String? mode,
    bool? async,
    String? notificationUrl,
    Map<String, dynamic>? extraParams,
  }) async {
    if (tag == null && publicIds == null && prefix == null) {
      throw const CloudinaryConfigException(
        'createArchive needs one of tag, publicIds or prefix to select '
        'assets.',
      );
    }
    return ArchiveResult.fromJson(await _transport.send(
      method: 'POST',
      segments: [resourceType.name, 'generate_archive'],
      signed: true,
      form: {
        if (tag != null) 'tag': tag,
        if (publicIds != null) 'public_ids': publicIds,
        if (prefix != null) 'prefix': prefix,
        if (targetFormat != null) 'target_format': targetFormat,
        if (targetPublicId != null) 'target_public_id': targetPublicId,
        if (mode != null) 'mode': mode,
        if (async != null) 'async': async,
        if (notificationUrl != null) 'notification_url': notificationUrl,
        ...?extraParams,
      },
    ));
  }

  /// Creates a zip archive. A convenience wrapper over [createArchive].
  Future<ArchiveResult> createZip({
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? tag,
    List<String>? publicIds,
    String? prefix,
    String? targetPublicId,
    String? mode,
    Map<String, dynamic>? extraParams,
  }) =>
      createArchive(
        resourceType: resourceType,
        tag: tag,
        publicIds: publicIds,
        prefix: prefix,
        targetFormat: 'zip',
        targetPublicId: targetPublicId,
        mode: mode,
        extraParams: extraParams,
      );

  /// Deletes an asset using the delete token returned by its upload.
  ///
  /// Unsigned on purpose: this is how a client app undoes its own upload
  /// without holding an API secret. The token expires ten minutes after
  /// upload.
  Future<DestroyResult> deleteByToken({
    required String token,
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
  }) async =>
      DestroyResult.fromJson(await _transport.send(
        method: 'POST',
        segments: [resourceType.name, 'delete_by_token'],
        form: {'token': token},
      ));

  void _requireTagOrUrls(String? tag, List<String>? urls, String method) {
    if (tag == null && (urls == null || urls.isEmpty)) {
      throw CloudinaryConfigException(
        '$method needs either a tag or a non-empty urls list.',
      );
    }
  }
}

/// Encodes contextual metadata as Cloudinary's `key=value|key=value` format.
///
/// `=` and `|` inside a value are backslash-escaped, without which a value
/// containing either would silently split into extra entries.
String encodeContext(Map<String, String> context) => context.entries
    .map((e) => '${_escapeContext(e.key)}=${_escapeContext(e.value)}')
    .join('|');

String _escapeContext(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll('=', r'\=').replaceAll('|', r'\|');
