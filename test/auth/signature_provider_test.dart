import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// A provider lets a client app run signed operations with the API secret
/// kept on its own server. It was accepted and advertised but never invoked,
/// so every signed call on a provider-backed client threw.
class _RecordingSigner implements SignatureProvider {
  Map<String, dynamic>? seen;
  int calls = 0;

  @override
  Future<RemoteSignature> sign(Map<String, dynamic> params) async {
    seen = params;
    calls++;
    return const RemoteSignature(
      signature: 'deadbeef',
      timestamp: 1700000000,
      apiKey: 'remote-key',
    );
  }
}

void main() {
  test('a signed upload routes through the provider', () async {
    final signer = _RecordingSigner();
    late String body;

    final c = Cloudinary.unsigned(
      cloudName: 'demo',
      signatureProvider: signer,
      client: MockClient((req) async {
        body = req.body;
        return http.Response(jsonEncode({'public_id': 'x'}), 200);
      }),
    );

    final result = await c.upload.upload(
      file: const CloudinaryFileSource.url('https://example.com/a.png'),
      folder: 'f',
    );

    expect(signer.calls, 1);
    expect(result.publicId, 'x');
    expect(body, contains('deadbeef'));
    expect(body, contains('remote-key'));
    expect(body, contains('1700000000'));
  });

  test(
    'the provider receives the parameters to sign, without the file',
    () async {
      final signer = _RecordingSigner();
      final c = Cloudinary.unsigned(
        cloudName: 'demo',
        signatureProvider: signer,
        client: MockClient(
          (_) async => http.Response(jsonEncode({'public_id': 'x'}), 200),
        ),
      );

      await c.upload.upload(
        file: const CloudinaryFileSource.url('https://example.com/a.png'),
        folder: 'trips',
      );

      expect(signer.seen, isNotNull);
      expect(signer.seen!['folder'], 'trips');
      expect(signer.seen!.containsKey('file'), isFalse);
      expect(signer.seen!.containsKey('api_key'), isFalse);
    },
  );

  test('a signed admin call works through the provider', () async {
    final signer = _RecordingSigner();
    late String body;

    final c = Cloudinary.unsigned(
      cloudName: 'demo',
      signatureProvider: signer,
      client: MockClient((req) async {
        body = req.body;
        return http.Response(jsonEncode({'result': 'ok'}), 200);
      }),
    );

    final r = await c.upload.destroy(publicId: 'p');

    expect(r.isDeleted, isTrue);
    expect(body, contains('deadbeef'));
  });

  test('without a provider and without a secret, it still throws', () async {
    final c = Cloudinary.unsigned(
      cloudName: 'demo',
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    await expectLater(
      c.upload.upload(
        file: const CloudinaryFileSource.url('https://example.com/a.png'),
      ),
      throwsA(isA<CloudinaryConfigException>()),
    );
  });

  test(
    'a local secret still signs locally when no provider is given',
    () async {
      late String body;
      final c = Cloudinary.signed(
        cloudName: 'demo',
        apiKey: 'k',
        apiSecret: 's',
        client: MockClient((req) async {
          body = req.body;
          return http.Response(jsonEncode({'result': 'ok'}), 200);
        }),
      );

      await c.upload.destroy(publicId: 'p');

      expect(body, isNot(contains('deadbeef')));
      expect(body, contains('signature'));
    },
  );
}
