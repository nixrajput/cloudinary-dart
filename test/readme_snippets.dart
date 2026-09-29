// Every ```dart block in README.md appears in this file verbatim, so the
// analyzer compiles it; readme_test.dart checks the match.
// ignore_for_file: unused_element, unused_local_variable, avoid_print
// ignore_for_file: avoid_single_cascade_in_expression_statements

import 'dart:typed_data';

import 'package:cloudinary/cloudinary.dart';

// dart format off

class _Backend {
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async => {};
}

final myBackend = _Backend();

void _signed() {
final cloudinary = Cloudinary.signed(
  cloudName: 'your-cloud',
  apiKey: 'your-key',
  apiSecret: 'your-secret',
);
}

void _unsigned() {
final cloudinary = Cloudinary.unsigned(cloudName: 'your-cloud');
}

void _fromEnvironment() {
final cloudinary = Cloudinary.fromEnvironment();
}

Future<void> _upload() async {
final result = await cloudinary.upload.upload(
  file: const CloudinaryFileSource.path('/path/to/photo.jpg'),
  folder: 'trips/2026',
  tags: ['holiday'],
  onProgress: (sent, total) => print('$sent / $total'),
);

print(result.secureUrl);
}

Future<void> _unsignedUpload(Uint8List bytes) async {
final result = await cloudinary.upload.unsignedUpload(
  file: CloudinaryFileSource.bytes(bytes, filename: 'photo.jpg'),
  uploadPreset: 'my_unsigned_preset',
);
}

void _sources(Uint8List bytes) {
const CloudinaryFileSource.path('/path/to/photo.jpg');   // not available on the web
CloudinaryFileSource.bytes(bytes, filename: 'a.png');
const CloudinaryFileSource.url('https://example.com/a.png');
}

void _url() {
final url = cloudinary.url.image('trips/2026/photo.jpg')
    .transform(Transformation()
      ..width(600)
      ..height(400)
      ..crop(CropMode.fill)
      ..gravity(Gravity.auto)
      ..quality(Quality.auto)
      ..format(DeliveryFormat.auto))
    .build();
}

void _chain() {
final url = cloudinary.url.image('photo.jpg')
    .transformChain(TransformationChain([
      Transformation()..width(600)..crop(CropMode.fill),
      Transformation()..effect(Effect.sepia),
    ]))
    .build();
}

void _raw() {
Transformation()..raw('e_custom:42');
}

void _signedUrl() {
cloudinary.url.image('private.jpg').signed().build();

cloudinary.url.image('private.jpg').authToken(
  const AuthToken(key: 'your-token-key', acl: '/image/*', duration: 3600),
).build();
}

Future<void> _admin() async {
await cloudinary.admin.account.ping();
await cloudinary.admin.account.usage();

final page = await cloudinary.admin.resources.list(maxResults: 50);
final more = await cloudinary.admin.resources.list(nextCursor: page.nextCursor);

await cloudinary.admin.folders.create('trips/2026');
await cloudinary.admin.tags.list(prefix: 'hol');
await cloudinary.admin.transformations.create(name: 'thumb', transformation: 'w_150,h_150,c_fill');
await cloudinary.admin.uploadPresets.create(name: 'mobile', unsigned: true);
await cloudinary.admin.metadataFields.create(
  externalId: 'photographer',
  label: 'Photographer',
  type: MetadataFieldType.string,
);
}

Future<void> _search() async {
final results = await cloudinary.search
    .expression('resource_type:image AND tags=holiday')
    .sortBy('created_at', SortDirection.desc)
    .aggregate('format')
    .maxResults(50)
    .execute();

for (final asset in results.resources) {
  print('${asset.publicId} ${asset.bytes}');
}
}

void _searchUrl() {
final url = cloudinary.search.expression('tags=holiday').toUrl(ttl: 300);
}

class MySigner implements SignatureProvider {
  @override
  Future<RemoteSignature> sign(Map<String, dynamic> params) async {
    final res = await myBackend.post('/cloudinary/sign', params);
    return RemoteSignature(
      signature: res['signature'],
      timestamp: res['timestamp'],
      apiKey: res['api_key'],
    );
  }
}

final cloudinary = Cloudinary.unsigned(
  cloudName: 'your-cloud',
  signatureProvider: MySigner(),
);

Future<void> _errors(CloudinaryFileSource source) async {
try {
  await cloudinary.upload.upload(file: source);
} on CloudinaryRateLimitException catch (e) {
  print('Rate limited, resets at ${e.resetAt}');
} on CloudinaryAuthException {
  print('Check your credentials');
} on CloudinaryApiException catch (e) {
  print('Cloudinary said ${e.statusCode}: ${e.message}');
} on CloudinaryTransportException catch (e) {
  print('Never reached Cloudinary: ${e.cause}');
}
}

void _webhook(String rawRequestBody, Map<String, String> headers) {
final ok = verifyNotificationSignature(
  body: rawRequestBody,          // the raw body as received, not re-encoded
  timestamp: int.parse(headers['x-cld-timestamp']!),
  signature: headers['x-cld-signature']!,
  apiSecret: 'your-secret',
);
}

Future<void> _v2(String path) async {
// v2
final result = await cloudinary.upload.upload(
  file: CloudinaryFileSource.path(path),
);
print(result.secureUrl);
}
