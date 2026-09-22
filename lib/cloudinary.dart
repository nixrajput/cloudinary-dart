/// A complete Cloudinary SDK for Dart and Flutter.
///
/// Covers the Upload, Admin and Search APIs plus signed delivery URL
/// construction, with no Flutter dependency, so the same package serves a
/// Flutter app, a Dart backend and a CLI.
///
/// Create a client, then reach an API family through [Cloudinary.upload],
/// [Cloudinary.admin], [Cloudinary.search] or [Cloudinary.url]:
///
/// ```dart
/// import 'package:cloudinary/cloudinary.dart';
///
/// Future<void> main() async {
///   final cloudinary = Cloudinary.signed(
///     cloudName: 'your-cloud',
///     apiKey: 'your-key',
///     apiSecret: 'your-secret',
///   );
///
///   final result = await cloudinary.upload.upload(
///     file: CloudinaryFileSource.path('photo.jpg'),
///     folder: 'trips',
///   );
///   print(result.secureUrl);
///
///   cloudinary.close();
/// }
/// ```
///
/// Calls return typed models and throw a [CloudinaryException] subtype on
/// failure. Every model also exposes `raw`, the complete decoded response, so
/// a field this package does not model is still reachable.
///
/// In a Flutter or web app an API secret must not be present at all. Use
/// [Cloudinary.unsigned] with an upload preset, or supply a
/// [SignatureProvider] that signs on your own server.
library;

export 'src/api/admin/account_api.dart';
export 'src/api/admin/admin_api.dart';
export 'src/api/admin/folders_api.dart';
export 'src/api/admin/metadata_api.dart';
export 'src/api/admin/resources_api.dart';
export 'src/api/admin/streaming_profiles_api.dart';
export 'src/api/admin/tags_api.dart';
export 'src/api/admin/transformations_api.dart';
export 'src/api/admin/upload_mappings_api.dart';
export 'src/api/admin/upload_presets_api.dart';
export 'src/api/search/search_api.dart';
export 'src/api/search/search_query.dart';
export 'src/api/upload_api.dart';
export 'src/auth/auth_token.dart';
export 'src/auth/notification.dart';
export 'src/auth/signature.dart';
export 'src/auth/signature_algorithm.dart';
export 'src/auth/signature_provider.dart';
export 'src/cloudinary.dart';
export 'src/config/cloudinary_config.dart';
export 'src/config/url_config.dart';
export 'src/enums/cloudinary_delivery_type.dart';
export 'src/enums/cloudinary_resource_type.dart';
export 'src/exceptions.dart';
export 'src/http/file_source.dart';
export 'src/http/progress.dart';
export 'src/http/retry_policy.dart';
export 'src/http/transport.dart';
export 'src/models/admin_config_models.dart';
export 'src/models/admin_models.dart';
export 'src/models/model_base.dart';
export 'src/models/search_result.dart';
export 'src/models/upload_result.dart';
export 'src/models/upload_results.dart';
export 'src/url/cloudinary_url.dart';
export 'src/url/transformation.dart';
export 'src/url/transformation_enums.dart';
