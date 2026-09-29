import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'throwaway.dart';
import 'widgets.dart';

const _code =
    '''// On a server or in a CLI, read CLOUDINARY_URL from the environment.
// On the web there is no environment, so this throws.
final cloudinary = Cloudinary.fromEnvironment();

// Or pass the same string explicitly.
final other = Cloudinary.fromUrl('cloudinary://key:secret@your-cloud');''';

/// Parses a `CLOUDINARY_URL` live, the way `Cloudinary.fromUrl` does.
class ConfigSection extends StatefulWidget {
  const ConfigSection({super.key});

  @override
  State<ConfigSection> createState() => _ConfigSectionState();
}

class _ConfigSectionState extends State<ConfigSection>
    with AutomaticKeepAliveClientMixin {
  final _url = TextEditingController(
    text: 'cloudinary://$throwawayApiKey:$throwawaySecret@demo',
  );

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    CloudinaryConfig? config;
    String? error;
    try {
      config = CloudinaryConfig.parse(_url.text.trim());
    } on CloudinaryConfigException catch (e) {
      error = e.message;
    }
    return Section(
      title: 'Configuration',
      subtitle: 'The CLOUDINARY_URL format, parsed as you type.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _url,
            decoration: const InputDecoration(
              labelText: 'CLOUDINARY_URL',
              prefixIcon: Icon(Icons.link),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Gaps.m),
          if (config != null) ...[
            Wrap(
              spacing: Gaps.l,
              runSpacing: Gaps.m,
              children: [
                Reading(caption: 'Cloud name', value: config.cloudName),
                Reading(
                  caption: 'API key',
                  value: config.apiKey.isEmpty ? 'none' : config.apiKey,
                ),
                Reading(
                  caption: 'Can sign',
                  value: config.canSign ? 'yes' : 'no',
                ),
              ],
            ),
            const SizedBox(height: Gaps.m),
            Labelled(
              label: 'toString() never prints the secret',
              child: CodeBlock('$config', wrap: true),
            ),
          ],
          if (error != null) Outcome(ok: false, text: error),
          const SizedBox(height: Gaps.m),
          const CodeBlock(_code, label: 'the code'),
        ],
      ),
    );
  }
}
