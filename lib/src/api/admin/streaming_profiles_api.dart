import 'dart:convert';

import '../../http/transport.dart';
import '../../models/admin_config_models.dart';
import '../../models/admin_models.dart';

/// Admin endpoints for adaptive streaming profiles.
class StreamingProfilesApi {
  /// Creates a streaming profiles API bound to [_transport].
  StreamingProfilesApi(this._transport);

  final CloudinaryTransport _transport;

  /// Lists streaming profiles.
  Future<StreamingProfileListResult> list() async =>
      StreamingProfileListResult.fromJson(
        await _transport.send(
          method: 'GET',
          segments: ['streaming_profiles'],
          basicAuth: true,
        ),
      );

  /// Fetches one profile by name.
  Future<StreamingProfile> get(String name) async => StreamingProfile.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['streaming_profiles', name],
      basicAuth: true,
    ),
  );

  /// Creates a profile.
  Future<AdminAck> create({
    required String name,
    String? displayName,
    List<Map<String, dynamic>>? representations,
  }) async => AdminAck.fromJson(
    await _transport.send(
      method: 'POST',
      segments: ['streaming_profiles'],
      form: {
        'name': name,
        'display_name': ?displayName,
        'representations': ?_encode(representations),
      },
      basicAuth: true,
    ),
  );

  /// Updates a profile.
  Future<AdminAck> update(
    String name, {
    String? displayName,
    List<Map<String, dynamic>>? representations,
  }) async => AdminAck.fromJson(
    await _transport.send(
      method: 'PUT',
      segments: ['streaming_profiles', name],
      form: {
        'display_name': ?displayName,
        'representations': ?_encode(representations),
      },
      basicAuth: true,
    ),
  );

  /// Cloudinary takes representations as a JSON string, not repeated fields.
  static String? _encode(List<Map<String, dynamic>>? representations) =>
      representations == null ? null : jsonEncode(representations);

  /// Deletes a profile.
  Future<AdminAck> delete(String name) async => AdminAck.fromJson(
    await _transport.send(
      method: 'DELETE',
      segments: ['streaming_profiles', name],
      basicAuth: true,
    ),
  );
}
