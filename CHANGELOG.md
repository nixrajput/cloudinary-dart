# Changelog

## 2.0.0

A rewrite. See [MIGRATION.md](MIGRATION.md) for a call-by-call mapping from 1.x.

### Added

- **Admin API**, complete: resources, folders, tags, transformations, upload presets, upload mappings, streaming profiles, structured metadata fields and rules, usage, ping and config. Ten groups reached as `cloudinary.admin.<group>`.
- **Search API** with a chainable query builder, folder search, aggregations, cursor paging and signed cacheable search URLs.
- **Delivery URL builder**: transformations, chained transformations, private CDN distributions, CNAMEs, CRC-32 CDN subdomain sharding, SEO suffixes, short URLs, forced versions, signed URLs and `__cld_token__` auth tokens.
- **Upload API** completed: `explicit`, `rename`, `destroyByAssetId`, tag and context commands, structured metadata updates, `explode`, `multi`, `generateSprite`, `text`, archives and `deleteByToken`.
- **`SignatureProvider`**, so a client app can run signed uploads while the API secret stays on your server.
- **Webhook notification verification** with a constant-time comparison and a configurable freshness window.
- **Typed exceptions**: a sealed `CloudinaryException` hierarchy covering API, rate limit, auth, not-found, transport, config and signature failures.
- **Typed response models**, each exposing `raw` so a response field this package does not model is still reachable.
- **`CLOUDINARY_URL` support** via `Cloudinary.fromEnvironment()` and `Cloudinary.fromUrl()`.
- Automatic retries on 420, 429, 502, 503 and 504, honouring `Retry-After`, configurable through `RetryPolicy`.

### Changed

- **Breaking: failures now throw** instead of returning a response object carrying an `error` string.
- **Breaking: `package:dio` replaced by `package:http`**, and the barrel no longer re-exports the HTTP client, so its types are no longer part of this package's public API. `ProgressCallback` becomes `CloudinaryProgressCallback`. An `http.Client` can be injected.
- **Breaking: `CloudinaryResponse` split** into one model per operation.
- **Breaking: `file` and `fileBytes` replaced by `CloudinaryFileSource`**, with `.path`, `.bytes` and `.url` variants.
- **Breaking: `optParams` renamed to `extraParams`**, `progressCallback` to `onProgress`.
- **Breaking: API grouped by family**: `cloudinary.upload.*`, `cloudinary.admin.*`, `cloudinary.search.*`, `cloudinary.url.*`.
- Dart SDK floor raised to `^3.8.0`, for sealed classes and null-aware elements.
- `CloudinaryDeliveryType` is now exported and its members extended. Its source file name was misspelled and never exported in 1.x.

### Fixed

- **Array parameters are sent as repeated `key[]` pairs**, matching Cloudinary's own encoder. They were comma-joined, so `admin.resources.delete(['a', 'b'])` asked Cloudinary to delete one asset literally named `a,b` and silently removed nothing.
- Endpoints that take JSON bodies (`restore`, related assets, folder rename) were form-encoded.
- `transform()` replaced the transformation chain instead of adding to it, silently dropping earlier stages.
- Delivery URLs were signed before escaping, so the signature did not match the emitted path; `?` and `#` were not escaped at all.
- A URL suffix was appended to the delivery-type segments rather than replacing them with Cloudinary's plural form.
- `fetch` and the other remote-source delivery types could not build a URL.
- `crc32` hashed UTF-16 code units, so a non-ASCII public ID picked a different CDN shard from every other SDK.
- Context encoding escaped backslashes, which Cloudinary does not, corrupting any value containing one.
- A form whose values were all null crashed on a null check instead of sending an empty body.
- `multi`, `generateSprite` and `text` omitted the resource-type segment Cloudinary's `api_url` always adds, so they hit the wrong route.
- Streaming profile representations were sent as repeated form fields; Cloudinary takes one JSON string.
- Structured metadata values did not escape `"`, which Cloudinary requires there but not in contextual metadata.
- A `.` or `..` in a public ID survived into a delivery URL, where a CDN resolves it away and can reach a different product environment.
- The transformation, format and URL suffix were interpolated into delivery URLs without escaping, so a `?` could open a query string.
- A folder search parsed its response as assets and an asset query could be turned into a folder request; the two are now coupled to their parsers.
- HTTP 420 was treated as a rate limit but excluded from the default retry set.
- A stale rate-limit reset or a non-positive `Retry-After` retried immediately instead of backing off.
- A repeated multipart field silently kept only the last value while the signature covered all of them.
- Webhook verification bounded only the lower end of the timestamp window, so a far-future timestamp stayed acceptable.
- Retries replayed POST and DELETE requests that may already have been applied. Only a 429, where the server states it did not act, repeats a non-idempotent request now.
- The per-attempt timeout covered only the response headers, so a peer that stalled mid-body hung the call indefinitely.
- A throttled Admin request ignored `X-FeatureRateLimit-Reset`, burning its retries in milliseconds against an hourly quota.
- A missing or unreadable upload file escaped as a raw `dart:io` error rather than a `CloudinaryException`.
- A `Map` passed through `extraParams` was serialized with Dart's `toString` and signed in that form; it is now rejected with an explanation.
- A failed constructor left an HTTP client open with no object to close it on.
- A SEO URL suffix was included in the delivery signature payload, which Cloudinary excludes, so every signed SEO URL was rejected. The format extension now trails the suffix, and a suffix containing `.` or `/` is rejected.
- A transformation value containing a space produced a syntactically invalid URL.
- `transformChain` stored the caller's chain by reference, so a later `transform()` mutated a chain they still held.
- Signed search URLs ignored `UrlConfig`, pointing private-CDN and CNAME accounts at a host they do not serve from.
- Signature timestamps were sent in milliseconds; Cloudinary expects UNIX seconds.
- Signature parameters were sorted by the joined `key=value` string instead of by key, which produces a different digest whenever one parameter name is a prefix of another.
- `destroy` had an inverted null check that threw a null-check error instead of its intended message.
- Response getters mutated the object they were reading from.
- Errors were printed to stdout from library code.
- A dead HTTP client carrying credentials in its base URL was constructed on every request and never used.
- The analyzer `errors:` block in `analysis_options.yaml` sat at the top level instead of under `analyzer:`, so none of its escalations had ever taken effect.

### Security

- **Delivery URL paths reject `.` and `..` segments.** Dart's `Uri` collapses dot segments, so a `..` inside a caller-supplied public ID or folder path walked out of the `/v1_1/<cloud>` scope and re-aimed an authenticated Admin request at a different endpoint, with the API key and secret still attached.
- **The web secret guard now detects both web compilers.** It used `identical(0, 0.0)`, which is true only under dart2js; under dart2wasm it read false and the guard never fired, so an API secret shipped in the bundle. It now uses `bool.fromEnvironment('dart.library.js_interop')` and lives in the private constructor that every factory routes through, so `Cloudinary.fromUrl` and `Cloudinary.fromEnvironment` are covered too.
- **Auth tokens escape `!` and the client IP.** `!` separates ACL entries, so a `!` inside a caller-supplied identifier split one entry into several and could widen a token to every asset in the environment. A `~` in `ip` could splice an extra field into the signed token.
- **Signed delivery URLs no longer fall back silently.** A public ID that was an absolute URL was returned untouched, discarding a requested signature and auth token and handing back a third-party origin; that now throws.
- **Signature version 2 is now the default.** Version 1 does not escape `&` inside parameter values, so a value containing `&` is absorbed into the signed string as additional parameters. Version 1 remains selectable for compatibility.
- **Validation guards no longer use `assert`.** Dart strips asserts from release builds, so in a release Flutter build 1.x sent an unauthenticated request instead of failing when a signed method was called on an unsigned client.
- **Admin credentials moved out of the URL** and into an `Authorization: Basic` header, so they no longer leak into logs and proxies.
- **`Cloudinary.signed` refuses to construct on a web runtime** unless `allowSecretOnWeb: true` is passed, preventing an API secret from shipping in a browser bundle.
- `CloudinaryConfig.toString()` redacts the API secret.

## 1.2.2

- **Chore**: Added automated pub.dev release pipeline (version check, tag, publish); no API changes.

## 1.2.0

- **Update**: `LICENSE` changed to MIT.
- **Update**: All dependencies are updated to latest version.
- **Fix**: All known bugs fixed.

## 1.1.3

- **Update**: All dependencies are updated to latest version.
- **Fix**: All known bugs fixed.

## 1.1.2

- **Update**: All dependencies are updated to latest version.
- **Fix**: All known bugs fixed.

## 1.1.1

- **Update**: All dependencies are updated to latest version.
- **Fix**: All known bugs fixed.

## 1.1.0

- **Documentation**: Updated documentation for the package.
- **Fix**: All known bugs fixed.

## 1.0.3

- Code cleanup and refactoring for better readability and maintainability.
- Package documentation updated.

## 1.0.2

- Code cleanup and refactoring for better readability and maintainability.
- Package documentation updated.

## 1.0.1

- Code cleanup and refactoring for better readability and maintainability.
- Package documentation updated.
- Project code formatted using `dartfmt`.

## 1.0.0

- Initial version.
