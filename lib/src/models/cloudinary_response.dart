class CloudinaryResponse {
  int? statusCode;
  String? publicId;
  int? version;
  int? width;
  int? height;
  String? format;
  String? createdAt;
  String? resourceType;
  List<dynamic>? tags;
  int? bytes;
  String? type;
  String? eTag;
  String? url;
  String? secureUrl;
  String? signature;
  String? originalFilename;
  String? result;
  String? error;
  Map<String, dynamic>? deleted;
  bool? partial;

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

  bool get isSuccessful =>
      ((statusCode ??= 200) >= 200 && statusCode! < 300) && isResultOk;

  bool get isResultOk => (error?.isEmpty ?? true) && (result ??= 'ok') == 'ok';

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

  CloudinaryResponse.fromError(this.error);

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
