import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10a: attacks run through zones with real players.

late Rules rules;
late World world;
late Map<ClubId, MatchTeam> teams;
late Map<ClubId, int> tierOf;

String _rulesFile() =>
    File('../../rules/rules_2026_27.json').readAsStringSync();

MatchTeam _team(Club club, List<Player> squad) => MatchTeam(
  clubId: club.id,
  name: club.name,
  squad: squad,
  sheet: AutoManager(rules).build(squad)!,
);

void main() {
  setUpAll(() {
    rules = Rules.parse(_rulesFile()).valueOrNull!;
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

  List<MatchResult> play(int games, int tier) {
    final engine = MatchEngine(rules);
    final clubs = byTier(tier);
    return [
      for (var i = 0; i < games; i++)
        engine.simulate(
          clubs[i % clubs.length],
          clubs[(i * 5 + 1) % clubs.length],
          seed: 300 + i,
        ),
    ];
  }

  test('zone rules: every position has five columns, lanes fit sides', () {
    final z = rules.match.zones;
    for (final p in Position.values) {
      expect(z.columnWeights[p], hasLength(ZoneRules.columns), reason: p.id);
    }
    expect(z.startColumnWeights.last, 0);
    expect(z.laneFactor(Position.lv, 0), z.laneSame);
    expect(z.laneFactor(Position.lv, 1), z.laneAdjacent);
    expect(z.laneFactor(Position.lv, 2), z.laneFar);
    expect(z.laneFactor(Position.ra, 2), z.laneSame);
    expect(z.laneFactor(Position.zm, 1), z.laneSame);
    expect(z.laneFactor(Position.zm, 0), z.centreOnWing);
    expect(z.lanesFor('wings'), isNot(z.lanesFor('unknown_system')));
    expect(z.lanesFor('unknown_system'), z.laneWeights['default']);
  });

  test('zone rules: wrong values are refused', () {
    Map<String, dynamic> json() =>
        jsonDecode(_rulesFile()) as Map<String, dynamic>;
    Map<String, dynamic> zones(Map<String, dynamic> m) =>
        (m['match'] as Map<String, dynamic>)['zones'] as Map<String, dynamic>;

    final startInBox = json();
    zones(startInBox)['start_column_weights'] = [0.2, 0.5, 0.2, 0.0, 0.1];
    expect(Rules.parse(jsonEncode(startInBox)).errorOrNull, isNotNull);

    final missing = json();
    (zones(missing)['column_weights'] as Map<String, dynamic>).remove('ST');
    expect(Rules.parse(jsonEncode(missing)).errorOrNull, isNotNull);

    final short = json();
    zones(short)['step_share'] = [0.5, 0.5];
    expect(Rules.parse(jsonEncode(short)).errorOrNull, isNotNull);
  });

  test('shots and lost balls carry a zone and the right players', () {
    final engine = MatchEngine(rules);
    final clubs = byTier(1);
    for (var i = 0; i < 30; i++) {
      final home = clubs[i % clubs.length];
      final away = clubs[(i * 7 + 2) % clubs.length];
      if (home.clubId == away.clubId) continue;
      final r = engine.simulate(home, away, seed: 40 + i);
      final squads = [
        {for (final p in home.squad) p.id},
        {for (final p in away.squad) p.id},
      ];
      final won = [0, 0];
      for (final e in r.events) {
        if (e.type == MatchEventType.shot && e.quality != null) {
          expect(e.column, anyOf(3, 4));
          expect(e.lane, inInclusiveRange(0, 2));
          for (final id in e.chain) {
            expect(squads[e.side], contains(id));
            expect(id, isNot(e.player));
          }
          // An assisted goal from open play: the pass came from the last
          // player of the attack.
          if (e.isGoal && e.otherPlayer != null && e.chain.isNotEmpty) {
            expect(e.otherPlayer, e.chain.last);
          }
        }
        if (e.type == MatchEventType.ballWon) {
          won[e.side]++;
          expect(
            e.column!,
            greaterThanOrEqualTo(rules.match.zones.ballWonEventFromColumn),
          );
          expect(e.column!, lessThan(ZoneRules.columns - 1));
          expect(squads[e.side], contains(e.player));
          expect(squads[1 - e.side], contains(e.otherPlayer));
        }
      }
      expect(r.homeStats.ballsWon, greaterThanOrEqualTo(won[0]));
      expect(r.awayStats.ballsWon, greaterThanOrEqualTo(won[1]));
      expect(r.homeStats.ballsWon + r.awayStats.ballsWon, greaterThan(20));
    }
  });

  test('left-sided players carry the ball on the left lane', () {
    final position = {
      for (final t in teams.values)
        for (final p in t.squad) p.id: p.position,
    };
    var left = 0;
    var right = 0;
    for (final r in play(60, 1)) {
      for (final e in r.events) {
        if (e.lane != 0) continue;
        final ids = [
          ...e.chain,
          if (e.type == MatchEventType.ballWon) e.otherPlayer!,
        ];
        for (final id in ids) {
          final p = position[id];
          if (p == Position.lv || p == Position.la) left++;
          if (p == Position.rv || p == Position.ra) right++;
        }
      }
    }
    stdout.writeln('ZONES-REPORT left lane: left-sided=$left right=$right');
    expect(left, greaterThan(right * 1.5));
  });

  test('zones report: where balls are lost (report)', () {
    final byColumn = List.filled(ZoneRules.columns, 0);
    var shots = 0;
    var chainLength = 0;
    final results = play(100, 2);
    for (final r in results) {
      for (final e in r.events) {
        if (e.type == MatchEventType.ballWon) byColumn[e.column!]++;
        if (e.type == MatchEventType.shot && e.quality != null) {
          shots++;
          chainLength += e.chain.length;
        }
      }
    }
    final n = results.length;
    stdout.writeln(
      'ZONES-REPORT tier2 ballWonEvents/game by column=$byColumn '
      '(/$n games) openPlayShots/game=${(shots / n).toStringAsFixed(2)} '
      'chain=${(chainLength / shots).toStringAsFixed(2)}',
    );
    expect(shots, greaterThan(0));
  });
}
