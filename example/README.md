# cloudinary example

A Flutter app demonstrating the package end to end: signed and unsigned
uploads with progress, deleting an asset, building a transformed delivery URL,
and querying the Search API.

## Running it

Credentials are passed with `--dart-define`, so nothing is committed. Only
`CLOUDINARY_CLOUD_NAME` is required.

Unsigned uploads, which is what a real client app should do:

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=your-cloud \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=your-unsigned-preset \
  --dart-define=CLOUDINARY_FOLDER=demo
```

Adding an API key and secret switches the app to a signed client, which also
enables the delete and search actions:

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=your-cloud \
  --dart-define=CLOUDINARY_API_KEY=your-key \
  --dart-define=CLOUDINARY_API_SECRET=your-secret \
  --dart-define=CLOUDINARY_FOLDER=demo
```

Do not ship an API secret in a real mobile or web build. The app only builds a
signed client because credentials were passed explicitly here; in production
use an unsigned preset or a `SignatureProvider` that signs on your server.

## What it shows

- `upload.upload` and `upload.unsignedUpload`, from a file path or from bytes,
  with an `onProgress` callback driving the progress bar.
- `upload.destroy`, checking `DestroyResult.isDeleted` rather than relying on
  an exception, because Cloudinary answers `not found` with a 200.
- `url.image(...).transform(...)` building a delivery URL with no network call,
  which the app then renders.
- `search.expression(...)` listing what is in the upload folder.
- Catching `CloudinaryException` instead of inspecting a response for an error
  string, which is the main change from 1.x.
