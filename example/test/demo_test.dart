import 'package:cloudinary/cloudinary.dart';
import 'package:cloudinary_example/src/config_section.dart';
import 'package:cloudinary_example/src/errors_section.dart';
import 'package:cloudinary_example/src/signing_section.dart';
import 'package:cloudinary_example/src/url_playground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpSection(WidgetTester tester, Widget section) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 3000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: section)),
    ),
  );
}

void main() {
  group('the URL playground', () {
    test('builds the default URL on the demo cloud', () {
      expect(
        const UrlOptions().url,
        'https://res.cloudinary.com/demo/image/upload/'
        'ar_4:3,c_fill,f_auto,g_auto,q_auto,w_800/sample',
      );
    });

    test('drops gravity for a crop mode that does not use it', () {
      final url = const UrlOptions().copyWith(crop: CropMode.fit).url;
      expect(url, contains('c_fit'));
      expect(url, isNot(contains('g_')));
    });

    test('pads with an automatic background colour', () {
      expect(
        const UrlOptions().copyWith(crop: CropMode.pad).url,
        contains('b_auto'),
      );
    });

    test('clears the effect when none is chosen', () {
      final sepia = const UrlOptions().copyWith(effect: () => Effect.sepia);
      expect(sepia.url, contains('e_sepia'));
      expect(sepia.copyWith(effect: () => null).url, isNot(contains('e_')));
    });

    test('shows the Dart that builds the same URL', () {
      final options = const UrlOptions().copyWith(
        effect: () => Effect.grayscale,
        shorten: true,
      );
      expect(options.url, startsWith('https://res.cloudinary.com/demo/iu/'));
      expect(options.dartCode, contains('urlConfig: UrlConfig(shorten: true)'));
      expect(options.dartCode, contains('..effect(Effect.grayscale)'));
      expect(options.dartCode, contains(".image('sample')"));
    });
  });

  testWidgets('webhook verification fails once the body is tampered with', (
    tester,
  ) async {
    await pumpSection(tester, const SigningSection());
    expect(find.textContaining('Signature valid'), findsOneWidget);

    await tester.tap(find.text('Tamper with the body'));
    await tester.pump();
    expect(find.textContaining('Signature invalid'), findsOneWidget);
  });

  testWidgets('version 1 signs the ampersand bare, version 2 escapes it', (
    tester,
  ) async {
    await pumpSection(tester, const SigningSection());
    expect(find.textContaining('Fish %26 chips'), findsOneWidget);

    await tester.tap(find.text('Version 1'));
    await tester.pump();
    expect(find.textContaining('caption=Fish & chips'), findsOneWidget);
  });

  testWidgets('a CLOUDINARY_URL parses, and the secret stays redacted', (
    tester,
  ) async {
    await pumpSection(tester, const ConfigSection());
    expect(find.text('demo'), findsOneWidget);
    expect(find.textContaining('<redacted>'), findsOneWidget);
    expect(find.textContaining('throwaway-demo-secret'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'not a url');
    await tester.pump();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('a real configuration error is caught and shown', (tester) async {
    await pumpSection(tester, const ErrorsSection());
    await tester.tap(find.text('Empty cloud name'));
    await tester.pump();
    expect(
      find.textContaining('CloudinaryConfigException: cloudName'),
      findsOneWidget,
    );

    await tester.tap(find.text('Token without an ACL'));
    await tester.pump();
    expect(
      find.textContaining('CloudinarySignatureException: An auth token'),
      findsOneWidget,
    );
  });
}
