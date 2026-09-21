<p align="center">
  <img src="https://raw.githubusercontent.com/nixrajput/cloudinary-dart/master/assets/logo.svg" width="96" alt="cloudinary for Dart" />
</p>

<h1 align="center">cloudinary</h1>

<p align="center">Every Cloudinary endpoint, in one pure-Dart package that never asks your app to hold a secret it shouldn't.</p>

<p align="center">
  <a href="https://pub.dev/packages/cloudinary"><img src="https://img.shields.io/pub/v/cloudinary.svg?label=Version" alt="pub package" /></a>
  <a href="https://github.com/nixrajput/cloudinary-dart/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/nixrajput/cloudinary-dart/ci.yml?branch=master&label=CI" alt="CI" /></a>
  <a href="https://pub.dev/packages/cloudinary/score"><img src="https://img.shields.io/pub/likes/cloudinary?label=Likes" alt="pub likes" /></a>
  <a href="https://pub.dev/packages/cloudinary/score"><img src="https://img.shields.io/pub/points/cloudinary?label=Points" alt="pub points" /></a>
  <a href="https://github.com/nixrajput/cloudinary-dart/blob/master/LICENSE"><img src="https://img.shields.io/github/license/nixrajput/cloudinary-dart?label=Licence" alt="licence" /></a>
</p>

<p align="center">
  <b>92 API methods</b> across Upload, Admin and Search &nbsp;·&nbsp; <b>304 tests</b> &nbsp;·&nbsp; <b>2 runtime dependencies</b> &nbsp;·&nbsp; <b>0 Flutter dependencies</b>
</p>

<p align="center">
  <sub>Every signature, auth token and delivery URL is pinned by golden vectors derived from Cloudinary's own algorithm, so correctness here is measured rather than asserted. Coverage and correctness are the numbers this package reports.</sub>
</p>

<p align="center">
  <a href="#quick-start">Quick start</a> &nbsp;·&nbsp;
  <a href="#uploading">Uploading</a> &nbsp;·&nbsp;
  <a href="#delivery-urls">Delivery URLs</a> &nbsp;·&nbsp;
  <a href="#admin-api">Admin</a> &nbsp;·&nbsp;
  <a href="#search-api">Search</a> &nbsp;·&nbsp;
  <a href="#is-this-for-you">Is this for you</a> &nbsp;·&nbsp;
  <a href="MIGRATION.md">Migrating from v1</a>
</p>

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Overview](#overview)
- [Quick start](#quick-start)
  - [Prerequisites](#prerequisites)
  - [Install](#install)
  - [Create a client](#create-a-client)
- [Uploading](#uploading)
- [Delivery URLs](#delivery-urls)
- [Admin API](#admin-api)
- [Search API](#search-api)
- [Keeping your API secret out of your app](#keeping-your-api-secret-out-of-your-app)
- [Handling errors](#handling-errors)
- [Verifying webhooks](#verifying-webhooks)
- [Before and after](#before-and-after)
- [Is this for you](#is-this-for-you)
- [Compared to](#compared-to)
- [FAQ](#faq)
- [What is not covered](#what-is-not-covered)
- [About Cloudinary](#about-cloudinary)
- [Contributing](#contributing)
- [License](#license)
- [Support the project](#support-the-project)
- [Connect](#connect)

## Overview

This package talks to Cloudinary's Upload, Admin and Search APIs and builds signed delivery URLs. It is written in pure Dart with no Flutter dependency, so the same code runs in a Flutter app, a Dart backend, a CLI, and on the web.

Responses come back as typed models, failures throw typed exceptions, and every model also exposes the raw decoded map, so a field Cloudinary added last week is reachable today rather than after a release here.

## Quick start

### Prerequisites

- Dart SDK `^3.8.0` (Flutter 3.32 or newer bundles a compatible SDK).
- A Cloudinary account. Your cloud name, API key and API secret are on the dashboard.
- For client-side uploads, an [unsigned upload preset](https://cloudinary.com/documentation/upload_presets), so the app needs no secret.

### Install

```yaml
dependencies:
  cloudinary: ^2.0.0
```

Then `dart pub get` or `flutter pub get`, and import it:

```dart
import 'package:cloudinary/cloudinary.dart';
```

### Create a client

On a server, where the secret is safe:

```dart
final cloudinary = Cloudinary.signed(
  cloudName: 'your-cloud',
  apiKey: 'your-key',
  apiSecret: 'your-secret',
);
```

In a Flutter or web app, where it is not:

```dart
final cloudinary = Cloudinary.unsigned(cloudName: 'your-cloud');
```

You can also read the standard `CLOUDINARY_URL` environment variable:

```dart
final cloudinary = Cloudinary.fromEnvironment();
```

Call `cloudinary.close()` when you are done, unless you passed your own `http.Client`, in which case closing it is yours to do.

## Uploading

```dart
final result = await cloudinary.upload.upload(
  file: CloudinaryFileSource.path('/path/to/photo.jpg'),
  folder: 'trips/2026',
  tags: ['holiday'],
  onProgress: (sent, total) => print('$sent / $total'),
);

print(result.secureUrl);
```

From a client app with an unsigned preset, and no credentials anywhere:

```dart
final result = await cloudinary.upload.unsignedUpload(
  file: CloudinaryFileSource.bytes(bytes, filename: 'photo.jpg'),
  uploadPreset: 'my_unsigned_preset',
);
```

A file can come from a path, from bytes, or from a URL Cloudinary fetches itself:

```dart
CloudinaryFileSource.path('/path/to/photo.jpg');   // not available on the web
CloudinaryFileSource.bytes(bytes, filename: 'a.png');
CloudinaryFileSource.url('https://example.com/a.png');
```

The rest of the Upload API is there too: `explicit`, `rename`, `destroy`, `destroyByAssetId`, `addTag`, `removeTag`, `replaceTag`, `removeAllTags`, `addContext`, `removeAllContext`, `updateMetadata`, `explode`, `multi`, `generateSprite`, `text`, `createArchive`, `createZip` and `deleteByToken`.

## Delivery URLs

URL building is pure and synchronous, so it is safe to call inside a widget `build`.

```dart
final url = cloudinary.url.image('trips/2026/photo.jpg')
    .transform(Transformation()
      ..width(600)
      ..height(400)
      ..crop(CropMode.fill)
      ..gravity(Gravity.auto)
      ..quality(Quality.auto)
      ..format(DeliveryFormat.auto))
    .build();
```

Chain several transformations when one stage feeds the next:

```dart
final url = cloudinary.url.image('photo.jpg')
    .transformChain(TransformationChain([
      Transformation()..width(600)..crop(CropMode.fill),
      Transformation()..effect(Effect.sepia),
    ]))
    .build();
```

Anything without a typed setter goes through `raw`, so you are never blocked:

```dart
Transformation()..raw('e_custom:42');
```

Sign a URL so nobody can edit the transformation, or attach a time-limited token:

```dart
cloudinary.url.image('private.jpg').signed().build();

cloudinary.url.image('private.jpg').authToken(
  AuthToken(key: 'your-token-key', acl: '/image/*', duration: 3600),
).build();
```

Private CDN distributions, CNAMEs, CDN subdomain sharding, SEO suffixes, short URLs and version pinning are all configured once through `UrlConfig`.

## Admin API

Grouped the way Cloudinary's own documentation is, so things are where you expect:

```dart
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
```

The ten groups are `account`, `resources`, `folders`, `tags`, `transformations`, `uploadPresets`, `uploadMappings`, `streamingProfiles`, `metadataFields` and `metadataRules`.

`resources.deleteAll` requires `confirm: true`. Cloudinary has no undo for it.

## Search API

```dart
final results = await cloudinary.search
    .expression('resource_type:image AND tags=holiday')
    .sortBy('created_at', SortDirection.desc)
    .aggregate('format')
    .maxResults(50)
    .execute();

for (final asset in results.resources) {
  print('${asset.publicId} ${asset.bytes}');
}
```

For a query you run repeatedly from clients, build a signed, cacheable search URL instead:

```dart
final url = cloudinary.search.expression('tags=holiday').toUrl(ttl: 300);
```

## Keeping your API secret out of your app

An API secret shipped in a mobile or web build is readable by anyone who downloads it. This package makes that hard to do by accident:

- `Cloudinary.signed` **throws on a web runtime** unless you pass `allowSecretOnWeb: true`.
- Guards are thrown exceptions, never `assert`, because Dart strips asserts from release builds. A guard that vanishes in production is not a guard.
- The API secret never appears in a URL, and `toString()` redacts it.

When a client genuinely needs a signed operation, sign it on your server and hand the signature back:

```dart
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
```

## Handling errors

Failures throw. The hierarchy is sealed, so a `switch` over it is exhaustive and the analyzer tells you when a new case appears.

```dart
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
```

429 and 5xx responses are retried automatically, honouring `Retry-After`. A 500 on an upload is deliberately not retried, because the upload may have partly succeeded. Configure or disable it with `RetryPolicy`.

## Verifying webhooks

```dart
final ok = verifyNotificationSignature(
  body: rawRequestBody,          // the raw bytes as received, not re-encoded
  timestamp: int.parse(headers['x-cld-timestamp']!),
  signature: headers['x-cld-signature']!,
  apiSecret: 'your-secret',
);
```

The comparison is constant-time and payloads older than two hours are rejected, which limits replay.

## Before and after

Version 1 returned a response object whether or not the call worked, so a failure looked like a success until you checked the right getter:

```dart
// v1
final response = await cloudinary.upload(file: path);
if (response.isSuccessful) {
  print(response.secureUrl);
} else {
  print(response.error);   // easy to forget, and silent when you do
}
```

Version 2 throws, and returns a typed model:

```dart
// v2
final result = await cloudinary.upload.upload(
  file: CloudinaryFileSource.path(path),
);
print(result.secureUrl);
```

[MIGRATION.md](MIGRATION.md) maps every v1 call to its v2 equivalent.

## Is this for you

Use this package if you want one dependency that covers uploading, administration, search and delivery URLs, with typed errors and no Flutter dependency so your backend and your app can share it.

It fits particularly well if you are uploading from a client app, because the signature provider and the web guard are built for exactly that.

**Skip it if** you only need to build delivery URLs and never call an API. Cloudinary's own [`cloudinary_url_gen`](https://pub.dev/packages/cloudinary_url_gen) is purpose-built for that and has a richer typed transformation DSL. This package covers the common transformation parameters and gives you `raw` for the rest, which is the right trade when URL building is not the main thing you are doing.

## Compared to

**[`cloudinary_url_gen`](https://pub.dev/packages/cloudinary_url_gen)** is Cloudinary's official URL builder. Its transformation DSL is more expressive than this one: a named constructor per effect, per gravity mode, per qualifier. It does not call the Upload, Admin or Search APIs.

**[`cloudinary_api`](https://pub.dev/packages/cloudinary_api)** is Cloudinary's official API client, and pairs with `cloudinary_url_gen`. If you prefer first-party packages and are happy taking two of them, that combination is a reasonable choice.

**[`cloudinary_flutter`](https://pub.dev/packages/cloudinary_flutter)** adds Flutter widgets on top of the official packages. This package has no widgets and no Flutter dependency, which is what lets it run on a server.

**This package** is one dependency covering all three APIs plus URL building, with a sealed error hierarchy, a raw-map escape hatch on every model, and client-side secret handling as a first-class concern.

## FAQ

**Does it work on the web?**
Yes. The package compiles to JavaScript, and that is verified rather than assumed. The one exception is `CloudinaryFileSource.path`, which needs a filesystem; use `.bytes` there and you get a clear exception rather than a mystery if you forget.

**Why does `Cloudinary.signed` throw in my Flutter web build?**
Because an API secret in a browser bundle is readable by anyone who opens devtools. Use `Cloudinary.unsigned` with an upload preset, or a `SignatureProvider`. If you are certain the code never reaches a browser, pass `allowSecretOnWeb: true`.

**Can I use my own HTTP client?**
Yes, pass any `http.Client` to the constructor. That is also how the test suite runs with no network. The package does not re-export `package:http`, so its types are not frozen into this API.

**Cloudinary added a response field. Do I have to wait for a release?**
No. Every model exposes `raw`, the complete decoded response, so the new field is available immediately as `result.raw['new_field']`.

**Why is there no benchmark in the header?**
Because there is nothing honest to measure. The time in any call here is Cloudinary's and the network's. Coverage and correctness are the claims worth making, so those are the ones made.

## What is not covered

Version 2.0 does not include the Provisioning API (sub-accounts, users, user groups and access keys) or the v2 Analysis API. Both are candidates for a later release. Everything else in Upload, Admin and Search is here.

## About Cloudinary

Cloudinary is a media API for websites and mobile apps: it stores, transforms, optimises and delivers images and video through multiple CDNs.

## Contributing

Fork the repository, make your changes, and open a pull request. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first, and note that every PR must bump the version in `pubspec.yaml` and add a matching `CHANGELOG.md` entry.

## License

MIT. See [LICENSE](LICENSE).

## Support the project

<div align="center">

cloudinary is MIT licensed and free to use, always. If it saves you writing the signing code twice, sponsorship is welcome.

<br />

<a href="https://github.com/sponsors/nixrajput">
  <img src="https://img.shields.io/badge/Sponsor_on_GitHub-EA4AAA?style=for-the-badge&logo=githubsponsors&logoColor=white" alt="GitHub Sponsors" />
</a>
<a href="https://ko-fi.com/nixrajput">
  <img src="https://img.shields.io/badge/Ko--fi-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white" alt="Ko-fi" />
</a>
<a href="https://www.buymeacoffee.com/nixrajput">
  <img src="https://img.shields.io/badge/Buy_Me_a_Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black" alt="Buy Me a Coffee" />
</a>

</div>

## Connect

<div align="center">

**Nikhil Rajput**

<a href="https://github.com/nixrajput"><img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub" /></a>
<a href="https://linkedin.com/in/nixrajput"><img src="https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn" /></a>
<a href="https://x.com/nixrajput"><img src="https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white" alt="X" /></a>
<a href="https://instagram.com/nixrajput"><img src="https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white" alt="Instagram" /></a>
<a href="https://telegram.me/nixrajput"><img src="https://img.shields.io/badge/Telegram-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram" /></a>
<a href="mailto:nkr.nikhil.nkr@gmail.com"><img src="https://img.shields.io/badge/Email-EA4335?style=for-the-badge&logo=gmail&logoColor=white" alt="Email" /></a>

</div>
