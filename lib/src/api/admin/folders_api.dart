import '../../http/transport.dart';
import '../../models/admin_models.dart';

/// Admin endpoints for managing media library folders.
class FoldersApi {
  /// Creates a folders API bound to [_transport].
  FoldersApi(this._transport);

  final CloudinaryTransport _transport;

  /// Lists folders at the root of the media library.
  Future<FolderListResult> root({
    int? maxResults,
    String? nextCursor,
  }) async =>
      FolderListResult.fromJson(
        await _transport.send(
          method: 'GET',
          segments: ['folders'],
          query: {
            if (maxResults != null) 'max_results': maxResults,
            if (nextCursor != null) 'next_cursor': nextCursor,
          },
          basicAuth: true,
        ),
      );

  /// Lists the folders directly under [path].
  Future<FolderListResult> subfolders(
    String path, {
    int? maxResults,
    String? nextCursor,
  }) async =>
      FolderListResult.fromJson(
        await _transport.send(
          method: 'GET',
          segments: ['folders', ...splitFolderPath(path)],
          query: {
            if (maxResults != null) 'max_results': maxResults,
            if (nextCursor != null) 'next_cursor': nextCursor,
          },
          basicAuth: true,
        ),
      );

  /// Creates the folder at [path], including any missing parents.
  Future<AdminAck> create(String path) async => AdminAck.fromJson(
        await _transport.send(
          method: 'POST',
          segments: ['folders', ...splitFolderPath(path)],
          basicAuth: true,
        ),
      );

  /// Deletes the folder at [path]. The folder must already be empty.
  Future<AdminAck> delete(String path) async => AdminAck.fromJson(
        await _transport.send(
          method: 'DELETE',
          segments: ['folders', ...splitFolderPath(path)],
          basicAuth: true,
        ),
      );

  /// Moves or renames the folder at [fromPath] to [toPath].
  Future<AdminAck> rename(String fromPath, String toPath) async =>
      AdminAck.fromJson(
        await _transport.send(
          method: 'PUT',
          segments: ['folders', ...splitFolderPath(fromPath)],
          form: {'to_folder': toPath},
          basicAuth: true,
        ),
      );
}

/// Splits a folder path into URL segments.
///
/// Each component is encoded separately by the transport, so the separators
/// stay real path separators instead of becoming `%2F`, while a space inside
/// a component is still escaped.
List<String> splitFolderPath(String path) =>
    path.split('/').where((part) => part.isNotEmpty).toList(growable: false);
