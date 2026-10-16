import 'dart:io';

import 'package:bolzplatz_app/game/loaded_world.dart';
import 'package:bolzplatz_app/game/stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

LoadedWorld _load() => LoadedWorld.fromTexts(
  File('../data/world_2026_27.json').readAsStringSync(),
  File('../rules/rules_2026_27.json').readAsStringSync(),
  File('../data/names_de.json').readAsStringSync(),
  File('../rules/calendar_rules.json').readAsStringSync(),
);

void main() {
  final loaded = _load();

  test('the zones match the movements of the pyramid', () {
    TableZone z(int level, int n, int place) =>
        zoneOf(level: level, teamCount: n, place: place);
    // First league: last two down, 16th in the play-off.
    expect(z(1, 18, 1), TableZone.none);
    expect(z(1, 18, 16), TableZone.playoffDown);
    expect(z(1, 18, 17), TableZone.relegation);
    expect(z(1, 18, 18), TableZone.relegation);
    // Second league: two up, third in the play-off, 16th play-off, 17/18 down.
    expect(z(2, 18, 2), TableZone.promotion);
    expect(z(2, 18, 3), TableZone.playoffUp);
    expect(z(2, 18, 16), TableZone.playoffDown);
    expect(z(2, 18, 17), TableZone.relegation);
    // Third league has 20 clubs: the last four go down.
    expect(z(3, 20, 2), TableZone.promotion);
    expect(z(3, 20, 3), TableZone.playoffUp);
    expect(z(3, 20, 16), TableZone.none);
    expect(z(3, 20, 17), TableZone.relegation);
    // Fourth league: the champion may go up, the last four go down.
    expect(z(4, 18, 1), TableZone.chance);
    expect(z(4, 18, 14), TableZone.none);
    expect(z(4, 18, 15), TableZone.relegation);
  });

  test('the start state has all eight leagues with empty tables', () {
    final stats = SeasonStats.start(loaded);
    expect(stats.isForecast, isTrue);
    expect(stats.leagues.length, 8);
    expect(stats.bolzplatz, isNull);
    expect(stats.goals, isEmpty);
    var clubs = 0;
    for (final l in stats.leagues) {
      final rows = stats.tables[l.id]!;
      expect(rows.length, l.teamCount, reason: l.name);
      expect(rows.every((e) => e.played == 0 && e.points == 0), isTrue);
      // Strongest club first.
      final strengths = [for (final e in rows) loaded.strengths[e.club]!];
      expect(
        strengths,
        orderedEquals([...strengths]..sort((a, b) => b.compareTo(a))),
      );
      clubs += rows.length;
    }
    // 146 clubs play in the eight leagues, the rest waits in the pools.
    expect(clubs, 146);
  });

  test('a played season fills tables, cup and scorer lists', () {
    final seasons = loaded.world.leagueSeasons;
    final tables = <LeagueId, List<TableEntry>>{};
    for (final ls in seasons) {
      final t = LeagueTable(ls.clubIds);
      // The first club wins every match against the others once.
      final first = ls.clubIds.first;
      for (final other in ls.clubIds.skip(1)) {
        t.record(first, other, 2, 0);
      }
      tables[ls.league.id] = t.standing;
    }
    int tierOf(ClubId c) =>
        seasons.firstWhere((ls) => ls.clubIds.contains(c)).league.level;
    final top = [
      for (final ls in seasons.where((ls) => ls.league.level <= 2))
        ...ls.clubIds,
    ];
    final lower = [
      for (final ls in seasons.where((ls) => ls.league.level >= 3))
        ...ls.clubIds,
    ].take(28).toList();
    final cup = KnockoutCup.bolzplatz(
      top: top,
      lower: lower,
      tier: tierOf,
      rng: SeededRandom(7),
    );
    while (!cup.isFinished) {
      cup.playNextRound((home, away) => home);
    }
    final players = loaded.world.players.take(30).toList();
    final outcome = SeasonOutcome(
      tables: tables,
      bolzplatz: cup,
      pottWinners: {Region.nord: top.first},
      pottQualifiers: const [],
      matchesPlayed: 0,
      goalsScored: 0,
      homeWins: 0,
      draws: 0,
      awayWins: 0,
      goalsByPlayer: const {},
      injuries: 0,
      redCards: 0,
      yellowCards: 0,
      minutesByPlayer: const {},
      shots: 0,
      leagueGoalsByPlayer: {
        for (var i = 0; i < players.length; i++) players[i].id: i % 7,
      },
      leagueAssistsByPlayer: {players[3].id: 5, players[4].id: 2},
    );
    final stats = SeasonStats.fromOutcome(loaded, outcome, matchday: 34);
    expect(stats.isForecast, isFalse);
    expect(stats.bolzplatz!.rounds.length, 6);
    expect(stats.pottWinners[Region.nord], top.first);
    // Sorted by goals, then no zero entries; at most 20 rows.
    final goals = [for (final r in stats.goals) r.count];
    expect(goals, orderedEquals([...goals]..sort((a, b) => b.compareTo(a))));
    expect(goals.every((g) => g > 0), isTrue);
    expect(stats.goals.length, lessThanOrEqualTo(20));
    expect(stats.assists.map((r) => r.count), [5, 2]);
    // The champion leads his table.
    final l1 = seasons.first.league.id;
    expect(stats.tables[l1]!.first.club, seasons.first.clubIds.first);
  });
}
