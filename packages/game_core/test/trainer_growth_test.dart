import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Step 11e: the manager grows with work and results, licences, courses.

final _calendarRules = CalendarRules.fromJsonString(
  File('../../rules/calendar_rules.json').readAsStringSync(),
);
late Rules rules;
late World world;

Trainer _trainer({Licence licence = Licence.none, double value = 50}) =>
    Trainer(
      name: 'Kalle',
      appearance: const TrainerAppearance(),
      backstoryId: 'pub_landlord',
      values: {for (final v in ManagerValue.values) v: value},
      licence: licence,
    );

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
  });

  test('the rules: start licences of the backstories, what the leagues ask '
      'for, courses for every step', () {
    final career = rules.career;
    expect(career.backstory('failed_pro').licence, Licence.b);
    expect(career.backstory('pub_landlord').licence, Licence.none);
    expect(career.backstory('scandal_coach').licence, Licence.a);
    expect(career.backstory('pe_teacher').licence, Licence.c);
    final g = career.growth;
    expect(g.requiredFor(1), Licence.pro);
    expect(g.requiredFor(4), Licence.a);
    for (final l in Licence.values.skip(1)) {
      expect(g.courseDays[l], greaterThan(0));
    }
    expect(Licence.b.covers(Licence.c), isTrue);
    expect(Licence.c.covers(Licence.a), isFalse);
    expect(Licence.a.next, Licence.pro);
    expect(Licence.pro.next, isNull);
    final t = TrainerFactory.create(
      rules: rules,
      name: 'Uwe',
      appearance: const TrainerAppearance(),
      backstoryId: 'youth_coach',
      seed: 4,
    );
    expect(t.licence, Licence.b);
    expect(t.seasons, 0);
  });

  test('a saved trainer keeps licence and seasons; an old save takes the '
      'licence it is given', () {
    final t = _trainer(licence: Licence.a).copyWith(seasons: 3);
    final back = Trainer.fromJson(t.toJson());
    expect(back.licence, Licence.a);
    expect(back.seasons, 3);
    final old = t.toJson()
      ..remove('licence')
      ..remove('seasons');
    final legacy = Trainer.fromJson(old, licence: Licence.c);
    expect(legacy.licence, Licence.c);
    expect(legacy.seasons, 0);
  });

  test('work grows the values, slower near the top and at most the cap a '
      'season; courses, stress and the price of a missing licence', () {
    final g = rules.career.growth;
    final growth = TrainerGrowth(g);
    final low = TrainerProgress(_trainer(value: 30));
    final high = TrainerProgress(_trainer(value: 85));
    for (var i = 0; i < 10; i++) {
      low.add(g, 'talk');
      high.add(g, 'talk');
    }
    final l = growth.current(low, 0)[ManagerValue.manManagement] - 30;
    final h = growth.current(high, 0)[ManagerValue.manManagement] - 85;
    expect(l, greaterThan(h));
    expect(h, greaterThan(0));
    for (var i = 0; i < 500; i++) {
      low.add(g, 'talk');
    }
    expect(
      growth.current(low, 0)[ManagerValue.manManagement],
      closeTo(30 + g.seasonCap, 0.05),
    );

    final p = TrainerProgress(_trainer());
    p.courses.add(
      const Course(
        start: 100,
        days: 3,
        licence: Licence.c,
        value: ManagerValue.charisma,
      ),
    );
    expect(p.courseOn(101), isNotNull);
    expect(growth.current(p, 101).licence, Licence.none);
    expect(growth.current(p, 103).licence, Licence.c);
    expect(
      growth.current(p, 103)[ManagerValue.charisma],
      50 + g.courseGain,
    );
    p.cover = LicenceCover.waiver;
    expect(
      growth.current(p, 0)[ManagerValue.presidentTrust],
      50 - g.waiverTrust,
    );
    p.cover = LicenceCover.strawMan;
    expect(growth.current(p, 0)[ManagerValue.pressImage], 50 - g.strawPress);

    // Defeats in a row pile up stress, the holidays take it off, a
    // stressed manager loses some of his team talks.
    final s = TrainerProgress(_trainer(value: 55));
    for (var i = 0; i < 5; i++) {
      growth.afterMatch(s, 0, 2);
    }
    expect(s.stress, greaterThan(55 + 5 * g.stress['loss']!));
    expect(growth.strain(s.stress), greaterThan(0));
    expect(growth.strain(40), 0);
    final before = s.stress;
    growth.holiday(s);
    expect(s.stress, lessThan(before));
    const coach = CoachProfile(charisma: 70, motivation: 70);
    expect(coach.withStrain(0.2).talk, lessThan(coach.talk));
  });

  test('the end of the season: standing after the verdict, promotion and '
      'the cup, one season more', () {
    final growth = TrainerGrowth(rules.career.growth);
    final s = rules.career.growth.standing;
    final good = TrainerProgress(_trainer())..cupRounds = 3;
    final up = growth.close(
      good,
      epochDay: 0,
      verdict: GoalVerdict.exceeded,
      levelChange: -1,
      cupWon: true,
    );
    final expected =
        50 + s['exceeded']! + s['promoted']! + 3 * s['cup_round']!;
    expect(up[ManagerValue.standing], closeTo(expected + s['cup_win']!, 0.05));
    expect(up.seasons, 1);
    final down = growth.close(
      TrainerProgress(_trainer()),
      epochDay: 0,
      verdict: GoalVerdict.failed,
      levelChange: 1,
    );
    expect(down[ManagerValue.standing], 50 + s['failed']! + s['relegated']!);
  });

  test('in a season: talks and planning teach, the licence question, a '
      'course in the holidays, the assistant stands in (report)', () {
    final state = SeasonState.fromWorld(world);
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    final club = state.members[top]!.first;
    final runner = SeasonRunner(rules, calendarRules: _calendarRules);
    final base = _trainer(licence: Licence.c, value: 50);
    final run = runner.begin(
      state,
      seed: 77,
      humanClubs: {club},
      trainers: {club: base},
    );
    expect(runner.progressOf(club), isNotNull);
    expect(runner.trainerOf(state.members[top]![1]), isNull);
    // The first league asks for Pro.
    expect(runner.licenceMissing(club), Licence.pro);
    expect(runner.setLicenceCover(club, LicenceCover.strawMan), isTrue);
    expect(runner.setLicenceCover(club, LicenceCover.waiver), isFalse);

    // A course in the summer window: always the next step, B after C.
    final windows = runner.courseWindowsOf(club);
    expect(windows, hasLength(2));
    final summer = windows.first;
    final start = summer.$1 + 1;
    expect(runner.courseBlock(club, summer.$2 + 30), 'window');
    expect(runner.courseBlock(club, start), isNull);
    final booked = runner.bookCourse(
      club,
      start,
      ManagerValue.tacticalKnowledge,
    );
    expect(booked, isTrue);
    // After the course B stands; A asks for a season as manager.
    expect(runner.courseBlock(club, start + 10), 'seasons');
    final course = runner.progressOf(club)!.courses.single;
    expect(course.licence, Licence.b);
    expect(runner.canTalkTo(club, start), isFalse);
    final own = TrainingDay(const [
      TrainingSession('speed', Intensity.hard),
      TrainingSession('speed', Intensity.hard),
      TrainingSession('speed', Intensity.hard),
    ]);
    runner.setTrainingDay(club, start, own);
    expect(
      runner.trainingDayOf(club, start).toJson(),
      isNot(own.toJson()),
    );

    final squad = state.squads[club]!;
    final dayOne = run.timeline.days.first.date.epochDay;
    var landed = 0;
    for (var w = 0; w < 10; w++) {
      final day = dayOne + 7 * w + 30;
      if (runner.canTalkTo(club, day)) {
        final r = runner.talkTo(
          club,
          squad[w % squad.length].id,
          PlayerTalk.encourage,
          day,
        );
        if (r == 1) landed++;
      }
      runner.setTrainingDay(club, day, TrainingDay(const []));
    }
    for (var i = 0; i < 60 && !run.isOver; i++) {
      runner.completeDay(run, runner.openDay(run));
    }
    final now = runner.trainerOf(club)!;
    final p = runner.progressOf(club)!;
    final raw = {
      for (final e in p.raw.entries) e.key.id: e.value.toStringAsFixed(2),
    };
    stdout.writeln(
      'GROWTH-REPORT talks landed=$landed weeks planned=${p.plannedWeeks.length} '
      'raw=$raw '
      'stress=${p.stress.toStringAsFixed(1)} licence=${now.licence.id} '
      'tactics=${now[ManagerValue.tacticalKnowledge]} '
      'man management=${now[ManagerValue.manManagement]} '
      'press=${now[ManagerValue.pressImage]}',
    );
    expect(now.licence, Licence.b);
    expect(now[ManagerValue.tacticalKnowledge], greaterThan(50));
    expect(now[ManagerValue.pressImage], 50 - rules.career.growth.strawPress);
    if (landed > 0) expect(now[ManagerValue.manManagement], greaterThan(50));
    expect(p.plannedWeeks, isNotEmpty);
    expect(p.stress, isNot(50));
  });
}
