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
- Automatic retries on 429, 502, 503 and 504, honouring `Retry-After`, configurable through `RetryPolicy`.

### Changed

- **Breaking: failures now throw** instead of returning a response object carrying an `error` string.
- **Breaking: `package:dio` replaced by `package:http`**, and the barrel no longer re-exports the HTTP client, so its types are no longer part of this package's public API. `ProgressCallback` becomes `CloudinaryProgressCallback`. An `http.Client` can be injected.
- **Breaking: `CloudinaryResponse` split** into one model per operation.
- **Breaking: `file` and `fileBytes` replaced by `CloudinaryFileSource`**, with `.path`, `.bytes` and `.url` variants.
- **Breaking: `optParams` renamed to `extraParams`**, `progressCallback` to `onProgress`.
- **Breaking: API grouped by family**: `cloudinary.upload.*`, `cloudinary.admin.*`, `cloudinary.search.*`, `cloudinary.url.*`.
- Dart SDK floor raised to `>=3.0.0`, for sealed classes.
- `CloudinaryDeliveryType` is now exported and its members extended. Its source file name was misspelled and never exported in 1.x.

### Fixed

- Signature timestamps were sent in milliseconds; Cloudinary expects UNIX seconds.
- Signature parameters were sorted by the joined `key=value` string instead of by key, which produces a different digest whenever one parameter name is a prefix of another.
- `destroy` had an inverted null check that threw a null-check error instead of its intended message.
- Response getters mutated the object they were reading from.
- Errors were printed to stdout from library code.
- A dead HTTP client carrying credentials in its base URL was constructed on every request and never used.
- The analyzer `errors:` block in `analysis_options.yaml` sat at the top level instead of under `analyzer:`, so none of its escalations had ever taken effect.

### Security

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
