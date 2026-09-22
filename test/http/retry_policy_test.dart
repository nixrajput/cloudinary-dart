import 'package:cloudinary/cloudinary.dart';
import 'package:cloudinary/src/http/http_date.dart';
import 'package:test/test.dart';

void main() {
  group('RetryPolicy', () {
    test('backoff doubles per attempt', () {
      const p = RetryPolicy(baseDelay: Duration(milliseconds: 100));
      expect(p.delayFor(1), const Duration(milliseconds: 100));
      expect(p.delayFor(2), const Duration(milliseconds: 200));
      expect(p.delayFor(3), const Duration(milliseconds: 400));
    });

    test('a server Retry-After overrides the computed backoff', () {
      const p = RetryPolicy(baseDelay: Duration(milliseconds: 100));
      expect(
        p.delayFor(3, retryAfter: const Duration(seconds: 7)),
        const Duration(seconds: 7),
      );
    });

    test('only transient statuses retry', () {
      const p = RetryPolicy();
      expect(p.shouldRetry(429), isTrue);
      expect(p.shouldRetry(503), isTrue);
      expect(p.shouldRetry(500), isFalse);
      expect(p.shouldRetry(400), isFalse);
    });

    test('none disables retrying', () {
      expect(RetryPolicy.none.maxAttempts, 1);
    });
  });

  group('parseHttpDate', () {
    test('parses an RFC 1123 date', () {
      expect(
        parseHttpDate('Wed, 03 Sep 2026 09:00:00 GMT'),
        DateTime.utc(2026, 9, 3, 9),
      );
    });

    test('parses a single-digit day', () {
      expect(
        parseHttpDate('Wed, 3 Sep 2026 09:00:00 GMT'),
        DateTime.utc(2026, 9, 3, 9),
      );
    });

    test('returns null for anything else', () {
      expect(parseHttpDate('not a date'), isNull);
      expect(parseHttpDate('2026-09-03T09:00:00Z'), isNull);
      expect(parseHttpDate('Wed, 03 Xxx 2026 09:00:00 GMT'), isNull);
    });
  });

  group('retry safety', () {
    test('a server Retry-After is capped', () {
      const p = RetryPolicy(maxDelay: Duration(seconds: 30));
      expect(
        p.delayFor(1, retryAfter: const Duration(hours: 24)),
        const Duration(seconds: 30),
      );
    });

    test('computed backoff is capped too', () {
      const p = RetryPolicy(
        baseDelay: Duration(seconds: 10),
        maxDelay: Duration(seconds: 15),
      );
      expect(p.delayFor(5), const Duration(seconds: 15));
    });

    test('a short Retry-After is honoured as given', () {
      const p = RetryPolicy();
      expect(
        p.delayFor(1, retryAfter: const Duration(seconds: 2)),
        const Duration(seconds: 2),
      );
    });
  });
}
