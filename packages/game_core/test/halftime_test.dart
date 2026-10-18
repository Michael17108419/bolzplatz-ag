import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10g3: the half-time analysis.

late Rules rules;
late List<MatchTeam> tier1;

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    final world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    tier1 = [
      for (final club in world.clubs)
        if (club.leagueId == top)
          () {
            final squad = [
              for (final p in world.players)
                if (p.clubId == club.id) p,
            ];
            return MatchTeam(
              clubId: club.id,
              name: club.name,
              squad: squad,
              sheet: AutoManager(rules).build(squad)!,
              autoManage: false,
            );
          }(),
    ];
  });

  MatchSession atBreak(int i) {
    final s = MatchSession(
      rules: rules,
      home: tier1[i % tier1.length],
      away: tier1[(i * 7 + 3) % tier1.length],
      seed: 5500 + i,
    );
    while (!(s.inBreak && s.minute > 0)) {
      s.advanceTo(s.minute + 1);
    }
    return s;
  }

  test('the analysis counts the half, a top assistant says more and never '
      'errs, a weak one errs now and then; fixes apply (report)', () {
    final kinds = <HalfNoteKind, int>{};
    var wrongTop = 0;
    var wrongPoor = 0;
    var notesTop = 0;
    var notesPoor = 0;
    var fixes = 0;
    for (var i = 0; i < 80; i++) {
      if (i % tier1.length == (i * 7 + 3) % tier1.length) continue;
      final s = atBreak(i);
      final top = s.halfTimeReport(0, tactics: 100, seed: i);
      final poor = s.halfTimeReport(0, tactics: 0, seed: i);
      expect(top.duels, greaterThan(0));
      expect(top.duelsWon, lessThanOrEqualTo(top.duels));
      expect(top.notes.length, lessThanOrEqualTo(3));
      expect(poor.notes.length, lessThanOrEqualTo(1));
      notesTop += top.notes.length;
      notesPoor += poor.notes.length;
      wrongTop += top.notes.where((n) => !n.real).length;
      wrongPoor += poor.notes.where((n) => !n.real).length;
      for (final n in top.notes) {
        kinds[n.kind] = (kinds[n.kind] ?? 0) + 1;
        final fix = n.fix;
        if (fix != null) {
          final before = s.actions.length;
          fix.applyTo(s);
          if (s.actions.length > before) fixes++;
        }
      }
    }
    stdout.writeln(
      'HALF-REPORT notes top=$notesTop (wrong $wrongTop) poor=$notesPoor '
      '(wrong $wrongPoor) fixes applied=$fixes kinds=$kinds',
    );
    expect(wrongTop, 0);
    expect(notesTop, greaterThan(notesPoor));
    expect(fixes, greaterThan(0));
  });
}
