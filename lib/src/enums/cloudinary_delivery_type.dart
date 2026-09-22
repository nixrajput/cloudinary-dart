/// How an asset is delivered and how Cloudinary obtained it.
///
/// This forms the second path segment of a delivery URL, as in
/// `/image/upload/...` or `/image/fetch/...`.
enum CloudinaryDeliveryType {
  /// Assets uploaded to your product environment.
  upload,

  /// Uploaded assets that require a signed URL to access.
  private,

  /// Assets fetched from a remote URL on first request.
  fetch,

  /// Uploaded assets restricted by an access token.
  authenticated,

  /// A generated list of assets sharing a tag.
  list,

  /// Assets fetched from a Facebook profile.
  facebook,

  /// Assets fetched from a Twitter profile by name.
  twitter,

  /// Assets fetched from Gravatar.
  gravatar,

  /// Thumbnails fetched from YouTube.
  youtube,

  /// Thumbnails fetched from Vimeo.
  vimeo,

  /// A generated sprite sheet.
  sprite,

  /// A generated multi-frame asset.
  multi,

  /// A generated text image.
  text,

  /// An asset referenced by asset id.
  asset,

  /// Thumbnails fetched from Animoto.
  animoto,

  /// Thumbnails fetched from Dailymotion.
  dailymotion;

  /// The value Cloudinary uses for this type in a URL path.
  String get wireName => name;
}
