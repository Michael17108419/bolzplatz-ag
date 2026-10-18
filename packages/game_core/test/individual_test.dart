import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Step 11c: individual training.

final _calendarRules = CalendarRules.fromJsonString(
  File('../../rules/calendar_rules.json').readAsStringSync(),
);
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

  test('plans round trip, suggestions for every position', () {
    for (final plan in const [
      IndividualPlan.unit('finishing'),
      IndividualPlan.position(Position.lv),
      IndividualPlan.role('target_man'),
    ]) {
      expect(IndividualPlan.fromJson(plan.toJson()), plan);
    }
    final runner = SeasonRunner(rules, calendarRules: _calendarRules);
    runner.begin(SeasonState.fromWorld(world), seed: 1);
    for (final pos in Position.values) {
      final p = world.players.firstWhere((x) => x.position == pos);
      expect(runner.suggestIndividual(p)?.unit, isNotNull, reason: pos.id);
    }
  });

  test('a player learns a new position over weeks and his own unit grows '
      'faster (report)', () {
    final state = SeasonState.fromWorld(world);
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    final club = state.members[top]!.first;
    final squad = state.squads[club]!;
    final learner = squad.firstWhere(
      (p) =>
          p.position != Position.lv &&
          !p.position.isGoalkeeper &&
          !p.secondaryPositions.containsKey(Position.lv),
    );
    final young = [...squad]
      ..sort((a, b) => b.birthDate.epochDay.compareTo(a.birthDate.epochDay));
    final shooter = young.firstWhere(
      (p) => p.id != learner.id && !p.position.isGoalkeeper,
    );

    SeasonRunner season({required bool individual}) {
      final runner = SeasonRunner(rules, calendarRules: _calendarRules);
      final run = runner.begin(state, seed: 92, humanClubs: {club});
      if (individual) {
        runner.setIndividual(
          club,
          learner.id,
          const IndividualPlan.position(Position.lv),
        );
        runner.setIndividual(
          club,
          shooter.id,
          const IndividualPlan.unit('finishing'),
        );
      }
      for (var i = 0; i < 25 && !run.isOver; i++) {
        runner.completeDay(run, runner.openDay(run));
      }
      return runner;
    }

    final a = season(individual: true);
    final b = season(individual: false);
    Player find(SeasonRunner r, PlayerId id) =>
        r.squadOf(club).firstWhere((p) => p.id == id);
    final learnt = find(a, learner.id).secondaryPositions[Position.lv];
    final fa = find(a, shooter.id).attributes[Attribute.finishing];
    final fb = find(b, shooter.id).attributes[Attribute.finishing];
    stdout.writeln(
      'INDIVIDUAL-REPORT weeks=${a.learntWeeks(learner.id)} position=$learnt '
      'finishing own plan=${fa.toStringAsFixed(2)} '
      'team only=${fb.toStringAsFixed(2)} '
      'start=${shooter.attributes[Attribute.finishing].toStringAsFixed(2)}',
    );
    expect(learnt, isNotNull);
    expect(fa, greaterThan(fb));
  });
}
