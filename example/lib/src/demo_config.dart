import 'package:cloudinary/cloudinary.dart';

/// Credentials come from `--dart-define` so nothing is committed.
const String cloudName = String.fromEnvironment(
  'CLOUDINARY_CLOUD_NAME',
  defaultValue: '',
);
const String apiKey = String.fromEnvironment(
  'CLOUDINARY_API_KEY',
  defaultValue: '',
);
const String apiSecret = String.fromEnvironment(
  'CLOUDINARY_API_SECRET',
  defaultValue: '',
);
const String uploadPreset = String.fromEnvironment(
  'CLOUDINARY_UPLOAD_PRESET',
  defaultValue: '',
);
const String folder = String.fromEnvironment(
  'CLOUDINARY_FOLDER',
  defaultValue: '',
);

/// Builds a signed client when a key and secret were supplied, and an
/// unsigned one otherwise.
///
/// On the web `Cloudinary.signed` refuses to construct, because a secret in a
/// browser bundle is readable by anyone. That refusal is deliberately not
/// suppressed here: the demo falls back to an unsigned client so you can see
/// the guard work. Real apps should use an unsigned upload preset, or a
/// [SignatureProvider] that signs on a server you control.
Cloudinary createClient() {
  if (apiKey.isEmpty || apiSecret.isEmpty) {
    return Cloudinary.unsigned(cloudName: cloudName);
  }

  try {
    return Cloudinary.signed(
      cloudName: cloudName,
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
  } on CloudinaryConfigException {
    return Cloudinary.unsigned(cloudName: cloudName);
  }
}
