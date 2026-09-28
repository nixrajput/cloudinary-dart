import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'url_playground.dart';
import 'widgets.dart';

/// The delivered image with the URL that produced it.
class UrlPreview extends StatelessWidget {
  const UrlPreview({
    super.key,
    required this.options,
    required this.imageHeight,
    required this.showCode,
  });

  final UrlOptions options;

  /// Sized by the page, so the pinned preview always fits the screen.
  final double imageHeight;

  /// Only where the screen is tall enough; the list carries the code otherwise.
  final bool showCode;

  @override
  Widget build(BuildContext context) {
    final url = options.url;
    return Section(
      title: 'Preview',
      subtitle: showCode
          ? "Delivered live from Cloudinary's public demo cloud."
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: imageHeight,
            child: DeliveredImage(url: url),
          ),
          const SizedBox(height: Gaps.m),
          CodeBlock(url, label: 'the URL', wrap: true),
          if (showCode) ...[
            const SizedBox(height: Gaps.m),
            CodeBlock(options.dartCode, label: 'the code'),
          ],
        ],
      ),
    );
  }
}

/// A network image that shows progress and a readable failure instead of
/// throwing, which also keeps widget tests, where every request fails, quiet.
class DeliveredImage extends StatelessWidget {
  const DeliveredImage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Gaps.s),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Gaps.s),
        child: Image.network(
          url,
          key: ValueKey(url),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          semanticLabel: 'The image Cloudinary delivers for this URL',
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined, color: scheme.error),
                const SizedBox(height: Gaps.s),
                const Text('Could not load this image'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
