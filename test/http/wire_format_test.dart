import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Cloudinary's own encoder (`hashToParameters`) appends `[]` to an array key
/// and emits one pair per element. Comma-joining instead makes the server
/// read a single value literally named `a,b`, so a delete silently removes
/// nothing.
void main() {
  late String body;
  late Uri url;

  Cloudinary client() => Cloudinary.signed(
    cloudName: 'demo',
    apiKey: 'k',
    apiSecret: 's',
    client: MockClient((req) async {
      body = req.body;
      url = req.url;
      return http.Response('{"deleted":{}}', 200);
    }),
  );

  test('a form array becomes repeated key[] pairs', () async {
    await client().admin.resources.delete(['a', 'b']);

    expect(body, contains('public_ids%5B%5D=a'));
    expect(body, contains('public_ids%5B%5D=b'));
    expect(body, isNot(contains('a%2Cb')), reason: 'must not comma-join');
  });

  test('a query array becomes repeated key[] pairs', () async {
    await client().admin.resources.listByAssetIds(['a', 'b']);

    expect(url.queryParametersAll['asset_ids[]'], ['a', 'b']);
  });

  test('a single-element array still gets brackets', () async {
    await client().admin.resources.delete(['only']);
    expect(body, contains('public_ids%5B%5D=only'));
  });

  test('a value containing a comma survives intact', () async {
    await client().admin.resources.delete(['a,b', 'c']);

    final decoded = Uri.decodeQueryComponent(
      body.split('&').first.split('=')[1],
    );
    expect(decoded, 'a,b');
  });

  test('scalars are not bracketed', () async {
    await client().admin.resources.deleteByPrefix('old/');
    expect(body, contains('prefix=old%2F'));
    expect(body, isNot(contains('prefix%5B%5D')));
  });

  test('upload tags stay comma-joined, matching Cloudinary', () async {
    await client().upload.upload(
      file: const CloudinaryFileSource.url('https://example.com/a.png'),
      tags: ['x', 'y'],
    );
    expect(body, contains('x,y'));
    expect(body, isNot(contains('tags[]')));
  });

  test('restore sends a JSON body with real arrays', () async {
    await client().admin.resources.restore(['a'], versions: ['v']);

    final json = jsonDecode(body) as Map<String, dynamic>;
    expect(json['public_ids'], ['a']);
    expect(json['versions'], ['v']);
  });

  test('a form whose values are all null does not crash', () async {
    await client().admin.resources.update('pid', extraParams: {'x': null});
    expect(body, isEmpty);
  });
}
