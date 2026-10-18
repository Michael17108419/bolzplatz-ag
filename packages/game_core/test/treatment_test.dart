import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10e6: a minute off after treatment (not the keeper) and
// the ten-second change of a leading team.

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

  test('treatments: keepers stay, others a minute off; slow changes only by '
      'a leading team late on (report)', () {
    var treatments = 0;
    var keepers = 0;
    var slow = 0;
    const games = 300;
    for (var i = 0; i < games; i++) {
      final r = MatchEngine(rules).simulate(
        tier1[i % tier1.length],
        tier1[(i * 7 + 2) % tier1.length],
        seed: 8000 + i,
      );
      for (final e in r.events) {
        if (e.type == MatchEventType.treatment) {
          treatments++;
          final keeper = tier1
              .expand((t) => t.squad)
              .firstWhere((p) => p.id == e.player)
              .position
              .isGoalkeeper;
          expect(e.value, keeper ? 0 : 1);
          if (keeper) keepers++;
        }
        if (e.type == MatchEventType.timeWasting &&
            e.action == 'sub_ten_seconds') {
          slow++;
          final lead = e.side == 0
              ? e.homeGoals - e.awayGoals
              : e.awayGoals - e.homeGoals;
          expect(lead, greaterThan(0));
          expect(
            e.minute,
            greaterThanOrEqualTo(rules.match.timeWasting.fromMinute),
          );
        }
      }
    }
    stdout.writeln(
      'TREATMENT-REPORT treatments/game=${(treatments / games).toStringAsFixed(2)} '
      'keepers=$keepers slow changes=$slow in $games games',
    );
    expect(treatments / games, inInclusiveRange(0.8, 2.5));
  });
}
