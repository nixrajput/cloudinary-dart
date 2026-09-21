/// How an asset is resized and cropped.
enum CropMode {
  /// Change dimensions without preserving aspect ratio.
  scale,

  /// Scale down to fit within the bounds.
  fit,

  /// Scale down only if larger than the bounds.
  limit,

  /// Scale up only if smaller than the bounds.
  mfit,

  /// Fill the bounds exactly, cropping the overflow.
  fill,

  /// Fill the bounds, never scaling up.
  lfill,

  /// Pad to the bounds after fitting.
  pad,

  /// Pad only if smaller than the bounds.
  lpad,

  /// Pad after scaling up to fit.
  mpad,

  /// Crop to the bounds without resizing.
  crop,

  /// Create a thumbnail around detected content.
  thumb,

  /// Fill the bounds using content-aware gravity.
  fillPad('fill_pad'),

  /// Resize to the given aspect ratio using content-aware cropping.
  auto;

  const CropMode([this._wire]);

  final String? _wire;

  /// The value Cloudinary expects in a URL.
  String get wireName => _wire ?? name;
}

/// Which part of an asset to keep when cropping.
enum Gravity {
  /// Let Cloudinary choose.
  auto,

  /// The centre.
  center,

  /// The north edge.
  north,

  /// The north-east corner.
  northEast('north_east'),

  /// The north-west corner.
  northWest('north_west'),

  /// The south edge.
  south,

  /// The south-east corner.
  southEast('south_east'),

  /// The south-west corner.
  southWest('south_west'),

  /// The east edge.
  east,

  /// The west edge.
  west,

  /// A detected face.
  face,

  /// Every detected face.
  faces,

  /// Detected faces, falling back to the centre.
  facesCenter('faces:center'),

  /// Any detected subject.
  subject;

  const Gravity([this._wire]);

  final String? _wire;

  /// The value Cloudinary expects in a URL.
  String get wireName => _wire ?? name;
}

/// Output quality.
enum Quality {
  /// Let Cloudinary decide.
  auto,

  /// Favour smaller files.
  autoLow('auto:low'),

  /// Balance size and fidelity.
  autoGood('auto:good'),

  /// Favour fidelity.
  autoBest('auto:best'),

  /// Favour size aggressively.
  autoEco('auto:eco');

  const Quality([this._wire]);

  final String? _wire;

  /// The value Cloudinary expects in a URL.
  String get wireName => _wire ?? name;
}

/// Delivery format.
enum DeliveryFormat {
  /// Pick the best format for the requesting browser.
  auto,

  /// JPEG.
  jpg,

  /// PNG.
  png,

  /// WebP.
  webp,

  /// AVIF.
  avif,

  /// GIF.
  gif,

  /// MP4.
  mp4,

  /// WebM.
  webm,

  /// SVG.
  svg,

  /// PDF.
  pdf;

  /// The value Cloudinary expects in a URL.
  String get wireName => name;
}

/// Named visual effects that need no argument.
enum Effect {
  /// Greyscale.
  grayscale,

  /// Sepia tone.
  sepia,

  /// Negative.
  negate,

  /// Oil-paint styling.
  oilPaint('oil_paint'),

  /// Pixelation.
  pixelate,

  /// Gaussian blur.
  blur,

  /// Sharpening.
  sharpen,

  /// Automatic contrast.
  autoContrast('auto_contrast'),

  /// Automatic colour balance.
  autoColor('auto_color'),

  /// Automatic brightness.
  autoBrightness('auto_brightness'),

  /// Improve overall appearance.
  improve,

  /// Upscale with machine learning.
  upscale,

  /// Remove the background.
  backgroundRemoval('background_removal');

  const Effect([this._wire]);

  final String? _wire;

  /// The value Cloudinary expects in a URL.
  String get wireName => _wire ?? name;
}

/// Transformation flags, which alter how other parameters behave.
enum Flag {
  /// Deliver as a download.
  attachment,

  /// Keep every frame of an animation.
  animated,

  /// Render progressively.
  progressive,

  /// Do not enlarge beyond the original.
  relative,

  /// Preserve transparency.
  preserveTransparency('preserve_transparency'),

  /// Strip metadata.
  stripProfile('strip_profile'),

  /// Keep colour profile and metadata.
  keepAttribution('keep_attribution'),

  /// Apply the layer to every page.
  layerApply('layer_apply'),

  /// Treat the asset as a single page.
  getinfo,

  /// Do not upscale on fill.
  ignoreAspectRatio('ignore_aspect_ratio'),

  /// Use lossy compression for a normally lossless format.
  lossy;

  const Flag([this._wire]);

  final String? _wire;

  /// The value Cloudinary expects in a URL.
  String get wireName => _wire ?? name;
}
