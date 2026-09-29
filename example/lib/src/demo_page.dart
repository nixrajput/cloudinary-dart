import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'admin_tour.dart';
import 'app_theme.dart';
import 'config_section.dart';
import 'errors_section.dart';
import 'logo_mark.dart';
import 'preview.dart';
import 'scroll_forwarder.dart';
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
  final _list = ScrollController();
  var _options = const UrlOptions();

  void _update(UrlOptions next) => setState(() => _options = next);

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Options and preview must both stay in view. With room or in landscape
    // both are pinned side by side above one list; on a portrait phone the
    // preview is pinned and the options lead the list under it.
    final twoPane = size.width >= Gaps.twoPane || size.width > size.height;
    final maxWidth = twoPane ? Gaps.maxWideWidth : Gaps.maxWidth;
    final side = math.max(Gaps.m, (size.width - maxWidth) / 2);
    final showCode = twoPane && size.height >= Gaps.codeInPreview;
    // A fifth of the height on a short screen, so the pinned preview and the
    // wrapped URL under it still fit whole.
    final imageHeight = twoPane && size.height >= Gaps.tallEnough
        ? 320.0
        : (size.height / 5).clamp(64.0, 120.0);
    final preview = UrlPreview(
      options: _options,
      imageHeight: imageHeight,
      showCode: showCode,
    );
    return Scaffold(
      appBar: AppBar(
        titleSpacing: side,
        // Scales down rather than overflowing beside the theme switch on a
        // narrow phone or with a large text size.
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LogoMark(size: 28),
              SizedBox(width: Gaps.s + Gaps.s / 2),
              Text('cloudinary'),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: side),
            child: ThemeModeSwitch(
              mode: widget.themeMode,
              onChanged: widget.onThemeModeChanged,
            ),
          ),
        ],
      ),
      // An explicit ListView padding drops the device insets, so SafeArea
      // restores them; without it the last card sits under the home bar.
      body: SafeArea(
        top: false,
        // The wheel over the pinned preview scrolls the list too.
        child: ScrollForwarder(
          controller: _list,
          child: twoPane
              ? _twoPane(side, preview, !showCode)
              : _onePane(side, preview),
        ),
      ),
    );
  }

  Widget _twoPane(double side, Widget preview, bool withCode) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final list = EdgeInsets.fromLTRB(side, Gaps.s, Gaps.s, Gaps.l);
            // Pinned like the preview only when the options fit whole and the
            // list keeps room; a half-hidden card reads as broken.
            final room =
                Gaps.pinOptions * MediaQuery.textScalerOf(context).scale(1);
            if (constraints.maxHeight < room) {
              return _content(list, withCode: withCode);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(side, Gaps.s, Gaps.s, Gaps.s),
                  child: _optionsCard(),
                ),
                Expanded(
                  child: _content(list, withOptions: false, withCode: withCode),
                ),
              ],
            );
          },
        ),
      ),
      Expanded(
        // Scrolls only when the preview is taller than the screen.
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(Gaps.s, Gaps.s, side, Gaps.l),
          child: preview,
        ),
      ),
    ],
  );

  Widget _onePane(double side, Widget preview) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(side, Gaps.s, side, Gaps.s),
        child: preview,
      ),
      Expanded(
        child: _content(
          EdgeInsets.fromLTRB(side, Gaps.s, side, Gaps.l),
          withCode: true,
        ),
      ),
    ],
  );

  /// Everything that is not pinned, in the one list that scrolls.
  Widget _content(
    EdgeInsets padding, {
    bool withOptions = true,
    bool withCode = false,
  }) => ListView(
    controller: _list,
    padding: padding,
    children: [
      if (withOptions) ...[_optionsCard(), const SizedBox(height: Gaps.m)],
      // A preview without its code leaves it to the list.
      if (withCode) ...[_codeCard(), const SizedBox(height: Gaps.m)],
      const UploadSection(),
      const SizedBox(height: Gaps.m),
      const SigningSection(),
      const SizedBox(height: Gaps.m),
      const SearchSection(),
      const SizedBox(height: Gaps.m),
      const AdminTour(),
      const SizedBox(height: Gaps.m),
      const ConfigSection(),
      const SizedBox(height: Gaps.m),
      const ErrorsSection(),
    ],
  );

  Widget _optionsCard() => Section(
    title: 'Options',
    child: OptionsPanel(options: _options, onChanged: _update),
  );

  Widget _codeCard() => Section(
    title: 'Code',
    subtitle: 'The Dart that builds the preview URL.',
    child: CodeBlock(_options.dartCode, label: 'the code'),
  );
}
