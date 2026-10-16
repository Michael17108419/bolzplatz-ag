import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

late Rules rules;
late MatchTeam home;
late MatchTeam away;

MatchTeam _team(String name, int id, List<Player> squad) => MatchTeam(
  clubId: ClubId(id),
  name: name,
  squad: squad,
  sheet: AutoManager(rules).build(squad)!,
);

List<String> _lines(MatchResult r) => [
  for (final e in r.events)
    '${e.minute}/${e.type.name}/${e.side}/${e.player?.value}/'
        '${e.otherPlayer?.value}/${e.homeGoals}:${e.awayGoals}',
];

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    final world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    final clubs = world.clubs.take(2).toList();
    List<Player> squad(Club c) => [
      for (final p in world.players)
        if (p.clubId == c.id) p,
    ];
    home = _team(clubs[0].name, clubs[0].id.value, squad(clubs[0]));
    away = _team(clubs[1].name, clubs[1].id.value, squad(clubs[1]));
  });

  test('a team sheet survives JSON', () {
    final sheet = home.sheet.copyWith(pressing: 2, tempo: 0, defensiveLine: 2);
    final back = TeamSheet.fromJson(
      jsonDecode(jsonEncode(sheet.toJson())) as Map<String, dynamic>,
    );
    expect(back.formationId, sheet.formationId);
    expect(back.systemId, sheet.systemId);
    expect(back.startingXi, sheet.startingXi);
    expect(back.slotRoles, sheet.slotRoles);
    expect(back.bench, sheet.bench);
    expect(back.pressing, 2);
    expect(back.tempo, 0);
    expect(back.defensiveLine, 2);
  });

  test('a live match can be repeated from its recorded changes', () {
    for (final seed in [3, 11, 42]) {
      final live = MatchSession(
        rules: rules,
        home: home,
        away: away,
        seed: seed,
      )..advanceTo(30);
      final off = live.onPitch(0).firstWhere((id) {
        final p = home.squad.firstWhere((x) => x.id == id);
        return !p.position.isGoalkeeper;
      });
      final on = live.benchOf(0).firstWhere((id) {
        final p = home.squad.firstWhere((x) => x.id == id);
        return !p.position.isGoalkeeper;
      });
      expect(live.substitute(0, off, on), isTrue);
      live.advanceTo(61);
      live.changeTactics(0, pressing: 2, tempo: 0);
      final result = live.finish();
      final actions = live.actions;
      expect(actions.where((a) => a.isSubstitution), hasLength(1));
      expect(actions, hasLength(2));

      final saved = jsonEncode([for (final a in actions) a.toJson()]);
      final loaded = [
        for (final m in jsonDecode(saved) as List<dynamic>)
          SessionAction.fromJson(m as Map<String, dynamic>),
      ];
      final again = MatchSession(
        rules: rules,
        home: home,
        away: away,
        seed: seed,
      )..replay(loaded);
      final repeated = again.finish();
      expect(_lines(repeated), _lines(result), reason: 'seed $seed');
      expect(repeated.homeGoals, result.homeGoals);
      expect(repeated.awayGoals, result.awayGoals);
      expect(again.actions, hasLength(2));
    }
  });

  test('the assistant\'s own changes are not recorded', () {
    final session = MatchSession(rules: rules, home: home, away: away, seed: 5)
      ..finish();
    expect(session.actions, isEmpty);
  });

  test('a neutral venue takes the home advantage away', () {
    var withAdvantage = 0;
    var neutral = 0;
    for (var seed = 1; seed <= 400; seed++) {
      final a = MatchSession(
        rules: rules,
        home: home,
        away: away,
        seed: seed,
      ).finish();
      final b = MatchSession(
        rules: rules,
        home: home,
        away: away,
        seed: seed,
        neutral: true,
      ).finish();
      withAdvantage += a.homeGoals - a.awayGoals;
      neutral += b.homeGoals - b.awayGoals;
    }
    expect(withAdvantage, greaterThan(neutral));
  });
}
