import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Parses a form body preserving repeated `key[]` pairs.
Map<String, List<String>> parseForm(String body) {
  final out = <String, List<String>>{};
  if (body.isEmpty) return out;
  for (final pair in body.split('&')) {
    final i = pair.indexOf('=');
    if (i < 0) continue;
    final k = Uri.decodeQueryComponent(pair.substring(0, i));
    final v = Uri.decodeQueryComponent(pair.substring(i + 1));
    out.putIfAbsent(k, () => <String>[]).add(v);
  }
  return out;
}

class Captured {
  late http.Request request;

  String get path => request.url.path;
  String get method => request.method;
  Map<String, String> get query => request.url.queryParameters;
  Map<String, String> get form => Uri.splitQueryString(request.body);
  Map<String, List<String>> get forms => parseForm(request.body);
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
  group('account', () {
    test('ping uses basic auth and keeps the secret out of the url', () async {
      final (c, cap) = clientReturning({'status': 'ok'});
      final r = await c.admin.account.ping();

      expect(cap.path, '/v1_1/demo/ping');
      expect(cap.method, 'GET');
      expect(cap.request.headers['authorization'], startsWith('Basic '));
      expect(cap.request.url.toString(), isNot(contains('s@')));
      expect(r.isOk, isTrue);
    });

    test('usage parses plan and credits', () async {
      final (c, _) = clientReturning({
        'plan': 'Free',
        'credits': {'usage': 0.5, 'limit': 25},
        'objects': {'usage': 42},
      });
      final u = await c.admin.account.usage();

      expect(u.plan, 'Free');
      expect(u.creditsUsage, 0.5);
      expect(u.creditsLimit, 25.0);
      expect(u.objectCount, 42);
    });

    test('usage for a specific day appends a formatted date', () async {
      final (c, cap) = clientReturning({'plan': 'Free'});
      await c.admin.account.usage(date: DateTime.utc(2026, 9, 3));
      expect(cap.path, '/v1_1/demo/usage/03-09-2026');
    });

    test('config', () async {
      final (c, cap) = clientReturning({'cloud_name': 'demo'});
      await c.admin.account.config(settings: true);

      expect(cap.path, '/v1_1/demo/config');
      expect(cap.query['settings'], 'true');
    });

    test('resourceTypes', () async {
      final (c, cap) = clientReturning({
        'resource_types': ['image', 'video'],
      });
      final types = await c.admin.account.resourceTypes();

      expect(cap.path, '/v1_1/demo/resources');
      expect(types, ['image', 'video']);
    });

    test('admin calls from an unsigned client throw', () async {
      final c = Cloudinary.unsigned(cloudName: 'demo');
      await expectLater(
        c.admin.account.ping(),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });

  group('resources', () {
    test('list with a delivery type', () async {
      final (c, cap) = clientReturning({'resources': <Object>[]});
      await c.admin.resources.list(type: 'upload', maxResults: 10);

      expect(cap.path, '/v1_1/demo/resources/image/upload');
      expect(cap.query['max_results'], '10');
    });

    test('list paging surfaces next_cursor', () async {
      final (c, _) = clientReturning({
        'resources': [
          {'public_id': 'a'},
        ],
        'next_cursor': 'CURSOR',
      });
      final page = await c.admin.resources.list();

      expect(page.resources.single.publicId, 'a');
      expect(page.nextCursor, 'CURSOR');
    });

    test('listByTag', () async {
      final (c, cap) = clientReturning({'resources': <Object>[]});
      await c.admin.resources.listByTag('holiday');
      expect(cap.path, '/v1_1/demo/resources/image/tags/holiday');
    });

    test('listByContext', () async {
      final (c, cap) = clientReturning({'resources': <Object>[]});
      await c.admin.resources.listByContext('alt', value: 'x');

      expect(cap.path, '/v1_1/demo/resources/image/context');
      expect(cap.query['key'], 'alt');
      expect(cap.query['value'], 'x');
    });

    test('listByModeration', () async {
      final (c, cap) = clientReturning({'resources': <Object>[]});
      await c.admin.resources.listByModeration(
        kind: 'manual',
        status: 'pending',
      );
      expect(cap.path, '/v1_1/demo/resources/image/moderations/manual/pending');
    });

    test('listByAssetFolder', () async {
      final (c, cap) = clientReturning({'resources': <Object>[]});
      await c.admin.resources.listByAssetFolder('trips');

      expect(cap.path, '/v1_1/demo/resources/by_asset_folder');
      expect(cap.query['asset_folder'], 'trips');
    });

    test('listByAssetIds sends a repeated array key', () async {
      final (c, cap) = clientReturning({'resources': <Object>[]});
      await c.admin.resources.listByAssetIds(['a', 'b']);

      expect(cap.path, '/v1_1/demo/resources/by_asset_ids');
      expect(cap.request.url.queryParametersAll['asset_ids[]'], ['a', 'b']);
    });

    test('get by public id', () async {
      final (c, cap) = clientReturning({'public_id': 'p'});
      await c.admin.resources.get('p', colors: true);

      expect(cap.path, '/v1_1/demo/resources/image/upload/p');
      expect(cap.query['colors'], 'true');
    });

    test('getByAssetId', () async {
      final (c, cap) = clientReturning({'public_id': 'p'});
      await c.admin.resources.getByAssetId('aid');
      expect(cap.path, '/v1_1/demo/resources/aid');
    });

    test('update posts tags', () async {
      final (c, cap) = clientReturning({'public_id': 'p'});
      await c.admin.resources.update('p', tags: ['a', 'b']);

      expect(cap.method, 'POST');
      expect(cap.form['tags'], 'a,b'); // tags are comma-joined, not an array
    });

    test('restore', () async {
      final (c, cap) = clientReturning({});
      await c.admin.resources.restore(['a']);
      expect(cap.path, '/v1_1/demo/resources/image/upload/restore');
      expect(cap.request.headers['content-type'], contains('application/json'));
    });

    test('delete by public ids', () async {
      final (c, cap) = clientReturning({
        'deleted': {'a': 'deleted'},
      });
      final r = await c.admin.resources.delete(['a']);

      expect(cap.method, 'DELETE');
      expect(cap.forms['public_ids[]'], ['a']);
      expect(r.deleted['a'], 'deleted');
    });

    test('deleteByPrefix', () async {
      final (c, cap) = clientReturning({'deleted': <String, Object>{}});
      await c.admin.resources.deleteByPrefix('old/');
      expect(cap.form['prefix'], 'old/');
    });

    test('deleteByTag', () async {
      final (c, cap) = clientReturning({'deleted': <String, Object>{}});
      await c.admin.resources.deleteByTag('junk');
      expect(cap.path, '/v1_1/demo/resources/image/tags/junk');
    });

    test('deleteAll refuses without explicit confirmation', () async {
      var called = false;
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
        client: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        c.admin.resources.deleteAll(confirm: false),
        throwsA(isA<CloudinaryConfigException>()),
      );
      expect(called, isFalse);
    });

    test('deleteAll proceeds when confirmed', () async {
      final (c, cap) = clientReturning({'deleted': <String, Object>{}});
      await c.admin.resources.deleteAll(confirm: true);
      expect(cap.form['all'], 'true');
    });

    test('deleteDerived', () async {
      final (c, cap) = clientReturning({});
      await c.admin.resources.deleteDerived(['d1']);
      expect(cap.path, '/v1_1/demo/derived_resources');
    });

    test('addRelated', () async {
      final (c, cap) = clientReturning({});
      await c.admin.resources.addRelated(publicId: 'p', assetsToRelate: ['q']);
      expect(cap.path, '/v1_1/demo/resources/related_assets/image/upload/p');
    });

    test('updateAccessMode needs exactly one selector', () {
      final (c, _) = clientReturning({});
      expect(
        () => c.admin.resources.updateAccessMode(accessMode: 'public'),
        throwsA(isA<CloudinaryConfigException>()),
      );
      expect(
        () => c.admin.resources.updateAccessMode(
          accessMode: 'public',
          prefix: 'a',
          tag: 'b',
        ),
        throwsA(isA<CloudinaryConfigException>()),
      );
    });
  });

  group('folders', () {
    test('root', () async {
      final (c, cap) = clientReturning({'folders': <Object>[]});
      await c.admin.folders.root();
      expect(cap.path, '/v1_1/demo/folders');
    });

    test('a nested path keeps separators and escapes spaces', () async {
      final (c, cap) = clientReturning({'success': true});
      await c.admin.folders.create('a/b c');
      expect(cap.path, '/v1_1/demo/folders/a/b%20c');
    });

    test('subfolders', () async {
      final (c, cap) = clientReturning({'folders': <Object>[]});
      await c.admin.folders.subfolders('trips/2026');
      expect(cap.path, '/v1_1/demo/folders/trips/2026');
    });

    test('rename sends to_folder', () async {
      final (c, cap) = clientReturning({'success': true});
      await c.admin.folders.rename('old', 'new');

      expect(cap.method, 'PUT');
      expect(cap.path, '/v1_1/demo/folders/old');
      expect(jsonDecode(cap.request.body), {'to_folder': 'new'});
    });

    test('delete', () async {
      final (c, cap) = clientReturning({'success': true});
      await c.admin.folders.delete('gone');

      expect(cap.method, 'DELETE');
      expect(cap.path, '/v1_1/demo/folders/gone');
    });

    test('folder listing parses entries', () async {
      final (c, _) = clientReturning({
        'folders': [
          {'name': 'trips', 'path': 'trips'},
        ],
      });
      final r = await c.admin.folders.root();
      expect(r.folders.single.name, 'trips');
    });
  });

  group('tags', () {
    test('list', () async {
      final (c, cap) = clientReturning({
        'tags': ['a', 'b'],
      });
      final r = await c.admin.tags.list(prefix: 'a');

      expect(cap.path, '/v1_1/demo/tags/image');
      expect(cap.query['prefix'], 'a');
      expect(r.tags, ['a', 'b']);
    });
  });

  group('transformations', () {
    test('list', () async {
      final (c, cap) = clientReturning({'transformations': <Object>[]});
      await c.admin.transformations.list();
      expect(cap.path, '/v1_1/demo/transformations');
    });

    test('get identifies by parameter, not path', () async {
      final (c, cap) = clientReturning({'name': 'w_100'});
      await c.admin.transformations.get('w_100');

      expect(cap.path, '/v1_1/demo/transformations');
      expect(cap.query['transformation'], 'w_100');
    });

    test('create', () async {
      final (c, cap) = clientReturning({'message': 'created'});
      await c.admin.transformations.create(
        name: 'small',
        transformation: 'w_100',
      );

      expect(cap.method, 'POST');
      expect(cap.form['name'], 'small');
    });

    test('update uses PUT', () async {
      final (c, cap) = clientReturning({'message': 'updated'});
      await c.admin.transformations.update('small', allowedForStrict: true);

      expect(cap.method, 'PUT');
      expect(cap.form['allowed_for_strict'], 'true');
    });

    test('delete', () async {
      final (c, cap) = clientReturning({'message': 'deleted'});
      await c.admin.transformations.delete('small');
      expect(cap.method, 'DELETE');
    });
  });

  group('upload presets', () {
    test('name goes in the path', () async {
      final (c, cap) = clientReturning({'name': 'p'});
      await c.admin.uploadPresets.get('p');
      expect(cap.path, '/v1_1/demo/upload_presets/p');
    });

    test('create', () async {
      final (c, cap) = clientReturning({'message': 'created'});
      await c.admin.uploadPresets.create(name: 'p', unsigned: true);

      expect(cap.path, '/v1_1/demo/upload_presets');
      expect(cap.form['unsigned'], 'true');
    });

    test('delete', () async {
      final (c, cap) = clientReturning({'message': 'deleted'});
      await c.admin.uploadPresets.delete('p');

      expect(cap.method, 'DELETE');
      expect(cap.path, '/v1_1/demo/upload_presets/p');
    });
  });

  group('upload mappings', () {
    test('folder goes in a parameter, not the path', () async {
      final (c, cap) = clientReturning({'folder': 'f'});
      await c.admin.uploadMappings.get('f');

      expect(cap.path, '/v1_1/demo/upload_mappings');
      expect(cap.query['folder'], 'f');
    });

    test('create', () async {
      final (c, cap) = clientReturning({'message': 'created'});
      await c.admin.uploadMappings.create(
        folder: 'f',
        template: 'https://example.com',
      );

      expect(cap.form['folder'], 'f');
      expect(cap.form['template'], 'https://example.com');
    });
  });

  group('streaming profiles', () {
    test('list', () async {
      final (c, cap) = clientReturning({'data': <Object>[]});
      await c.admin.streamingProfiles.list();
      expect(cap.path, '/v1_1/demo/streaming_profiles');
    });

    test('name goes in the path', () async {
      final (c, cap) = clientReturning({'name': 'hd'});
      await c.admin.streamingProfiles.get('hd');
      expect(cap.path, '/v1_1/demo/streaming_profiles/hd');
    });

    test('create', () async {
      final (c, cap) = clientReturning({'message': 'created'});
      await c.admin.streamingProfiles.create(
        name: 'hd',
        representations: const [
          {
            'transformation': {'crop': 'limit'},
          },
        ],
      );
      expect(cap.method, 'POST');
    });
  });

  group('structured metadata', () {
    test('create sends a JSON body', () async {
      final (c, cap) = clientReturning({'external_id': 'f'});
      await c.admin.metadataFields.create(
        externalId: 'f',
        label: 'Field',
        type: MetadataFieldType.string,
      );

      expect(cap.path, '/v1_1/demo/metadata_fields');
      expect(cap.request.headers['content-type'], contains('application/json'));
      expect(cap.jsonBody['external_id'], 'f');
      expect(cap.jsonBody['label'], 'Field');
    });

    test('the enumeration type is sent as enum on the wire', () async {
      final (c, cap) = clientReturning({'external_id': 'f'});
      await c.admin.metadataFields.create(
        externalId: 'f',
        label: 'Field',
        type: MetadataFieldType.enumeration,
        datasourceValues: [
          {'external_id': 'a', 'value': 'A'},
        ],
      );

      expect(cap.jsonBody['type'], 'enum');
      expect(cap.jsonBody['datasource'], isA<Map<String, dynamic>>());
    });

    test('every other type keeps its own name', () {
      expect(MetadataFieldType.string.wireName, 'string');
      expect(MetadataFieldType.integer.wireName, 'integer');
      expect(MetadataFieldType.date.wireName, 'date');
      expect(MetadataFieldType.set.wireName, 'set');
    });

    test('list parses definitions', () async {
      final (c, cap) = clientReturning({
        'metadata_fields': [
          {'external_id': 'f', 'label': 'Field', 'type': 'string'},
        ],
      });
      final fields = await c.admin.metadataFields.list();

      expect(cap.path, '/v1_1/demo/metadata_fields');
      expect(fields.single.externalId, 'f');
    });

    test('field id goes in the path', () async {
      final (c, cap) = clientReturning({'external_id': 'f'});
      await c.admin.metadataFields.update('f', label: 'New');

      expect(cap.method, 'PUT');
      expect(cap.path, '/v1_1/demo/metadata_fields/f');
    });

    test('datasource ordering', () async {
      final (c, cap) = clientReturning({});
      await c.admin.metadataFields.orderDatasource(
        externalId: 'f',
        orderBy: 'value',
      );
      expect(cap.path, '/v1_1/demo/metadata_fields/f/datasource/order');
    });

    test('rules create sends JSON', () async {
      final (c, cap) = clientReturning({'external_id': 'r'});
      await c.admin.metadataRules.create(
        metadataFieldId: 'f',
        condition: {'metadata_field_id': 'x'},
        result: {'enable': true},
      );

      expect(cap.path, '/v1_1/demo/metadata_rules');
      expect(cap.jsonBody['metadata_field_id'], 'f');
    });

    test('rules delete', () async {
      final (c, cap) = clientReturning({'message': 'deleted'});
      await c.admin.metadataRules.delete('r');

      expect(cap.method, 'DELETE');
      expect(cap.path, '/v1_1/demo/metadata_rules/r');
    });
  });
}
