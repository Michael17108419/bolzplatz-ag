import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10c: hidden character traits in the match, the captain.

late Rules rules;
late List<MatchTeam> tier1;

String _rulesFile() =>
    File('../../rules/rules_2026_27.json').readAsStringSync();

MatchTeam _with(
  MatchTeam t, {
  Map<CharacterTrait, double>? set,
  TeamSheet? sheet,
}) {
  final squad = [
    for (final p in t.squad)
      set == null ? p : p.copyWith(traits: {...p.traits, ...set}),
  ];
  return MatchTeam(
    clubId: t.clubId,
    name: t.name,
    squad: squad,
    sheet: sheet ?? t.sheet,
  );
}

void main() {
  setUpAll(() {
    rules = Rules.parse(_rulesFile()).valueOrNull!;
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

  /// All events of the home side in [games] matches of [home] against the
  /// other clubs of the first league.
  List<MatchEvent> homeEvents(MatchTeam home, int games) {
    final engine = MatchEngine(rules);
    return [
      for (var i = 0; i < games; i++)
        ...engine
            .simulate(home, tier1[1 + i % (tier1.length - 1)], seed: 900 + i)
            .events
            .where((e) => e.side == 0),
    ];
  }

  test('character rules are read, a missing number is refused', () {
    final c = rules.match.character;
    expect(c.reference, 50);
    expect(c.scale, greaterThan(0));
    final json = jsonDecode(_rulesFile()) as Map<String, dynamic>;
    ((json['match'] as Map<String, dynamic>)['character']
            as Map<String, dynamic>)
        .remove('egoism_self_shot');
    expect(Rules.parse(jsonEncode(json)).errorOrNull, isNotNull);
  });

  test('the captain: named on the sheet, else the leader of the eleven', () {
    final team = tier1[0];
    final named = team.sheet.startingXi[5];
    final withCaptain = _with(team, sheet: team.sheet.copyWith(captain: named));
    final a = MatchSession(
      rules: rules,
      home: withCaptain,
      away: tier1[1],
      seed: 1,
    );
    expect(a.captainOf(0), named);

    final b = MatchSession(rules: rules, home: team, away: tier1[1], seed: 1);
    final eleven = [
      for (final id in team.sheet.startingXi)
        team.squad.firstWhere((p) => p.id == id),
    ];
    final best = eleven.reduce(
      (x, y) =>
          (y.traits[CharacterTrait.leadership] ?? 0) >
              (x.traits[CharacterTrait.leadership] ?? 0)
          ? y
          : x,
    );
    expect(
      eleven
          .firstWhere((p) => p.id == b.captainOf(0))
          .traits[CharacterTrait.leadership],
      best.traits[CharacterTrait.leadership],
    );

    // The captain survives saving the sheet; a captain on the bench is
    // ignored.
    final json = withCaptain.sheet.toJson();
    expect(TeamSheet.fromJson(json).captain, named);
    final cleared = team.sheet.copyWith(captain: named, clearCaptain: true);
    expect(cleared.captain, isNull);
    final benchCaptain = _with(
      team,
      sheet: team.sheet.copyWith(captain: team.sheet.bench.first),
    );
    final c = MatchSession(
      rules: rules,
      home: benchCaptain,
      away: tier1[1],
      seed: 1,
    );
    expect(team.sheet.startingXi, contains(c.captainOf(0)));
  });

  test('egoists shoot from distance more often than team players', () {
    int longShots(double egoism) {
      final team = _with(tier1[0], set: {CharacterTrait.egoism: egoism});
      var n = 0;
      for (final e in homeEvents(team, 40)) {
        if (e.type == MatchEventType.shot && e.action == 'long_shot') n++;
      }
      return n;
    }

    final egoists = longShots(95);
    final teamPlayers = longShots(5);
    stdout.writeln(
      'CHARACTER-REPORT long shots in 40 games: egoists=$egoists '
      'team players=$teamPlayers',
    );
    expect(egoists, greaterThan(teamPlayers * 1.3));
  });

  test('hotheads see more cards than calm players', () {
    int cards(double value) {
      final team = _with(
        tier1[0],
        set: {CharacterTrait.temper: value, CharacterTrait.aggression: value},
      );
      const kinds = {
        MatchEventType.yellowCard,
        MatchEventType.secondYellow,
        MatchEventType.redCard,
      };
      var n = 0;
      for (final e in homeEvents(team, 60)) {
        if (kinds.contains(e.type)) n++;
      }
      return n;
    }

    // The share within one team moves: a team of hotheads against normal
    // opponents. Compare a whole team of hotheads with the same team calm.
    final hot = cards(95);
    final calm = cards(5);
    stdout.writeln('CHARACTER-REPORT cards in 60 games: hot=$hot calm=$calm');
    expect(hot, greaterThan(calm * 1.2));
  });

  test('creative players play more through balls', () {
    int throughBalls(double value) {
      final team = _with(tier1[0], set: {CharacterTrait.creativity: value});
      var n = 0;
      for (final e in homeEvents(team, 40)) {
        if (e.action == 'through_ball') n++;
      }
      return n;
    }

    final creative = throughBalls(95);
    final plain = throughBalls(5);
    stdout.writeln(
      'CHARACTER-REPORT through balls seen in 40 games: creative=$creative '
      'plain=$plain',
    );
    expect(creative, greaterThan(plain));
  });

  test('party animals start the match with less energy', () {
    final party = _with(tier1[0], set: {CharacterTrait.partyFactor: 100});
    final session = MatchSession(
      rules: rules,
      home: party,
      away: tier1[1],
      seed: 3,
    );
    for (final id in session.onPitch(0)) {
      expect(
        session.energyOf(0, id),
        closeTo(100 - rules.match.character.partyEnergy, 1e-9),
      );
    }
  });
}
