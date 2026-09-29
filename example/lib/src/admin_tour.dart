import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'widgets.dart';

typedef AdminGroup = ({
  String name,
  String summary,
  String code,
  String response,
});

/// One entry per group under `cloudinary.admin`, with a call and the shape of
/// what comes back.
const adminGroups = <AdminGroup>[
  (
    name: 'account',
    summary: 'Usage against your plan, a health check and account settings.',
    code: '''final usage = await cloudinary.admin.account.usage();
print('\${usage.plan}: \${usage.creditsUsedPercent}% of credits used');

await cloudinary.admin.account.ping();''',
    response: '''{
  "plan": "Free",
  "credits": {"usage": 3.2, "limit": 25, "used_percent": 12.8},
  "objects": {"usage": 1840},
  "transformations": {"usage": 5212}
}''',
  ),
  (
    name: 'resources',
    summary: 'List, fetch, update, restore and delete assets.',
    code: '''final page = await cloudinary.admin.resources.list(
  maxResults: 20,
  tags: true,
);
for (final asset in page.resources) {
  print('\${asset.publicId} \${asset.bytes} bytes');
}

final one = await cloudinary.admin.resources.get('sample');''',
    response: '''{
  "resources": [
    {"public_id": "sample", "format": "jpg", "bytes": 120253,
     "width": 864, "height": 576, "tags": ["flowers"]}
  ],
  "next_cursor": "8edbc61040178db60b0973ca9494bf3a"
}''',
  ),
  (
    name: 'folders',
    summary: 'Browse, create, rename and delete asset folders.',
    code: '''final root = await cloudinary.admin.folders.root();
final inside = await cloudinary.admin.folders.subfolders('samples');
await cloudinary.admin.folders.create('products/2026');''',
    response: '''{
  "folders": [
    {"name": "animals", "path": "samples/animals"},
    {"name": "food", "path": "samples/food"}
  ],
  "total_count": 2
}''',
  ),
  (
    name: 'tags',
    summary: 'List the tags in use, optionally by prefix.',
    code: '''final tags = await cloudinary.admin.tags.list(prefix: 'holi');
print(tags.tags);''',
    response: '''{"tags": ["holiday", "holiday-2026"]}''',
  ),
  (
    name: 'transformations',
    summary: 'Named transformations, reusable by name in any URL.',
    code: '''await cloudinary.admin.transformations.create(
  name: 'square_thumb',
  transformation: 'c_thumb,g_auto,h_200,w_200',
);
// Then in a URL: Transformation()..named('square_thumb')''',
    response: '''{"message": "created"}''',
  ),
  (
    name: 'uploadPresets',
    summary:
        'Presets that fix upload settings; unsigned ones allow '
        'browser uploads.',
    code: '''await cloudinary.admin.uploadPresets.create(
  name: 'avatars',
  unsigned: true,
  settings: {'folder': 'avatars', 'allowed_formats': 'jpg,png'},
);''',
    response: '''{"message": "created", "name": "avatars"}''',
  ),
  (
    name: 'uploadMappings',
    summary: 'Map a folder to a remote URL prefix for lazy migration.',
    code: '''await cloudinary.admin.uploadMappings.create(
  folder: 'legacy',
  template: 'https://old.example.com/images/',
);''',
    response: '''{"message": "created"}''',
  ),
  (
    name: 'streamingProfiles',
    summary: 'Adaptive bitrate profiles for HLS and DASH video.',
    code: '''final list = await cloudinary.admin.streamingProfiles.list();
for (final p in list.profiles) {
  print('\${p.name} (predefined: \${p.predefined})');
}''',
    response: '''{
  "data": [
    {"name": "hd", "display_name": "HD", "predefined": true},
    {"name": "full_hd", "display_name": "Full HD", "predefined": true}
  ]
}''',
  ),
  (
    name: 'metadataFields',
    summary: 'Structured metadata fields, with their datasources.',
    code: '''final field = await cloudinary.admin.metadataFields.create(
  externalId: 'sku',
  label: 'SKU',
  type: MetadataFieldType.string,
);''',
    response: '''{"external_id": "sku", "label": "SKU", "type": "string"}''',
  ),
  (
    name: 'metadataRules',
    summary: 'Conditional rules between metadata fields.',
    code: '''final rules = await cloudinary.admin.metadataRules.list();''',
    response: '''{
  "metadata_rules": [
    {"external_id": "sku-needs-category", "metadata_field_id": "sku",
     "state": "active"}
  ]
}''',
  ),
];

/// The Admin API, one group at a time. Every call needs the API secret, so
/// the page shows the call and a sample response instead of running it.
class AdminTour extends StatefulWidget {
  const AdminTour({super.key});

  @override
  State<AdminTour> createState() => _AdminTourState();
}

class _AdminTourState extends State<AdminTour>
    with AutomaticKeepAliveClientMixin {
  var _group = adminGroups.first;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownMenu<AdminGroup>(
          label: const Text('Group'),
          leadingIcon: const Icon(Icons.admin_panel_settings_outlined),
          expandedInsets: EdgeInsets.zero,
          initialSelection: _group,
          dropdownMenuEntries: [
            for (final g in adminGroups)
              DropdownMenuEntry(value: g, label: 'admin.${g.name}'),
          ],
          onSelected: (g) {
            if (g != null) setState(() => _group = g);
          },
        ),
        const SizedBox(height: Gaps.m),
        Text(_group.summary, style: theme.textTheme.bodyMedium),
        const SizedBox(height: Gaps.m),
        CodeBlock(_group.code, label: 'the code'),
        const SizedBox(height: Gaps.m),
        Labelled(
          label: 'A response looks like this',
          child: CodeBlock(_group.response, label: 'the response'),
        ),
      ],
    );
  }
}
