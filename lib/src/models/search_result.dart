import 'admin_models.dart';
import 'model_base.dart';

/// A page of search results.
class SearchResult extends CloudinaryModel {
  /// Parses a search response.
  const SearchResult.fromJson(super.json);

  /// The assets on this page.
  List<AssetResource> get resources => (readObjects('resources') ?? const [])
      .map(AssetResource.fromJson)
      .toList();

  /// Total assets matching the expression, across all pages.
  int? get totalCount => readInt('total_count');

  /// How long Cloudinary took, in milliseconds.
  int? get time => readInt('time');

  /// Cursor for the next page, or null when this is the last one.
  String? get nextCursor => readStr('next_cursor');

  /// Aggregation counts, when aggregates were requested.
  Map<String, dynamic>? get aggregations => readObject('aggregations');
}

/// A page of folder search results.
class FolderSearchResult extends CloudinaryModel {
  /// Parses a folder search response.
  const FolderSearchResult.fromJson(super.json);

  /// The folders on this page.
  List<Folder> get folders =>
      (readObjects('folders') ?? const []).map(Folder.fromJson).toList();

  /// Total folders matching the expression.
  int? get totalCount => readInt('total_count');

  /// Cursor for the next page.
  String? get nextCursor => readStr('next_cursor');
}
