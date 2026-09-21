import '../../enums/cloudinary_resource_type.dart';
import '../../http/transport.dart';
import '../../models/admin_models.dart';

/// Admin endpoints for listing tags.
class TagsApi {
  /// Creates a tags API bound to [_transport].
  TagsApi(this._transport);

  final CloudinaryTransport _transport;

  /// Lists tags in use for [resourceType].
  Future<TagListResult> list({
    CloudinaryResourceType resourceType = CloudinaryResourceType.image,
    String? prefix,
    int? maxResults,
    String? nextCursor,
  }) async =>
      TagListResult.fromJson(
        await _transport.send(
          method: 'GET',
          segments: ['tags', resourceType.name],
          query: {
            if (prefix != null) 'prefix': prefix,
            if (maxResults != null) 'max_results': maxResults,
            if (nextCursor != null) 'next_cursor': nextCursor,
          },
          basicAuth: true,
        ),
      );
}
