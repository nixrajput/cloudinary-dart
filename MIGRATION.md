# Migrating from v1 to v2

Version 2 is a rewrite. There are no deprecated shims, because the three v1 methods cannot survive the change to throwing errors: a shim that kept their signatures would have to keep swallowing failures, which is the main thing being fixed.

The `1.x` line stays available for fixes. Nothing forces you to move.

## The three changes that matter

### 1. Failures throw instead of being returned

In v1 every call returned a `CloudinaryResponse` whether or not it worked, and a failure was only visible if you checked the right getter. It was easy to read `secureUrl` from a failed upload and get null with no explanation.

```dart
// v1
final response = await cloudinary.upload(file: path);
if (response.isSuccessful) {
  print(response.secureUrl);
} else {
  print(response.error);
}
```

```dart
// v2
try {
  final result = await cloudinary.upload.upload(
    file: CloudinaryFileSource.path(path),
  );
  print(result.secureUrl);
} on CloudinaryApiException catch (e) {
  print('${e.statusCode}: ${e.message}');
}
```

The exception hierarchy is sealed, so a `switch` over `CloudinaryException` is exhaustive: `CloudinaryApiException`, `CloudinaryRateLimitException`, `CloudinaryAuthException`, `CloudinaryNotFoundException`, `CloudinaryTransportException`, `CloudinaryConfigException` and `CloudinarySignatureException`.

### 2. Dio is gone, and is no longer part of the public API

v1's barrel re-exported `package:dio/dio.dart`, so Dio's `Response`, `Options` and `ProgressCallback` were part of this package's surface and a Dio major would have forced a major here.

v2 uses `package:http` internally and exports nothing from it. If you referenced Dio types through this package, import Dio yourself or switch to the equivalents:

| v1 | v2 |
| --- | --- |
| `ProgressCallback` (from Dio) | `CloudinaryProgressCallback` |
| `Response` (from Dio) | not exposed; methods return typed models |
| passing Dio options | pass your own `http.Client` to the constructor |

### 3. One response type became several

`CloudinaryResponse` conflated upload results with destroy results and tag results. v2 returns a model per operation: `UploadResult`, `DestroyResult`, `PublicIdsResult`, `ArchiveResult`, `SpriteResult`, `TextResult`, `ExplodeResult`, `AssetResource`, `ResourceListResult`, `SearchResult` and so on.

Every one of them exposes `raw`, the complete decoded response, so anything not modelled is still reachable.

## Method mapping

| v1 | v2 |
| --- | --- |
| `Cloudinary.signedConfig(apiKey:, apiSecret:, cloudName:)` | `Cloudinary.signed(cloudName:, apiKey:, apiSecret:)` |
| `Cloudinary.unsignedConfig(cloudName:)` | `Cloudinary.unsigned(cloudName:)` |
| `cloudinary.upload(file: path, fileBytes: bytes, ...)` | `cloudinary.upload.upload(file: CloudinaryFileSource.path(path))` or `.bytes(bytes)` |
| `cloudinary.unsignedUpload(uploadPreset:, file:, ...)` | `cloudinary.upload.unsignedUpload(uploadPreset:, file:)` |
| `cloudinary.destroy(publicId, resourceType:, invalidate:)` | `cloudinary.upload.destroy(publicId:, resourceType:, invalidate:)` |
| `optParams: {...}` | `extraParams: {...}` |
| `progressCallback:` | `onProgress:` |
| `response.isSuccessful` | the call either returns or throws |
| `response.error` | the thrown exception's `message` |

The `file` and `fileBytes` pair is now one `CloudinaryFileSource`:

```dart
CloudinaryFileSource.path('/path/to/file.jpg');   // not available on the web
CloudinaryFileSource.bytes(bytes, filename: 'file.jpg');
CloudinaryFileSource.url('https://example.com/file.jpg');
```

`CloudinaryResourceType` keeps its name and its members, so that part of your code does not change.

## Security fixes you were affected by

These are the reason to move even if the API shape suits you:

- **Signatures were computed over a millisecond timestamp.** Cloudinary expects UNIX seconds, so v1's timestamp was roughly a thousand times too large.
- **Signature parameters were sorted by the joined `key=value` string** rather than by key. The two orders differ whenever one parameter name is a prefix of another, producing a different digest from the one Cloudinary computes.
- **Signatures were unescaped (version 1).** Cloudinary defaults to version 2, which escapes `&` inside a value so that a value containing `&` cannot smuggle extra parameters into the signed string. v2 of this package uses signature version 2 by default, with version 1 still selectable for compatibility.
- **Guards were `assert`, which release builds strip.** In a release Flutter build, calling a signed method on an unsigned v1 client did not fail: it sent an unauthenticated request. v2 throws `CloudinaryConfigException` from a real check.
- **Admin credentials were embedded in the URL** as `https://key:secret@...`, which leaks into logs and proxies. v2 sends an `Authorization: Basic` header.

## What is new

- The full Admin API, ten resource families, roughly seventy methods.
- The Search API with a chainable query builder and signed, cacheable search URLs.
- Delivery URL building with transformations, private CDN support, CDN sharding, SEO suffixes, signed URLs and `__cld_token__` auth tokens.
- `SignatureProvider`, for signed uploads from a client app with the secret kept on your server.
- A web guard that refuses to hold an API secret on a JavaScript runtime unless you opt out explicitly.
- Webhook notification verification with a constant-time comparison.
- Automatic retries on 429 and 5xx, honouring `Retry-After`.
