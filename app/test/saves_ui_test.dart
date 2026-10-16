import 'dart:io';

import 'package:bolzplatz_app/game/loaded_world.dart';
import 'package:bolzplatz_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Spiel laden shows the four slots, all empty at first', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldLoaderProvider.overrideWithValue(
            () async => LoadedWorld.fromTexts(
              File('../data/world_2026_27.json').readAsStringSync(),
              File('../rules/rules_2026_27.json').readAsStringSync(),
              File('../data/names_de.json').readAsStringSync(),
              File('../rules/calendar_rules.json').readAsStringSync(),
            ),
          ),
        ],
        child: const BolzplatzApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spiel laden'));
    await tester.pumpAndSettle();
    expect(find.text('Spielstände'), findsWidgets);
    for (final slot in ['auto', '1', '2', '3']) {
      expect(find.byKey(ValueKey('save-slot-$slot')), findsOneWidget);
    }
    expect(find.textContaining('Noch kein Spielstand'), findsOneWidget);
    expect(find.byKey(const ValueKey('load-btn-1')), findsNothing);
    expect(find.byKey(const ValueKey('save-btn-1')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('saves-back')));
    await tester.pumpAndSettle();
    expect(find.text('Neues Spiel'), findsOneWidget);
  });
}
