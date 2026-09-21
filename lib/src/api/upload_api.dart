import '../enums/cloudinary_resource_type.dart';
import '../exceptions.dart';
import '../http/file_source.dart';
import '../http/progress.dart';
import '../http/transport.dart';
import '../models/upload_result.dart';

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
