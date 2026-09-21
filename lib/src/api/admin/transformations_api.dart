import '../../http/transport.dart';
import '../../models/admin_config_models.dart';
import '../../models/admin_models.dart';

/// Admin endpoints for stored transformations.
///
/// Unlike presets and streaming profiles, these identify the transformation
/// by a `transformation` parameter rather than a path segment. That
/// asymmetry is Cloudinary's, not an oversight here.
class TransformationsApi {
  /// Creates a transformations API bound to [_transport].
  TransformationsApi(this._transport);

  final CloudinaryTransport _transport;

  /// Lists stored transformations.
  Future<TransformationListResult> list({
    int? maxResults,
    String? nextCursor,
    bool? named,
  }) async =>
      TransformationListResult.fromJson(await _transport.send(
        method: 'GET',
        segments: ['transformations'],
        query: {
          if (maxResults != null) 'max_results': maxResults,
          if (nextCursor != null) 'next_cursor': nextCursor,
          if (named != null) 'named': named,
        },
        basicAuth: true,
      ));

  /// Fetches one transformation by name or definition.
  Future<TransformationInfo> get(
    String transformation, {
    int? maxResults,
    String? nextCursor,
  }) async =>
      TransformationInfo.fromJson(await _transport.send(
        method: 'GET',
        segments: ['transformations'],
        query: {
          'transformation': transformation,
          if (maxResults != null) 'max_results': maxResults,
          if (nextCursor != null) 'next_cursor': nextCursor,
        },
        basicAuth: true,
      ));

  /// Creates a named transformation.
  Future<AdminAck> create({
    required String name,
    required String transformation,
  }) async =>
      AdminAck.fromJson(await _transport.send(
        method: 'POST',
        segments: ['transformations'],
        form: {'name': name, 'transformation': transformation},
        basicAuth: true,
      ));

  /// Updates a stored transformation.
  Future<AdminAck> update(
    String transformation, {
    bool? allowedForStrict,
    String? unsafeUpdate,
  }) async =>
      AdminAck.fromJson(await _transport.send(
        method: 'PUT',
        segments: ['transformations'],
        form: {
          'transformation': transformation,
          if (allowedForStrict != null) 'allowed_for_strict': allowedForStrict,
          if (unsafeUpdate != null) 'unsafe_update': unsafeUpdate,
        },
        basicAuth: true,
      ));

  /// Deletes a stored transformation.
  Future<AdminAck> delete(String transformation, {bool? invalidate}) async =>
      AdminAck.fromJson(await _transport.send(
        method: 'DELETE',
        segments: ['transformations'],
        form: {
          'transformation': transformation,
          if (invalidate != null) 'invalidate': invalidate,
        },
        basicAuth: true,
      ));
}
