/// Reads `CLOUDINARY_URL` from the process environment where one exists.
///
/// Resolves to a stub returning null on platforms without a process
/// environment, such as the web, so importing this never pulls in `dart:io`
/// for a browser build.
library;

export 'environment_stub.dart' if (dart.library.io) 'environment_io.dart';
