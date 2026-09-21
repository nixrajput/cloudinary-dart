import 'package:http/http.dart' as http;

import 'api/admin/admin_api.dart';
import 'api/search/search_api.dart';
import 'api/upload_api.dart';
import 'auth/signature_provider.dart';
import 'config/cloudinary_config.dart';
import 'config/environment.dart';
import 'config/url_config.dart';
import 'exceptions.dart';
import 'http/retry_policy.dart';
import 'http/transport.dart';
import 'url/cloudinary_url.dart';

// True on both web compilers. `identical(0, 0.0)` detects only dart2js: under
// dart2wasm int and double have distinct representations, so it reads false
// and the secret guard below would never fire.
const bool _isWebRuntime = bool.fromEnvironment('dart.library.js_interop');

/// Entry point for the Cloudinary API.
///
/// Construct with [Cloudinary.signed] on a server, or [Cloudinary.unsigned]
/// in a client app where an API secret must not be present.
///
/// ```dart
/// final cloudinary = Cloudinary.signed(
///   cloudName: 'your-cloud',
///   apiKey: 'your-key',
///   apiSecret: 'your-secret',
/// );
///
/// await cloudinary.admin.account.ping();
/// cloudinary.close();
/// ```
///
/// Call [close] when finished, unless you supplied your own client, which
/// this object does not own and will not close.
class Cloudinary {
  Cloudinary._({
    required this.config,
    required this.urlConfig,
    required this.signatureProvider,
    http.Client? client,
    RetryPolicy retry = const RetryPolicy(),
    Duration timeout = const Duration(seconds: 60),
    bool allowSecretOnWeb = false,
  }) : transport = CloudinaryTransport(
         config: config,
         client: client,
         retry: retry,
         timeout: timeout,
       ) {
    config.validate();
    // Every factory converges here, so no constructor can hold a secret on
    // the web by skipping the check.
    if (_isWebRuntime && config.canSign && !allowSecretOnWeb) {
      throw const CloudinaryConfigException(
        'Refusing to hold an API secret on the web: it would ship in your '
        'bundle and be readable by anyone. Use Cloudinary.unsigned with an '
        'upload preset, or pass a SignatureProvider that signs on your '
        'server. Set allowSecretOnWeb: true only if this code never reaches '
        'a browser.',
      );
    }
  }

  /// Creates a client that can sign requests locally.
  ///
  /// Recommended for servers and CLIs, where holding [apiSecret] is safe.
  ///
  /// ```dart
  /// final cloudinary = Cloudinary.signed(
  ///   cloudName: 'your-cloud',
  ///   apiKey: 'your-key',
  ///   apiSecret: 'your-secret',
  /// );
  /// ```
  ///
  /// Throws [CloudinaryConfigException] when [apiKey] or [apiSecret] is
  /// empty, when [cloudName] is empty, or on a JavaScript runtime unless
  /// [allowSecretOnWeb] is set, because an API secret in a browser bundle is
  /// readable by anyone who opens developer tools.
  factory Cloudinary.signed({
    required String cloudName,
    required String apiKey,
    required String apiSecret,
    UrlConfig urlConfig = const UrlConfig(),
    int signatureVersion = 2,
    http.Client? client,
    RetryPolicy retry = const RetryPolicy(),
    Duration timeout = const Duration(seconds: 60),
    bool allowSecretOnWeb = false,
  }) {
    if (apiKey.isEmpty || apiSecret.isEmpty) {
      throw const CloudinaryConfigException(
        'Cloudinary.signed needs a non-empty apiKey and apiSecret. Use '
        'Cloudinary.unsigned for preset-based uploads without credentials.',
      );
    }
    return Cloudinary._(
      config: CloudinaryConfig(
        cloudName: cloudName,
        apiKey: apiKey,
        apiSecret: apiSecret,
        signatureVersion: signatureVersion,
      ),
      urlConfig: urlConfig,
      signatureProvider: null,
      client: client,
      retry: retry,
      timeout: timeout,
      allowSecretOnWeb: allowSecretOnWeb,
    );
  }

  /// Creates a client that holds no API secret.
  ///
  /// Recommended for Flutter and web apps. Unsigned uploads need an upload
  /// preset configured as unsigned in your Cloudinary settings.
  ///
  /// ```dart
  /// final cloudinary = Cloudinary.unsigned(cloudName: 'your-cloud');
  ///
  /// await cloudinary.upload.unsignedUpload(
  ///   file: CloudinaryFileSource.bytes(bytes, filename: 'photo.jpg'),
  ///   uploadPreset: 'my_unsigned_preset',
  /// );
  /// ```
  ///
  /// Supply a [signatureProvider] to perform signed operations with the
  /// secret kept on your own server.
  ///
  /// Throws [CloudinaryConfigException] when [cloudName] is empty.
  factory Cloudinary.unsigned({
    required String cloudName,
    UrlConfig urlConfig = const UrlConfig(),
    SignatureProvider? signatureProvider,
    http.Client? client,
    RetryPolicy retry = const RetryPolicy(),
    Duration timeout = const Duration(seconds: 60),
  }) => Cloudinary._(
    config: CloudinaryConfig(cloudName: cloudName),
    urlConfig: urlConfig,
    signatureProvider: signatureProvider,
    client: client,
    retry: retry,
    timeout: timeout,
  );

  /// Creates a client from a `CLOUDINARY_URL` string.
  ///
  /// The value takes the form `cloudinary://<api_key>:<api_secret>@<cloud>`.
  ///
  /// Throws [CloudinaryConfigException] when the string is not a well-formed
  /// Cloudinary URL, or when it carries a secret on a web runtime and
  /// [allowSecretOnWeb] is not set.
  factory Cloudinary.fromUrl(
    String cloudinaryUrl, {
    UrlConfig urlConfig = const UrlConfig(),
    http.Client? client,
    RetryPolicy retry = const RetryPolicy(),
    Duration timeout = const Duration(seconds: 60),
    bool allowSecretOnWeb = false,
  }) => Cloudinary._(
    config: CloudinaryConfig.parse(cloudinaryUrl),
    urlConfig: urlConfig,
    signatureProvider: null,
    client: client,
    retry: retry,
    timeout: timeout,
    allowSecretOnWeb: allowSecretOnWeb,
  );

  /// Creates a client from the `CLOUDINARY_URL` environment variable.
  ///
  /// Throws [CloudinaryConfigException] when the variable is unset, or on a
  /// platform with no process environment such as the web.
  factory Cloudinary.fromEnvironment({
    UrlConfig urlConfig = const UrlConfig(),
    http.Client? client,
    RetryPolicy retry = const RetryPolicy(),
    Duration timeout = const Duration(seconds: 60),
    bool allowSecretOnWeb = false,
  }) {
    final value = readCloudinaryUrl();
    if (value == null || value.isEmpty) {
      throw const CloudinaryConfigException(
        'CLOUDINARY_URL is not set in the environment.',
      );
    }
    return Cloudinary.fromUrl(
      value,
      urlConfig: urlConfig,
      client: client,
      allowSecretOnWeb: allowSecretOnWeb,
      retry: retry,
      timeout: timeout,
    );
  }

  /// Credentials and signing options.
  final CloudinaryConfig config;

  /// Delivery URL options.
  final UrlConfig urlConfig;

  /// Signing hook for clients that keep the secret on a server.
  final SignatureProvider? signatureProvider;

  /// The transport this client sends through.
  final CloudinaryTransport transport;

  AdminApi? _admin;
  SearchApi? _search;
  UrlApi? _url;
  UploadApi? _upload;

  /// The Upload API: uploading, renaming, tagging and destroying assets.
  UploadApi get upload => _upload ??= UploadApi(transport);

  /// The Admin API: assets, folders, tags, transformations, presets,
  /// streaming profiles and structured metadata.
  AdminApi get admin => _admin ??= AdminApi(transport);

  /// The Search API: expression-based asset and folder search.
  SearchApi get search => _search ??= SearchApi(transport, config);

  /// Delivery URL construction, including transformations and signing.
  UrlApi get url => _url ??= UrlApi(config, urlConfig);

  /// Whether signing is delegated to a [SignatureProvider].
  bool get canSignRemotely => signatureProvider != null;

  /// Whether this client can sign at all, locally or remotely.
  bool get canSign => config.canSign || canSignRemotely;

  /// Releases the internally created HTTP client.
  ///
  /// A client passed to the constructor is left open, since this object does
  /// not own it.
  void close() => transport.close();
}
