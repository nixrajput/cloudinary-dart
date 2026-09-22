/// Supplies request signatures from somewhere other than this process.
///
/// Lets a Flutter or web client perform signed uploads while the API secret
/// stays on a server you control. Implement this against your own signing
/// endpoint and pass it to `Cloudinary.unsigned`.
///
/// ```dart
/// class MySigner implements SignatureProvider {
///   @override
///   Future<RemoteSignature> sign(Map<String, dynamic> params) async {
///     final res = await myBackend.post('/cloudinary/sign', params);
///     return RemoteSignature(
///       signature: res['signature'],
///       timestamp: res['timestamp'],
///       apiKey: res['api_key'],
///     );
///   }
/// }
/// ```
abstract class SignatureProvider {
  /// Allows subclasses to be const.
  const SignatureProvider();

  /// Signs [params] and returns the signature alongside the values it was
  /// computed with.
  ///
  /// The returned [RemoteSignature.timestamp] must be the timestamp the
  /// signature was computed against. Returning a different one makes
  /// Cloudinary reject the request.
  Future<RemoteSignature> sign(Map<String, dynamic> params);
}

/// A signature produced by a [SignatureProvider].
class RemoteSignature {
  /// Creates a remote signature result.
  const RemoteSignature({
    required this.signature,
    required this.timestamp,
    required this.apiKey,
  });

  /// Hex signature returned by the signing endpoint.
  final String signature;

  /// UNIX seconds the signature was computed against.
  final int timestamp;

  /// The API key matching the secret that produced [signature].
  final String apiKey;
}
