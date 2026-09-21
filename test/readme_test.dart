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
    final used = RegExp(
      r'\]\[([^\]]+)\]',
    ).allMatches(raw).map((m) => m.group(1)!).toSet();

    expect(used.difference(defined), isEmpty, reason: 'undefined references');
    expect(defined.difference(used), isEmpty, reason: 'unused references');
  });

  test('no em-dashes', () {
    expect(raw.contains('—'), isFalse);
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

  test('the migration guide it links to exists', () {
    expect(File('MIGRATION.md').existsSync(), isTrue);
  });
}
