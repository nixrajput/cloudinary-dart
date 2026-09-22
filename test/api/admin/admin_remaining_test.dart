import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Request-shape coverage for the Admin methods the focused suites do not
/// already exercise. Each asserts verb and path, which is what a typo in a
/// segment array actually breaks.
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
}

(Cloudinary, Captured) client([Map<String, dynamic> body = const {}]) {
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
  group('resources, remaining methods', () {
    test('listByPublicIds', () async {
      final (c, cap) = client({'resources': <Object>[]});
      await c.admin.resources.listByPublicIds(['a', 'b']);

      expect(cap.path, '/v1_1/demo/resources/image/upload');
      expect(cap.request.url.queryParametersAll['public_ids[]'], ['a', 'b']);
    });

    test('list passes through every filter', () async {
      final (c, cap) = client({'resources': <Object>[]});
      await c.admin.resources.list(
        prefix: 'p',
        tags: true,
        context: true,
        moderations: true,
        metadata: true,
        direction: 'desc',
        startAt: '2026-01-01',
        fields: ['public_id'],
        nextCursor: 'C',
      );

      expect(cap.query['prefix'], 'p');
      expect(cap.query['tags'], 'true');
      expect(cap.query['context'], 'true');
      expect(cap.query['moderations'], 'true');
      expect(cap.query['metadata'], 'true');
      expect(cap.query['direction'], 'desc');
      expect(cap.query['start_at'], '2026-01-01');
      expect(cap.request.url.queryParametersAll['fields[]'], ['public_id']);
      expect(cap.query['next_cursor'], 'C');
    });

    test('get passes every analysis flag', () async {
      final (c, cap) = client({'public_id': 'p'});
      await c.admin.resources.get(
        'p',
        colors: true,
        faces: true,
        exif: true,
        pages: true,
        cinemagraphAnalysis: true,
        accessibilityAnalysis: true,
        qualityAnalysis: true,
        maxResults: 5,
      );

      expect(cap.query['faces'], 'true');
      expect(cap.query['exif'], 'true');
      expect(cap.query['pages'], 'true');
      expect(cap.query['cinemagraph_analysis'], 'true');
      expect(cap.query['accessibility_analysis'], 'true');
      expect(cap.query['quality_analysis'], 'true');
      expect(cap.query['max_results'], '5');
    });

    test('update passes every field', () async {
      final (c, cap) = client({'public_id': 'p'});
      await c.admin.resources.update(
        'p',
        context: 'a=b',
        metadata: 'c=d',
        moderationStatus: 'approved',
        assetFolder: 'f',
        displayName: 'N',
        extraParams: {'custom': 1},
      );

      expect(cap.form['context'], 'a=b');
      expect(cap.form['metadata'], 'c=d');
      expect(cap.form['moderation_status'], 'approved');
      expect(cap.form['asset_folder'], 'f');
      expect(cap.form['display_name'], 'N');
      expect(cap.form['custom'], '1');
    });

    test('restoreByAssetIds', () async {
      final (c, cap) = client();
      await c.admin.resources.restoreByAssetIds(['a'], versions: ['v']);

      expect(cap.path, '/v1_1/demo/resources/restore');
      final body = jsonDecode(cap.request.body) as Map<String, dynamic>;
      expect(body['asset_ids'], ['a']);
      expect(body['versions'], ['v']);
    });

    test('deleteByAssetIds', () async {
      final (c, cap) = client({'deleted': <String, Object>{}});
      await c.admin.resources.deleteByAssetIds(['a'], invalidate: true);

      expect(cap.method, 'DELETE');
      expect(cap.path, '/v1_1/demo/resources');
      expect(cap.forms['asset_ids[]'], ['a']);
      expect(cap.form['invalidate'], 'true');
    });

    test('deleteBackedUpAssets', () async {
      final (c, cap) = client();
      await c.admin.resources.deleteBackedUpAssets(
        assetId: 'aid',
        versionIds: ['v1'],
      );

      expect(cap.path, '/v1_1/demo/resources/backup/aid');
      expect(cap.forms['version_ids[]'], ['v1']);
    });

    test('deleteDerivedByTransformation', () async {
      final (c, cap) = client();
      await c.admin.resources.deleteDerivedByTransformation(
        publicIds: ['a'],
        transformations: 'w_100',
      );

      expect(cap.method, 'DELETE');
      expect(cap.form['transformations'], 'w_100');
      expect(cap.form['keep_original'], 'true');
      expect(cap.forms['public_ids[]'], ['a']);
    });

    test('addRelatedByAssetId', () async {
      final (c, cap) = client();
      await c.admin.resources.addRelatedByAssetId(
        assetId: 'aid',
        assetsToRelate: ['b'],
      );
      expect(cap.path, '/v1_1/demo/resources/related_assets/aid');
      expect(cap.request.headers['content-type'], contains('application/json'));
    });

    test('deleteRelated', () async {
      final (c, cap) = client();
      await c.admin.resources.deleteRelated(
        publicId: 'p',
        assetsToUnrelate: ['b'],
      );

      expect(cap.method, 'DELETE');
      expect(cap.path, '/v1_1/demo/resources/related_assets/image/upload/p');
    });

    test('deleteRelatedByAssetId', () async {
      final (c, cap) = client();
      await c.admin.resources.deleteRelatedByAssetId(
        assetId: 'aid',
        assetsToUnrelate: ['b'],
      );
      expect(cap.path, '/v1_1/demo/resources/related_assets/aid');
    });

    test('updateAccessMode by tag', () async {
      final (c, cap) = client();
      await c.admin.resources.updateAccessMode(
        accessMode: 'authenticated',
        tag: 't',
        maxResults: 10,
        nextCursor: 'C',
      );

      expect(cap.path, '/v1_1/demo/resources/image/upload/update_access_mode');
      expect(cap.form['access_mode'], 'authenticated');
      expect(cap.form['tag'], 't');
    });
  });

  group('folders and tags, remaining', () {
    test('root paging', () async {
      final (c, cap) = client({'folders': <Object>[]});
      await c.admin.folders.root(maxResults: 5, nextCursor: 'C');

      expect(cap.query['max_results'], '5');
      expect(cap.query['next_cursor'], 'C');
    });

    test('subfolders paging', () async {
      final (c, cap) = client({'folders': <Object>[]});
      await c.admin.folders.subfolders('a', maxResults: 5, nextCursor: 'C');
      expect(cap.query['next_cursor'], 'C');
    });
  });

  group('transformations, presets, mappings, profiles', () {
    test('transformations list filters', () async {
      final (c, cap) = client({'transformations': <Object>[]});
      await c.admin.transformations.list(
        maxResults: 5,
        nextCursor: 'C',
        named: true,
      );

      expect(cap.query['named'], 'true');
      expect(cap.query['max_results'], '5');
    });

    test('transformations get paging', () async {
      final (c, cap) = client({'name': 'n'});
      await c.admin.transformations.get('n', maxResults: 5, nextCursor: 'C');
      expect(cap.query['next_cursor'], 'C');
    });

    test('transformations update with unsafe_update', () async {
      final (c, cap) = client({'message': 'ok'});
      await c.admin.transformations.update('n', unsafeUpdate: 'w_200');
      expect(cap.form['unsafe_update'], 'w_200');
    });

    test('transformations delete with invalidate', () async {
      final (c, cap) = client({'message': 'ok'});
      await c.admin.transformations.delete('n', invalidate: true);
      expect(cap.form['invalidate'], 'true');
    });

    test('presets list paging', () async {
      final (c, cap) = client({'presets': <Object>[]});
      await c.admin.uploadPresets.list(maxResults: 5, nextCursor: 'C');
      expect(cap.query['max_results'], '5');
    });

    test('presets update', () async {
      final (c, cap) = client({'message': 'ok'});
      await c.admin.uploadPresets.update(
        'p',
        unsigned: false,
        settings: {'folder': 'f'},
      );

      expect(cap.method, 'PUT');
      expect(cap.form['unsigned'], 'false');
      expect(cap.form['folder'], 'f');
    });

    test('mappings list paging', () async {
      final (c, cap) = client({'mappings': <Object>[]});
      await c.admin.uploadMappings.list(maxResults: 5, nextCursor: 'C');
      expect(cap.query['next_cursor'], 'C');
    });

    test('mappings update and delete', () async {
      final (c, cap) = client({'message': 'ok'});
      await c.admin.uploadMappings.update(
        folder: 'f',
        template: 'https://e.com',
      );
      expect(cap.method, 'PUT');

      final (c2, cap2) = client({'message': 'ok'});
      await c2.admin.uploadMappings.delete('f');
      expect(cap2.method, 'DELETE');
      expect(cap2.form['folder'], 'f');
    });

    test('streaming profiles update and delete', () async {
      final (c, cap) = client({'message': 'ok'});
      await c.admin.streamingProfiles.update(
        'hd',
        displayName: 'HD',
        representations: const [
          {
            'transformation': {'crop': 'limit', 'width': 1920},
          },
        ],
      );

      expect(cap.method, 'PUT');
      expect(cap.form['display_name'], 'HD');

      final (c2, cap2) = client({'message': 'ok'});
      await c2.admin.streamingProfiles.delete('hd');
      expect(cap2.method, 'DELETE');
      expect(cap2.path, '/v1_1/demo/streaming_profiles/hd');
    });
  });

  group('structured metadata, remaining', () {
    test('get one field', () async {
      final (c, cap) = client({'external_id': 'f'});
      await c.admin.metadataFields.get('f');
      expect(cap.path, '/v1_1/demo/metadata_fields/f');
    });

    test('delete a field', () async {
      final (c, cap) = client({'message': 'ok'});
      await c.admin.metadataFields.delete('f');
      expect(cap.method, 'DELETE');
    });

    test('create with mandatory and a default', () async {
      final (c, cap) = client({'external_id': 'f'});
      await c.admin.metadataFields.create(
        externalId: 'f',
        label: 'F',
        type: MetadataFieldType.integer,
        mandatory: true,
        defaultValue: 3,
        extraParams: {'restrictions': 'none'},
      );

      final body = jsonDecode(cap.request.body) as Map<String, dynamic>;
      expect(body['mandatory'], isTrue);
      expect(body['default_value'], 3);
      expect(body['restrictions'], 'none');
    });

    test('datasource update, delete and restore', () async {
      final (c, cap) = client();
      await c.admin.metadataFields.updateDatasource(
        externalId: 'f',
        values: [
          {'external_id': 'a', 'value': 'A'},
        ],
      );
      expect(cap.path, '/v1_1/demo/metadata_fields/f/datasource');
      expect(cap.method, 'PUT');

      final (c2, cap2) = client();
      await c2.admin.metadataFields.deleteDatasourceEntries(
        externalId: 'f',
        entriesExternalIds: ['a'],
      );
      expect(cap2.method, 'DELETE');

      final (c3, cap3) = client();
      await c3.admin.metadataFields.restoreDatasourceEntries(
        externalId: 'f',
        entriesExternalIds: ['a'],
      );
      expect(cap3.path, '/v1_1/demo/metadata_fields/f/datasource_restore');
    });

    test('reorderFields', () async {
      final (c, cap) = client();
      await c.admin.metadataFields.reorderFields(orderBy: 'label');
      expect(cap.path, '/v1_1/demo/metadata_fields/order');
      expect(cap.method, 'PUT');
    });

    test('rules list and update', () async {
      final (c, cap) = client({
        'metadata_rules': [
          {'external_id': 'r'},
        ],
      });
      final rules = await c.admin.metadataRules.list();
      expect(rules.single.externalId, 'r');
      expect(cap.path, '/v1_1/demo/metadata_rules');

      final (c2, cap2) = client({'external_id': 'r'});
      await c2.admin.metadataRules.update('r', name: 'N', state: 'active');
      expect(cap2.method, 'PUT');
      final body = jsonDecode(cap2.request.body) as Map<String, dynamic>;
      expect(body['state'], 'active');
    });
  });
}
