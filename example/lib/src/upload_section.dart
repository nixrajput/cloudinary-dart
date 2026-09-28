import 'dart:typed_data';

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'preview.dart';
import 'widgets.dart';

const _code =
    '''final cloudinary = Cloudinary.unsigned(cloudName: 'your-cloud');

final result = await cloudinary.upload.unsignedUpload(
  file: CloudinaryFileSource.bytes(bytes, filename: 'photo.jpg'),
  uploadPreset: 'your-unsigned-preset',
  folder: 'demo',
  onProgress: (sent, total) => print('\$sent / \$total'),
);

print(result.secureUrl);''';

/// A real unsigned upload to the visitor's own cloud. Unsigned presets are
/// the only safe way to upload straight from a browser.
class UploadSection extends StatefulWidget {
  const UploadSection({super.key});

  @override
  State<UploadSection> createState() => _UploadSectionState();
}

class _UploadSectionState extends State<UploadSection>
    with AutomaticKeepAliveClientMixin {
  final _cloud = TextEditingController();
  final _preset = TextEditingController();
  final _folder = TextEditingController(text: 'cloudinary-dart-demo');
  XFile? _file;
  Uint8List? _bytes;
  double? _progress;
  UploadResult? _result;
  String? _uploadedCloud;
  String? _error;

  bool get _busy => _progress != null;

  @override
  void dispose() {
    _cloud.dispose();
    _preset.dispose();
    _folder.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _file = file;
      _bytes = bytes;
      _result = null;
      _error = null;
    });
  }

  Future<void> _upload() async {
    final cloud = _cloud.text.trim();
    final preset = _preset.text.trim();
    final folder = _folder.text.trim();
    final bytes = _bytes;
    if (cloud.isEmpty || preset.isEmpty || bytes == null) {
      setState(
        () => _error =
            'Enter a cloud name and an unsigned preset, '
            'then choose an image.',
      );
      return;
    }
    setState(() {
      _progress = 0;
      _result = null;
      _error = null;
    });
    final cloudinary = Cloudinary.unsigned(cloudName: cloud);
    try {
      final result = await cloudinary.upload.unsignedUpload(
        file: CloudinaryFileSource.bytes(bytes, filename: _file?.name),
        uploadPreset: preset,
        folder: folder.isEmpty ? null : folder,
        onProgress: (sent, total) {
          if (mounted && total > 0) setState(() => _progress = sent / total);
        },
      );
      if (mounted) {
        setState(() {
          _result = result;
          _uploadedCloud = cloud;
        });
      }
    } on CloudinaryException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      cloudinary.close();
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final result = _result;
    return Section(
      title: 'Upload',
      subtitle:
          'A real unsigned upload from this device to your own cloud. '
          'Nothing is stored here.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create an upload preset with signing mode "Unsigned" in your '
            'Cloudinary settings. A signed upload needs the API secret, so '
            'it runs on your server, or through a SignatureProvider that '
            'asks your server to sign.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Gaps.m),
          TextField(
            controller: _cloud,
            decoration: const InputDecoration(
              labelText: 'Cloud name',
              prefixIcon: Icon(Icons.cloud_outlined),
            ),
          ),
          const SizedBox(height: Gaps.m),
          TextField(
            controller: _preset,
            decoration: const InputDecoration(
              labelText: 'Unsigned upload preset',
              prefixIcon: Icon(Icons.key_off_outlined),
            ),
          ),
          const SizedBox(height: Gaps.m),
          TextField(
            controller: _folder,
            decoration: const InputDecoration(
              labelText: 'Folder (optional)',
              prefixIcon: Icon(Icons.folder_outlined),
            ),
          ),
          const SizedBox(height: Gaps.m),
          Wrap(
            spacing: Gaps.s,
            runSpacing: Gaps.s,
            children: [
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.image_outlined),
                label: Text(_file == null ? 'Choose an image' : 'Change'),
              ),
              FilledButton.icon(
                onPressed: _busy || _bytes == null ? null : _upload,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Upload'),
              ),
            ],
          ),
          if (_bytes case final bytes?) ...[
            const SizedBox(height: Gaps.m),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Gaps.s),
                  child: Image.memory(
                    bytes,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: Gaps.m),
                Expanded(
                  child: Reading(
                    caption: _file?.name ?? 'Chosen image',
                    value: '${(bytes.length / 1024).toStringAsFixed(0)} KB',
                  ),
                ),
              ],
            ),
          ],
          if (_progress case final progress?) ...[
            const SizedBox(height: Gaps.m),
            LinearProgressIndicator(value: progress),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: Gaps.m),
            Outcome(ok: false, text: error),
          ],
          if (result != null) ...[
            const SizedBox(height: Gaps.m),
            Outcome(ok: true, text: 'Uploaded as ${result.publicId}'),
            const SizedBox(height: Gaps.m),
            Wrap(
              spacing: Gaps.l,
              runSpacing: Gaps.m,
              children: [
                Reading(
                  caption: 'Size',
                  value: '${result.width} x ${result.height}',
                ),
                Reading(caption: 'Format', value: result.format ?? '-'),
                Reading(caption: 'Bytes', value: '${result.bytes ?? '-'}'),
              ],
            ),
            if (result.secureUrl case final url?) ...[
              const SizedBox(height: Gaps.m),
              CodeBlock(url, label: 'the URL', wrap: true),
            ],
            if ((result.publicId, _uploadedCloud) case (
              final id?,
              final cloud?,
            )) ...[
              const SizedBox(height: Gaps.m),
              Text(
                'A 240 px square thumbnail, from the URL builder:',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: Gaps.s),
              SizedBox(
                height: 120,
                child: DeliveredImage(
                  url:
                      UrlApi(
                            CloudinaryConfig(cloudName: cloud),
                            const UrlConfig(),
                          )
                          .image(id)
                          .transform(
                            Transformation()
                              ..width(240)
                              ..height(240)
                              ..crop(CropMode.thumb)
                              ..gravity(Gravity.auto),
                          )
                          .build(),
                ),
              ),
            ],
          ],
          const SizedBox(height: Gaps.m),
          const CodeBlock(_code, label: 'the code'),
        ],
      ),
    );
  }
}
