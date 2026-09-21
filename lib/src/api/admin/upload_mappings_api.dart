import '../../http/transport.dart';
import '../../models/admin_config_models.dart';
import '../../models/admin_models.dart';

/// Admin endpoints for upload mappings.
///
/// Like transformations, these identify the target by parameter rather than
/// by path segment.
class UploadMappingsApi {
  /// Creates an upload mappings API bound to [_transport].
  UploadMappingsApi(this._transport);

  final CloudinaryTransport _transport;

  /// Lists upload mappings.
  Future<UploadMappingListResult> list({
    int? maxResults,
    String? nextCursor,
  }) async =>
      UploadMappingListResult.fromJson(await _transport.send(
        method: 'GET',
        segments: ['upload_mappings'],
        query: {
          if (maxResults != null) 'max_results': maxResults,
          if (nextCursor != null) 'next_cursor': nextCursor,
        },
        basicAuth: true,
      ));

  /// Fetches the mapping for [folder].
  Future<UploadMapping> get(String folder) async => UploadMapping.fromJson(
        await _transport.send(
          method: 'GET',
          segments: ['upload_mappings'],
          query: {'folder': folder},
          basicAuth: true,
        ),
      );

  /// Creates a mapping from [folder] to [template].
  Future<AdminAck> create({
    required String folder,
    required String template,
  }) async =>
      AdminAck.fromJson(await _transport.send(
        method: 'POST',
        segments: ['upload_mappings'],
        form: {'folder': folder, 'template': template},
        basicAuth: true,
      ));

  /// Updates the mapping for [folder].
  Future<AdminAck> update({
    required String folder,
    required String template,
  }) async =>
      AdminAck.fromJson(await _transport.send(
        method: 'PUT',
        segments: ['upload_mappings'],
        form: {'folder': folder, 'template': template},
        basicAuth: true,
      ));

  /// Deletes the mapping for [folder].
  Future<AdminAck> delete(String folder) async => AdminAck.fromJson(
        await _transport.send(
          method: 'DELETE',
          segments: ['upload_mappings'],
          form: {'folder': folder},
          basicAuth: true,
        ),
      );
}
