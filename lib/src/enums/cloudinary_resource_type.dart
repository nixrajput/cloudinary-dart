/// The kind of asset an operation acts on.
///
/// This is the first path segment of an API call and of a delivery URL, so it
/// routes the request as well as describing the asset.
enum CloudinaryResourceType {
  /// Images, including animated formats and PDFs.
  image,

  /// Files stored and delivered without media processing.
  raw,

  /// Video and audio.
  video,

  /// Let Cloudinary detect the type from the file. Valid for uploads only.
  auto,
}
