# cloudinary

A dart package for to integrate [Cloudinary](https://cloudinary.com/) API into your dart and flutter app. This package is a wrapper around the [Cloudinary API](https://cloudinary.com/documentation/image_upload_api_reference).

[![pub package](https://img.shields.io/pub/v/cloudinary.svg)][pub]
[![Flutter](https://img.shields.io/badge/Flutter-3.3.0-blue.svg)](https://flutter.io/)
[![Dart](https://img.shields.io/badge/Dart-2.18.0-blue.svg)](https://www.dartlang.org/)
[![Code Climate](https://codeclimate.com/github/nixrajput/cloudinary-dart/badges/gpa.svg)](https://codeclimate.com/github/nixrajput/cloudinary-dart)
[![Test Coverage](https://codeclimate.com/github/nixrajput/cloudinary-dart/badges/coverage.svg)](https://codeclimate.com/github/nixrajput/cloudinary-dart/coverage)

## Installation

Add **cloudinary** as a dependency of your project, for this you can use the command:

**For Dart projects**

```shell
dart pub add cloudinary
```

**For Flutter projects**

```shell
flutter pub add cloudinary
```

This command will add **cloudinary** to the **pubspec.yaml** of your project.
Finally you just have to run: `dart pub get` **or** `flutter pub get` depending on the project type and this will download the dependency to your pub-cache

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
  final response = await cloudinary.upload(
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

You can upload a file from path or byte array representation, you can also pass an `optParams` map to do a more elaborated upload according to https://cloudinary.com/documentation/image_upload_api_reference
The `cloudinary.upload(...)` function is fully documented, you can check the description to know what other options you have.

### Do a unsigned file upload

Recommended for server client side apps.
The way to do this request is almost the same as above, the only difference is the `uploadPreset` which is required for unsigned uploads.

```dart
  final response = await cloudinary.unsignedUpload(
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

You can upload a file from path or byte array representation, you can also pass an `optParams` map to do a more elaborated upload according to https://cloudinary.com/documentation/image_upload_api_reference
The `cloudinary.unsignedUpload(...)` function is fully documented, you can check the description to know what other options you have.

### Do a file delete *(this will use the cloudinary destroy method)*

```dart
    final response = await cloudinary.destroy('public_id',
      url: url,
      resourceType: CloudinaryResourceType.image,
      invalidate: false,
    );
    if(response.isSuccessful ?? false){
      //Do something else
    }
```

To delete a cloudinary file it´s necessary a `public_id`, as you can see in the sample code the `deleteResource(...)` function can delete a file by it's url...
You can also pass an `optParams` map to do a more elaborated delete *(destroy)* according to https://cloudinary.com/documentation/image_upload_api_reference#destroy_method
The `cloudinary.destroy(...)` function is fully documented, you can check the description to know what other options you have.

## About Cloudinary

Cloudinary is a powerful media API for websites and mobile apps alike, Cloudinary enables developers to efficiently manage, transform, optimize, and deliver images and videos through multiple CDNs. Ultimately, viewers enjoy responsive and personalized visual-media experiences—irrespective of the viewing device.

## Get Help
If you run into an issue or have a question, you can either:
- Issues related to the SDK: [Open a Github issue](https://github.com/nixrajput/cloudinary-dart/issues).

## Connect With Me

[<img align="left" alt="nixrajput | Website" width="24px" src="https://raw.githubusercontent.com/nixrajput/nixlab-files/master/images/icons/globe-icon.svg" />][website]

[<img align="left" alt="nixrajput | GitHub" width="24px" src="https://raw.githubusercontent.com/nixrajput/nixlab-files/master/images/icons/github-brands.svg" />][github]

[<img align="left" alt="nixrajput | Instagram" width="24px" src="https://raw.githubusercontent.com/nixrajput/nixlab-files/master/images/icons/instagram-brands.svg" />][instagram]

[<img align="left" alt="nixrajput | Facebook" width="24px" src="https://raw.githubusercontent.com/nixrajput/nixlab-files/master/images/icons/facebook-brands.svg" />][facebook]

[<img align="left" alt="nixrajput | Twitter" width="24px" src="https://raw.githubusercontent.com/nixrajput/nixlab-files/master/images/icons/twitter-brands.svg" />][twitter]

[<img align="left" alt="nixrajput | LinkedIn" width="24px" src="https://raw.githubusercontent.com/nixrajput/nixlab-files/master/images/icons/linkedin-in-brands.svg" />][linkedin]

[pub]: https://pub.dev/packages/cloudinary
[github]: https://github.com/nixrajput
[website]: https://nixlab.co.in
[facebook]: https://facebook.com/nixrajput07
[twitter]: https://twitter.com/nixrajput07
[instagram]: https://instagram.com/nixrajput
[linkedin]: https://linkedin.com/in/nixrajput