import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// The outcome of asking the user for an image.
sealed class PickResult {
  const PickResult();
}

class PickedImage extends PickResult {
  const PickedImage(this.path);

  final String path;
}

class PickCancelled extends PickResult {
  const PickCancelled();
}

class PickFailed extends PickResult {
  const PickFailed(this.message);

  final String message;
}

/// Picks one image, translating platform errors into [PickFailed].
Future<PickResult> pickImage(ImageSource source) async {
  try {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    return file == null ? const PickCancelled() : PickedImage(file.path);
  } on PlatformException catch (e) {
    return PickFailed(switch (e.code) {
      'camera_access_denied' =>
        'Camera permission denied. Grant it in system '
            'settings.',
      'photo_access_denied' =>
        'Photo permission denied. Grant it in system '
            'settings.',
      _ => e.message ?? 'Could not open the picker.',
    });
  }
}
