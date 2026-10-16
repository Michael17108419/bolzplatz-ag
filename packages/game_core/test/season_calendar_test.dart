import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

CalendarRules _rules() => CalendarRules.fromJsonString(
  File('../../rules/calendar_rules.json').readAsStringSync(),
);

String _signature(LeagueCalendar c) => [
  for (final m in c.matchdays)
    '${m.number}${m.isMidweek ? 'm' : ''}:'
        '${[for (final g in m.groups) '${g.date}T${g.timeLabel}x${g.matches}'].join(',')}',
].join(';');

void main() {
  group('holidays', () {
    test('Easter Sunday of known years', () {
      expect(easterSunday(2024), GameDate(2024, 3, 31));
      expect(easterSunday(2026), GameDate(2026, 4, 5));
      expect(easterSunday(2027), GameDate(2027, 3, 28));
      expect(easterSunday(2038), GameDate(2038, 4, 25));
    });

    test('Advent related days of 2026', () {
      expect(firstAdvent(2026), GameDate(2026, 11, 29));
      expect(totensonntag(2026), GameDate(2026, 11, 22));
      expect(volkstrauertag(2026), GameDate(2026, 11, 15));
      expect(bussUndBettag(2026), GameDate(2026, 11, 18));
    });

    test('nationwide and regional holidays', () {
      final cal = HolidayCalendar();
      expect(cal.isHoliday(GameDate(2026, 10, 3)), isTrue);
      expect(cal.isHoliday(GameDate(2026, 1, 6)), isFalse);
      expect(
        cal.isHoliday(GameDate(2026, 1, 6), state: Bundesland.bayern),
        isTrue,
      );
      expect(
        cal.isHoliday(GameDate(2026, 1, 6), state: Bundesland.hamburg),
        isFalse,
      );
      expect(cal.holidaysOn(GameDate(2026, 4, 3)).single.key, 'goodFriday');
    });

    test('every year has the nationwide holidays', () {
      for (var year = 2026; year <= 2125; year++) {
        final nationwide = holidaysOfYear(year)
            .where((h) => h.isNationwide)
            .length;
        expect(nationwide, 9, reason: '$year');
      }
    });

    test('days without football move one day earlier', () {
      final cal = HolidayCalendar();
      expect(cal.isNoFootballDay(GameDate(2027, 3, 26)), isTrue);
      expect(cal.playableDay(GameDate(2027, 3, 26)), GameDate(2027, 3, 25));
      expect(cal.isNoFootballDay(GameDate(2026, 11, 22)), isTrue);
      expect(cal.playableDay(GameDate(2026, 11, 22)), GameDate(2026, 11, 21));
      expect(cal.isNoFootballDay(GameDate(2026, 12, 24)), isTrue);
      expect(cal.isNoFootballDay(GameDate(2026, 12, 25)), isTrue);
      expect(cal.isNoFootballDay(GameDate(2026, 12, 26)), isFalse);
    });

    test('1 May on Friday to Sunday frees that weekend', () {
      final cal = HolidayCalendar();
      expect(cal.isLabourDayWeekend(GameDate(2026, 5, 2)), isTrue); // Friday
      expect(cal.isLabourDayWeekend(GameDate(2027, 5, 1)), isTrue); // Saturday
      expect(cal.isLabourDayWeekend(GameDate(2022, 4, 30)), isTrue); // Sunday
      expect(cal.isLabourDayWeekend(GameDate(2028, 4, 29)), isFalse); // Monday
    });
  });

  group('calendar rules', () {
    test('the rules file loads', () {
      final r = _rules();
      expect(
        r.leagues.keys,
        containsAll(['liga1', 'liga2', 'liga3', 'stufe4']),
      );
      expect(r.leagues['liga3']!.matchdays, 38);
    });

    test('a wrong schema version is rejected', () {
      expect(
        () => CalendarRules.fromJsonString('{"schema_version": 99}'),
        throwsA(isA<RulesError>()),
      );
    });

    test('kickoff times must be on the half hour', () {
      expect(parseMinuteOfDay('15:30'), 930);
      expect(() => parseMinuteOfDay('15:45'), throwsA(isA<RulesError>()));
    });
  });

  group('season 2026/27', () {
    final gen = CalendarGenerator(_rules());
    const season = Season(2026);

    test('Liga 3 starts on Friday 7 August with 10 matches', () {
      final c = gen.build(season, 'liga3');
      final first = c.matchdays.first;
      expect(first.firstDate, GameDate(2026, 8, 7));
      expect(first.matches, 10);
      expect(
        [for (final g in first.groups) '${g.date}T${g.timeLabel}x${g.matches}'],
        [
          '2026-08-07T19:00x1',
          '2026-08-08T14:00x5',
          '2026-08-08T16:30x1',
          '2026-08-09T13:30x1',
          '2026-08-09T16:30x1',
          '2026-08-09T19:30x1',
        ],
      );
    });

    test('Liga 3 has four English weeks and ends on 22 May', () {
      final c = gen.build(season, 'liga3');
      expect(c.midweekRounds, 4);
      expect(c.matchdays.length, 38);
      expect(c.lastDate, GameDate(2027, 5, 22));
      expect(c.matchdays.last.groups.single.timeLabel, '13:30');
    });

    test('Liga 3 winter break runs from 21 December to 14 January', () {
      final c = gen.build(season, 'liga3');
      final inBreak = [
        for (final m in c.matchdays)
          for (final g in m.groups)
            if (!g.date.isBefore(GameDate(2026, 12, 20)) &&
                !g.date.isAfter(GameDate(2027, 1, 14)))
              g.date,
      ];
      expect(inBreak, isEmpty);
      expect(c.winterBreakFirstSaturday, GameDate(2026, 12, 26));
      expect(
        c.matchdayOn(GameDate(2027, 1, 15)),
        isNotNull,
        reason: 'play resumes on Friday 15 January',
      );
    });

    test('Liga 1 starts late and has three to five English weeks', () {
      final c = gen.build(season, 'liga1');
      expect(c.matchdays.first.firstDate, GameDate(2026, 8, 28));
      expect(c.midweekRounds, inInclusiveRange(3, 5));
      final midweek = c.matchdays.firstWhere((m) => m.isMidweek);
      expect(midweek.matches, 9);
      expect([for (final g in midweek.groups) g.matches], [1, 3, 1, 4]);
    });

    test('the international break stops Liga 1 to 3 but not the fourth', () {
      for (final key in ['liga1', 'liga2', 'liga3']) {
        final c = gen.build(season, key);
        expect(c.matchdayOn(GameDate(2026, 9, 26)), isNull, reason: key);
        expect(c.matchdayOn(GameDate(2026, 10, 3)), isNull, reason: key);
        expect(c.internationalBreakSaturdays.length, 4, reason: key);
      }
      final s4 = gen.build(season, 'stufe4');
      expect(s4.matchdayOn(GameDate(2026, 9, 26)), isNotNull);
      expect(s4.internationalBreakSaturdays, isEmpty);
      expect(s4.midweekRounds, 0);
    });

    test('Liga 2 midweek rounds split into Tuesday and Wednesday', () {
      var c = gen.build(const Season(2026), 'liga2');
      for (var year = 2027; c.midweekRounds == 0 && year < 2060; year++) {
        c = gen.build(Season(year), 'liga2');
      }
      final mid = c.matchdays.where((m) => m.isMidweek).toList();
      expect(mid, isNotEmpty);
      for (final m in mid) {
        expect(m.groups.length, 2);
        expect(m.groups.first.date.weekday, 2);
        expect(m.groups.last.date.weekday, 3);
        expect(m.matches, 9);
      }
    });

    test('the last two matchdays of the fourth leagues are on Sundays', () {
      final c = gen.build(season, 'stufe4');
      for (final m in c.matchdays.sublist(c.matchdays.length - 2)) {
        expect(m.groups.length, 1);
        expect(m.groups.single.date.weekday, 7);
        expect(m.groups.single.timeLabel, '14:00');
      }
    });
  });

  group('100 seasons', () {
    final gen = CalendarGenerator(_rules());

    test('every league fits into every season', () {
      for (var year = 2026; year <= 2125; year++) {
        for (final key in gen.leagueKeys) {
          final c = gen.build(Season(year), key);
          final rules = gen.rules.leagues[key]!;
          final reason = '$year $key';
          expect(c.matchdays.length, rules.matchdays, reason: reason);
          expect(c.midweekRounds, lessThanOrEqualTo(rules.maxMidweekRounds));
          expect(c.midweekRounds, greaterThanOrEqualTo(rules.minMidweekRounds));
          expect(
            c.matchdays.where((m) => m.isMidweek).length,
            c.midweekRounds,
            reason: reason,
          );
          for (final m in c.matchdays) {
            expect(m.matches, rules.matchesPerMatchday, reason: reason);
          }
          expect(
            c.lastDate.isAfter(GameDate(year + 1, 5, 31)),
            isFalse,
            reason: reason,
          );
          expect(c.firstDate.isBefore(GameDate(year, 8, 1)), isFalse);
        }
      }
    });

    test('dates rise, nothing is played on days without football', () {
      final cal = HolidayCalendar();
      for (var year = 2026; year <= 2125; year++) {
        for (final key in gen.leagueKeys) {
          final c = gen.build(Season(year), key);
          GameDate? previous;
          for (final m in c.matchdays) {
            if (previous != null) {
              expect(
                m.firstDate.isAfter(previous),
                isTrue,
                reason: '$year $key',
              );
            }
            previous = m.lastDate;
            for (final g in m.groups) {
              expect(
                cal.isNoFootballDay(g.date),
                isFalse,
                reason: '$year $key',
              );
              expect(g.minuteOfDay % 30, 0);
            }
          }
          expect(c.matchdays[c.matchdays.length - 1].groups.length, 1);
          expect(c.matchdays[c.matchdays.length - 2].groups.length, 1);
          expect(c.matchdays.last.isMidweek, isFalse);
        }
      }
    });

    test('the players get 30 free working days with a block of 12', () {
      for (var year = 2026; year <= 2125; year++) {
        for (final key in gen.leagueKeys) {
          final v = gen.build(Season(year), key).vacation;
          expect(
            v.totalWerktage,
            greaterThanOrEqualTo(30),
            reason: '$year $key',
          );
          expect(
            v.longestBlockWerktage,
            greaterThanOrEqualTo(12),
            reason: '$year $key',
          );
        }
      }
    });

    test('the same input gives the same calendar', () {
      for (final key in gen.leagueKeys) {
        final a = _signature(gen.build(const Season(2031), key));
        final b = _signature(
          CalendarGenerator(_rules()).build(const Season(2031), key),
        );
        expect(a, b);
      }
    });

    test('Liga 1 starts at the end of August in even years', () {
      for (var year = 2026; year <= 2125; year += 2) {
        final c = gen.build(Season(year), 'liga1');
        expect(
          c.firstSaturday.isBefore(GameDate(year, 8, 29)),
          isFalse,
          reason: '$year',
        );
        expect(
          c.firstSaturday.isAfter(GameDate(year, 9, 4)),
          isFalse,
          reason: '$year',
        );
      }
    });
  });
}
