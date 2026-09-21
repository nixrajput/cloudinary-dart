import '../auth/signature_algorithm.dart';
import '../exceptions.dart';

/// Credentials and signing options for a Cloudinary product environment.
///
/// Immutable and const-constructible, so a Flutter widget tree can hold one
/// without causing rebuilds. [toString] never reveals [apiSecret].
class CloudinaryConfig {
  /// Creates a configuration.
  ///
  /// [apiKey] and [apiSecret] may be empty for unsigned, preset-based use.
  const CloudinaryConfig({
    required this.cloudName,
    this.apiKey = '',
    this.apiSecret = '',
    this.signatureVersion = 2,
    this.signatureAlgorithm = CloudinarySignatureAlgorithm.sha1,
  });

  /// Parses a `CLOUDINARY_URL` value of the form
  /// `cloudinary://<api_key>:<api_secret>@<cloud_name>`.
  ///
  /// Throws [CloudinaryConfigException] when the value is not a well-formed
  /// Cloudinary URL. Credentials are percent-decoded, so a secret containing
  /// reserved characters round-trips correctly.
  factory CloudinaryConfig.parse(String cloudinaryUrl) {
    final Uri uri;
    try {
      uri = Uri.parse(cloudinaryUrl);
    } on FormatException catch (e) {
      throw CloudinaryConfigException('CLOUDINARY_URL is not a valid URI: $e');
    }

    if (uri.scheme != 'cloudinary') {
      throw CloudinaryConfigException(
        'CLOUDINARY_URL must use the cloudinary:// scheme, '
        'got "${uri.scheme}://".',
      );
    }
    if (uri.host.isEmpty) {
      throw const CloudinaryConfigException(
        'CLOUDINARY_URL is missing the cloud name. Expected '
        'cloudinary://<api_key>:<api_secret>@<cloud_name>.',
      );
    }

    final userInfo = uri.userInfo;
    final separator = userInfo.indexOf(':');
    final key = separator == -1 ? userInfo : userInfo.substring(0, separator);
    final secret = separator == -1 ? '' : userInfo.substring(separator + 1);

    return CloudinaryConfig(
      cloudName: uri.host,
      apiKey: Uri.decodeComponent(key),
      apiSecret: Uri.decodeComponent(secret),
    );
  }

  /// The product environment (cloud) name.
  final String cloudName;

  /// The API key, or an empty string for unsigned use.
  final String apiKey;

  /// The API secret, or an empty string for unsigned use.
  final String apiSecret;

  /// Signature version. 2 escapes `&` in parameter values, which prevents a
  /// value from smuggling extra parameters into the signed string. Version 1
  /// exists only for compatibility with older signing implementations.
  final int signatureVersion;

  /// Hash algorithm used for request signatures.
  final CloudinarySignatureAlgorithm signatureAlgorithm;

  /// Whether this configuration can sign requests locally.
  bool get canSign => apiKey.isNotEmpty && apiSecret.isNotEmpty;

  /// Throws [CloudinaryConfigException] if the configuration is unusable.
  void validate() {
    if (cloudName.trim().isEmpty) {
      throw const CloudinaryConfigException(
        'cloudName must not be empty. Find it on your Cloudinary dashboard.',
      );
    }
    if (signatureVersion != 1 && signatureVersion != 2) {
      throw CloudinaryConfigException(
        'signatureVersion must be 1 or 2, got $signatureVersion.',
      );
    }
  }

  /// Throws [CloudinaryConfigException] unless local signing is possible.
  ///
  /// Called before any signed request. This is a thrown guard rather than an
  /// `assert` on purpose: Dart strips asserts from release builds, so an
  /// assert here would let a release build send an unauthenticated request
  /// instead of failing.
  void requireSigning() {
    validate();
    if (!canSign) {
      throw const CloudinaryConfigException(
        'This operation requires an API secret. Construct the client with '
        'Cloudinary.signed(...), or supply a SignatureProvider to sign on '
        'your server for client-side apps.',
      );
    }
  }

  /// Returns a copy with the given fields replaced.
  CloudinaryConfig copyWith({
    String? cloudName,
    String? apiKey,
    String? apiSecret,
    int? signatureVersion,
    CloudinarySignatureAlgorithm? signatureAlgorithm,
  }) =>
      CloudinaryConfig(
        cloudName: cloudName ?? this.cloudName,
        apiKey: apiKey ?? this.apiKey,
        apiSecret: apiSecret ?? this.apiSecret,
        signatureVersion: signatureVersion ?? this.signatureVersion,
        signatureAlgorithm: signatureAlgorithm ?? this.signatureAlgorithm,
      );

  @override
  String toString() => 'CloudinaryConfig(cloudName: $cloudName, '
      'apiKey: ${apiKey.isEmpty ? '<none>' : apiKey}, '
      'apiSecret: ${apiSecret.isEmpty ? '<none>' : '<redacted>'})';
}
