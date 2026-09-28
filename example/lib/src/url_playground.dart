import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'widgets.dart';

/// Cloudinary's public demo cloud, which serves the sample assets Cloudinary's
/// own documentation uses, so the playground needs no account.
const demoCloud = 'demo';

const samplePublicIds = [
  'sample',
  'cld-sample',
  'cld-sample-2',
  'cld-sample-3',
  'cld-sample-4',
  'cld-sample-5',
  'samples/animals/cat',
  'samples/food/dessert',
  'samples/landscapes/beach-boat',
  'samples/people/smiling-man',
];

const cropModes = [
  CropMode.fill,
  CropMode.thumb,
  CropMode.crop,
  CropMode.auto,
  CropMode.fit,
  CropMode.pad,
  CropMode.scale,
];

const gravities = [
  Gravity.auto,
  Gravity.center,
  Gravity.face,
  Gravity.north,
  Gravity.south,
];

const effects = [
  Effect.grayscale,
  Effect.sepia,
  Effect.blur,
  Effect.pixelate,
  Effect.oilPaint,
  Effect.negate,
  Effect.improve,
  Effect.autoContrast,
];

const qualities = [
  Quality.auto,
  Quality.autoEco,
  Quality.autoGood,
  Quality.autoBest,
];

/// AVIF and the rest are left out: Flutter decodes these on every platform.
const formats = [
  DeliveryFormat.auto,
  DeliveryFormat.jpg,
  DeliveryFormat.png,
  DeliveryFormat.webp,
];

const ratios = ['1:1', '4:3', '16:9'];

/// Only these crop modes choose which part of the image to keep, so only they
/// take a gravity.
bool usesGravity(CropMode mode) => const {
  CropMode.fill,
  CropMode.lfill,
  CropMode.fillPad,
  CropMode.thumb,
  CropMode.crop,
  CropMode.auto,
}.contains(mode);

@immutable
class UrlOptions {
  const UrlOptions({
    this.publicId = 'sample',
    this.width = 800,
    this.ratio = '4:3',
    this.crop = CropMode.fill,
    this.gravity = Gravity.auto,
    this.effect,
    this.quality = Quality.auto,
    this.format = DeliveryFormat.auto,
    this.rounded = false,
    this.rotated = false,
    this.cdnSubdomain = false,
    this.shorten = false,
  });

  final String publicId;
  final int width;
  final String ratio;
  final CropMode crop;
  final Gravity gravity;
  final Effect? effect;
  final Quality quality;
  final DeliveryFormat format;
  final bool rounded;
  final bool rotated;
  final bool cdnSubdomain;
  final bool shorten;

  UrlOptions copyWith({
    String? publicId,
    int? width,
    String? ratio,
    CropMode? crop,
    Gravity? gravity,
    Effect? Function()? effect,
    Quality? quality,
    DeliveryFormat? format,
    bool? rounded,
    bool? rotated,
    bool? cdnSubdomain,
    bool? shorten,
  }) => UrlOptions(
    publicId: publicId ?? this.publicId,
    width: width ?? this.width,
    ratio: ratio ?? this.ratio,
    crop: crop ?? this.crop,
    gravity: gravity ?? this.gravity,
    effect: effect == null ? this.effect : effect(),
    quality: quality ?? this.quality,
    format: format ?? this.format,
    rounded: rounded ?? this.rounded,
    rotated: rotated ?? this.rotated,
    cdnSubdomain: cdnSubdomain ?? this.cdnSubdomain,
    shorten: shorten ?? this.shorten,
  );

  double get aspectRatio {
    final [w, h] = ratio.split(':').map(double.parse).toList();
    return w / h;
  }

  UrlConfig get urlConfig =>
      UrlConfig(cdnSubdomain: cdnSubdomain, shorten: shorten);

  Transformation get transformation {
    final t = Transformation()
      ..width(width)
      ..aspectRatio(ratio)
      ..crop(crop)
      ..quality(quality)
      ..format(format);
    if (usesGravity(crop)) t.gravity(gravity);
    // Pad fills the added space; auto picks a colour from the image's edges.
    if (crop == CropMode.pad) t.background('auto');
    if (effect case final effect?) t.effect(effect);
    if (rounded) t.radius('max');
    if (rotated) t.angle(90);
    return t;
  }

  String get url => UrlApi(
    CloudinaryConfig(cloudName: demoCloud),
    urlConfig,
  ).image(publicId).transform(transformation).build();

  /// The Dart that builds [url], as a reader would write it.
  String get dartCode {
    final config = [
      if (cdnSubdomain) 'cdnSubdomain: true',
      if (shorten) 'shorten: true',
    ];
    final steps = [
      '..width($width)',
      "..aspectRatio('$ratio')",
      '..crop(CropMode.${crop.name})',
      if (usesGravity(crop)) '..gravity(Gravity.${gravity.name})',
      if (crop == CropMode.pad) "..background('auto')",
      if (effect != null) '..effect(Effect.${effect!.name})',
      '..quality(Quality.${quality.name})',
      '..format(DeliveryFormat.${format.name})',
      if (rounded) "..radius('max')",
      if (rotated) '..angle(90)',
    ];
    return [
      'final cloudinary = Cloudinary.unsigned(',
      "  cloudName: '$demoCloud',",
      if (config.isNotEmpty) '  urlConfig: UrlConfig(${config.join(', ')}),',
      ');',
      '',
      'final url = cloudinary.url',
      "    .image('$publicId')",
      '    .transform(',
      '      Transformation()',
      for (final step in steps) '        $step',
      '    )',
      '    .build();',
    ].join('\n');
  }
}

class OptionsPanel extends StatelessWidget {
  const OptionsPanel({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final UrlOptions options;
  final ValueChanged<UrlOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget toggle(String label, bool value, UrlOptions Function(bool) next) =>
        FilterChip(
          label: Text(label),
          selected: value,
          onSelected: (v) => onChanged(next(v)),
        );
    Widget menu<T>(
      String label,
      T? value,
      List<T> values,
      String Function(T) name,
      ValueChanged<T?> onSelected, {
      bool enabled = true,
    }) => DropdownMenu<T>(
      label: Text(label),
      enabled: enabled,
      expandedInsets: EdgeInsets.zero,
      initialSelection: value,
      dropdownMenuEntries: [
        for (final v in values) DropdownMenuEntry(value: v, label: name(v)),
      ],
      onSelected: onSelected,
    );
    // Two menus a row once there is room, one each on a narrow screen.
    Widget pair(Widget a, Widget b) => LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 360
          ? Column(
              children: [
                a,
                const SizedBox(height: Gaps.m),
                b,
              ],
            )
          : Row(
              children: [
                Expanded(child: a),
                const SizedBox(width: Gaps.m),
                Expanded(child: b),
              ],
            ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        menu<String>(
          'Public ID',
          options.publicId,
          samplePublicIds,
          (id) => id,
          (id) => onChanged(options.copyWith(publicId: id)),
        ),
        const SizedBox(height: Gaps.m),
        pair(
          menu<CropMode>(
            'Crop',
            options.crop,
            cropModes,
            (c) => c.name,
            (c) => onChanged(options.copyWith(crop: c)),
          ),
          menu<Gravity>(
            'Gravity',
            options.gravity,
            gravities,
            (g) => g.name,
            (g) => onChanged(options.copyWith(gravity: g)),
            enabled: usesGravity(options.crop),
          ),
        ),
        const SizedBox(height: Gaps.m),
        pair(
          menu<Effect?>(
            'Effect',
            options.effect,
            [null, ...effects],
            (e) => e?.name ?? 'none',
            (e) => onChanged(options.copyWith(effect: () => e)),
          ),
          menu<Quality>(
            'Quality',
            options.quality,
            qualities,
            (q) => q.name,
            (q) => onChanged(options.copyWith(quality: q)),
          ),
        ),
        const SizedBox(height: Gaps.m),
        Text('Width ${options.width} px'),
        Slider(
          value: options.width.toDouble(),
          min: 200,
          max: 1600,
          divisions: 14,
          onChanged: (v) => onChanged(options.copyWith(width: v.round())),
        ),
        Labelled(
          label: 'Aspect ratio and format',
          child: Wrap(
            spacing: Gaps.s,
            runSpacing: Gaps.s,
            children: [
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final r in ratios)
                    ButtonSegment(value: r, label: Text(r)),
                ],
                selected: {options.ratio},
                onSelectionChanged: (s) =>
                    onChanged(options.copyWith(ratio: s.single)),
              ),
              SegmentedButton<DeliveryFormat>(
                showSelectedIcon: false,
                segments: [
                  for (final f in formats)
                    ButtonSegment(value: f, label: Text(f.name)),
                ],
                selected: {options.format},
                onSelectionChanged: (s) =>
                    onChanged(options.copyWith(format: s.single)),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gaps.m),
        Wrap(
          spacing: Gaps.s,
          runSpacing: Gaps.s,
          children: [
            toggle(
              'Round',
              options.rounded,
              (v) => options.copyWith(rounded: v),
            ),
            toggle(
              'Rotate 90°',
              options.rotated,
              (v) => options.copyWith(rotated: v),
            ),
            toggle(
              'CDN subdomain',
              options.cdnSubdomain,
              (v) => options.copyWith(cdnSubdomain: v),
            ),
            toggle(
              'Short URL',
              options.shorten,
              (v) => options.copyWith(shorten: v),
            ),
          ],
        ),
      ],
    );
  }
}
