import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10g2: opponent analysis and match plan.

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
            );
          }(),
    ];
  });

  MatchSession make(int i) => MatchSession(
    rules: rules,
    home: tier1[i % tier1.length],
    away: tier1[(i * 7 + 3) % tier1.length],
    seed: 6600 + i,
  );

  test('a top analyst sees only real weaknesses, a poor one also ghosts; '
      'the same seed shows the same notes (report)', () {
    var ghostsTop = 0;
    var ghostsPoor = 0;
    var notesTop = 0;
    var notesPoor = 0;
    for (var i = 0; i < 60; i++) {
      final s = make(i);
      final top = s.scout(0, tactics: 100, seed: i);
      final poor = s.scout(0, tactics: 5, seed: i);
      notesTop += top.length;
      notesPoor += poor.length;
      ghostsTop += top.where((n) => !n.real).length;
      ghostsPoor += poor.where((n) => !n.real).length;
      expect(top.length, lessThanOrEqualTo(5));
      expect(poor.length, lessThanOrEqualTo(2));
      expect(
        [for (final n in s.scout(0, tactics: 5, seed: i)) n.focus],
        [for (final n in poor) n.focus],
      );
    }
    stdout.writeln(
      'PLAN-REPORT notes top=$notesTop (ghosts $ghostsTop) '
      'poor=$notesPoor (ghosts $ghostsPoor) in 60 matches',
    );
    expect(ghostsTop, 0);
    expect(ghostsPoor, greaterThan(0));
    expect(notesTop, greaterThan(notesPoor));
  });

  test('a plan on a real weakness pays, one on a ghost costs (report)', () {
    var hit = 0;
    var none = 0;
    var miss = 0;
    var games = 0;
    for (var i = 0; i < 300; i++) {
      if (i % tier1.length == (i * 7 + 3) % tier1.length) continue;
      final probe = make(i);
      final real = probe.scout(0, tactics: 100, seed: i);
      if (real.isEmpty) continue;
      final ghost = PlanFocus.values.where(
        (f) => !real.any((n) => n.focus == f),
      );
      if (ghost.isEmpty) continue;
      games++;
      int diff(List<PlanFocus> plan) {
        final s = make(i)..setPlan(0, plan);
        final r = s.finish();
        return r.homeGoals - r.awayGoals;
      }

      hit += diff([real.first.focus]);
      none += diff(const []);
      miss += diff([ghost.first]);
    }
    stdout.writeln(
      'PLAN-REPORT goal difference hit=$hit none=$none miss=$miss '
      '($games games)',
    );
    expect(games, greaterThan(100));
    expect(hit, greaterThan(miss));
    expect(hit, greaterThanOrEqualTo(none));
  });

  test('the plan is set before kick-off only, two points at most, and '
      'replays the same', () {
    final s = make(1);
    s.setPlan(0, PlanFocus.values);
    expect(s.actions.single.plan, hasLength(2));
    expect(
      s.events.where((e) => e.type == MatchEventType.matchPlan),
      hasLength(1),
    );
    final json = [for (final a in s.actions) a.toJson()];
    s.advanceTo(10);
    s.setPlan(1, [PlanFocus.counter]);
    expect(s.actions, hasLength(1));
    final r = s.finish();
    final again = make(1)
      ..replay([for (final j in json) SessionAction.fromJson(j)]);
    final r2 = again.finish();
    expect(r2.homeGoals, r.homeGoals);
    expect(r2.awayGoals, r.awayGoals);
  });
}
