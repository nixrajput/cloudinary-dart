import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class Captured {
  late http.Request request;

  String get path => request.url.path;
  String get method => request.method;
  Map<String, dynamic> get jsonBody =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

(Cloudinary, Captured) clientReturning(Map<String, dynamic> body) {
  final captured = Captured();
  final c = Cloudinary.signed(
    cloudName: 'demo',
    apiKey: 'k',
    apiSecret: 's',
    client: MockClient((req) async {
      captured.request = req;
      return http.Response(jsonEncode(body), 200);
    }),
  );
  return (c, captured);
}

void main() {
  group('builder', () {
    test('accumulates and de-duplicates', () {
      final (c, _) = clientReturning({});
      final q = c.search
          .expression('resource_type:image')
          .sortBy('created_at', SortDirection.desc)
          .sortBy('public_id')
          .aggregate('format')
          .aggregate('format')
          .withField('context')
          .withField('context')
          .maxResults(50);

      final json = q.toJson();
      expect(json['expression'], 'resource_type:image');
      expect(json['max_results'], 50);
      expect(json['sort_by'], [
        {'created_at': 'desc'},
        {'public_id': 'asc'},
      ]);
      expect(json['aggregate'], ['format']);
      expect(json['with_field'], ['context']);
    });

    test('empty accumulators are omitted, not sent as empty lists', () {
      final (c, _) = clientReturning({});
      final json = c.search.expression('a').toJson();

      expect(json.containsKey('sort_by'), isFalse);
      expect(json.containsKey('aggregate'), isFalse);
      expect(json.containsKey('with_field'), isFalse);
      expect(json.containsKey('fields'), isFalse);
    });

    test('each entry point starts a fresh query', () {
      final (c, _) = clientReturning({});
      c.search.expression('first').aggregate('format');
      final second = c.search.expression('second');

      expect(second.toJson().containsKey('aggregate'), isFalse);
      expect(second.toJson()['expression'], 'second');
    });
  });

  group('execution', () {
    test('posts JSON to resources/search', () async {
      final (c, cap) = clientReturning({
        'total_count': 1,
        'time': 12,
        'resources': [
          {'public_id': 'a'},
        ],
        'next_cursor': 'C',
      });

      final r = await c.search.expression('resource_type:image').execute();

      expect(cap.path, '/v1_1/demo/resources/search');
      expect(cap.method, 'POST');
      expect(cap.request.headers['content-type'], contains('application/json'));
      expect(cap.jsonBody['expression'], 'resource_type:image');
      expect(r.totalCount, 1);
      expect(r.time, 12);
      expect(r.nextCursor, 'C');
      expect(r.resources.single.publicId, 'a');
    });

    test('folder search posts to folders/search', () async {
      final (c, cap) = clientReturning({
        'folders': <Object>[],
        'total_count': 0,
      });

      await c.search.folders().expression('path:a/*').executeFolders();

      expect(cap.path, '/v1_1/demo/folders/search');
    });

    test('aggregations are surfaced', () async {
      final (c, _) = clientReturning({
        'resources': <Object>[],
        'aggregations': {
          'format': {'jpg': 3},
        },
      });

      final r = await c.search.aggregate('format').execute();
      expect(r.aggregations?['format'], {'jpg': 3});
    });

    test('search needs credentials', () async {
      final c = Cloudinary.unsigned(cloudName: 'demo');
      await expectLater(
        c.search.expression('a').execute(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });

  group('signed search urls', () {
    test('embeds the ttl and a signature, and omits the cursor', () {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
      );

      final url = c.search
          .expression('a')
          .nextCursor('IGNORED')
          .toUrl(ttl: 300);

      expect(url, startsWith('https://res.cloudinary.com/demo/search/'));
      expect(url, contains('/300/'));
      expect(url, isNot(contains('IGNORED')));
    });

    test('the same query signs identically, so the URL is cacheable', () {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
      );

      expect(
        c.search.expression('a').toUrl(ttl: 60),
        c.search.expression('a').toUrl(ttl: 60),
      );
    });

    test('a different expression produces a different signature', () {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
      );

      expect(
        c.search.expression('a').toUrl(ttl: 60),
        isNot(c.search.expression('b').toUrl(ttl: 60)),
      );
    });

    test('a cursor is appended after the payload', () {
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
      );

      expect(
        c.search.expression('a').toUrl(ttl: 60, nextCursor: 'CUR'),
        endsWith('/CUR'),
      );
    });

    test('toUrl needs credentials', () {
      final c = Cloudinary.unsigned(cloudName: 'demo');
      expect(
        () => c.search.expression('a').toUrl(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });
}
