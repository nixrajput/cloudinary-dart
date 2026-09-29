import 'config/cloudinary_config.dart';
import 'exceptions.dart';

// True on both web compilers. `identical(0, 0.0)` detects only dart2js: under
// dart2wasm int and double have distinct representations, so it reads false
// and the secret guard would never fire.
const bool _isWebRuntime = bool.fromEnvironment('dart.library.js_interop');

/// Throws when [config] holds an API secret on the web, unless
/// [allowSecretOnWeb]: a secret in a browser bundle is readable by anyone.
/// [onWeb] is a parameter only so the VM tests can reach the refusal.
void refuseSecretOnWeb(
  CloudinaryConfig config, {
  required bool allowSecretOnWeb,
  bool onWeb = _isWebRuntime,
}) {
  if (onWeb && config.canSign && !allowSecretOnWeb) {
    throw const CloudinaryConfigException(
      'Refusing to hold an API secret on the web: it would ship in your '
      'bundle and be readable by anyone. Use Cloudinary.unsigned with an '
      'upload preset, or pass a SignatureProvider that signs on your '
      'server. Set allowSecretOnWeb: true only if this code never reaches '
      'a browser.',
    );
  }
}
