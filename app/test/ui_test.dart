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
            File('../rules/calendar_rules.json').readAsStringSync(),
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
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('outfit-next')));
      await tester.pumpAndSettle();
    }
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
    // The office: the desk scene with club, badge and the things on it.
    expect(find.byKey(const ValueKey('office-play')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-day')), findsOneWidget);
    expect(find.byKey(const ValueKey('desk-door')), findsOneWidget);
    // The menu holds the club, the date and the trainer.
    await tester.tap(find.byKey(const ValueKey('office-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('office-club')), findsOneWidget);
    expect(find.byKey(const ValueKey('office-date')), findsOneWidget);
    expect(find.byKey(const ValueKey('office-trainer')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('badge-post')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );
    // A phone held upright: the room shows in three zones; the post and the
    // tactics board wait in the first one, so no mark points elsewhere.
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('office-zones')), findsOneWidget);
    expect(find.byKey(const ValueKey('zone-dot-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('desk-name-post')), findsOneWidget);
    expect(find.byKey(const ValueKey('zone-hint-left')), findsNothing);
    expect(find.byKey(const ValueKey('zone-hint-right')), findsNothing);
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('office-zones')), findsNothing);
    // The post: a mail can be opened and counts as read.
    await tester.tap(find.byKey(const ValueKey('desk-post')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mail-subject')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('mail-president')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mail-subject')), findsOneWidget);
    // The Jour Fix jumps to the calendar, which shows the next opponent.
    await tester.tap(find.byKey(const ValueKey('mail-jourfix')));
    await tester.pumpAndSettle();
    final toCalendar = find.byKey(const ValueKey('mail-go-calendar'));
    await tester.ensureVisible(toCalendar);
    await tester.tap(toCalendar);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('office-opponent')), findsOneWidget);
    // The number key 1 leads back to the post, Esc to the office.
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mail-president')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('badge-post')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    // The tactics board: pitch, role, swap, formation, "Passt so".
    expect(find.byKey(const ValueKey('badge-tactics')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lineup-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey('lineup-strength')), findsOneWidget);
    expect(find.byKey(const ValueKey('lineup-benchcount')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('slot-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lineup-slotcard')), findsOneWidget);
    final noRole = find.byKey(const ValueKey('lineup-role-none'));
    await tester.ensureVisible(noRole);
    await tester.pumpAndSettle();
    await tester.tap(noRole);
    await tester.pumpAndSettle();
    final candidate = find
        .byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('lineup-player-'),
        )
        .at(2);
    await tester.ensureVisible(candidate);
    await tester.pumpAndSettle();
    await tester.tap(candidate);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lineup-slotcard')), findsNothing);
    final tactics = find.byKey(const ValueKey('lineup-tab-0'));
    await tester.ensureVisible(tactics);
    await tester.pumpAndSettle();
    await tester.tap(tactics);
    await tester.pumpAndSettle();
    final formation = find.byKey(const ValueKey('lineup-formation-3-5-2'));
    await tester.ensureVisible(formation);
    await tester.pumpAndSettle();
    await tester.tap(formation);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('slot-10')), findsOneWidget);
    final confirm = find.byKey(const ValueKey('lineup-confirm'));
    if (confirm.evaluate().isNotEmpty) {
      await tester.ensureVisible(confirm);
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('lineup-confirmed')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('badge-tactics')), findsNothing);
    // The player files: squad list, filter, sort and a profile with tabs.
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('squad-count')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('squad-filter-goalkeepers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('squad-sort-age')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('squad-filter-all')));
    await tester.pumpAndSettle();
    final firstRow = find
        .byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('squad-') &&
              RegExp(r'^squad-\d+$')
                  .hasMatch((w.key! as ValueKey<String>).value),
        )
        .first;
    await tester.tap(firstRow);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-overall')), findsOneWidget);
    for (var i = 1; i < 5; i++) {
      await tester.tap(find.byKey(ValueKey('profile-tab-$i')));
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    // Statistics: tables of all leagues, the cups and the scorer lists.
    await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-table')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-forecast')), findsOneWidget);
    for (final id in [1, 5]) {
      final chip = find.byKey(ValueKey('stats-league-$id'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('stats-table')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('stats-tab-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-bolz-round-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-pott-nord')), findsOneWidget);
    expect(find.text('Noch nicht ausgelost.'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('stats-tab-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-scorers-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('stats-scorers-assists')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-scorers-empty')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    // The clock: the date is shown.
    expect(find.text('Mi 01.07.2026'), findsOneWidget);
    // The calendar shows the month with today marked.
    await tester.tap(find.byKey(const ValueKey('desk-calendar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cal-title')), findsOneWidget);
    expect(find.text('Juli 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('cal-day-2')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cal-next')));
    await tester.pumpAndSettle();
    expect(find.text('August 2026'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    // The door is "Weiter".
    await tester.tap(find.byKey(const ValueKey('desk-door')));
    await tester.pumpAndSettle();
    // Preview before the match.
    expect(
      find.byKey(const ValueKey('match-preview-strength')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('match-preview-lineup')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('step-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // Live: the minutes run, the speed can be changed, the match paused.
    expect(find.byKey(const ValueKey('match-score')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('match-speed-2')));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('match-ticker')), findsOneWidget);
    expect(find.byKey(const ValueKey('match-line-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('match-pause')));
    await tester.pump();
    // Conference: clock, matches of the league and the live table.
    await tester.tap(find.byKey(const ValueKey('match-view-conference')));
    await tester.pump();
    expect(find.byKey(const ValueKey('conf-clock')), findsOneWidget);
    expect(find.byKey(const ValueKey('conf-list')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('conf-match-'),
      ),
      findsWidgets,
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('conf-table-0')),
      find.byKey(const ValueKey('conf-list')),
      const Offset(0, -200),
    );
    expect(find.byKey(const ValueKey('conf-table-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('match-view-own')));
    await tester.pump();
    // Tactics: change the pressing, the ticker notes it.
    await tester.tap(find.byKey(const ValueKey('match-tactics')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('match-slider-pressing-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('match-dialog-close')));
    await tester.pumpAndSettle();
    // Substitution: first one who goes, then one who comes.
    await tester.tap(find.byKey(const ValueKey('match-subs')));
    await tester.pumpAndSettle();
    final off = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('match-sub-off-'),
    );
    expect(off, findsWidgets);
    // Pick an outfield player (the keeper stands first).
    await tester.tap(off.at(3));
    await tester.pumpAndSettle();
    final on = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('match-sub-on-'),
    );
    expect(on, findsWidgets);
    await tester.tap(find.byKey(const ValueKey('match-dialog-close')));
    await tester.pumpAndSettle();
    // Leaving in the middle of the match is blocked.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('match-score')), findsOneWidget);
    // Let the note disappear, it covers the buttons.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    // Skip to the end, then the report.
    await tester.tap(find.byKey(const ValueKey('match-skip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('match-report')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('report-score')), findsOneWidget);
    expect(find.byKey(const ValueKey('report-verdict')), findsOneWidget);
    // The table now shows a played matchday.
    await tester.tap(find.byKey(const ValueKey('report-table')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-forecast')), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-office')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('office-play')), findsOneWidget);
  });

  test('the app copies of world, rules and names equal the originals', () {
    for (final pair in const [
      ['assets/data/world_2026_27.json', '../data/world_2026_27.json'],
      ['assets/data/rules_2026_27.json', '../rules/rules_2026_27.json'],
      ['assets/data/names_de.json', '../data/names_de.json'],
      ['assets/data/calendar_rules.json', '../rules/calendar_rules.json'],
    ]) {
      expect(
        File(pair[0]).readAsStringSync().replaceAll('\r\n', '\n'),
        File(pair[1]).readAsStringSync().replaceAll('\r\n', '\n'),
        reason: '${pair[0]} is out of date, copy it from ${pair[1]}',
      );
    }
  });
}
