/// [CloudinaryResponse] is the response model class for the [Cloudinary] class
class CloudinaryResponse {
  /// The [statusCode] of the response from the server (200, 400, 401, 404, 500)
  int? statusCode;

  /// The [publicId] of the uploaded file (if any)
  String? publicId;

  /// The [secureUrl] of the uploaded file (if any) (https)
  String? secureUrl;

  /// The [url] of the uploaded file (if any) (http)
  String? url;

  /// The [version] of the uploaded file (if any)
  int? version;

  /// The [width] of the uploaded file (if any)
  int? width;

  /// The [height] of the uploaded file (if any)
  int? height;

  /// The [format] of the uploaded file (if any) (jpg, png, etc)
  String? format;

  /// The [resourceType] of the uploaded file (if any) (image, video, raw)
  String? resourceType;

  /// The [createdAt] of the uploaded file (if any) (in ISO 8601 format)
  String? createdAt;

  /// The [bytes] of the uploaded file (if any) (size of the file)
  int? bytes;

  /// The [type] of the uploaded file (if any) (upload, private, authenticated)
  String? type;

  /// The [tags] of the uploaded file (if any) (array of strings)
  List<dynamic>? tags;

  /// The [etag] of the uploaded file (if any)
  String? eTag;

  /// The [signature] of the uploaded file (if any) (used for signed uploads)
  String? signature;

  /// The [originalFilename] of the uploaded file (if any)
  /// (the original name of the file on the client)
  String? originalFilename;

  /// The [error] of the uploaded file (if any)
  String? error;

  /// The [result] of the uploaded file (if any)
  /// (the result of the upload, if successful)
  String? result;

  /// The [deleted] of the uploaded file (if any)
  /// (the result of the deletion, if successful)
  Map<String, dynamic>? deleted;

  /// The [partial] of the uploaded file (if any) (true/false)
  bool? partial;

  /// The constructor for the [CloudinaryResponse] class
  CloudinaryResponse({
    this.statusCode,
    this.publicId,
    this.version,
    this.width,
    this.height,
    this.format,
    this.createdAt,
    this.resourceType,
    this.tags,
    this.bytes,
    this.type,
    this.eTag,
    this.url,
    this.secureUrl,
    this.signature,
    this.originalFilename,
    this.result,
    this.error,
    this.deleted,
    this.partial,
  });

  /// Returns true if the response is ok and the file was uploaded successfully
  bool get isSuccessful =>
      ((statusCode ??= 200) >= 200 && statusCode! < 300) && isResultOk;

  /// The [isResultOk] method checks if the result of the upload was successful
  bool get isResultOk => (error?.isEmpty ?? true) && (result ??= 'ok') == 'ok';

  /// The method [fromJsonMap] converts the [json] to a [CloudinaryResponse] object
  CloudinaryResponse.fromJsonMap(Map<String, dynamic> map)
      : publicId = map['public_id'],
        version = map['version'],
        width = map['width'],
        height = map['height'],
        format = map['format'],
        createdAt = map['created_at'],
        resourceType = map['resource_type'],
        tags = map['tags'],
        bytes = map['bytes'],
        type = map['type'],
        eTag = map['etag'],
        url = map['url'],
        secureUrl = map['secure_url'],
        signature = map['signature'],
        originalFilename = map['original_filename'],
        result = map['result'] ?? 'ok',
        deleted = map['deleted'],
        partial = map['partial'];

  /// The method [fromError] converts the [error] to a [CloudinaryResponse] object
  CloudinaryResponse.fromError(this.error);

  /// The method [toJson] converts the [CloudinaryResponse] object to a [Map]
  Map<String, dynamic> toJson() => {
        'status_code': statusCode,
        'public_id': publicId,
        'version': version,
        'width': width,
        'height': height,
        'format': format,
        'created_at': createdAt,
        'resource_type': resourceType,
        'tags': tags,
        'bytes': bytes,
        'type': type,
        'etag': eTag,
        'url': url,
        'secure_url': secureUrl,
        'signature': signature,
        'original_filename': originalFilename,
        'result': result,
        'deleted': deleted,
        'partial': partial,
      };
}
