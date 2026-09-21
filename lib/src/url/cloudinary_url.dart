import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../auth/auth_token.dart';
import '../auth/signature_algorithm.dart';
import '../config/cloudinary_config.dart';
import '../config/url_config.dart';
import '../enums/cloudinary_delivery_type.dart';
import '../enums/cloudinary_resource_type.dart';
import '../exceptions.dart';
import 'distribution.dart';
import 'transformation.dart';

/// Builds delivery URLs.
///
/// Reached as `cloudinary.url`. Pure and synchronous, so a widget can call it
/// during a build.
class UrlApi {
  /// Creates a URL API bound to a configuration.
  const UrlApi(this._config, this._urlConfig);

  final CloudinaryConfig _config;
  final UrlConfig _urlConfig;

  /// Starts a URL for an image.
  CloudinaryUrlBuilder image(String publicId) => CloudinaryUrlBuilder(
    config: _config,
    urlConfig: _urlConfig,
    publicId: publicId,
    resourceType: CloudinaryResourceType.image,
  );

  /// Starts a URL for a video.
  CloudinaryUrlBuilder video(String publicId) => CloudinaryUrlBuilder(
    config: _config,
    urlConfig: _urlConfig,
    publicId: publicId,
    resourceType: CloudinaryResourceType.video,
  );

  /// Starts a URL for a raw file.
  CloudinaryUrlBuilder raw(String publicId) => CloudinaryUrlBuilder(
    config: _config,
    urlConfig: _urlConfig,
    publicId: publicId,
    resourceType: CloudinaryResourceType.raw,
  );
}

/// A chainable delivery URL under construction.
class CloudinaryUrlBuilder {
  /// Creates a builder. Prefer [UrlApi.image] and friends.
  CloudinaryUrlBuilder({
    required CloudinaryConfig config,
    required UrlConfig urlConfig,
    required String publicId,
    required CloudinaryResourceType resourceType,
  }) : _config = config,
       _urlConfig = urlConfig,
       _publicId = publicId,
       _resourceType = resourceType;

  final CloudinaryConfig _config;
  final UrlConfig _urlConfig;
  final String _publicId;
  final CloudinaryResourceType _resourceType;

  CloudinaryDeliveryType _deliveryType = CloudinaryDeliveryType.upload;
  TransformationChain? _chain;
  int? _version;
  String? _format;
  String? _urlSuffix;
  bool _signed = false;
  bool _longSignature = false;
  AuthToken? _authToken;

  /// Applies a single transformation.
  CloudinaryUrlBuilder transform(Transformation transformation) {
    _chain = TransformationChain([transformation]);
    return this;
  }

  /// Applies a chain of transformations, joined with `/`.
  CloudinaryUrlBuilder transformChain(TransformationChain chain) {
    _chain = chain;
    return this;
  }

  /// Sets the delivery type segment.
  CloudinaryUrlBuilder deliveryType(CloudinaryDeliveryType type) {
    _deliveryType = type;
    return this;
  }

  /// Pins an explicit version, which always wins over a forced `v1`.
  CloudinaryUrlBuilder version(int value) {
    _version = value;
    return this;
  }

  /// Appends a file extension, converting the delivered format.
  CloudinaryUrlBuilder format(String value) {
    _format = value;
    return this;
  }

  /// Adds an SEO-friendly suffix in place of the delivery type segment.
  CloudinaryUrlBuilder urlSuffix(String value) {
    _urlSuffix = value;
    return this;
  }

  /// Signs the URL so it cannot be altered by the requester.
  ///
  /// [longSignature] switches to a 32-character SHA-256 signature instead of
  /// the 8-character SHA-1 default.
  CloudinaryUrlBuilder signed({bool longSignature = false}) {
    _signed = true;
    _longSignature = longSignature;
    return this;
  }

  /// Appends a time-limited access token as a query string.
  CloudinaryUrlBuilder authToken(AuthToken token) {
    _authToken = token;
    return this;
  }

  /// Builds the URL.
  String build() {
    // An absolute source is already a URL; Cloudinary returns it untouched.
    if (_publicId.startsWith('http://') || _publicId.startsWith('https://')) {
      return _publicId;
    }

    final transformation = _chain?.serialize() ?? '';
    final source = _format == null ? _publicId : '$_publicId.$_format';
    final sourceToSign = _urlSuffix == null ? source : '$source/$_urlSuffix';

    final signature = _signed
        ? _signatureFor(transformation, sourceToSign)
        : '';
    final versionSegment = _resolveVersion(sourceToSign);

    final prefix = buildDistributionPrefix(
      cloudName: _config.cloudName,
      source: _publicId,
      config: _urlConfig,
    );

    final parts = <String>[
      prefix,
      ...resolveTypeSegments(
        resourceType: _resourceType.name,
        deliveryType: _deliveryType.wireName,
        config: _urlConfig,
      ),
      signature,
      transformation,
      versionSegment,
      sourceToSign,
    ].where((part) => part.isNotEmpty);

    final url = parts.join('/').replaceAll(' ', '%20');

    final token = _authToken;
    if (token == null) return url;
    return '$url?${token.generate()}';
  }

  /// Cloudinary forces `v1` when the source has a folder path and no explicit
  /// version, so overwriting an asset busts CDN caches.
  String _resolveVersion(String sourceToSign) {
    if (_version != null) return 'v$_version';
    if (!_urlConfig.forceVersion) return '';
    if (!sourceToSign.contains('/')) return '';
    if (RegExp(r'^v\d+').hasMatch(sourceToSign)) return '';
    return 'v1';
  }

  String _signatureFor(String transformation, String sourceToSign) {
    if (_config.apiSecret.isEmpty) {
      throw const CloudinaryConfigException(
        'Signing a delivery URL needs an API secret. Construct the client '
        'with Cloudinary.signed(...).',
      );
    }

    final toSign = [
      transformation,
      sourceToSign,
    ].where((part) => part.isNotEmpty).join('/');

    final algorithm = _longSignature
        ? CloudinarySignatureAlgorithm.sha256
        : _config.signatureAlgorithm;
    final length = _longSignature ? 32 : 8;

    final payload = utf8.encode(toSign + _config.apiSecret);
    final digest = switch (algorithm) {
      CloudinarySignatureAlgorithm.sha1 => sha1.convert(payload),
      CloudinarySignatureAlgorithm.sha256 => sha256.convert(payload),
    };

    final encoded = base64
        .encode(digest.bytes)
        .substring(0, length)
        .replaceAll('/', '_')
        .replaceAll('+', '-');

    return 's--$encoded--';
  }
}
