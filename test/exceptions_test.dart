import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

void main() {
  test('rate limit exception carries reset metadata', () {
    final e = CloudinaryRateLimitException(
      message: 'Rate limited',
      limit: 500,
      remaining: 0,
      resetAt: DateTime.utc(2026, 1, 1),
    );
    expect(e, isA<CloudinaryException>());
    expect(e, isA<CloudinaryApiException>());
    expect(e.remaining, 0);
    expect(e.limit, 500);
    expect(e.toString(), contains('429'));
  });

  test('config exception names the fix', () {
    const e = CloudinaryConfigException(
      'apiSecret is required for signed calls',
    );
    expect(e.toString(), contains('apiSecret'));
  });

  test('transport exception keeps the underlying cause', () {
    final cause = StateError('socket closed');
    final e = CloudinaryTransportException('Request failed', cause: cause);
    expect(e.cause, same(cause));
  });

  test('api exception exposes the raw body', () {
    const e = CloudinaryApiException(
      message: 'bad',
      statusCode: 400,
      raw: {
        'error': {'message': 'bad'},
        'unmodelled': 7,
      },
    );
    expect(e.raw['unmodelled'], 7);
    expect(e.toString(), 'CloudinaryApiException(400): bad');
  });

  test('the hierarchy switches exhaustively', () {
    String describe(CloudinaryException e) => switch (e) {
      CloudinaryRateLimitException() => 'rate',
      CloudinaryAuthException() => 'auth',
      CloudinaryNotFoundException() => 'missing',
      CloudinaryApiException() => 'api',
      CloudinaryTransportException() => 'transport',
      CloudinaryConfigException() => 'config',
      CloudinarySignatureException() => 'signature',
    };

    expect(describe(const CloudinaryAuthException(message: 'x')), 'auth');
    expect(describe(const CloudinaryRateLimitException(message: 'x')), 'rate');
    expect(
      describe(const CloudinaryApiException(message: 'x', statusCode: 500)),
      'api',
    );
  });
}
