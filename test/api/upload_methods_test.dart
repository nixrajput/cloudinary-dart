import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Captures the single request an API call makes.
class Captured {
  late http.Request request;

  Map<String, String> get form => Uri.splitQueryString(request.body);
  String get path => request.url.path;
  String get method => request.method;
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
  test('explicit', () async {
    final (c, cap) = clientReturning({'public_id': 'p'});
    await c.upload.explicit(publicId: 'p', eager: 'w_100');

    expect(cap.path, '/v1_1/demo/image/explicit');
    expect(cap.form['public_id'], 'p');
    expect(cap.form['type'], 'upload');
    expect(cap.form['eager'], 'w_100');
    expect(cap.form['signature'], isNotNull);
  });

  test('rename posts both public ids', () async {
    final (c, cap) = clientReturning({'public_id': 'b'});
    await c.upload.rename(fromPublicId: 'a', toPublicId: 'b');

    expect(cap.path, '/v1_1/demo/image/rename');
    expect(cap.form['from_public_id'], 'a');
    expect(cap.form['to_public_id'], 'b');
  });

  test('destroy', () async {
    final (c, cap) = clientReturning({'result': 'ok'});
    final r = await c.upload.destroy(publicId: 'p', invalidate: true);

    expect(cap.path, '/v1_1/demo/image/destroy');
    expect(cap.form['public_id'], 'p');
    expect(cap.form['invalidate'], 'true');
    expect(r.isDeleted, isTrue);
  });

  test('destroy reports a miss without throwing', () async {
    final (c, _) = clientReturning({'result': 'not found'});
    final r = await c.upload.destroy(publicId: 'gone');

    expect(r.isDeleted, isFalse);
    expect(r.result, 'not found');
  });

  test('destroy rejects an empty public id', () {
    final (c, _) = clientReturning({'result': 'ok'});
    expect(
      () => c.upload.destroy(publicId: ''),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });

  test('destroyByAssetId uses DELETE on the asset path', () async {
    final (c, cap) = clientReturning({'result': 'ok'});
    await c.upload.destroyByAssetId(assetId: 'aid');

    expect(cap.method, 'DELETE');
    expect(cap.path, '/v1_1/demo/asset/aid');
  });

  group('tag commands', () {
    test('add', () async {
      final (c, cap) = clientReturning({
        'public_ids': ['a']
      });
      final r = await c.upload.addTag(tag: 't', publicIds: ['a', 'b']);

      expect(cap.path, '/v1_1/demo/image/tags');
      expect(cap.form['command'], 'add');
      expect(cap.form['tag'], 't');
      expect(cap.form['public_ids'], 'a,b');
      expect(r.publicIds, ['a']);
    });

    test('remove', () async {
      final (c, cap) = clientReturning({'public_ids': <String>[]});
      await c.upload.removeTag(tag: 't', publicIds: ['a']);
      expect(cap.form['command'], 'remove');
    });

    test('replace', () async {
      final (c, cap) = clientReturning({'public_ids': <String>[]});
      await c.upload.replaceTag(tag: 't', publicIds: ['a']);
      expect(cap.form['command'], 'replace');
    });

    test('remove_all sends no tag', () async {
      final (c, cap) = clientReturning({'public_ids': <String>[]});
      await c.upload.removeAllTags(publicIds: ['a']);

      expect(cap.form['command'], 'remove_all');
      expect(cap.form.containsKey('tag'), isFalse);
    });
  });

  test('addContext escapes = and | in values', () async {
    final (c, cap) = clientReturning({'public_ids': <String>[]});
    await c.upload.addContext(
      context: {'alt': 'a=b|c'},
      publicIds: ['x'],
    );

    expect(cap.path, '/v1_1/demo/image/context');
    expect(cap.form['command'], 'add');
    expect(cap.form['context'], r'alt=a\=b\|c');
  });

  test('removeAllContext', () async {
    final (c, cap) = clientReturning({'public_ids': <String>[]});
    await c.upload.removeAllContext(publicIds: ['x']);
    expect(cap.form['command'], 'remove_all');
  });

  test('updateMetadata', () async {
    final (c, cap) = clientReturning({'public_ids': <String>[]});
    await c.upload.updateMetadata(metadata: {'k': 'v'}, publicIds: ['x']);

    expect(cap.path, '/v1_1/demo/image/metadata');
    expect(cap.form['metadata'], 'k=v');
  });

  test('explode', () async {
    final (c, cap) = clientReturning({'status': 'processing', 'batch_id': 'b'});
    final r = await c.upload.explode(publicId: 'p', transformation: 'pg_all');

    expect(cap.path, '/v1_1/demo/image/explode');
    expect(r.batchId, 'b');
  });

  test('multi has no resource type segment', () async {
    final (c, cap) = clientReturning({'public_id': 'p'});
    await c.upload.multi(tag: 't');
    expect(cap.path, '/v1_1/demo/multi');
  });

  test('generateSprite has no resource type segment', () async {
    final (c, cap) = clientReturning({'public_id': 'p'});
    await c.upload.generateSprite(tag: 't');
    expect(cap.path, '/v1_1/demo/sprite');
  });

  test('multi requires a tag or urls', () {
    final (c, _) = clientReturning({});
    expect(
      () => c.upload.multi(),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });

  test('text', () async {
    final (c, cap) = clientReturning({'width': 100, 'height': 20});
    final r = await c.upload.text(text: 'hello', fontFamily: 'Arial');

    expect(cap.path, '/v1_1/demo/text');
    expect(cap.form['text'], 'hello');
    expect(cap.form['font_family'], 'Arial');
    expect(r.width, 100);
  });

  test('createArchive', () async {
    final (c, cap) = clientReturning({'public_id': 'a', 'file_count': 3});
    final r = await c.upload.createArchive(tag: 't');

    expect(cap.path, '/v1_1/demo/image/generate_archive');
    expect(r.fileCount, 3);
  });

  test('createArchive requires a selector', () {
    final (c, _) = clientReturning({});
    expect(
      () => c.upload.createArchive(),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });

  test('createZip forces the zip target format', () async {
    final (c, cap) = clientReturning({'public_id': 'a'});
    await c.upload.createZip(tag: 't');
    expect(cap.form['target_format'], 'zip');
  });

  test('deleteByToken sends neither api_key nor signature', () async {
    final (c, cap) = clientReturning({'result': 'ok'});
    await c.upload.deleteByToken(token: 'tok');

    expect(cap.path, '/v1_1/demo/image/delete_by_token');
    expect(cap.form['token'], 'tok');
    expect(cap.form.containsKey('api_key'), isFalse);
    expect(cap.form.containsKey('signature'), isFalse);
  });
}
