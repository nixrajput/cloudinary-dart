import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Cloudinary API abstraction class for making requests to the Cloudinary API
/// It uses the [Dio] to make the requests
abstract class CloudinaryApi {
  /// The [defaultUrl] is the base url for the cloudinary api
  static const defaultUrl = 'https://api.cloudinary.com/v1_1/';

  /// The [Dio] object used to make the upload requests
  final Dio _dio;

  /// The [Dio] object used to make the delete requests
  final Dio _deleteDio;

  /// CloudinaryApi constructor used to initialize the [Dio] objects
  /// It takes the [apiKey], [apiSecret] and [cloudName] as parameters
  /// to build the [defaultUrl]
  CloudinaryApi({String? apiKey, String? apiSecret})
      : _dio = Dio(BaseOptions(baseUrl: '$defaultUrl/')),
        _deleteDio = Dio(
          BaseOptions(
            baseUrl: '$defaultUrl/'.replaceFirst(
              'https://',
              'https://$apiKey:$apiSecret@',
            ),
          ),
        );

  /// Post request to the cloudinary api
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Delete request to the cloudinary api
  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _deleteDio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Generates a proper Cloudinary Authentication Signature according to
  /// https://cloudinary.com/documentation/upload_images#generating_authentication_signature
  String? getSignature(
      {String? secret, int? timeStamp, Map<String, dynamic>? params}) {
    timeStamp ??= DateTime.now().millisecondsSinceEpoch;
    String? signature;
    try {
      var signatureParams = <String, dynamic>{}..addAll(params ?? {});
      signatureParams['timestamp'] = timeStamp;

      /// Removing unwanted params
      signatureParams.remove('api_key');
      signatureParams.remove('cloud_name');
      signatureParams.remove('file');
      signatureParams.remove('resource_type');

      /// Merging key and value with '='
      var paramsList = <String>[];
      signatureParams.forEach((key, value) => paramsList.add('$key=$value'));

      /// Sorting params alphabetically
      paramsList.sort();

      /// Merging params with '&'
      var stringParams = StringBuffer();
      if (paramsList.isNotEmpty) stringParams.write(paramsList[0]);
      for (var i = 1; i < paramsList.length; ++i) {
        stringParams.write('&${paramsList[i]}');
      }

      /// Adding API Secret to the params
      stringParams.write(secret);

      /// Generating signatureHash
      var bytes = utf8.encode(stringParams.toString().trim());
      signature = sha1.convert(bytes).toString();
    } catch (e) {
      print(e);
    }
    return signature;
  }
}
