// Reads files from the repository, so it runs on the VM only.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

/// Guards the README's internal consistency, which drifts silently otherwise.
void main() {
  final raw = File('README.md').readAsStringSync();
  // A '#' inside a fence is a shell comment or a hex colour, not a heading.
  final body = raw.replaceAll(RegExp(r'```[\s\S]*?```'), '');

  String slug(String heading) => heading
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9 -]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');

  final headings = RegExp(
    r'^##+ (.+)$',
    multiLine: true,
  ).allMatches(body).map((m) => slug(m.group(1)!)).toSet();

  final tocLinks = RegExp(
    r'^\s*- \[[^\]]+\]\(#([^)]+)\)',
    multiLine: true,
  ).allMatches(body).map((m) => m.group(1)!).toSet();

  test('every table-of-contents entry points at a real heading', () {
    expect(
      tocLinks.difference(headings),
      isEmpty,
      reason: 'TOC entries with no matching heading',
    );
  });

  test('every heading appears in the table of contents', () {
    const exempt = {'table-of-contents'};
    expect(
      headings.difference(tocLinks).difference(exempt),
      isEmpty,
      reason: 'headings missing from the TOC',
    );
  });

  test('every link reference is defined and used', () {
    final defined = RegExp(
      r'^\[([^\]]+)\]:',
      multiLine: true,
    ).allMatches(raw).map((m) => m.group(1)!).toSet();
    final used = RegExp(r'\]\[([^\]]+)\]')
        .allMatches(raw)
        .map((m) => m.group(1)!)
        .toSet();

    expect(used.difference(defined), isEmpty, reason: 'undefined references');
    expect(defined.difference(used), isEmpty, reason: 'unused references');
  });

  test('no em-dashes', () {
    expect(raw.contains('\u2014'), isFalse); // em-dash
  });

  test('the claim row counts match reality', () {
    // Counts in the claim row are the only place these numbers live, so they
    // are checked rather than trusted.
    final methodCount = Directory('lib/src/api')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map(
          (f) => RegExp(
            r'^  Future<',
            multiLine: true,
          ).allMatches(f.readAsStringSync()).length,
        )
        .fold<int>(0, (a, b) => a + b);

    final claimed = RegExp(r'<b>(\d+) API methods</b>').firstMatch(raw);
    expect(claimed, isNotNull, reason: 'claim row lost its method count');
    expect(int.parse(claimed!.group(1)!), methodCount);
  });

  test('the claimed test count matches the suite', () {
    // The claim row is the only place this number lives, and it silently
    // drifted once already.
    final declared = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map(
          (f) => RegExp(
            r'^\s+test\(',
            multiLine: true,
          ).allMatches(f.readAsStringSync()).length,
        )
        .fold<int>(0, (a, b) => a + b);

    final claimed = RegExp(r'<b>(\d+) tests</b>').firstMatch(raw);
    expect(claimed, isNotNull, reason: 'claim row lost its test count');
    expect(int.parse(claimed!.group(1)!), declared);
  });

  test('every Dart block compiles: it appears in readme_snippets.dart', () {
    final snippets = File('test/readme_snippets.dart').readAsStringSync();
    final blocks = RegExp(r'```dart\n([\s\S]*?)```')
        .allMatches(raw)
        .map((m) => m.group(1)!)
        .where((b) => !b.startsWith('// v1'));
    expect(blocks, isNotEmpty);
    for (final block in blocks) {
      expect(snippets.contains(block.trimRight()), isTrue, reason: block);
    }
  });

  test('every link to a repository file is absolute and exists', () {
    // pub.dev drops relative links, so repository files are linked by URL.
    const blob = 'https://github.com/nixrajput/cloudinary-dart/blob/master/';
    for (final path in ['README.md', 'CHANGELOG.md', 'example/README.md']) {
      final text = File(path)
          .readAsStringSync()
          .replaceAll(RegExp(r'```[\s\S]*?```'), '');
      final targets = RegExp(r'\]\(([^)\s]+)\)|href="([^"]+)"')
          .allMatches(text)
          .map((m) => (m.group(1) ?? m.group(2))!)
          .where((t) => !t.startsWith('#') && !t.startsWith('mailto:'));
      for (final target in targets) {
        expect(target, contains('://'), reason: '$path links $target');
        if (target.startsWith(blob)) {
          final file = target.substring(blob.length).split('#').first;
          expect(
            File(file).existsSync(),
            isTrue,
            reason: '$path links $target',
          );
        }
      }
    }
  });
}
