import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../config/cloudinary_config.dart';
import '../../http/transport.dart';
import '../../models/search_result.dart';

/// Sort direction for a search ordering.
enum SortDirection {
  /// Ascending.
  asc,

  /// Descending.
  desc,
}

/// Which collection a search runs against.
enum SearchTarget {
  /// Search assets.
  assets(['resources', 'search']),

  /// Search folders.
  folders(['folders', 'search']);

  const SearchTarget(this.segments);

  /// Path segments for this target.
  final List<String> segments;
}

/// A chainable Cloudinary search query.
///
/// Every builder method returns this same instance, so calls can be chained
/// or applied one at a time. `sortBy`, `aggregate`, `withField` and `fields`
/// accumulate rather than replace, and the last three de-duplicate.
class SearchQuery {
  /// Creates a query bound to a transport and target.
  SearchQuery({
    required CloudinaryTransport transport,
    required CloudinaryConfig config,
    this.target = SearchTarget.assets,
  })  : _transport = transport,
        _config = config;

  final CloudinaryTransport _transport;
  final CloudinaryConfig _config;

  /// Which collection this query searches.
  final SearchTarget target;

  String? _expression;
  int? _maxResults;
  String? _nextCursor;
  int _ttl = 300;
  final List<Map<String, String>> _sortBy = [];
  final List<String> _aggregate = [];
  final List<String> _withField = [];
  final List<String> _fields = [];

  /// Sets the search expression, in Cloudinary's search syntax.
  SearchQuery expression(String value) {
    _expression = value;
    return this;
  }

  /// Limits how many results one page returns.
  SearchQuery maxResults(int value) {
    _maxResults = value;
    return this;
  }

  /// Continues a previous search from its cursor.
  SearchQuery nextCursor(String value) {
    _nextCursor = value;
    return this;
  }

  /// Adds an ordering. Repeated calls order by each field in turn.
  SearchQuery sortBy(String field,
      [SortDirection direction = SortDirection.asc]) {
    _sortBy.add({field: direction.name});
    return this;
  }

  /// Requests an aggregation count for [field].
  SearchQuery aggregate(String field) {
    if (!_aggregate.contains(field)) _aggregate.add(field);
    return this;
  }

  /// Asks for an extra field to be included on each result.
  SearchQuery withField(String field) {
    if (!_withField.contains(field)) _withField.add(field);
    return this;
  }

  /// Restricts which fields each result carries.
  SearchQuery fields(String field) {
    if (!_fields.contains(field)) _fields.add(field);
    return this;
  }

  /// Sets how long a URL from [toUrl] stays valid, in seconds.
  SearchQuery ttl(int seconds) {
    _ttl = seconds;
    return this;
  }

  /// Renders the query as the JSON body Cloudinary expects.
  ///
  /// Empty accumulators are omitted rather than sent as empty lists, which
  /// keeps the signed payload of [toUrl] stable.
  Map<String, dynamic> toJson() => {
        if (_expression != null) 'expression': _expression,
        if (_maxResults != null) 'max_results': _maxResults,
        if (_nextCursor != null) 'next_cursor': _nextCursor,
        if (_sortBy.isNotEmpty) 'sort_by': _sortBy,
        if (_aggregate.isNotEmpty) 'aggregate': _aggregate,
        if (_withField.isNotEmpty) 'with_field': _withField,
        if (_fields.isNotEmpty) 'fields': _fields,
      };

  /// Runs the search.
  Future<SearchResult> execute() async => SearchResult.fromJson(
        await _transport.send(
          method: 'POST',
          segments: target.segments,
          json: true,
          form: toJson(),
          basicAuth: true,
        ),
      );

  /// Runs a folder search.
  Future<FolderSearchResult> executeFolders() async =>
      FolderSearchResult.fromJson(
        await _transport.send(
          method: 'POST',
          segments: SearchTarget.folders.segments,
          json: true,
          form: toJson(),
          basicAuth: true,
        ),
      );

  /// Builds a cacheable, signed search URL.
  ///
  /// The cursor is deliberately excluded from the signed payload so the same
  /// URL can be reused across pages, which is what makes the result
  /// cacheable on the CDN.
  String toUrl({int? ttl, String? nextCursor}) {
    _config.requireSigning();

    final effectiveTtl = ttl ?? _ttl;
    final payload = Map<String, dynamic>.from(toJson())..remove('next_cursor');
    final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final signature = sha256
        .convert(utf8.encode('$effectiveTtl$encoded${_config.apiSecret}'))
        .toString();

    final suffix = nextCursor == null ? '' : '/$nextCursor';
    return 'https://res.cloudinary.com/${_config.cloudName}/search/'
        '$signature/$effectiveTtl/$encoded$suffix';
  }
}
