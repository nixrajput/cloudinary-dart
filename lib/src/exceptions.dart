/// Base type for every error this package throws.
///
/// Sealed so callers can `switch` over the failure modes exhaustively and have
/// the analyzer tell them when a new one is added.
sealed class CloudinaryException implements Exception {
  /// Creates a Cloudinary exception with a human-readable [message].
  const CloudinaryException(this.message);

  /// Human-readable description of what went wrong.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when Cloudinary answers with a non-2xx status.
class CloudinaryApiException extends CloudinaryException {
  /// Creates an API exception from a Cloudinary error response.
  const CloudinaryApiException({
    required String message,
    required this.statusCode,
    this.raw = const <String, dynamic>{},
  }) : super(message);

  /// HTTP status code returned by Cloudinary.
  final int statusCode;

  /// The decoded response body, so callers can read fields this package does
  /// not model.
  final Map<String, dynamic> raw;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// Thrown when Cloudinary rate-limits the request.
///
/// Cloudinary caps Admin API calls per hour and reports the window through
/// `X-FeatureRateLimit-*` response headers, which are surfaced here.
class CloudinaryRateLimitException extends CloudinaryApiException {
  /// Creates a rate-limit exception carrying Cloudinary's limit headers.
  const CloudinaryRateLimitException({
    required super.message,
    super.statusCode = 429,
    super.raw,
    this.limit,
    this.remaining,
    this.resetAt,
  });

  /// Requests permitted in the current window.
  final int? limit;

  /// Requests left in the current window.
  final int? remaining;

  /// When the current window resets.
  final DateTime? resetAt;
}

/// Thrown when Cloudinary rejects the credentials.
class CloudinaryAuthException extends CloudinaryApiException {
  /// Creates an authentication exception.
  const CloudinaryAuthException({
    required super.message,
    super.statusCode = 401,
    super.raw,
  });
}

/// Thrown when the requested asset or resource does not exist.
class CloudinaryNotFoundException extends CloudinaryApiException {
  /// Creates a not-found exception.
  const CloudinaryNotFoundException({
    required super.message,
    super.statusCode = 404,
    super.raw,
  });
}

/// Thrown when the request never reached Cloudinary.
///
/// Wraps socket failures, DNS failures and timeouts. [cause] carries the
/// underlying error for callers that need to distinguish them.
class CloudinaryTransportException extends CloudinaryException {
  /// Creates a transport exception wrapping [cause].
  const CloudinaryTransportException(super.message, {this.cause});

  /// The underlying socket or timeout error, when there was one.
  final Object? cause;
}

/// Thrown when the client is configured wrongly, before any request is sent.
///
/// Configuration is validated eagerly rather than through `assert`, because
/// Dart strips asserts from release builds and a stripped guard would let an
/// unauthenticated request reach Cloudinary silently.
class CloudinaryConfigException extends CloudinaryException {
  /// Creates a configuration exception.
  const CloudinaryConfigException(super.message);
}

/// Thrown when generating or verifying a signature fails.
class CloudinarySignatureException extends CloudinaryException {
  /// Creates a signature exception.
  const CloudinarySignatureException(super.message);
}
