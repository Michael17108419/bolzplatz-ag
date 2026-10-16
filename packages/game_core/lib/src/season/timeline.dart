import '../calendar/calendar_rules.dart';
import '../calendar/game_date.dart';
import '../calendar/holidays.dart';
import '../calendar/season.dart';
import '../calendar/season_calendar.dart';
import '../model/ids.dart';
import '../rng/seeded_random.dart';
import '../rules/rules.dart';
import 'schedule.dart';

/// One league match placed in the calendar.
class LeagueKick {
  const LeagueKick(this.league, this.matchday, this.fixture);

  final LeagueId league;

  /// Matchday number of the league, starting at 1.
  final int matchday;
  final Fixture fixture;
}

/// League matches that kick off together.
class LeagueSlot {
  const LeagueSlot(this.minuteOfDay, this.kicks);

  final int minuteOfDay;
  final List<LeagueKick> kicks;
}

enum CupKind { bolzplatz, pott }

/// A kickoff window of a cup round. The ties of the round are spread over
/// its windows when the round is drawn.
class CupWindow {
  const CupWindow({
    required this.kind,
    required this.round,
    required this.minuteOfDay,
    required this.index,
    required this.count,
  });

  final CupKind kind;

  /// Round number, starting at 0.
  final int round;
  final int minuteOfDay;

  /// Position of this window among the [count] windows of the round.
  final int index;
  final int count;
}

/// Everything that is played on one calendar day.
class DayPlan {
  DayPlan(this.date);

  final GameDate date;
  final List<LeagueSlot> leagueSlots = [];
  final List<CupWindow> cupWindows = [];

  bool get hasLeagueMatches => leagueSlots.isNotEmpty;

  int get leagueMatches => leagueSlots.fold(0, (a, s) => a + s.kicks.length);
}

/// The whole season on the calendar: for every day with matches the league
/// kickoff groups and the cup windows. Built once from the schedules and the
/// calendar rules, it only depends on its inputs.
class SeasonTimeline {
  SeasonTimeline._(this.season, this.days, this.calendars, this.leagueGroup);

  final Season season;

  /// Days with matches, in date order.
  final List<DayPlan> days;

  /// Calendar of each league group (`liga1`, `liga2`, `liga3`, `stufe4`).
  final Map<String, LeagueCalendar> calendars;

  /// Calendar group of each league.
  final Map<LeagueId, String> leagueGroup;

  /// The plan of [date], or null if nothing is played.
  DayPlan? planOn(GameDate date) {
    var lo = 0;
    var hi = days.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      final c = days[mid].date.compareTo(date);
      if (c == 0) return days[mid];
      if (c < 0) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return null;
  }

  /// Index of the first day on or after [date], or -1 if there is none.
  int firstIndexOnOrAfter(GameDate date) {
    for (var i = 0; i < days.length; i++) {
      if (!days[i].date.isBefore(date)) return i;
    }
    return -1;
  }

  /// First and last day with matches.
  GameDate get firstDate => days.first.date;

  GameDate get lastDate => days.last.date;

  /// Calendar group for a league level.
  static String groupKeyOfLevel(int level) => switch (level) {
    1 => 'liga1',
    2 => 'liga2',
    3 => 'liga3',
    _ => 'stufe4',
  };

  /// Builds the timeline. [schedules] has the fixtures of each league per
  /// matchday; they are spread over the kickoff groups of the calendar with
  /// the generator of [seed].
  static SeasonTimeline build({
    required Rules rules,
    required CalendarRules calendarRules,
    required CalendarGenerator generator,
    required Season season,
    required Map<LeagueId, List<List<Fixture>>> schedules,
    required int seed,
  }) {
    final levelOf = {for (final l in rules.leagues) LeagueId(l.id): l.level};
    final byDate = <int, DayPlan>{};
    DayPlan plan(GameDate d) =>
        byDate.putIfAbsent(d.epochDay, () => DayPlan(d));

    final calendars = <String, LeagueCalendar>{};
    final groupOf = <LeagueId, String>{};
    final root = SeededRandom(seed).fork('timeline');
    for (final e in schedules.entries) {
      final key = groupKeyOfLevel(levelOf[e.key] ?? 4);
      groupOf[e.key] = key;
      final cal = calendars.putIfAbsent(key, () => generator.build(season, key));
      if (cal.matchdays.length != e.value.length) {
        throw StateError(
          'League ${e.key.value} has ${e.value.length} matchdays, '
          'the calendar ${cal.matchdays.length}',
        );
      }
      for (var i = 0; i < e.value.length; i++) {
        final cm = cal.matchdays[i];
        final fixtures = List<Fixture>.of(e.value[i]);
        root.fork('slots:${e.key.value}:${i + 1}').shuffle(fixtures);
        var next = 0;
        for (final g in cm.groups) {
          final kicks = [
            for (var k = 0; k < g.matches; k++)
              LeagueKick(e.key, i + 1, fixtures[next++]),
          ];
          final day = plan(g.date);
          final slot = day.leagueSlots
              .where((s) => s.minuteOfDay == g.minuteOfDay)
              .firstOrNull;
          if (slot == null) {
            day.leagueSlots.add(LeagueSlot(g.minuteOfDay, kicks));
          } else {
            slot.kicks.addAll(kicks);
          }
        }
        if (next != fixtures.length) {
          throw StateError('Calendar and schedule differ in matches per day');
        }
      }
    }
    for (final d in byDate.values) {
      d.leagueSlots.sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    }

    _placeCups(rules, calendarRules, generator.holidays, calendars, byDate);

    final days = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final d in days) {
      d.cupWindows.sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    }
    return SeasonTimeline._(
      season,
      List.unmodifiable(days),
      Map.unmodifiable(calendars),
      Map.unmodifiable(groupOf),
    );
  }

  static void _placeCups(
    Rules rules,
    CalendarRules calendarRules,
    HolidayCalendar holidays,
    Map<String, LeagueCalendar> calendars,
    Map<int, DayPlan> byDate,
  ) {
    final cups = calendarRules.cups;
    final first = calendars['liga1']!;

    bool leagueFree(GameDate d) =>
        !(byDate[d.epochDay]?.hasLeagueMatches ?? false) &&
        !holidays.isNoFootballDay(d);

    /// The Tuesday and Wednesday of the first week after [from] in which
    /// both days are free of league matches and cup rounds.
    GameDate freeTuesday(GameDate from) {
      var monday = from.plusDays(8 - from.weekday);
      for (var i = 0; i < 12; i++) {
        final tue = monday.plusDays(1);
        final wed = monday.plusDays(2);
        final clash = (byDate[tue.epochDay]?.cupWindows.isNotEmpty ?? false) ||
            (byDate[wed.epochDay]?.cupWindows.isNotEmpty ?? false);
        if (leagueFree(tue) && leagueFree(wed) && !clash) return tue;
        monday = monday.plusDays(7);
      }
      throw StateError('No free week for a cup round');
    }

    void add(
      GameDate date,
      CupKind kind,
      int round,
      int minute,
      int index,
      int count,
    ) {
      byDate
          .putIfAbsent(date.epochDay, () => DayPlan(date))
          .cupWindows
          .add(
            CupWindow(
              kind: kind,
              round: round,
              minuteOfDay: minute,
              index: index,
              count: count,
            ),
          );
    }

    final bolzAfter = rules.season.cups.bolzplatzAfterMatchday;
    for (var r = 0; r < bolzAfter.length; r++) {
      final isFinal = r == bolzAfter.length - 1;
      if (isFinal) {
        final lastLeague = [
          for (final c in calendars.values) c.lastDate,
        ].reduce((a, b) => a.isAfter(b) ? a : b);
        final saturday = CalendarGenerator.saturdayOnOrBefore(lastLeague)
            .plusDays(7 * cups.bolzplatzFinalWeeksAfterLastLeagueWeekend);
        add(
          holidays.playableDay(
            saturday.plusDays(cups.bolzplatzFinal.weekday - 6),
          ),
          CupKind.bolzplatz,
          r,
          cups.bolzplatzFinal.minuteOfDay,
          0,
          1,
        );
        continue;
      }
      final md = bolzAfter[r].clamp(1, first.matchdays.length).toInt();
      final tue = freeTuesday(first.matchdays[md - 1].lastDate);
      final windows = cups.bolzplatzWindows;
      for (var w = 0; w < windows.length; w++) {
        add(
          tue.plusDays(windows[w].weekday - 2),
          CupKind.bolzplatz,
          r,
          windows[w].minuteOfDay,
          w,
          windows.length,
        );
      }
    }

    final pottRounds = rules.season.cups.pottAfterMatchday.length;
    final year = first.season.startYear;
    for (var r = 0; r < pottRounds; r++) {
      final month = cups.pottMonths[r % cups.pottMonths.length];
      final y = month >= 7 ? year : year + 1;
      var d = GameDate(y, month, cups.pottFirstDayOfMonth);
      d = d.plusDays((cups.pottWindow.weekday - d.weekday) % 7);
      for (var i = 0; i < 8; i++) {
        final clash = byDate[d.epochDay]?.cupWindows.isNotEmpty ?? false;
        if (leagueFree(d) && !clash) break;
        d = d.plusDays(7);
      }
      add(d, CupKind.pott, r, cups.pottWindow.minuteOfDay, 0, 1);
    }
  }
}
