import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Step 11a: training days, templates, the generator and freshness.

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

  test('at least 20 units in groups, templates and the generator respect '
      'match days', () {
    final tr = rules.season.training;
    expect(tr.units.length, greaterThanOrEqualTo(20));
    expect(tr.groups.keys, containsAll(['fitness', 'tactics', 'recovery']));
    expect(tr.templates.keys, contains('match_prep'));
    const matches = {100, 104};
    expect(TrainingPlanner.distanceKey(100, matches), 'match');
    expect(TrainingPlanner.distanceKey(99, matches), '-1');
    expect(TrainingPlanner.distanceKey(101, matches), '+1');
    expect(TrainingPlanner.distanceKey(102, matches), '-2');
    final planner = TrainingPlanner(tr);
    expect(planner.fromTemplate('match_prep', 100, matches).sessions, isEmpty);
    expect(
      planner.fromTemplate('match_prep', 101, matches).sessions.single.unit,
      'regeneration',
    );
    final hard = planner.fromGoals(
      ['finishing', 'pressing'],
      Intensity.hard,
      110,
      matches,
    );
    expect(hard.sessions, hasLength(3));
    expect(hard.sessions.every((s) => s.intensity == Intensity.hard), isTrue);
    expect(TrainingDay(List.filled(5, hard.sessions.first)).sessions.length, 3);
    final back = TrainingDay.fromJson(hard.toJson());
    expect(back.sessions, hard.sessions);
  });

  test('hard training drains freshness and adds load, recovery restores it; '
      'past days can not be planned (report)', () {
    final state = SeasonState.fromWorld(world);
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    final club = state.members[top]!.first;

    (double, double) season(TrainingDay day) {
      final runner = SeasonRunner(rules, calendarRules: _calendarRules);
      final run = runner.begin(state, seed: 81, humanClubs: {club});
      final start = Season(state.startYear).start.epochDay;
      for (var d = start; d < start + 120; d++) {
        if (!runner.matchDaysOf(club).contains(d)) {
          runner.setTrainingDay(club, d, day);
        }
      }
      for (var i = 0; i < 6 && !run.isOver; i++) {
        runner.completeDay(run, runner.openDay(run));
      }
      final today = run.timeline.days[run.dayIndex].date.epochDay;
      final squad = run.state.squads[club]!;
      final fresh =
          squad
              .map((p) => runner.freshnessOf(p.id, club: club, epochDay: today))
              .reduce((a, b) => a + b) /
          squad.length;
      final load =
          squad.map((p) => runner.loadOf(p.id, today)).reduce((a, b) => a + b) /
          squad.length;
      expect(runner.setTrainingDay(club, start, day), isFalse);
      return (fresh, load);
    }

    final hard = season(
      TrainingDay(const [
        TrainingSession('endurance', Intensity.hard),
        TrainingSession('practice_match', Intensity.hard),
        TrainingSession('pressing', Intensity.hard),
      ]),
    );
    final easy = season(
      TrainingDay(const [TrainingSession('regeneration', Intensity.light)]),
    );
    stdout.writeln(
      'TRAINING-REPORT freshness hard=${hard.$1.toStringAsFixed(1)} '
      'easy=${easy.$1.toStringAsFixed(1)} load hard=${hard.$2.toStringAsFixed(2)} '
      'easy=${easy.$2.toStringAsFixed(2)}',
    );
    expect(hard.$1, lessThan(easy.$1 - 20));
    expect(hard.$2, greaterThan(easy.$2));
  });

  test('a season with the assistant keeps players fresh enough (report)', () {
    final runner = SeasonRunner(rules, calendarRules: _calendarRules);
    final run = runner.begin(SeasonState.fromWorld(world), seed: 82);
    for (var i = 0; i < 30 && !run.isOver; i++) {
      runner.completeDay(run, runner.openDay(run));
    }
    final today = run.timeline.days[run.dayIndex].date.epochDay;
    final values = <double>[];
    for (final e in run.state.squads.entries.take(40)) {
      for (final p in e.value) {
        values.add(runner.freshnessOf(p.id, club: e.key, epochDay: today));
      }
    }
    values.sort();
    final mean = values.reduce((a, b) => a + b) / values.length;
    stdout.writeln(
      'TRAINING-REPORT assistant freshness mean=${mean.toStringAsFixed(1)} '
      'min=${values.first.toStringAsFixed(0)} '
      'max=${values.last.toStringAsFixed(0)}',
    );
    expect(mean, inInclusiveRange(80, 100));
    expect(values.first, greaterThan(30));
  });
}
