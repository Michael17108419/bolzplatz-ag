import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

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

  SeasonRun begin(int seed) {
    final runner = SeasonRunner(rules, calendarRules: _calendarRules);
    return runner.begin(SeasonState.fromWorld(world), seed: seed);
  }

  Set<int> ownMatchDays(SeasonRun run, ClubId club) => {
    for (final d in run.timeline.days)
      for (final s in d.leagueSlots)
        for (final k in s.kicks)
          if (k.fixture.home == club || k.fixture.away == club) d.date.epochDay,
  };

  Set<int> cupDays(SeasonRun run) => {
    for (final d in run.timeline.days)
      if (d.cupWindows.isNotEmpty) d.date.epochDay,
  };

  group('appointments', () {
    final holidays = HolidayCalendar();
    const season = Season(2026);

    test('they fall on free working days and fit the season', () {
      for (final seed in [1, 2, 3]) {
        final run = begin(seed);
        final state = run.state;
        for (final league in rules.leagues.where((l) => l.level <= 3)) {
          final club = state.members[LeagueId(league.id)]!.first;
          final list = AppointmentPlanner(holidays)
              .build(season: season, timeline: run.timeline, club: club);
          final own = ownMatchDays(run, club);
          final cups = cupDays(run);
          expect(list, isNotEmpty);
          DateTime? previous;
          for (final a in list) {
            final reason = '${a.id} seed $seed';
            expect(season.contains(a.date), isTrue, reason: reason);
            expect(own.contains(a.date.epochDay), isFalse, reason: reason);
            expect(cups.contains(a.date.epochDay), isFalse, reason: reason);
            expect(holidays.isHoliday(a.date), isFalse, reason: reason);
            expect(a.date.weekday, lessThanOrEqualTo(5), reason: reason);
            final t = DateTime.utc(a.date.year, a.date.month, a.date.day);
            if (previous != null) {
              expect(t.isBefore(previous), isFalse, reason: reason);
            }
            previous = t;
          }
          int count(AppointmentKind k) => list.where((a) => a.kind == k).length;
          expect(count(AppointmentKind.jourFix), inInclusiveRange(25, 45));
          expect(count(AppointmentKind.presidentTalk), 10);
          expect(count(AppointmentKind.pressTalk), 2);
          expect(count(AppointmentKind.sponsorTalk), 2);
        }
      }
    });

    test('the plan is the same every time', () {
      final run = begin(5);
      final club = run.state.members[LeagueId(rules.leagues.first.id)]!.first;
      String ids() =>
          AppointmentPlanner(holidays)
              .build(season: season, timeline: run.timeline, club: club)
              .map((a) => a.id)
              .join(',');
      expect(ids(), ids());
    });

    test('a Jour Fix follows every week with a league match', () {
      final run = begin(4);
      final club = run.state.members[LeagueId(rules.leagues.first.id)]!.first;
      final list = AppointmentPlanner(holidays)
          .build(season: season, timeline: run.timeline, club: club);
      final own = ownMatchDays(run, club);
      final fixes = {
        for (final a in list)
          if (a.kind == AppointmentKind.jourFix) a.date.epochDay,
      };
      for (final day in own) {
        final date = GameDate.fromEpochDay(day);
        if (date.weekday != 6 && date.weekday != 7) continue;
        final next = fixes.where((f) => f > day && f <= day + 5);
        expect(next, isNotEmpty, reason: '$date');
      }
    });
  });

  group('vacation', () {
    final holidays = HolidayCalendar();
    final planner = VacationPlanner(
      holidays,
      minTotal: _calendarRules.vacationWerktage,
      minBlock: _calendarRules.vacationBlockWerktage,
    );
    const season = Season(2026);

    test('Sundays and holidays do not break a block', () {
      final days = {
        GameDate(2026, 8, 14).epochDay,
        GameDate(2026, 8, 15).epochDay,
        GameDate(2026, 8, 17).epochDay,
      };
      final c = planner.check(season, days);
      expect(c.total, 3);
      expect(c.longestBlock, 3);
      // 3 October 2026 is a Saturday and a holiday.
      final bridged = {
        GameDate(2026, 10, 2).epochDay,
        GameDate(2026, 10, 5).epochDay,
      };
      expect(planner.check(season, bridged).longestBlock, 2);
      final gap = {
        GameDate(2026, 8, 14).epochDay,
        GameDate(2026, 8, 18).epochDay,
      };
      expect(planner.check(season, gap).longestBlock, 1);
    });

    test('the levels and the rule', () {
      VacationCheck c(int total, int block) => VacationCheck(
        total: total,
        longestBlock: block,
        minTotal: 30,
        minBlock: 12,
      );
      expect(c(20, 12).level, VacationLevel.less);
      expect(c(30, 12).level, VacationLevel.exact);
      expect(c(34, 12).level, VacationLevel.more);
      expect(c(30, 12).kept, isTrue);
      expect(c(30, 11).kept, isFalse);
      expect(c(29, 15).kept, isFalse);
      expect(c(40, 12).kept, isTrue);
    });

    test('the suggestion has 30 days with a long block on free days', () {
      for (final seed in [1, 2, 3]) {
        final run = begin(seed);
        for (final league in rules.leagues.where((l) => l.level <= 4)) {
          final club = run.state.members[LeagueId(league.id)]!.first;
          final blocked = {...ownMatchDays(run, club), ...cupDays(run)};
          final allowed = planner.allowedDays(season, blocked);
          final plan = planner.suggest(season, allowed);
          final c = planner.check(season, plan);
          expect(c.total, 30, reason: '${league.key} seed $seed');
          expect(c.kept, isTrue, reason: '${league.key} seed $seed');
          expect(plan.every(allowed.contains), isTrue);
        }
      }
    });
  });
}
