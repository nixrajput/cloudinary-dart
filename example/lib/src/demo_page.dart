import 'package:flutter/material.dart';

import 'admin_tour.dart';
import 'collapsible_section.dart';
import 'config_section.dart';
import 'demo_layout.dart';
import 'errors_section.dart';
import 'logo_mark.dart';
import 'preview.dart';
import 'search_section.dart';
import 'signing_section.dart';
import 'upload_section.dart';
import 'url_playground.dart';
import 'widgets.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  /// What the preview card needs around the image: its title and subtitle,
  /// the URL wrapped over up to four lines, and the padding. Below
  /// [_roomyPreview] the URL takes one scrolling line instead.
  static const _previewChrome = 264.0;
  static const _shortChrome = 150.0;
  static const _roomyPreview = 400.0;

  var _options = const UrlOptions();

  /// Bumped by a reset, so the menus rebuild with the defaults selected.
  var _generation = 0;

  @override
  Widget build(BuildContext context) => DemoLayout(
    title: 'cloudinary',
    logo: const LogoMark(size: 28),
    themeMode: widget.themeMode,
    onThemeModeChanged: widget.onThemeModeChanged,
    preview: (context, maxHeight) {
      final roomy = maxHeight >= _roomyPreview;
      final chrome = roomy ? _previewChrome : _shortChrome;
      return UrlPreview(
        options: _options,
        imageHeight: (maxHeight - chrome).clamp(64.0, 320.0),
        wrapUrl: roomy,
      );
    },
    onReset: () => setState(() {
      _options = const UrlOptions();
      _generation++;
    }),
    options: optionSections(
      options: _options,
      onChanged: (o) => setState(() => _options = o),
      generation: _generation,
    ),
    explore: [
      DemoSection(
        title: 'Code',
        summary: 'The Dart that builds the preview URL',
        subtitle: 'The Dart that builds the preview URL.',
        child: CodeBlock(_options.dartCode, label: 'the code'),
      ),
      const DemoSection(
        title: 'Upload',
        summary: 'A real unsigned upload to your own cloud',
        subtitle:
            'A real unsigned upload from this device to your own cloud. '
            'Nothing is stored here.',
        child: UploadSection(),
      ),
      const DemoSection(
        title: 'Signing',
        summary: 'Signatures, signed URLs, tokens and webhooks',
        subtitle:
            'Computed here with a throwaway secret, which is safe to show. '
            'A real secret never leaves your server.',
        child: SigningSection(),
      ),
      const DemoSection(
        title: 'Search',
        summary: 'The query builder and its request',
        subtitle:
            'The query is built here as you type. Running it needs the API '
            'secret, so it runs on your server.',
        child: SearchSection(),
      ),
      const DemoSection(
        title: 'Admin API',
        summary: 'All ten groups under cloudinary.admin',
        subtitle:
            'All ten groups under cloudinary.admin. Each call needs the API '
            'secret, so it runs on your server.',
        child: AdminTour(),
      ),
      const DemoSection(
        title: 'Configuration',
        summary: 'CLOUDINARY_URL, parsed as you type',
        subtitle: 'The CLOUDINARY_URL format, parsed as you type.',
        child: ConfigSection(),
      ),
      const DemoSection(
        title: 'Errors and retries',
        summary: 'The exception family and the retry policy',
        subtitle:
            'Every failure is a CloudinaryException subtype, so a switch '
            'over it is exhaustive.',
        child: ErrorsSection(),
      ),
    ],
  );
}
