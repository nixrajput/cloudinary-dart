import '../../config/cloudinary_config.dart';
import '../../http/transport.dart';
import 'search_query.dart';

/// The Cloudinary Search API.
///
/// Reached as `cloudinary.search`. Each builder method starts a fresh query,
/// so two searches never share accumulated state.
class SearchApi {
  /// Creates a search API bound to [_transport].
  SearchApi(this._transport, this._config);

  final CloudinaryTransport _transport;
  final CloudinaryConfig _config;

  /// Starts a new asset query.
  SearchQuery query() => SearchQuery(transport: _transport, config: _config);

  /// Starts a new folder query.
  SearchQuery folders() => SearchQuery(
        transport: _transport,
        config: _config,
        target: SearchTarget.folders,
      );

  /// Starts an asset query with an expression.
  SearchQuery expression(String value) => query().expression(value);

  /// Starts an asset query with a page size.
  SearchQuery maxResults(int value) => query().maxResults(value);

  /// Starts an asset query with an ordering.
  SearchQuery sortBy(
    String field, [
    SortDirection direction = SortDirection.asc,
  ]) =>
      query().sortBy(field, direction);

  /// Starts an asset query with an aggregation.
  SearchQuery aggregate(String field) => query().aggregate(field);

  /// Starts an asset query requesting an extra field.
  SearchQuery withField(String field) => query().withField(field);
}
