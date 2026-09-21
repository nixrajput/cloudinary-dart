import '../../http/transport.dart';
import '../../models/admin_config_models.dart';
import '../../models/admin_models.dart';

/// Admin endpoints for upload presets.
class UploadPresetsApi {
  /// Creates an upload presets API bound to [_transport].
  UploadPresetsApi(this._transport);

  final CloudinaryTransport _transport;

  /// Lists upload presets.
  Future<UploadPresetListResult> list({
    int? maxResults,
    String? nextCursor,
  }) async =>
      UploadPresetListResult.fromJson(await _transport.send(
        method: 'GET',
        segments: ['upload_presets'],
        query: {
          if (maxResults != null) 'max_results': maxResults,
          if (nextCursor != null) 'next_cursor': nextCursor,
        },
        basicAuth: true,
      ));

  /// Fetches one preset by name.
  Future<UploadPreset> get(String name) async => UploadPreset.fromJson(
        await _transport.send(
          method: 'GET',
          segments: ['upload_presets', name],
          basicAuth: true,
        ),
      );

  /// Creates a preset.
  Future<AdminAck> create({
    required String name,
    bool unsigned = false,
    Map<String, dynamic>? settings,
  }) async =>
      AdminAck.fromJson(await _transport.send(
        method: 'POST',
        segments: ['upload_presets'],
        form: {'name': name, 'unsigned': unsigned, ...?settings},
        basicAuth: true,
      ));

  /// Updates a preset.
  Future<AdminAck> update(
    String name, {
    bool? unsigned,
    Map<String, dynamic>? settings,
  }) async =>
      AdminAck.fromJson(await _transport.send(
        method: 'PUT',
        segments: ['upload_presets', name],
        form: {
          if (unsigned != null) 'unsigned': unsigned,
          ...?settings,
        },
        basicAuth: true,
      ));

  /// Deletes a preset.
  Future<AdminAck> delete(String name) async => AdminAck.fromJson(
        await _transport.send(
          method: 'DELETE',
          segments: ['upload_presets', name],
          basicAuth: true,
        ),
      );
}
