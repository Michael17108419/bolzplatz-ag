import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10d2: every step of an attack is kept for the reporter.

void main() {
  late Rules rules;
  late List<MatchTeam> tier1;

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

  test('shots, lost balls and counters carry the steps of the attack', () {
    final engine = MatchEngine(rules);
    const all =
        AttackStep.pressure |
        AttackStep.clear |
        AttackStep.close |
        AttackStep.pretty |
        AttackStep.fast;
    var steps = 0;
    var shots = 0;
    final flagCount = <int, int>{};
    for (var i = 0; i < 20; i++) {
      final home = tier1[i % tier1.length];
      final away = tier1[(i * 7 + 3) % tier1.length];
      if (home.clubId == away.clubId) continue;
      final r = engine.simulate(home, away, seed: 400 + i);
      final squads = [
        {for (final p in home.squad) p.id},
        {for (final p in away.squad) p.id},
      ];
      for (final e in r.events) {
        for (final s in e.steps) {
          expect(s.flags & ~all, 0);
          expect(s.column, inInclusiveRange(0, ZoneRules.columns - 2));
          expect(s.lane, inInclusiveRange(0, ZoneRules.lanes - 1));
          for (final f in [1, 2, 4, 8, 16]) {
            if (s.has(f)) flagCount[f] = (flagCount[f] ?? 0) + 1;
          }
        }
        if (e.type == MatchEventType.shot && e.quality != null) {
          shots++;
          steps += e.steps.length;
          expect(e.steps.every((s) => s.won), isTrue);
          for (final s in e.steps) {
            expect(squads[e.side], contains(s.player));
            expect(squads[1 - e.side], contains(s.opponent));
          }
        }
        if (e.type == MatchEventType.ballWon ||
            e.type == MatchEventType.counterAttack) {
          expect(e.steps, isNotEmpty);
          final last = e.steps.last;
          expect(last.won, isFalse);
          expect(last.player, e.otherPlayer);
          expect(last.opponent, e.player);
          expect(last.action, e.action);
        }
      }
    }
    stdout.writeln(
      'PROTOCOL-REPORT steps per open-play shot='
      '${(steps / shots).toStringAsFixed(2)} flags=$flagCount',
    );
    expect(shots, greaterThan(0));
  });
}
