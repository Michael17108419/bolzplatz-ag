import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

late Rules rules;
late World world;
late Map<ClubId, MatchTeam> teams;
late Map<ClubId, int> tierOf;

MatchTeam _team(Club club, List<Player> squad) {
  final sheet = AutoManager(rules).build(squad)!;
  return MatchTeam(
    clubId: club.id,
    name: club.name,
    squad: squad,
    sheet: sheet,
  );
}

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    final levels = {for (final l in world.leagues) l.id: l.level};
    teams = {};
    tierOf = {};
    for (final club in world.clubs) {
      final squad = [
        for (final p in world.players)
          if (p.clubId == club.id) p,
      ];
      teams[club.id] = _team(club, squad);
      tierOf[club.id] = club.leagueId == null ? 5 : levels[club.leagueId]!;
    }
  });

  List<MatchTeam> byTier(int tier) => [
    for (final e in teams.entries)
      if (tierOf[e.key] == tier) e.value,
  ];

  test('every club gets a valid sheet with eleven players and a bench', () {
    for (final t in teams.values) {
      final formation = rules.tactics.formation(t.sheet.formationId);
      expect(t.sheet.startingXi, hasLength(11), reason: t.name);
      expect(t.sheet.startingXi.toSet(), hasLength(11), reason: t.name);
      expect(t.sheet.bench, hasLength(7), reason: t.name);
      expect(formation.slots, hasLength(11));
      final keeper = t.squad.firstWhere((p) => p.id == t.sheet.startingXi[0]);
      expect(keeper.position.isGoalkeeper, isTrue, reason: t.name);
    }
  });

  test('the same seed gives the same match, another seed another one', () {
    final home = byTier(1)[0];
    final away = byTier(1)[1];
    final engine = MatchEngine(rules);
    final a = engine.simulate(home, away, seed: 7);
    final b = engine.simulate(home, away, seed: 7);
    expect(a.homeGoals, b.homeGoals);
    expect(a.awayGoals, b.awayGoals);
    expect(a.events.length, b.events.length);
    var different = false;
    for (var seed = 8; seed < 30; seed++) {
      final c = engine.simulate(home, away, seed: seed);
      if (c.events.length != a.events.length ||
          c.homeGoals != a.homeGoals ||
          c.awayGoals != a.awayGoals) {
        different = true;
      }
    }
    expect(different, isTrue);
  });

  test('events are consistent with the result', () {
    final engine = MatchEngine(rules);
    for (var seed = 0; seed < 40; seed++) {
      final r = engine.simulate(byTier(2)[0], byTier(3)[1], seed: seed);
      var home = 0;
      var away = 0;
      var last = 0;
      for (final e in r.events) {
        expect(e.minute >= last, isTrue);
        last = e.minute;
        expect(e.minute >= 0 && e.minute <= 90, isTrue);
        if (e.isGoal) {
          if (e.side == 0) {
            home++;
          } else {
            away++;
          }
        }
      }
      expect(home, r.homeGoals);
      expect(away, r.awayGoals);
      expect(r.homeStats.goals, r.homeGoals);
      expect(r.events.first.type, MatchEventType.kickOff);
      expect(r.events.last.type, MatchEventType.fullTime);
      expect(r.homeStats.shotsOnTarget >= r.homeStats.goals, isTrue);
      expect(r.homeStats.shots >= r.homeStats.shotsOnTarget, isTrue);
    }
  });

  test('substitutions: limits and goalkeeper rule', () {
    final home = byTier(1)[2];
    final away = byTier(1)[3];
    final session = MatchSession(rules: rules, home: home, away: away, seed: 3)
      ..advanceTo(30);
    bool isKeeper(PlayerId id) =>
        home.squad.firstWhere((p) => p.id == id).position.isGoalkeeper;
    final onPitch = session.onPitch(0).toList();
    final keeperOff = onPitch.firstWhere(isKeeper);
    final fieldOff = onPitch.firstWhere((id) => !isKeeper(id));
    final bench = session.benchOf(0);
    final benchKeeper = bench.firstWhere(
      (id) => home.squad.firstWhere((p) => p.id == id).position.isGoalkeeper,
    );
    final benchField = bench.firstWhere(
      (id) => !home.squad.firstWhere((p) => p.id == id).position.isGoalkeeper,
    );
    expect(session.substitute(0, keeperOff, benchField), isFalse);
    expect(session.substitute(0, fieldOff, benchKeeper), isFalse);
    expect(session.substitute(0, fieldOff, benchField), isTrue);
    expect(session.onPitch(0), contains(benchField));
    expect(session.onPitch(0), isNot(contains(fieldOff)));
    final result = session.finish();
    expect(result.homeStats.substitutions >= 1, isTrue);
  });

  test('mass test: goals, results and strength (report)', () {
    final engine = MatchEngine(rules);
    final tier1 = byTier(1);
    var goals = 0;
    var shots = 0;
    var homeWins = 0;
    var draws = 0;
    var awayWins = 0;
    var zeroZero = 0;
    var yellows = 0;
    var reds = 0;
    var injuries = 0;
    var corners = 0;
    const games = 400;
    for (var i = 0; i < games; i++) {
      final h = tier1[i % tier1.length];
      final a = tier1[(i * 7 + 3) % tier1.length];
      if (h.clubId == a.clubId) continue;
      final r = engine.simulate(h, a, seed: 1000 + i);
      goals += r.homeGoals + r.awayGoals;
      shots += r.homeStats.shots + r.awayStats.shots;
      if (r.homeGoals > r.awayGoals) {
        homeWins++;
      } else if (r.homeGoals < r.awayGoals) {
        awayWins++;
      } else {
        draws++;
      }
      if (r.homeGoals + r.awayGoals == 0) zeroZero++;
      yellows += r.homeStats.yellowCards + r.awayStats.yellowCards;
      reds += r.homeStats.redCards + r.awayStats.redCards;
      injuries += r.injuries.length;
      corners += r.homeStats.corners + r.awayStats.corners;
    }
    final n = homeWins + draws + awayWins;
    String f(double v) => v.toStringAsFixed(2);
    stdout.writeln(
      'MATCH-REPORT tier1 games=$n goals/game=${f(goals / n)} '
      'shots/game=${f(shots / n)} home/draw/away='
      '${f(homeWins / n)}/${f(draws / n)}/${f(awayWins / n)} '
      '0:0=${f(zeroZero / n)} yellow=${f(yellows / n)} red=${f(reds / n)} '
      'injuries=${f(injuries / n)} corners=${f(corners / n)}',
    );
    expect(goals / n, greaterThan(1.5));
    expect(goals / n, lessThan(4.5));
    expect(homeWins, greaterThan(awayWins));
  });

  test('strength matters: tier 1 beats tier 4 clearly', () {
    final engine = MatchEngine(rules);
    final strong = byTier(1);
    final weak = byTier(4);
    var strongPoints = 0;
    var weakPoints = 0;
    const games = 200;
    for (var i = 0; i < games; i++) {
      final s = strong[i % strong.length];
      final w = weak[(i * 5) % weak.length];
      final r = i.isEven
          ? engine.simulate(s, w, seed: 5000 + i)
          : engine.simulate(w, s, seed: 5000 + i);
      final strongGoals = i.isEven ? r.homeGoals : r.awayGoals;
      final weakGoals = i.isEven ? r.awayGoals : r.homeGoals;
      if (strongGoals > weakGoals) strongPoints += 3;
      if (strongGoals == weakGoals) {
        strongPoints++;
        weakPoints++;
      }
      if (strongGoals < weakGoals) weakPoints += 3;
    }
    stdout.writeln(
      'MATCH-REPORT tier1-vs-tier4 strongPoints/game='
      '${(strongPoints / games).toStringAsFixed(2)} '
      'weakPoints/game=${(weakPoints / games).toStringAsFixed(2)}',
    );
    expect(strongPoints, greaterThan(weakPoints * 2));
  });
}
