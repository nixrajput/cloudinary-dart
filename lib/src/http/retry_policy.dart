/// Controls retry behaviour for transient Cloudinary failures.
///
/// Only failures that certainly did not complete are retried. A 500 on a
/// POST is deliberately not retried: an upload may have partially succeeded,
/// and repeating it could create a duplicate asset.
class RetryPolicy {
  /// Creates a retry policy.
  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.retryOn = const {429, 502, 503, 504},
  });

  /// A policy that never retries.
  static const RetryPolicy none = RetryPolicy(maxAttempts: 1);

  /// Total attempts including the first. 1 disables retrying.
  final int maxAttempts;

  /// The first backoff delay. Doubles with each subsequent attempt.
  final Duration baseDelay;

  /// Ceiling on any single backoff, including a server-supplied
  /// `Retry-After`. Without it one header could park a call for hours.
  final Duration maxDelay;

  /// Status codes worth retrying.
  final Set<int> retryOn;

  /// Returns the backoff to wait after [attempt] failures.
  ///
  /// A server-supplied [retryAfter] always wins over the computed backoff.
  Duration delayFor(int attempt, {Duration? retryAfter}) {
    final delay = retryAfter ?? baseDelay * (1 << (attempt - 1));
    return delay > maxDelay ? maxDelay : delay;
  }

  /// Whether a response with [statusCode] should be retried.
  bool shouldRetry(int statusCode) => retryOn.contains(statusCode);
}
