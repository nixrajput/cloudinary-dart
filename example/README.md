# cloudinary example

## Usage

```dart
import 'package:cloudinary/cloudinary.dart';

Future<void> main() async {
  // In an app: unsigned uploads only, so no secret ships in the bundle.
  final cloudinary = Cloudinary.unsigned(cloudName: 'your-cloud');

  final url = cloudinary.url
      .image('sample')
      .transform(
        Transformation()
          ..width(600)
          ..crop(CropMode.fill)
          ..gravity(Gravity.auto)
          ..format(DeliveryFormat.auto),
      )
      .build();
  print(url); // https://res.cloudinary.com/your-cloud/image/upload/c_fill,f_auto,g_auto,w_600/sample

  final result = await cloudinary.upload.unsignedUpload(
    file: const CloudinaryFileSource.url('https://example.com/photo.jpg'),
    uploadPreset: 'your-unsigned-preset',
  );
  print(result.secureUrl);

  cloudinary.close();
}
```

## The demo app

This directory is also a Flutter demo of the whole package. It runs everything a browser can run safely against Cloudinary's public `demo` cloud, and shows the rest as the code and a sample response. It has seven parts:

- **Options and Preview:** a delivery URL built live from the public ID, crop, gravity, effect, quality, width, aspect ratio, format, rounding, rotation, CDN subdomains and short URLs, with the image Cloudinary delivers for it, the URL, and the Dart that builds it.
- **Upload:** a real unsigned upload from the device to your own cloud with progress, given your cloud name and an unsigned upload preset. Nothing is stored in the app.
- **Signing:** the string to sign and the signature (versions 1 and 2, SHA-1 and SHA-256), a signed delivery URL, an auth token, and webhook verification with a switch that tampers with the body, all computed with a throwaway secret. A `SignatureProvider` shows how a real app signs on its server.
- **Search:** a query built as you type, with its request body, a signed cacheable search URL and a sample response.
- **Admin API:** all ten groups under `cloudinary.admin`, each with a call and the shape of its response.
- **Configuration:** a `CLOUDINARY_URL` parsed as you type, with the secret redacted.
- **Errors and retries:** the sealed exception family, two failures triggered for real, and the delays the default `RetryPolicy` waits.

The preview never scrolls away. On wide or landscape screens the options and preview are both pinned side by side, whenever the options fit whole, with the rest in one list beneath. On a portrait phone the preview is pinned above that list, and the options lead it. A mouse wheel anywhere on the page scrolls the list. The app follows the device theme, and the switch in the app bar forces light or dark.

`flutter test` checks the layout at phone to desktop sizes, including a large text scale and a phone's bottom inset, and the live parts: the URLs, the signatures, webhook verification, configuration parsing and the errors.

Run it from this directory with `flutter run -d chrome`, or open the live demo at https://nixrajput.github.io/cloudinary-dart.
