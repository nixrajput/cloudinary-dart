import 'dart:io' show Platform;

/// Reads `CLOUDINARY_URL` from the process environment.
String? readCloudinaryUrl() => Platform.environment['CLOUDINARY_URL'];
