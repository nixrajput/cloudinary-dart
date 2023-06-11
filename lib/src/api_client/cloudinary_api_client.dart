import 'package:cloudinary/src/api_client/cloudinary_api.dart';
import 'package:cloudinary/src/enums/cloudinary_resource_type.dart';
import 'package:cloudinary/src/models/cloudinary_response.dart';
import 'package:dio/dio.dart';

/// Cloudinary Api Client class
/// This class is used to make the requests to the cloudinary api
class CloudinaryApiClient extends CloudinaryApi {
  static const _signedRequestAssertMessage = 'This endpoint requires an '
      'authorized request, check the Cloudinary constructor you are using and '
      'make sure you are using a valid `apiKey`, `apiSecret` and `cloudName`.';

  /// The [apiKey] used to make the authorized requests
  final String apiKey;

  /// The [apiSecret] used to make the authorized requests
  final String apiSecret;

  /// The [cloudName] used to make the requests
  final String cloudName;

  /// The [CloudinaryApiClient] constructor used to initialize the class
  /// [apiKey] is used to make the authorized requests
  /// [apiSecret] is used to make the authorized requests
  /// [cloudName] is used to make the requests
  CloudinaryApiClient({
    required this.apiKey,
    required this.apiSecret,
    required this.cloudName,
  }) : super(
          apiKey: apiKey,
          apiSecret: apiSecret,
        );

  /// Returns if the [CloudinaryApiClient] is authorized or not
  bool get isBasic => apiKey.isEmpty || apiSecret.isEmpty || cloudName.isEmpty;

  /// Uploads a file of [resourceType] with [fileName] to a [folder]
  /// in your specified [cloudName]
  /// The file to be uploaded can be from a path or a byte array
  ///
  /// [file] path to the file to upload
  /// [fileBytes] byte array of the file to uploaded
  /// [resourceType] defaults to [CloudinaryResourceType.auto]
  /// [fileName] is not mandatory, if not specified then a random name will be used
  /// [optParams] a Map of optional parameters as defined in
  /// https://cloudinary.com/documentation/image_upload_api_reference
  ///
  /// Response:
  /// Check all the attributes in the CloudinaryResponse to get the information
  /// you need... including secureUrl, publicId, etc.
  ///
  /// Official documentation: https://cloudinary.com/documentation/upload_images

  Future<CloudinaryResponse> upload({
    String? file,
    List<int>? fileBytes,
    String? publicId,
    String? fileName,
    String? folder,
    CloudinaryResourceType? resourceType,
    Map<String, dynamic>? optParams,
    ProgressCallback? progressCallback,
  }) async {
    assert(!isBasic, _signedRequestAssertMessage);

    if (file == null && fileBytes == null) {
      throw Exception('One of filePath or fileBytes must not be null');
    }

    var timeStamp = DateTime.now().millisecondsSinceEpoch;
    resourceType ??= CloudinaryResourceType.auto;

    var params = <String, dynamic>{};

    if (publicId != null || fileName != null) {
      params['public_id'] = publicId ?? fileName;
    }
    if (folder != null) params['folder'] = folder;

    /// Setting the optParams... this would override the public_id and folder
    /// if specified by user.
    if (optParams != null) params.addAll(optParams);
    params['api_key'] = apiKey;
    params['file'] = fileBytes != null
        ? MultipartFile.fromBytes(
            fileBytes,
            filename:
                fileName ?? DateTime.now().millisecondsSinceEpoch.toString(),
          )
        : await MultipartFile.fromFile(file!, filename: fileName);
    params['timestamp'] = timeStamp;
    params['signature'] =
        getSignature(secret: apiSecret, timeStamp: timeStamp, params: params);

    var formData = FormData.fromMap(params);

    Response<dynamic> response;
    int? statusCode;
    CloudinaryResponse cloudinaryResponse;
    try {
      response = await post(
        '$cloudName/${resourceType.name}/upload',
        data: formData,
        onSendProgress: progressCallback,
      );
      statusCode = response.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromJsonMap(response.data);
    } catch (error, stacktrace) {
      print('Exception occurred: $error stackTrace: $stacktrace');
      if (error is DioException) statusCode = error.response?.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromError('$error');
    }
    cloudinaryResponse.statusCode = statusCode;
    return cloudinaryResponse;
  }

  /// Uploads a file of [resourceType] with [fileName] to a [folder] in your
  /// specified [cloudName] using a [uploadPreset] with no need to specify an
  /// [apiKey] nor [apiSecret].
  /// The file to be uploaded can be from a path or a byte array
  ///
  /// [file] path to the file to upload
  /// [fileBytes] byte array of the file to uploaded
  /// [resourceType] defaults to [CloudinaryResourceType.auto]
  /// [fileName] is not mandatory, if not specified then a random name will be used
  /// [optParams] a Map of optional parameters as defined in
  /// https://cloudinary.com/documentation/image_upload_api_reference
  ///
  /// Response:
  /// Check all the attributes in the CloudinaryResponse to get the information
  /// you need... including secureUrl, publicId, etc.
  ///
  /// Official documentation:
  /// https://cloudinary.com/documentation/upload_images#unsigned_upload
  Future<CloudinaryResponse> unsignedUpload({
    String? file,
    required String uploadPreset,
    List<int>? fileBytes,
    String? publicId,
    String? fileName,
    String? folder,
    CloudinaryResourceType? resourceType,
    Map<String, dynamic>? optParams,
    ProgressCallback? progressCallback,
  }) async {
    assert(uploadPreset.isNotEmpty, 'Upload preset must not be empty.');

    if (file == null && fileBytes == null) {
      throw Exception('One of filePath or fileBytes must not be null');
    }

    resourceType ??= CloudinaryResourceType.auto;

    final params = <String, dynamic>{
      'upload_preset': uploadPreset,
      if (publicId != null || fileName != null)
        'public_id': publicId ?? fileName,
      if (folder != null) 'folder': folder,

      /// Setting the optParams... this would override the public_id and folder
      /// if specified by user.
      if (optParams?.isNotEmpty ?? false) ...optParams!,
    };

    params['file'] = fileBytes != null
        ? MultipartFile.fromBytes(fileBytes,
            filename:
                fileName ?? DateTime.now().millisecondsSinceEpoch.toString())
        : await MultipartFile.fromFile(file!, filename: fileName);

    var formData = FormData.fromMap(params);

    Response<dynamic> response;
    int? statusCode;
    CloudinaryResponse cloudinaryResponse;
    try {
      response = await post(
        '$cloudName/${resourceType.name}/upload',
        data: formData,
        onSendProgress: progressCallback,
      );
      statusCode = response.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromJsonMap(response.data);
    } catch (error, stacktrace) {
      print('Exception occurred: $error stackTrace: $stacktrace');
      if (error is DioException) statusCode = error.response?.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromError('$error');
    }
    cloudinaryResponse.statusCode = statusCode;
    return cloudinaryResponse;
  }

  /// Deletes a file of [resourceType] with [publicId]
  /// from your specified [cloudName]
  ///
  /// [publicId] The identifier of the uploaded asset. Note: The public ID value
  /// for images and videos should not include a file extension. Include the
  /// file extension for raw files only.
  /// [resourceType] defaults to [CloudinaryResourceType.image]
  /// [invalidate] If true, invalidates CDN cached copies of the asset (and all
  /// its transformed versions). Default: false.
  /// [optParams] a Map of optional parameters as defined in
  /// https://cloudinary.com/documentation/image_upload_api_reference#destroy_method
  ///
  /// Response:
  /// Check response.isResultOk to know if the file was successfully deleted.
  Future<CloudinaryResponse> destroy(
    String publicId, {
    CloudinaryResourceType? resourceType,
    bool? invalidate,
    Map<String, dynamic>? optParams,
  }) async {
    assert(!isBasic, _signedRequestAssertMessage);

    var timeStamp = DateTime.now().millisecondsSinceEpoch;
    resourceType ??= CloudinaryResourceType.image;

    final params = <String, dynamic>{};

    if (optParams != null) params.addAll(optParams);
    if (invalidate != null) params['invalidate'] = invalidate;
    params['public_id'] = publicId;
    params['api_key'] = apiKey;
    params['timestamp'] = timeStamp;
    params['signature'] =
        getSignature(secret: apiSecret, timeStamp: timeStamp, params: params);

    var formData = FormData.fromMap(params);

    Response<dynamic> response;
    CloudinaryResponse cloudinaryResponse;
    int? statusCode;
    try {
      response =
          await post('$cloudName/${resourceType.name}/destroy', data: formData);
      statusCode = response.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromJsonMap(response.data);
    } catch (error, stacktrace) {
      print('Exception occurred: $error stackTrace: $stacktrace');
      if (error is DioException) statusCode = error.response?.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromError('$error');
    }
    cloudinaryResponse.statusCode = statusCode;
    return cloudinaryResponse;
  }
}
