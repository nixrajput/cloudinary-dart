import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'src/demo_config.dart';
import 'src/demo_controller.dart';
import 'src/image_picking.dart';

void main() => runApp(const CloudinaryDemoApp());

class CloudinaryDemoApp extends StatelessWidget {
  const CloudinaryDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Cloudinary demo',
    theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
    home: const DemoPage(),
  );
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final DemoController _controller = DemoController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _pick(ImageSource source) async {
    final result = await pickImage(source);
    switch (result) {
      case PickedImage(:final path):
        _controller.setImage(path);
      case PickFailed(:final message):
        _controller.showError(message);
      case PickCancelled():
        break;
    }
  }

  Future<void> _choose() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Use camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  @override
  Widget build(BuildContext context) {
    if (cloudName.isEmpty) return const _MissingConfig();

    final c = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloudinary demo'),
        bottom: c.busy
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: c.progress == 0 ? null : c.progress,
                ),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SourceToggle(controller: c),
          const SizedBox(height: 16),
          if (c.imagePath != null)
            Image.file(File(c.imagePath!), height: 180, fit: BoxFit.contain),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: c.busy ? null : _choose,
            child: Text(c.imagePath == null ? 'Choose image' : 'Change image'),
          ),
          const SizedBox(height: 8),
          _UploadButtons(controller: c),
          if (c.result != null) _ResultPanel(controller: c),
          if (c.status != null) _Banner(text: c.status!),
          if (c.error != null) _Banner(text: c.error!, isError: true),
        ],
      ),
    );
  }
}

class _SourceToggle extends StatelessWidget {
  const _SourceToggle({required this.controller});

  final DemoController controller;

  @override
  Widget build(BuildContext context) => SegmentedButton<UploadSource>(
    segments: const [
      ButtonSegment(value: UploadSource.path, label: Text('From path')),
      ButtonSegment(value: UploadSource.bytes, label: Text('From bytes')),
    ],
    selected: {controller.source},
    onSelectionChanged: (s) => controller.setSource(s.first),
  );
}

class _UploadButtons extends StatelessWidget {
  const _UploadButtons({required this.controller});

  final DemoController controller;

  @override
  Widget build(BuildContext context) {
    final ready = controller.imagePath != null && !controller.busy;
    return Wrap(
      spacing: 12,
      alignment: WrapAlignment.center,
      children: [
        if (controller.canSign)
          FilledButton(
            onPressed: ready ? () => controller.upload(signed: true) : null,
            child: const Text('Signed upload'),
          ),
        if (controller.hasUploadPreset)
          FilledButton(
            onPressed: ready ? () => controller.upload(signed: false) : null,
            child: const Text('Unsigned upload'),
          ),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.controller});

  final DemoController controller;

  @override
  Widget build(BuildContext context) {
    final transformed = controller.transformedUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text('Delivery URL', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        SelectableText(controller.result?.secureUrl ?? ''),
        if (transformed != null) ...[
          const SizedBox(height: 16),
          Text(
            'Transformed URL',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          SelectableText(transformed),
          const SizedBox(height: 8),
          Image.network(
            transformed,
            height: 150,
            errorBuilder: (_, _, _) => const Text('Preview unavailable'),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton(
              onPressed: controller.busy ? null : controller.destroy,
              child: const Text('Delete'),
            ),
            if (controller.canSign)
              OutlinedButton(
                onPressed: controller.busy ? null : controller.search,
                child: const Text('Search folder'),
              ),
          ],
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: isError ? scheme.error : scheme.primary),
      ),
    );
  }
}

class _MissingConfig extends StatelessWidget {
  const _MissingConfig();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Run with --dart-define=CLOUDINARY_CLOUD_NAME=your-cloud.\n'
            'See example/README.md for the full command.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
