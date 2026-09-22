/// Hash algorithms Cloudinary accepts for request and URL signatures.
enum CloudinarySignatureAlgorithm {
  /// SHA-1. Cloudinary's default.
  sha1,

  /// SHA-256. Opt-in, and required for long URL signatures.
  sha256;

  /// The name Cloudinary uses for this algorithm on the wire.
  String get wireName => name;
}
