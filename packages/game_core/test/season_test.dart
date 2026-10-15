import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

late Rules rules;
late World world;

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
  });

  test('leagueSchedule is the schedule the season is played with', () {
    final clubs = [for (var i = 1; i <= 18; i++) ClubId(i)];
    final a = SeasonRunner.leagueSchedule(clubs, const LeagueId(3), 77);
    final b = SeasonRunner.leagueSchedule(clubs, const LeagueId(3), 77);
    final other = SeasonRunner.leagueSchedule(clubs, const LeagueId(4), 77);
    expect(a, hasLength(34));
    for (var d = 0; d < a.length; d++) {
      for (var i = 0; i < a[d].length; i++) {
        expect(a[d][i].home, b[d][i].home);
        expect(a[d][i].away, b[d][i].away);
      }
    }
    final same = [
      for (var i = 0; i < 9; i++)
        a[0][i].home == other[0][i].home && a[0][i].away == other[0][i].away,
    ];
    expect(same.every((x) => x), isFalse);
  });

  test('double round robin: everyone plays everyone twice, home and away', () {
    final clubs = [for (var i = 1; i <= 18; i++) ClubId(i)];
    final days = Schedule.doubleRoundRobin(clubs, SeededRandom(5));
    expect(days, hasLength(34));
    final pairs = <(int, int)>{};
    for (final day in days) {
      expect(day, hasLength(9));
      final seen = <ClubId>{};
      for (final f in day) {
        expect(seen.add(f.home), isTrue);
        expect(seen.add(f.away), isTrue);
        pairs.add((f.home.value, f.away.value));
      }
    }
    expect(pairs, hasLength(18 * 17));
    for (final c in clubs) {
      var homeRun = 0;
      var maxRun = 0;
      for (final day in days.take(17)) {
        final home = day.any((f) => f.home == c);
        homeRun = home
            ? (homeRun >= 0 ? homeRun + 1 : 1)
            : (homeRun <= 0 ? homeRun - 1 : -1);
        maxRun = homeRun.abs() > maxRun ? homeRun.abs() : maxRun;
      }
      expect(maxRun <= 2, isTrue, reason: 'club ${c.value}');
    }
  });

  test('league table orders by points, goal difference, goals', () {
    const one = ClubId(1);
    const two = ClubId(2);
    const three = ClubId(3);
    final t = LeagueTable(const [one, two, three])
      ..record(one, two, 2, 0)
      ..record(two, three, 1, 1)
      ..record(three, one, 0, 0);
    final order = t.order.map((c) => c.value).toList();
    expect(order, [1, 3, 2]);
    expect(t.entryOf(one).points, 4);
  });

  test('a full season of all leagues and cups runs and is consistent', () {
    final state = SeasonState.fromWorld(world);
    final runner = SeasonRunner(rules);
    final watch = Stopwatch()..start();
    final outcome = runner.play(state, seed: 11);
    watch.stop();
    // 306 + 306 + 380 + 5 * 306 league matches.
    expect(outcome.matchesPlayed, 2522);
    for (final e in outcome.tables.entries) {
      final n = e.value.length;
      for (final row in e.value) {
        expect(row.played, (n - 1) * 2);
      }
      expect(
        e.value.fold<int>(0, (s, r) => s + r.goalsFor),
        e.value.fold<int>(0, (s, r) => s + r.goalsAgainst),
      );
    }
    expect(outcome.bolzplatz.isFinished, isTrue);
    expect(outcome.bolzplatz.rounds.map((r) => r.length), [32, 16, 8, 4, 2, 1]);
    expect(outcome.pottWinners, hasLength(5));
    expect(outcome.pottQualifiers.length >= 24, isTrue);
    expect(
      outcome.pottQualifiers.toSet(),
      hasLength(outcome.pottQualifiers.length),
    );
    stdout.writeln(
      'SEASON-REPORT one season ${watch.elapsedMilliseconds} ms, '
      'goals/game ${(outcome.goalsScored / outcome.matchesPlayed).toStringAsFixed(2)}, '
      'injuries ${outcome.injuries}, reds ${outcome.redCards}',
    );
  });

  test('the same seed gives the same season', () {
    final state = SeasonState.fromWorld(world);
    final runner = SeasonRunner(rules);
    final a = runner.play(state, seed: 3);
    final b = runner.play(state, seed: 3);
    final league1 = LeagueId(rules.leagues.firstWhere((l) => l.level == 1).id);
    expect(a.standing(league1), b.standing(league1));
    expect(a.goalsScored, b.goalsScored);
    expect(a.bolzplatz.winner, b.bolzplatz.winner);
  });

  test('three seasons in a row keep the league sizes', () {
    var state = SeasonState.fromWorld(world);
    final runner = SeasonRunner(rules);
    for (var year = 0; year < 3; year++) {
      final outcome = runner.play(state, seed: 100 + year);
      final next = runner.nextSeason(state, outcome, seed: 200 + year);
      expect(next.errorOrNull, isNull, reason: 'year $year');
      state = next.valueOrNull!;
      for (final l in rules.leagues) {
        expect(
          state.members[LeagueId(l.id)],
          hasLength(l.teamCount),
          reason: '${l.key} in year $year',
        );
      }
      final all = [for (final m in state.members.values) ...m];
      expect(all.toSet(), hasLength(all.length));
      expect(all, hasLength(146));
      expect(state.startYear, 2027 + year);
      expect(state.pottQualifiers.length >= 24, isTrue);
    }
  });
}
