import 'environment.dart';

/// Where `Cloudinary.fromEnvironment` reads `CLOUDINARY_URL` from. It is a
/// variable only so tests can supply a value: a process cannot set its own
/// environment.
String? Function() cloudinaryUrlReader = readCloudinaryUrl;
