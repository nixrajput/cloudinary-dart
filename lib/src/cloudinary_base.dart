import 'package:cloudinary/src/api_client/cloudinary_api_client.dart';
import 'package:cloudinary/src/enums/cloudinary_resource_type.dart';
import 'package:cloudinary/src/models/cloudinary_response.dart';
import 'package:dio/dio.dart';

/// Cloudinary Base class
/// This class is used to upload and delete resources from cloudinary
/// It uses the [CloudinaryApiClient] to make the requests
/// It uses the [CloudinaryResponse] to parse the response
/// It uses the [CloudinaryResourceType] to define the resource type
/// It uses the [Dio] to make the requests
class Cloudinary {
  late final CloudinaryApiClient _client;

  Cloudinary._({
    String? apiKey,
    String? apiSecret,
    required String cloudName,
  })  : assert(cloudName.isNotEmpty, '`cloudName` must not be empty.'),
        _client = CloudinaryApiClient(
          apiKey: apiKey ?? '',
          apiSecret: apiSecret ?? '',
          cloudName: cloudName,
        );

  /// Use this constructor when you need full control over Cloudinary api
  /// like when you need to do authorized/signed api requests.
  /// Recommended for server side apps.
  factory Cloudinary.signedConfig(
      {required String apiKey,
      required String apiSecret,
      required String cloudName}) {
    assert(
        apiKey.isNotEmpty && apiSecret.isNotEmpty && cloudName.isNotEmpty,
        'None of `apiKey`, `apiSecret`, or `cloudName` '
        'must be empty.');
    return Cloudinary._(
      apiKey: apiKey,
      apiSecret: apiSecret,
      cloudName: cloudName,
    );
  }

  /// Use this constructor when you don't need to make authorized requests
  /// to Cloudinary api, like when you just need to do unsigned image upload.
  /// Recommended for client side apps.
  factory Cloudinary.unsignedConfig({
    required String cloudName,
  }) =>
      Cloudinary._(cloudName: cloudName);

  String get apiKey => _client.apiKey;
  String get apiSecret => _client.apiSecret;
  String get cloudName => _client.cloudName;

  /// Uploads a file of [resourceType] with [fileName] to a [folder]
  /// in your specified [cloudName]
  /// Response:
  /// [CloudinaryResponse], to know which data to get from the response
  Future<CloudinaryResponse> upload({
    String? file,
    List<int>? fileBytes,
    String? publicId,
    String? fileName,
    String? folder,
    CloudinaryResourceType? resourceType,
    Map<String, dynamic>? optParams,
    ProgressCallback? progressCallback,
  }) {
    return _client.upload(
      file: file,
      fileBytes: fileBytes,
      publicId: publicId,
      fileName: fileName,
      folder: folder,
      resourceType: resourceType,
      optParams: optParams,
      progressCallback: progressCallback,
    );
  }

  /// Uploads a file of [resourceType] with [fileName] to a [folder]
  /// in your specified [cloudName] using a [uploadPreset] with no need to
  /// specify an [apiKey] nor [apiSecret].
  ///
  /// Make sure you set a [uploadPreset] in your resource.
  /// Response:
  /// [CloudinaryResponse], to know which data to get from the response
  Future<CloudinaryResponse> unsignedUpload({
    String? file,
    required String? uploadPreset,
    List<int>? fileBytes,
    String? publicId,
    String? fileName,
    String? folder,
    CloudinaryResourceType? resourceType,
    Map<String, dynamic>? optParams,
    ProgressCallback? progressCallback,
  }) {
    assert(uploadPreset?.isNotEmpty ?? false,
        'Resource\'s uploadPreset must not be empty');
    return _client.unsignedUpload(
      uploadPreset: uploadPreset!,
      file: file,
      fileBytes: fileBytes,
      publicId: publicId,
      fileName: fileName,
      folder: folder,
      resourceType: resourceType,
      optParams: optParams,
      progressCallback: progressCallback,
    );
  }

  /// Deletes a file of [resourceType] with [publicId]
  /// from your specified [cloudName]
  /// By using the Destroy method of cloudinary api. Check here
  /// https://cloudinary.com/documentation/image_upload_api_reference#destroy_method
  ///
  /// [publicId] the asset id in your [cloudName], if not provided then [url]
  /// would be used. Note: The public ID value for images and videos should not
  /// include a file extension. Include the file extension for raw files only.
  /// [url] the url to the asset in your [cloudName], the publicId will be taken
  /// from here
  /// [cloudinaryImage] a Cloudinary Image to be deleted,  the publicId will
  /// be taken from here
  /// [resourceType] defaults to [CloudinaryResourceType.image]
  /// [invalidate] If true, invalidates CDN cached copies of the asset (and all
  /// its transformed versions). Default: false.
  /// [optParams] a Map of optional parameters as defined in
  /// https://cloudinary.com/documentation/image_upload_api_reference#destroy_method
  ///
  /// Response:
  /// Check [CloudinaryResponse.isResultOk] to know if the file was successfully deleted.
  Future<CloudinaryResponse> destroy(
    String? publicId, {
    String? url,
    CloudinaryResourceType? resourceType,
    bool? invalidate,
    Map<String, dynamic>? optParams,
  }) {
    assert(publicId != null || publicId!.isNotEmpty,
        'Resource\'s uploadPreset must not be empty');
    return _client.destroy(
      publicId!,
      resourceType: resourceType,
      invalidate: invalidate,
      optParams: optParams,
    );
  }
}
