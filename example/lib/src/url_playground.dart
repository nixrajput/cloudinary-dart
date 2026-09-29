import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'collapsible_section.dart';
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

/// The URL options as collapsible cards, grouped by what they change.
/// [generation] rebuilds the menus, which read their selection once, after a
/// reset.
List<DemoSection> optionSections({
  required UrlOptions options,
  required ValueChanged<UrlOptions> onChanged,
  required int generation,
}) {
  final o = options;
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
  // Two menus a row once there is room, one each on a narrow card.
  Widget pair(Widget a, Widget b) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 320
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
  Widget column(List<Widget> children) => KeyedSubtree(
    key: ValueKey(generation),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
  Widget chips(List<Widget> children) =>
      Wrap(spacing: Gaps.s, runSpacing: Gaps.s, children: children);
  return [
    DemoSection(
      title: 'Asset',
      summary: o.publicId,
      child: column([
        menu<String>(
          'Public ID',
          o.publicId,
          samplePublicIds,
          (id) => id,
          (id) => onChanged(o.copyWith(publicId: id)),
        ),
      ]),
    ),
    DemoSection(
      title: 'Resize and crop',
      summary: [
        o.crop.name,
        if (usesGravity(o.crop)) 'gravity ${o.gravity.name}',
        '${o.width} px',
        o.ratio,
      ].join(' · '),
      child: column([
        pair(
          menu<CropMode>(
            'Crop',
            o.crop,
            cropModes,
            (c) => c.name,
            (c) => onChanged(o.copyWith(crop: c)),
          ),
          menu<Gravity>(
            'Gravity',
            o.gravity,
            gravities,
            (g) => g.name,
            (g) => onChanged(o.copyWith(gravity: g)),
            enabled: usesGravity(o.crop),
          ),
        ),
        const SizedBox(height: Gaps.m),
        Text('Width ${o.width} px'),
        Slider(
          value: o.width.toDouble(),
          min: 200,
          max: 1600,
          divisions: 14,
          onChanged: (v) => onChanged(o.copyWith(width: v.round())),
        ),
        Labelled(
          label: 'Aspect ratio',
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final r in ratios)
                ButtonSegment(value: r, label: segmentLabel(r)),
            ],
            selected: {o.ratio},
            onSelectionChanged: (s) => onChanged(o.copyWith(ratio: s.single)),
          ),
        ),
      ]),
    ),
    DemoSection(
      title: 'Look',
      summary: [
        o.effect?.name ?? 'no effect',
        'quality ${o.quality.name}',
        o.format.name,
        if (o.rounded) 'round',
        if (o.rotated) 'rotated',
      ].join(' · '),
      child: column([
        pair(
          menu<Effect?>(
            'Effect',
            o.effect,
            [null, ...effects],
            (e) => e?.name ?? 'none',
            (e) => onChanged(o.copyWith(effect: () => e)),
          ),
          menu<Quality>(
            'Quality',
            o.quality,
            qualities,
            (q) => q.name,
            (q) => onChanged(o.copyWith(quality: q)),
          ),
        ),
        const SizedBox(height: Gaps.m),
        Labelled(
          label: 'Format',
          child: SegmentedButton<DeliveryFormat>(
            showSelectedIcon: false,
            segments: [
              for (final f in formats)
                ButtonSegment(value: f, label: segmentLabel(f.name)),
            ],
            selected: {o.format},
            onSelectionChanged: (s) => onChanged(o.copyWith(format: s.single)),
          ),
        ),
        const SizedBox(height: Gaps.m),
        chips([
          toggle('Round', o.rounded, (v) => o.copyWith(rounded: v)),
          toggle('Rotate 90°', o.rotated, (v) => o.copyWith(rotated: v)),
        ]),
      ]),
    ),
    DemoSection(
      title: 'Delivery',
      summary: [
        if (o.cdnSubdomain) 'CDN subdomain',
        if (o.shorten) 'short URL',
        if (!o.cdnSubdomain && !o.shorten) 'standard URL',
      ].join(' · '),
      child: chips([
        toggle(
          'CDN subdomain',
          o.cdnSubdomain,
          (v) => o.copyWith(cdnSubdomain: v),
        ),
        toggle('Short URL', o.shorten, (v) => o.copyWith(shorten: v)),
      ]),
    ),
  ];
}
