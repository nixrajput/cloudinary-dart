import 'dart:convert';

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'throwaway.dart';
import 'url_playground.dart';
import 'widgets.dart';

const _sampleResponse = '''{
  "total_count": 2,
  "time": 12,
  "aggregations": {"format": {"jpg": 2}},
  "next_cursor": null,
  "resources": [
    {
      "public_id": "kitten",
      "format": "jpg",
      "width": 1920,
      "height": 1280,
      "tags": ["kitten"],
      "secure_url": "https://res.cloudinary.com/demo/image/upload/kitten.jpg"
    }
  ]
}''';

/// Builds a Search API query live. Running it needs the API secret, so the
/// page shows the request and a sample response rather than calling it.
class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection>
    with AutomaticKeepAliveClientMixin {
  // allowSecretOnWeb exists for code that never reaches a browser. This page
  // is the exception it guards against, made safe by a throwaway secret.
  final _cloudinary = Cloudinary.signed(
    cloudName: demoCloud,
    apiKey: throwawayApiKey,
    apiSecret: throwawaySecret,
    allowSecretOnWeb: true,
  );
  final _expression = TextEditingController(
    text: 'resource_type:image AND tags=kitten',
  );
  var _descending = true;
  var _maxResults = 30;
  var _aggregate = true;
  var _withTags = true;

  @override
  void dispose() {
    _cloudinary.close();
    _expression.dispose();
    super.dispose();
  }

  SearchQuery get _query {
    final query = _cloudinary.search
        .expression(_expression.text)
        .sortBy(
          'created_at',
          _descending ? SortDirection.desc : SortDirection.asc,
        )
        .maxResults(_maxResults);
    if (_aggregate) query.aggregate('format');
    if (_withTags) query.withField('tags');
    return query;
  }

  String get _code => [
    'final page = await cloudinary.search',
    "    .expression('${_expression.text}')",
    "    .sortBy('created_at', SortDirection.${_descending ? 'desc' : 'asc'})",
    '    .maxResults($_maxResults)',
    if (_aggregate) "    .aggregate('format')",
    if (_withTags) "    .withField('tags')",
    '    .execute();',
    '',
    'final more = await cloudinary.search',
    '    // ...the same query...',
    '    .nextCursor(page.nextCursor!)',
    '    .execute();',
  ].join('\n');

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final query = _query;
    return Section(
      title: 'Search',
      subtitle:
          'The query is built here as you type. Running it needs the API '
          'secret, so it runs on your server.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _expression,
            decoration: const InputDecoration(
              labelText: 'Expression',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Gaps.m),
          Wrap(
            spacing: Gaps.s,
            runSpacing: Gaps.s,
            children: [
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 10, label: Text('10')),
                  ButtonSegment(value: 30, label: Text('30')),
                  ButtonSegment(value: 100, label: Text('100')),
                ],
                selected: {_maxResults},
                onSelectionChanged: (s) =>
                    setState(() => _maxResults = s.single),
              ),
              FilterChip(
                label: const Text('Newest first'),
                selected: _descending,
                onSelected: (v) => setState(() => _descending = v),
              ),
              FilterChip(
                label: const Text('Count formats'),
                selected: _aggregate,
                onSelected: (v) => setState(() => _aggregate = v),
              ),
              FilterChip(
                label: const Text('Include tags'),
                selected: _withTags,
                onSelected: (v) => setState(() => _withTags = v),
              ),
            ],
          ),
          const SizedBox(height: Gaps.m),
          Labelled(
            label: 'Request body',
            child: CodeBlock(
              const JsonEncoder.withIndent('  ').convert(query.toJson()),
              label: 'the request',
            ),
          ),
          const SizedBox(height: Gaps.m),
          Labelled(
            label: 'Signed, cacheable search URL (5 minute TTL)',
            child: CodeBlock(
              query.toUrl(ttl: 300),
              label: 'the URL',
              wrap: true,
            ),
          ),
          const SizedBox(height: Gaps.s),
          Text(
            'A search URL is signed once on your server and then cached by '
            'the CDN, so a client can page through results without the '
            'secret.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Gaps.m),
          Labelled(
            label: 'A response looks like this',
            child: const CodeBlock(_sampleResponse, label: 'the response'),
          ),
          const SizedBox(height: Gaps.m),
          CodeBlock(_code, label: 'the code'),
        ],
      ),
    );
  }
}
