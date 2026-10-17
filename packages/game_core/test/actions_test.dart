import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10b: the player on the ball chooses an action, duels use
// the values of that action, balls won in midfield start counter attacks.

late Rules rules;
late List<MatchTeam> tier1;

String _rulesFile() =>
    File('../../rules/rules_2026_27.json').readAsStringSync();

Map<String, dynamic> _match(Map<String, dynamic> m) =>
    m['match'] as Map<String, dynamic>;

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

  MatchTeam withSystem(MatchTeam t, String systemId) => MatchTeam(
    clubId: t.clubId,
    name: t.name,
    squad: t.squad,
    sheet: t.sheet.copyWith(systemId: systemId),
  );

  /// Plays [games] matches of the first club (home, with [systemId])
  /// against the others and returns all events of the home side.
  List<MatchEvent> homeEvents(String systemId, int games) {
    final engine = MatchEngine(rules);
    final home = withSystem(tier1[0], systemId);
    return [
      for (var i = 0; i < games; i++)
        ...engine
            .simulate(home, tier1[1 + i % (tier1.length - 1)], seed: 70 + i)
            .events
            .where((e) => e.side == 0),
    ];
  }

  test('action rules: six actions, wrong values are refused', () {
    final ids = [for (final a in rules.match.actions.list) a.id];
    expect(ids, [
      'short_pass',
      'through_ball',
      'long_ball',
      'cross',
      'dribble',
      'long_shot',
    ]);
    expect(rules.match.actions.systemWeight('wings', 'cross'), greaterThan(1));
    expect(rules.match.actions.systemWeight('nothing', 'cross'), 1.0);
    expect(rules.match.counter.fromColumns, {1, 2});
    expect(
      rules.match.zones.shareFrom(0),
      closeTo(rules.match.zones.stepShare.reduce((a, b) => a + b), 1e-9),
    );

    final unknown = jsonDecode(_rulesFile()) as Map<String, dynamic>;
    ((_match(unknown)['actions'] as Map<String, dynamic>)['system_weights']
            as Map<String, dynamic>)['wings'] =
        {'flying_kick': 2.0};
    expect(Rules.parse(jsonEncode(unknown)).errorOrNull, isNotNull);

    final badCounter = jsonDecode(_rulesFile()) as Map<String, dynamic>;
    (_match(badCounter)['counter'] as Map<String, dynamic>)['from_columns'] = [
      4,
    ];
    expect(Rules.parse(jsonEncode(badCounter)).errorOrNull, isNotNull);

    final badRisk = jsonDecode(_rulesFile()) as Map<String, dynamic>;
    final list =
        (_match(badRisk)['actions'] as Map<String, dynamic>)['list']
            as List<dynamic>;
    (list.first as Map<String, dynamic>)['risk'] = 1.5;
    expect(Rules.parse(jsonEncode(badRisk)).errorOrNull, isNotNull);
  });

  test('events name the action, shots from distance are long shots', () {
    final known = {for (final a in rules.match.actions.list) a.id};
    var longShots = 0;
    for (final e in homeEvents('possession', 30)) {
      if (e.type == MatchEventType.ballWon ||
          e.type == MatchEventType.counterAttack) {
        expect(known, contains(e.action));
        expect(e.action, isNot('long_shot'));
      }
      if (e.type == MatchEventType.shot && e.action == 'long_shot') {
        longShots++;
        expect(e.shotType, 'long_shot');
        expect(e.column, ZoneRules.columns - 2);
        expect(e.quality, ChanceQuality.half);
      }
    }
    expect(longShots, greaterThan(0));
  });

  test('counter attacks start in the opponent half after a ball won', () {
    var counters = 0;
    for (final e in homeEvents('counter', 30)) {
      if (e.type != MatchEventType.counterAttack) continue;
      counters++;
      // Lost in column 1 or 2 of the other team: mirrored 3 or 2.
      expect(e.column, anyOf(2, 3));
      expect(tier1[0].squad.map((p) => p.id), contains(e.player));
    }
    expect(counters, greaterThan(10));
  });

  test('the system shapes the play: wings cross, counter teams counter', () {
    int count(List<MatchEvent> events, bool Function(MatchEvent) f) =>
        events.where(f).length;
    final wings = homeEvents('wings', 40);
    final possession = homeEvents('possession', 40);
    final counter = homeEvents('counter', 40);
    bool cross(MatchEvent e) =>
        e.type == MatchEventType.shot && e.action == 'cross';
    bool counters(MatchEvent e) => e.type == MatchEventType.counterAttack;
    final crossWings = count(wings, cross);
    final crossPossession = count(possession, cross);
    final counterCounter = count(counter, counters);
    final counterPossession = count(possession, counters);
    stdout.writeln(
      'ACTIONS-REPORT shots after cross wings=$crossWings '
      'possession=$crossPossession; counters counter=$counterCounter '
      'possession=$counterPossession (40 games)',
    );
    expect(crossWings, greaterThan(crossPossession));
    expect(counterCounter, greaterThan(counterPossession));
  });

  test('actions report: how attacks end (report)', () {
    final shotsBy = <String, int>{};
    final lostBy = <String, int>{};
    var counters = 0;
    final events = homeEvents('possession', 60);
    for (final e in events) {
      final a = e.action ?? '-';
      if (e.type == MatchEventType.shot) shotsBy[a] = (shotsBy[a] ?? 0) + 1;
      if (e.type == MatchEventType.ballWon) lostBy[a] = (lostBy[a] ?? 0) + 1;
      if (e.type == MatchEventType.counterAttack) counters++;
    }
    stdout.writeln(
      'ACTIONS-REPORT home side, 60 games: shots by last action $shotsBy; '
      'own balls won in attacking third by action of the opponent $lostBy; '
      'own counters $counters',
    );
    expect(shotsBy, isNotEmpty);
  });
}
