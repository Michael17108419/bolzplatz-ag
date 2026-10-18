import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10f4: chemistry of pairs and of the eleven.

final _calendarRules = CalendarRules.fromJsonString(
  File('../../rules/calendar_rules.json').readAsStringSync(),
);
late Rules rules;
late World world;
late List<MatchTeam> tier1;

MatchTeam _with(MatchTeam t, double chem) => MatchTeam(
  clubId: t.clubId,
  name: t.name,
  squad: t.squad,
  sheet: t.sheet,
  chemistry: (a, b) => chem,
);

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
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

  test('pairs: nothing at first, half at one unit; keeper and striker need '
      'not know each other', () {
    expect(pairChemistry(0, 0, minutesUnit: 1800, yearsUnit: 3), 0);
    expect(pairChemistry(1800, 0, minutesUnit: 1800, yearsUnit: 3), 0.5);
    expect(pairChemistry(900, 1.5, minutesUnit: 1800, yearsUnit: 3), 0.5);
    expect(
      pairChemistry(18000, 0, minutesUnit: 1800, yearsUnit: 3),
      lessThan(1),
    );
    const keeper = PlayerId(1);
    const back = PlayerId(3);
    const striker = PlayerId(2);
    expect(pairKey(back, striker), pairKey(striker, back));
    const apart = [(keeper, Position.tw), (striker, Position.st)];
    expect(teamChemistry(apart, (a, b) => 1), 0.5);
    const three = [
      (keeper, Position.tw),
      (back, Position.iv),
      (striker, Position.st),
    ];
    expect(
      teamChemistry(three, (a, b) => a == keeper || b == keeper ? 1 : 0),
      1,
    );
  });

  test('a team that knows itself passes better (report)', () {
    var known = 0;
    var strangers = 0;
    for (var i = 0; i < 200; i++) {
      final a = tier1[i % tier1.length];
      final b = tier1[(i * 7 + 3) % tier1.length];
      final hi = MatchEngine(rules)
          .simulate(_with(a, 0.95), _with(b, 0.5), seed: 6100 + i);
      final lo = MatchEngine(rules)
          .simulate(_with(a, 0.05), _with(b, 0.5), seed: 6100 + i);
      known += hi.homeGoals - hi.awayGoals;
      strangers += lo.homeGoals - lo.awayGoals;
    }
    stdout.writeln(
      'CHEMISTRY-REPORT goal difference known=$known strangers=$strangers '
      '(200 games)',
    );
    expect(known, greaterThan(strangers));
  });

  test('over weeks the eleven grows together (report)', () {
    final runner = SeasonRunner(rules, calendarRules: _calendarRules);
    final state = SeasonState.fromWorld(world);
    final run = runner.begin(state, seed: 71);
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    final clubs = run.state.members[top]!;
    final sheets = {
      for (final c in clubs) c: AutoManager(rules).build(run.state.squads[c]!)!,
    };
    final before = {for (final c in clubs) c: runner.chemistryOf(sheets[c]!)};
    var days = 0;
    while (!run.isOver && days < 40) {
      runner.completeDay(run, runner.openDay(run));
      days++;
    }
    final after = {for (final c in clubs) c: runner.chemistryOf(sheets[c]!)};
    double mean(Map<ClubId, double> m) =>
        m.values.reduce((a, b) => a + b) / m.length;
    final lo = after.values.reduce((a, b) => a < b ? a : b);
    final hi = after.values.reduce((a, b) => a > b ? a : b);
    stdout.writeln(
      'CHEMISTRY-REPORT start=${mean(before).toStringAsFixed(2)} '
      'after 40 days=${mean(after).toStringAsFixed(2)} '
      'min=${lo.toStringAsFixed(2)} max=${hi.toStringAsFixed(2)}',
    );
    // The summer preparation gives every eleven a start near average.
    expect(mean(before), inInclusiveRange(0.3, 0.55));
    for (final c in clubs) {
      expect(after[c], greaterThan(before[c]!));
      expect(after[c], inInclusiveRange(0, 1));
    }
  });
}
