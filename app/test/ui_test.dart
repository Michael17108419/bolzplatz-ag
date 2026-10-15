import 'dart:io';

import 'package:bolzplatz_app/game/loaded_world.dart';
import 'package:bolzplatz_app/game/settings.dart';
import 'package:bolzplatz_app/ui/info_button.dart';
import 'package:bolzplatz_app/main.dart';
import 'package:bolzplatz_app/ui/logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _start(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        worldLoaderProvider.overrideWithValue(
          () async => LoadedWorld.fromTexts(
            File('../data/world_2026_27.json').readAsStringSync(),
            File('../rules/rules_2026_27.json').readAsStringSync(),
            File('../data/names_de.json').readAsStringSync(),
          ),
        ),
      ],
      child: const BolzplatzApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the main menu shows the logo and four entries', (tester) async {
    await _start(tester);
    expect(find.byType(BolzplatzLogo), findsOneWidget);
    expect(find.text('Neues Spiel'), findsOneWidget);
    expect(find.text('Spiel laden'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Beenden'), findsOneWidget);
  });

  testWidgets('settings open and Esc goes back', (tester) async {
    await _start(tester);
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    expect(find.text('Tastaturkürzel'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Neues Spiel'), findsOneWidget);
  });

  testWidgets('the helps can be switched off in the settings', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _start(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BolzplatzApp)),
    );
    expect(container.read(helpProvider), isTrue);
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('help-switch')));
    await tester.pumpAndSettle();
    expect(container.read(helpProvider), isFalse);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: InfoButton(message: 'Test')),
        ),
      ),
    );
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('a career is started through the five steps', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _start(tester);
    await tester.tap(find.text('Neues Spiel'));
    await tester.pumpAndSettle();
    // Step 1: the trainer needs a name.
    final next = find.byKey(const ValueKey('step-next'));
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Uschi Muster');
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    // Step 2: glasses and clothes.
    await tester.tap(find.byKey(const ValueKey('outfit-4')));
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    // Step 3: a backstory.
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('story-pe_teacher')));
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    // Step 4: no wish club.
    await tester.tap(next);
    await tester.pumpAndSettle();
    // Step 5: offers; take the first.
    expect(find.byKey(const ValueKey('offer-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('offer-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('president-portrait')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('offer-accept')));
    await tester.pumpAndSettle();
    // The office: club, next match, and a mail that can be opened.
    expect(find.byKey(const ValueKey('office-club')), findsOneWidget);
    expect(find.byKey(const ValueKey('office-opponent')), findsOneWidget);
    expect(find.byKey(const ValueKey('office-trainer')), findsOneWidget);
    expect(find.byKey(const ValueKey('mail-subject')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('mail-president')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mail-subject')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('step-next')));
    await tester.pumpAndSettle();
    expect(find.text('Kommt in Bauabschnitt 7.'), findsOneWidget);
  });

  test('the app copies of world, rules and names equal the originals', () {
    for (final pair in const [
      ['assets/data/world_2026_27.json', '../data/world_2026_27.json'],
      ['assets/data/rules_2026_27.json', '../rules/rules_2026_27.json'],
      ['assets/data/names_de.json', '../data/names_de.json'],
    ]) {
      expect(
        File(pair[0]).readAsStringSync().replaceAll('\r\n', '\n'),
        File(pair[1]).readAsStringSync().replaceAll('\r\n', '\n'),
        reason: '${pair[0]} is out of date, copy it from ${pair[1]}',
      );
    }
  });
}
