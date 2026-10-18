import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Temporary (step 10h3): where the time of a season goes.

void main() {
  test('timing', () {
    final rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    final world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    final teams = [
      for (final club in world.clubs)
        if (club.leagueId == top)
          for (final auto in [true, false])
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
                autoManage: auto,
              );
            }(),
    ];
    final ai = [for (var i = 0; i < teams.length; i += 2) teams[i]];
    final plain = [for (var i = 1; i < teams.length; i += 2) teams[i]];
    for (final (name, list) in [('ai', ai), ('plain', plain), ('ai2', ai)]) {
      final w = Stopwatch()..start();
      for (var i = 0; i < 300; i++) {
        MatchEngine(rules).simulate(
          list[i % list.length],
          list[(i * 7 + 3) % list.length],
          seed: i,
        );
      }
      stdout.writeln('PERF $name 300 matches ${w.elapsedMilliseconds} ms');
    }
    final w = Stopwatch()..start();
    final strengths = <double>[];
    for (var k = 0; k < 20; k++) {
      for (final p in world.players.take(5000)) {
        strengths.add(WorldReport.overall(p, rules));
      }
    }
    stdout.writeln(
      'PERF overall x${strengths.length} ${w.elapsedMilliseconds} ms',
    );
  });
}
