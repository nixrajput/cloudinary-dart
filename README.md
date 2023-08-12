# cloudinary

A dart package for to integrate [Cloudinary](https://cloudinary.com/) API into your dart and flutter
app. This package is a wrapper around
the [Cloudinary API](https://cloudinary.com/documentation/image_upload_api_reference).

[![pub package](https://img.shields.io/pub/v/cloudinary.svg?label=Version)][pub]
[![Stars](https://img.shields.io/github/stars/nixrajput/cloudinary-dart?label=Stars)][repo]
[![Forks](https://img.shields.io/github/forks/nixrajput/cloudinary-dart?label=Forks)][repo]
[![Watchers](https://img.shields.io/github/watchers/nixrajput/cloudinary-dart?label=Watchers)][repo]
[![Contributors](https://img.shields.io/github/contributors/nixrajput/cloudinary-dart?label=Contributors)][repo]

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/nixrajput/cloudinary-dart?label=Latest)][releases]
[![GitHub last commit](https://img.shields.io/github/last-commit/nixrajput/cloudinary-dart?label=Last+Commit)][repo]
[![GitHub issues](https://img.shields.io/github/issues/nixrajput/cloudinary-dart?label=Issues)][issues]
[![GitHub pull requests](https://img.shields.io/github/issues-pr/nixrajput/cloudinary-dart?label=Pull+Requests)][pulls]
[![GitHub Licence](https://img.shields.io/github/license/nixrajput/cloudinary-dart?label=Licence)][license]

## Installation

Add `cloudinary` as a dependency in your `pubspec.yaml` file:

```dart
dependencies:cloudinary: "
latest_version
"
```

Finally you just have to run: `dart pub get` **or** `flutter pub get` depending on the project type
and this will download the dependency to your pub-cache.

And import it:

```dart
import 'package:cloudinary/cloudinary.dart';
```

## Usage

### Initialize a Cloudinary object

```dart
/// This three params can be obtained directly from your Cloudinary account Dashboard.
/// The .signedConfig(...) factory constructor is recommended only for server side apps, where [apiKey] and 
/// [apiSecret] are secure. 
final cloudinary = Cloudinary.signedConfig(
  apiKey: apiKey,
  apiSecret: apiSecret,
  cloudName: cloudName,
);
```

or

```dart
/// The .unsignedConfig(...) factory constructor is recommended for client side apps, where [apiKey] and 
/// [apiSecret] must not be used, so .basic(...) constructor allows to do later unsigned requests.
final cloudinary = Cloudinary.unsignedConfig(
  cloudName: cloudName,
);
```

### Do a signed file upload

Recommended only for server side apps.

```dart

final response = await
cloudinary.upload
(
file: file.path,
fileBytes: file.readAsBytesSync(),
resourceType: CloudinaryResourceType.image,
folder: cloudinaryCustomFolder,
fileName: 'some-name',
progressCallback: (count, total) {
print(
'Uploading image from file with progress: $count/$total');
}),
);

if(response.isSuccessful) {
print('Get your image from with ${response.secureUrl}');
}   
```

You can upload a file from path or byte array representation, you can also pass an `optParams` map
to do a more elaborated upload according
to <https://cloudinary.com/documentation/image_upload_api_reference>
The `cloudinary.upload(...)` function is fully documented, you can check the description to know
what other options you have.

### Do a unsigned file upload

Recommended for server client side apps.
The way to do this request is almost the same as above, the only difference is the `uploadPreset`
which is required for unsigned uploads.

```dart

final response = await
cloudinary.unsignedUpload
(
file: file.path,
uploadPreset: somePreset,
fileBytes: file.readAsBytesSync(),
resourceType: CloudinaryResourceType.image,
folder: cloudinaryCustomFolder,
fileName: 'some-name',
progressCallback: (count, total) {
print(
'Uploading image from file with progress: $count/$total');
})
);

if(response.isSuccessful) {
print('Get your image from with ${response.secureUrl}');
}
```

You can upload a file from path or byte array representation, you can also pass an `optParams` map
to do a more elaborated upload according
to <https://cloudinary.com/documentation/image_upload_api_reference>
The `cloudinary.unsignedUpload(...)` function is fully documented, you can check the description to
know what other options you have.

### Do a file delete *(this will use the cloudinary destroy method)*

```dart

final response = await
cloudinary.destroy
('public_id
'
,url: url,
resourceType: CloudinaryResourceType.image,
invalidate: false,
);
if(response.isSuccessful ?? false){
//Do something else
}
```

To delete a cloudinary file it´s necessary a `public_id`, as you can see in the sample code
the `deleteResource(...)` function can delete a file by it's url...
You can also pass an `optParams` map to do a more elaborated delete *(destroy)* according
to <https://cloudinary.com/documentation/image_upload_api_reference#destroy_method>
The `cloudinary.destroy(...)` function is fully documented, you can check the description to know
what other options you have.

## About Cloudinary

Cloudinary is a powerful media API for websites and mobile apps alike, Cloudinary enables developers
to efficiently manage, transform, optimize, and deliver images and videos through multiple CDNs.
Ultimately, viewers enjoy responsive and personalized visual-media experiences—irrespective of the
viewing device.

## Get Help

If you run into an issue or have a question, you can either:

- Issues related to the
  SDK: [Open a Github issue](https://github.com/nixrajput/cloudinary-dart/issues).

## Connect With Me

[![Instagram: nixrajput](https://img.shields.io/badge/nixrajput-141430?logo=Instagram&logoColor=fff)][instagram]
[![Linkedin: nixrajput](https://img.shields.io/badge/nixrajput-141430?logo=Linkedin&logoColor=fff)][linkedin]
[![GitHub: nixrajput](https://img.shields.io/badge/nixrajput-141430?logo=Github&logoColor=fff)][github]
[![Twitter: nixrajput07](https://img.shields.io/badge/nixrajput07-141430?logo=Twitter&logoColor=fff)][twitter]
[![Facebook: nixrajput07](https://img.shields.io/badge/nixrajput07-141430?logo=Facebook&logoColor=fff)][facebook]

[pub]: https://pub.dev/packages/cloudinary

[github]: https://github.com/nixrajput

[facebook]: https://facebook.com/nixrajput07

[twitter]: https://twitter.com/nixrajput07

[instagram]: https://instagram.com/nixrajput

[linkedin]: https://linkedin.com/in/nixrajput

[releases]: https://github.com/nixrajput/cloudinary-dart/releases

[repo]: https://github.com/nixrajput/cloudinary-dart

[issues]: https://github.com/nixrajput/cloudinary-dart/issues

[license]: https://github.com/nixrajput/cloudinary-dart/blob/master/LICENSE.md

[pulls]: https://github.com/nixrajput/cloudinary-dart/pulls
