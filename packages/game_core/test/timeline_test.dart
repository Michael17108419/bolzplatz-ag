import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

late Rules rules;
late CalendarRules calendarRules;
late SeasonState state;

SeasonTimeline _build(int seed) {
  final schedules = {
    for (final e in state.members.entries)
      e.key: SeasonRunner.leagueSchedule(e.value, e.key, seed),
  };
  return SeasonTimeline.build(
    rules: rules,
    calendarRules: calendarRules,
    generator: CalendarGenerator(calendarRules),
    season: Season(state.startYear),
    schedules: schedules,
    seed: seed,
  );
}

String _signature(SeasonTimeline t) {
  final out = StringBuffer();
  for (final d in t.days) {
    out.write('${d.date}');
    for (final s in d.leagueSlots) {
      final ids = <String>[];
      for (final k in s.kicks) {
        ids.add('${k.league.value}.${k.matchday}.${k.fixture.home.value}');
      }
      out.write(' L${s.minuteOfDay}:${ids.join('/')}');
    }
    for (final w in d.cupWindows) {
      out.write(' C${w.kind.name}${w.round}@${w.minuteOfDay}');
    }
    out.writeln();
  }
  return out.toString();
}

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    calendarRules = CalendarRules.fromJsonString(
      File('../../rules/calendar_rules.json').readAsStringSync(),
    );
    state = SeasonState.fromWorld(
      WorldJson.decode(
        File('../../data/world_2026_27.json').readAsStringSync(),
      ),
    );
  });

  test('every league match is placed exactly once', () {
    final t = _build(5);
    final seen = <String>{};
    var count = 0;
    for (final d in t.days) {
      for (final s in d.leagueSlots) {
        for (final k in s.kicks) {
          count++;
          seen.add('${k.league.value}:${k.matchday}:${k.fixture.home.value}');
        }
      }
    }
    expect(count, 2522);
    expect(seen.length, 2522);
  });

  test('a club plays at most once per day', () {
    final t = _build(6);
    for (final d in t.days) {
      final clubs = <ClubId>{};
      for (final s in d.leagueSlots) {
        for (final k in s.kicks) {
          expect(clubs.add(k.fixture.home), isTrue, reason: '${d.date}');
          expect(clubs.add(k.fixture.away), isTrue, reason: '${d.date}');
        }
      }
    }
  });

  test('matchdays of a league are in order and on the calendar', () {
    final t = _build(7);
    final last = <LeagueId, int>{};
    for (final d in t.days) {
      for (final s in d.leagueSlots) {
        for (final k in s.kicks) {
          final before = last[k.league] ?? 0;
          expect(k.matchday, greaterThanOrEqualTo(before));
          expect(k.matchday - before, lessThanOrEqualTo(1));
          last[k.league] = k.matchday;
        }
      }
    }
    expect(t.firstDate, GameDate(2026, 8, 7));
    expect(t.lastDate.isAfter(GameDate(2027, 5, 31)), isFalse);
  });

  test('cup rounds have their own days with the right windows', () {
    final t = _build(8);
    final bolz = <int, List<CupWindow>>{};
    final pott = <int, GameDate>{};
    for (final d in t.days) {
      for (final w in d.cupWindows) {
        expect(d.hasLeagueMatches, isFalse, reason: '${d.date}');
        if (w.kind == CupKind.bolzplatz) {
          bolz.putIfAbsent(w.round, () => []).add(w);
        } else {
          pott[w.round] = d.date;
          expect(d.date.weekday, 3);
        }
      }
    }
    expect(bolz.keys.toList()..sort(), [0, 1, 2, 3, 4, 5]);
    for (var r = 0; r < 5; r++) {
      expect(bolz[r], hasLength(4), reason: 'round $r');
    }
    expect(bolz[5], hasLength(1));
    expect(pott.keys.toList()..sort(), [0, 1, 2, 3, 4]);
    expect(pott[0]!.month, 9);
    expect(pott[4]!.month, 1);
  });

  test('the Bolzplatz final is a Saturday after the last league weekend', () {
    final t = _build(9);
    final finalDay = t.days.lastWhere(
      (d) =>
          d.cupWindows.any((w) => w.kind == CupKind.bolzplatz && w.round == 5),
    );
    expect(finalDay.date.weekday, 6);
    for (final c in t.calendars.values) {
      expect(finalDay.date.isAfter(c.lastDate), isTrue);
    }
  });

  test('the same input gives the same timeline', () {
    expect(_signature(_build(10)), _signature(_build(10)));
    expect(_signature(_build(10)), isNot(_signature(_build(11))));
  });
}
