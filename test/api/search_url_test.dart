import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

/// A signed search URL must come from the same distribution the account
/// actually serves from, not the shared CDN.
void main() {
  test('a private CDN host is used for search URLs', () {
    final c = Cloudinary.signed(
      cloudName: 'demo',
      apiKey: 'k',
      apiSecret: 's',
      urlConfig: const UrlConfig(
        privateCdn: true,
        secureDistribution: 'cdn.example.com',
      ),
    );

    expect(
      c.search.expression('x').toUrl(),
      startsWith('https://cdn.example.com/search/'),
    );
  });

  test('search and delivery URLs agree on the host', () {
    final c = Cloudinary.signed(
      cloudName: 'demo',
      apiKey: 'k',
      apiSecret: 's',
      urlConfig: const UrlConfig(secureDistribution: 'cdn.example.com'),
    );

    expect(
      Uri.parse(c.search.expression('x').toUrl()).host,
      Uri.parse(c.url.image('a.jpg').build()).host,
    );
  });

  test('the default account still uses the shared CDN', () {
    final c = Cloudinary.signed(cloudName: 'demo', apiKey: 'k', apiSecret: 's');
    expect(
      c.search.expression('x').toUrl(),
      startsWith('https://res.cloudinary.com/demo/search/'),
    );
  });
}
