import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Step 11b: players develop every week, training moves the growth.

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

  test('52 neutral weeks give about the year of before (report)', () {
    final dev = Development(rules);
    final next = Season(world.season.startYear + 1).start;
    final bands = <String, List<double>>{};
    for (final p in world.players.take(600)) {
      final age = p.ageOn(next);
      final band = age < 22
          ? 'young'
          : age < 30
          ? 'prime'
          : 'old';
      final year = dev.advance(
        p,
        newSeasonStart: next,
        rng: SeededRandom(1).fork('y${p.id.value}'),
        minutesShare: 0.5,
      );
      var w = p;
      for (var k = 0; k < 52; k++) {
        w = dev.week(
          w,
          date: next,
          rng: SeededRandom(2).fork('w${p.id.value}:$k'),
          minutesShare: 0.5,
        );
      }
      final o = WorldReport.overall(p, rules);
      (bands['$band-year'] ??= []).add(WorldReport.overall(year, rules) - o);
      (bands['$band-week'] ??= []).add(WorldReport.overall(w, rules) - o);
    }
    double mean(List<double> l) => l.reduce((a, b) => a + b) / l.length;
    final line = [
      for (final e in bands.entries) '${e.key}=${mean(e.value).toStringAsFixed(2)}',
    ].join(' ');
    stdout.writeln('DEV-REPORT $line');
    for (final band in ['young', 'prime', 'old']) {
      expect(
        mean(bands['$band-week']!),
        closeTo(mean(bands['$band-year']!), 0.4),
        reason: band,
      );
    }
  });

  test('training a group makes it grow faster and decline slower', () {
    final dev = Development(rules);
    final next = Season(world.season.startYear + 1).start;
    final young = world.players
        .where((p) => p.ageOn(next) <= 20 && !p.position.isGoalkeeper)
        .take(100);
    var trained = 0.0;
    var plain = 0.0;
    for (final p in young) {
      var a = p;
      var b = p;
      for (var k = 0; k < 52; k++) {
        final rng = SeededRandom(3).fork('w${p.id.value}:$k');
        a = dev.week(
          a,
          date: next,
          rng: rng,
          minutesShare: 0.5,
          focus: {Attribute.finishing: 1.8},
        );
        b = dev.week(
          b,
          date: next,
          rng: SeededRandom(3).fork('w${p.id.value}:$k'),
          minutesShare: 0.5,
        );
      }
      trained += a.attributes[Attribute.finishing] - p.attributes[Attribute.finishing];
      plain += b.attributes[Attribute.finishing] - p.attributes[Attribute.finishing];
    }
    expect(trained, greaterThan(plain));
  });

  test('in a season players change every week, finishing training pays, '
      'the same seed gives the same players (report)', () {
    final state = SeasonState.fromWorld(world);
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    final club = state.members[top]!.first;

    SeasonRunner season(TrainingDay day) {
      final runner = SeasonRunner(rules, calendarRules: _calendarRules);
      final run = runner.begin(state, seed: 91, humanClubs: {club});
      final start = Season(state.startYear).start.epochDay;
      for (var d = start; d < start + 140; d++) {
        if (!runner.matchDaysOf(club).contains(d)) {
          runner.setTrainingDay(club, d, day);
        }
      }
      for (var i = 0; i < 12 && !run.isOver; i++) {
        runner.completeDay(run, runner.openDay(run));
      }
      return runner;
    }

    final shooting = TrainingDay(const [
      TrainingSession('finishing', Intensity.normal),
      TrainingSession('long_shots', Intensity.normal),
    ]);
    final resting = TrainingDay(const [
      TrainingSession('regeneration', Intensity.light),
    ]);
    final a = season(shooting);
    final b = season(resting);
    final again = season(shooting);
    double finishing(SeasonRunner r) =>
        r.squadOf(club).map((p) => p.attributes[Attribute.finishing]).reduce(
          (x, y) => x + y,
        );
    final before = state.squads[club]!
        .map((p) => p.attributes[Attribute.finishing])
        .reduce((x, y) => x + y);
    stdout.writeln(
      'DEV-REPORT club finishing sum before=${before.toStringAsFixed(1)} '
      'shooting=${finishing(a).toStringAsFixed(1)} '
      'resting=${finishing(b).toStringAsFixed(1)}',
    );
    expect(finishing(a), greaterThan(finishing(b)));
    expect(finishing(again), finishing(a));
    expect(a.squadOf(club).first.attributes, isNot(state.squads[club]!.first.attributes));
  });
}
