import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'throwaway.dart';
import 'url_playground.dart';
import 'widgets.dart';

const _providerCode =
    '''// The secret stays on your server; the app only ever sees a signature.
class ServerSigner implements SignatureProvider {
  @override
  Future<RemoteSignature> sign(Map<String, dynamic> params) async {
    final res = await http.post(
      Uri.parse('https://api.example.com/cloudinary/sign'),
      body: jsonEncode(params),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return RemoteSignature(
      signature: json['signature'] as String,
      timestamp: json['timestamp'] as int,
      apiKey: json['api_key'] as String,
    );
  }
}

final cloudinary = Cloudinary.unsigned(
  cloudName: 'your-cloud',
  signatureProvider: ServerSigner(),
);''';

const _verifyCode = '''final ok = verifyNotificationSignature(
  body: rawRequestBody,
  timestamp: int.parse(headers['x-cld-timestamp']!),
  signature: headers['x-cld-signature']!,
  apiSecret: apiSecret,
);''';

/// Signatures, signed URLs, auth tokens and webhook checks, computed here with
/// a throwaway secret so every step can be shown.
class SigningSection extends StatefulWidget {
  const SigningSection({super.key});

  @override
  State<SigningSection> createState() => _SigningSectionState();
}

class _SigningSectionState extends State<SigningSection>
    with AutomaticKeepAliveClientMixin {
  // Captured once, so the values on screen hold still while options change.
  final _timestamp = cloudinaryTimestamp();
  late final _token = const AuthToken(
    key: throwawayTokenKey,
    acl: '/image/authenticated/*',
    duration: 300,
  ).generate();
  late final _tokenUrl = const UrlApi(_config, UrlConfig())
      .image('sample')
      .deliveryType(CloudinaryDeliveryType.authenticated)
      .authToken(
        const AuthToken(
          key: throwawayTokenKey,
          acl: '/image/authenticated/*',
          duration: 300,
        ),
      )
      .build();
  var _version = 2;
  var _algorithm = CloudinarySignatureAlgorithm.sha1;
  var _tampered = false;

  static const _config = CloudinaryConfig(
    cloudName: demoCloud,
    apiKey: throwawayApiKey,
    apiSecret: throwawaySecret,
  );

  Map<String, dynamic> get _params => {
    'public_id': 'sample',
    'folder': 'demo',
    // The & inside a value is what signature version 2 escapes.
    'context': 'caption=Fish & chips',
    'timestamp': _timestamp,
  };

  String get _webhookBody => jsonEncode({
    'notification_type': 'upload',
    'public_id': 'sample',
    'version': _timestamp,
  });

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final signature = signRequest(
      _params,
      throwawaySecret,
      version: _version,
      algorithm: _algorithm,
    );
    final signedUrl = const UrlApi(
      _config,
      UrlConfig(),
    ).image('sample').transform(Transformation()..width(300)).signed().build();
    // Signed the way Cloudinary signs a notification it sends.
    final sent = sha1
        .convert(utf8.encode('$_webhookBody$_timestamp$throwawaySecret'))
        .toString();
    final received = _tampered
        ? _webhookBody.replaceFirst('"sample"', '"someone-else"')
        : _webhookBody;
    final verified = verifyNotificationSignature(
      body: received,
      timestamp: _timestamp,
      signature: sent,
      apiSecret: throwawaySecret,
    );

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: Gaps.s),
      child: Text(text, style: theme.textTheme.titleSmall),
    );

    return Section(
      title: 'Signing',
      subtitle:
          'Computed here with a throwaway secret, which is safe to show. '
          'A real secret never leaves your server.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading('Request signature'),
          Wrap(
            spacing: Gaps.s,
            runSpacing: Gaps.s,
            children: [
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1, label: Text('Version 1')),
                  ButtonSegment(value: 2, label: Text('Version 2')),
                ],
                selected: {_version},
                onSelectionChanged: (s) => setState(() => _version = s.single),
              ),
              SegmentedButton<CloudinarySignatureAlgorithm>(
                showSelectedIcon: false,
                segments: [
                  for (final a in CloudinarySignatureAlgorithm.values)
                    ButtonSegment(value: a, label: Text(a.name.toUpperCase())),
                ],
                selected: {_algorithm},
                onSelectionChanged: (s) =>
                    setState(() => _algorithm = s.single),
              ),
            ],
          ),
          const SizedBox(height: Gaps.m),
          Labelled(
            label: 'String to sign, keys sorted',
            child: CodeBlock(stringToSign(_params, version: _version)),
          ),
          const SizedBox(height: Gaps.m),
          Labelled(
            label: 'Signature',
            child: CodeBlock(signature, label: 'the signature'),
          ),
          const SizedBox(height: Gaps.s),
          Text(
            _version == 2
                ? 'Version 2 escapes the & inside a value, so a value cannot '
                      'add a parameter to the signed string.'
                : 'Version 1 leaves the & bare: "Fish & chips" reads as a '
                      'second parameter. Use version 2.',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: Gaps.l * 2),
          heading('Signed delivery URL'),
          CodeBlock(signedUrl, label: 'the URL', wrap: true),
          const SizedBox(height: Gaps.s),
          Text(
            'The s--...-- component proves the transformation was chosen by '
            'someone holding the secret. Cloudinary checks it against your '
            'real secret, so this one would be refused.',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: Gaps.l * 2),
          heading('Auth token'),
          CodeBlock(_token, label: 'the token'),
          const SizedBox(height: Gaps.m),
          Labelled(
            label: 'An authenticated URL carrying a token',
            child: CodeBlock(_tokenUrl, label: 'the URL', wrap: true),
          ),
          const Divider(height: Gaps.l * 2),
          heading('Webhook verification'),
          Labelled(label: 'Body received', child: CodeBlock(received)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tamper with the body'),
            value: _tampered,
            onChanged: (v) => setState(() => _tampered = v),
          ),
          Outcome(
            ok: verified,
            text: verified
                ? 'Signature valid: this came from Cloudinary.'
                : 'Signature invalid: reject the request.',
          ),
          const SizedBox(height: Gaps.m),
          const CodeBlock(_verifyCode, label: 'the code'),
          const Divider(height: Gaps.l * 2),
          heading('Signing on your server'),
          const CodeBlock(_providerCode, label: 'the code'),
        ],
      ),
    );
  }
}
