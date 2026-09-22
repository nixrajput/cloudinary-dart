import '../../http/transport.dart';
import '../../models/admin_config_models.dart';
import '../../models/admin_models.dart';

/// Admin endpoints for structured metadata field definitions.
///
/// These endpoints take JSON bodies rather than form encoding, unlike the
/// rest of the Admin API.
class MetadataFieldsApi {
  /// Creates a metadata fields API bound to [_transport].
  MetadataFieldsApi(this._transport);

  final CloudinaryTransport _transport;

  /// Lists metadata field definitions.
  Future<List<MetadataField>> list() async {
    final json = await _transport.send(
      method: 'GET',
      segments: ['metadata_fields'],
      basicAuth: true,
    );
    final fields = json['metadata_fields'];
    return fields is List
        ? fields
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => MetadataField.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [];
  }

  /// Fetches one field definition.
  Future<MetadataField> get(String externalId) async => MetadataField.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['metadata_fields', externalId],
      basicAuth: true,
    ),
  );

  /// Creates a field definition.
  ///
  /// [type] serializes to Cloudinary's wire name, so
  /// [MetadataFieldType.enumeration] is sent as `enum`.
  Future<MetadataField> create({
    required String externalId,
    required String label,
    required MetadataFieldType type,
    bool? mandatory,
    Object? defaultValue,
    List<Map<String, dynamic>>? datasourceValues,
    Map<String, dynamic>? extraParams,
  }) async => MetadataField.fromJson(
    await _transport.send(
      method: 'POST',
      segments: ['metadata_fields'],
      json: true,
      form: {
        'external_id': externalId,
        'label': label,
        'type': type.wireName,
        'mandatory': ?mandatory,
        'default_value': ?defaultValue,
        if (datasourceValues != null)
          'datasource': {'values': datasourceValues},
        ...?extraParams,
      },
      basicAuth: true,
    ),
  );

  /// Updates a field definition.
  Future<MetadataField> update(
    String externalId, {
    String? label,
    bool? mandatory,
    Object? defaultValue,
    Map<String, dynamic>? extraParams,
  }) async => MetadataField.fromJson(
    await _transport.send(
      method: 'PUT',
      segments: ['metadata_fields', externalId],
      json: true,
      form: {
        'label': ?label,
        'mandatory': ?mandatory,
        'default_value': ?defaultValue,
        ...?extraParams,
      },
      basicAuth: true,
    ),
  );

  /// Deletes a field definition.
  Future<AdminAck> delete(String externalId) async => AdminAck.fromJson(
    await _transport.send(
      method: 'DELETE',
      segments: ['metadata_fields', externalId],
      basicAuth: true,
    ),
  );

  /// Adds or updates datasource entries on a field.
  Future<Map<String, dynamic>> updateDatasource({
    required String externalId,
    required List<Map<String, dynamic>> values,
  }) => _transport.send(
    method: 'PUT',
    segments: ['metadata_fields', externalId, 'datasource'],
    json: true,
    form: {'values': values},
    basicAuth: true,
  );

  /// Soft-deletes datasource entries.
  Future<Map<String, dynamic>> deleteDatasourceEntries({
    required String externalId,
    required List<String> entriesExternalIds,
  }) => _transport.send(
    method: 'DELETE',
    segments: ['metadata_fields', externalId, 'datasource'],
    json: true,
    form: {'external_ids': entriesExternalIds},
    basicAuth: true,
  );

  /// Restores previously deleted datasource entries.
  Future<Map<String, dynamic>> restoreDatasourceEntries({
    required String externalId,
    required List<String> entriesExternalIds,
  }) => _transport.send(
    method: 'POST',
    segments: ['metadata_fields', externalId, 'datasource_restore'],
    json: true,
    form: {'external_ids': entriesExternalIds},
    basicAuth: true,
  );

  /// Reorders the entries of a field's datasource.
  Future<Map<String, dynamic>> orderDatasource({
    required String externalId,
    required String orderBy,
    String direction = 'asc',
  }) => _transport.send(
    method: 'POST',
    segments: ['metadata_fields', externalId, 'datasource', 'order'],
    json: true,
    form: {'order_by': orderBy, 'direction': direction},
    basicAuth: true,
  );

  /// Reorders the metadata fields themselves.
  Future<Map<String, dynamic>> reorderFields({
    required String orderBy,
    String direction = 'asc',
  }) => _transport.send(
    method: 'PUT',
    segments: ['metadata_fields', 'order'],
    json: true,
    form: {'order_by': orderBy, 'direction': direction},
    basicAuth: true,
  );
}

/// Admin endpoints for structured metadata rules.
class MetadataRulesApi {
  /// Creates a metadata rules API bound to [_transport].
  MetadataRulesApi(this._transport);

  final CloudinaryTransport _transport;

  /// Lists metadata rules.
  Future<List<MetadataRule>> list() async {
    final json = await _transport.send(
      method: 'GET',
      segments: ['metadata_rules'],
      basicAuth: true,
    );
    final rules = json['metadata_rules'];
    return rules is List
        ? rules
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => MetadataRule.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [];
  }

  /// Creates a metadata rule.
  Future<MetadataRule> create({
    required String metadataFieldId,
    required Map<String, dynamic> condition,
    required Map<String, dynamic> result,
    String? name,
  }) async => MetadataRule.fromJson(
    await _transport.send(
      method: 'POST',
      segments: ['metadata_rules'],
      json: true,
      form: {
        'metadata_field_id': metadataFieldId,
        'condition': condition,
        'result': result,
        'name': ?name,
      },
      basicAuth: true,
    ),
  );

  /// Updates a metadata rule.
  Future<MetadataRule> update(
    String externalId, {
    Map<String, dynamic>? condition,
    Map<String, dynamic>? result,
    String? name,
    String? state,
  }) async => MetadataRule.fromJson(
    await _transport.send(
      method: 'PUT',
      segments: ['metadata_rules', externalId],
      json: true,
      form: {
        'condition': ?condition,
        'result': ?result,
        'name': ?name,
        'state': ?state,
      },
      basicAuth: true,
    ),
  );

  /// Deletes a metadata rule.
  Future<AdminAck> delete(String externalId) async => AdminAck.fromJson(
    await _transport.send(
      method: 'DELETE',
      segments: ['metadata_rules', externalId],
      basicAuth: true,
    ),
  );
}
