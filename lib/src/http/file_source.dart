import 'dart:typed_data';

/// Where the bytes of an upload come from.
sealed class CloudinaryFileSource {
  const CloudinaryFileSource();

  /// Uploads an in-memory buffer.
  ///
  /// The only variant that works on every platform, including the web.
  const factory CloudinaryFileSource.bytes(
    Uint8List bytes, {
    String? filename,
  }) = CloudinaryBytesSource;

  /// Uploads a file from the local filesystem.
  ///
  /// Not available on the web, where there is no filesystem. Use
  /// [CloudinaryFileSource.bytes] there.
  const factory CloudinaryFileSource.path(String path, {String? filename}) =
      CloudinaryPathSource;

  /// Asks Cloudinary to fetch the asset from a remote URL.
  ///
  /// Sent as a plain form field rather than a file part, so nothing is
  /// uploaded from this machine.
  const factory CloudinaryFileSource.url(String url) = CloudinaryUrlSource;
}

/// An upload sourced from an in-memory buffer.
class CloudinaryBytesSource extends CloudinaryFileSource {
  /// Creates an in-memory upload source.
  const CloudinaryBytesSource(this.bytes, {this.filename});

  /// The bytes to upload.
  final Uint8List bytes;

  /// Filename to report to Cloudinary. Defaults to a timestamp when omitted.
  final String? filename;
}

/// An upload sourced from a local file path.
class CloudinaryPathSource extends CloudinaryFileSource {
  /// Creates a filesystem upload source.
  const CloudinaryPathSource(this.path, {this.filename});

  /// Path to the file to upload.
  final String path;

  /// Filename to report to Cloudinary. Defaults to the file's own name.
  final String? filename;
}

/// An upload Cloudinary fetches from a remote URL itself.
class CloudinaryUrlSource extends CloudinaryFileSource {
  /// Creates a remote-URL upload source.
  const CloudinaryUrlSource(this.url);

  /// The publicly reachable URL Cloudinary should fetch.
  final String url;
}
