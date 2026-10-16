import '../rng/seeded_random.dart';
import 'calendar_rules.dart';
import 'game_date.dart';
import 'holidays.dart';
import 'season.dart';

/// Matches that kick off together on one date and time.
class KickoffGroup {
  const KickoffGroup(this.date, this.minuteOfDay, this.matches);

  final GameDate date;

  /// Minutes after midnight, always on the half hour.
  final int minuteOfDay;
  final int matches;

  int get hour => minuteOfDay ~/ 60;
  int get minute => minuteOfDay % 60;

  /// Time as `HH:MM`.
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// One matchday of a league with its kickoff groups in time order.
class CalendarMatchday {
  const CalendarMatchday(this.number, this.isMidweek, this.groups);

  /// Matchday number, starting at 1.
  final int number;

  /// True for an "English week" round on Tuesday and Wednesday.
  final bool isMidweek;
  final List<KickoffGroup> groups;

  GameDate get firstDate => groups.first.date;

  GameDate get lastDate => groups.last.date;

  int get matches => groups.fold(0, (a, g) => a + g.matches);
}

/// Free days of the players in a season, counted in working days (Monday to
/// Saturday without public holidays).
class VacationPlan {
  const VacationPlan({
    required this.summerStart,
    required this.summerEnd,
    required this.summerWerktage,
    required this.winterStart,
    required this.winterEnd,
    required this.winterWerktage,
  });

  final GameDate summerStart;
  final GameDate summerEnd;
  final int summerWerktage;
  final GameDate winterStart;
  final GameDate winterEnd;
  final int winterWerktage;

  int get totalWerktage => summerWerktage + winterWerktage;

  /// The longer of the two blocks.
  int get longestBlockWerktage =>
      summerWerktage > winterWerktage ? summerWerktage : winterWerktage;
}

/// The calendar of one league group in one season.
class LeagueCalendar {
  const LeagueCalendar({
    required this.leagueKey,
    required this.season,
    required this.matchdays,
    required this.usableWeekends,
    required this.midweekRounds,
    required this.preparationStart,
    required this.firstSaturday,
    required this.winterBreakFirstSaturday,
    required this.winterBreakWeekends,
    required this.internationalBreakSaturdays,
    required this.vacation,
  });

  final String leagueKey;
  final Season season;
  final List<CalendarMatchday> matchdays;

  /// Weekends left for league matchdays after breaks and holidays.
  final int usableWeekends;

  /// Number of English weeks in this season.
  final int midweekRounds;
  final GameDate preparationStart;
  final GameDate firstSaturday;
  final GameDate winterBreakFirstSaturday;
  final int winterBreakWeekends;

  /// Saturdays of the weekends without league games because of international
  /// matches (empty for leagues without such breaks).
  final List<GameDate> internationalBreakSaturdays;
  final VacationPlan vacation;

  GameDate get firstDate => matchdays.first.firstDate;

  GameDate get lastDate => matchdays.last.lastDate;

  /// The matchday played on [date], or null.
  CalendarMatchday? matchdayOn(GameDate date) {
    for (final m in matchdays) {
      for (final g in m.groups) {
        if (g.date == date) return m;
      }
    }
    return null;
  }
}

/// Builds league calendars from [CalendarRules]. The result only depends on
/// the rules, the season and the league key, so the same input always gives
/// the same calendar.
class CalendarGenerator {
  CalendarGenerator(this.rules, [HolidayCalendar? holidays])
    : holidays = holidays ?? HolidayCalendar();

  final CalendarRules rules;
  final HolidayCalendar holidays;

  /// Saturday on or after [date].
  static GameDate saturdayOnOrAfter(GameDate date) =>
      date.plusDays((6 - date.weekday) % 7);

  /// Saturday on or before [date].
  static GameDate saturdayOnOrBefore(GameDate date) =>
      date.plusDays(-((date.weekday - 6) % 7));

  /// The league keys known to the rules.
  List<String> get leagueKeys => rules.leagues.keys.toList();

  /// Builds the calendar of [leagueKey] for [season].
  LeagueCalendar build(Season season, String leagueKey) {
    final lr = rules.leagues[leagueKey];
    if (lr == null) throw ArgumentError('Unknown league group $leagueKey');
    final year = season.startYear;

    final startRule = year.isEven ? lr.startEvenYear : lr.startOddYear;
    final firstSaturday = saturdayOnOrAfter(startRule.inYear(year));
    final lastSaturday =
        rules.lastWeekendOverrides[year] ??
        saturdayOnOrBefore(GameDate(year + 1, 5, 31))
            .plusDays(-7 * rules.lastWeekendWeeksBeforeMay31);

    final breakFirst = saturdayOnOrAfter(
      rules.winterBreakFirstSaturday.inYear(year),
    );
    final winterSaturdays = {
      for (var i = 0; i < lr.winterBreakWeekends; i++)
        breakFirst.plusDays(7 * i).epochDay,
    };
    final intlSaturdays = <GameDate>[];
    if (lr.internationalBreaks) {
      for (final b in rules.internationalBreaks) {
        final month = b.firstSaturdayOnOrAfter.month;
        final y = month >= 7 ? year : year + 1;
        final first = saturdayOnOrAfter(b.firstSaturdayOnOrAfter.inYear(y));
        for (var i = 0; i < b.weekends; i++) {
          intlSaturdays.add(first.plusDays(7 * i));
        }
      }
    }
    final intlSet = {for (final d in intlSaturdays) d.epochDay};

    final weekends = <GameDate>[];
    for (var d = firstSaturday; !d.isAfter(lastSaturday); d = d.plusDays(7)) {
      if (winterSaturdays.contains(d.epochDay)) continue;
      if (intlSet.contains(d.epochDay)) continue;
      if (holidays.isLabourDayWeekend(d)) continue;
      weekends.add(d);
    }

    final shortage = lr.matchdays - weekends.length;
    final midweek = shortage < lr.minMidweekRounds
        ? lr.minMidweekRounds
        : shortage;
    if (midweek > lr.maxMidweekRounds) {
      throw StateError(
        '${season.label} $leagueKey needs $midweek English weeks, '
        'at most ${lr.maxMidweekRounds} allowed',
      );
    }
    final weekendMatchdays = lr.matchdays - midweek;
    if (weekendMatchdays > weekends.length) {
      throw StateError('Not enough weekends for ${season.label} $leagueKey');
    }
    final used = weekends.sublist(0, weekendMatchdays);

    final rng = SeededRandom(year).fork('calendar:$leagueKey');
    final midweekBefore = _chooseMidweekWeekends(used, midweek);

    final days = <CalendarMatchday>[];
    var number = 0;
    for (var i = 0; i < used.length; i++) {
      if (midweekBefore.contains(i)) {
        number++;
        days.add(
          CalendarMatchday(number, true, _midweekGroups(lr, used[i], rng)),
        );
      }
      number++;
      final isFinal = number > lr.matchdays - 2;
      days.add(
        CalendarMatchday(
          number,
          false,
          isFinal ? _finalGroups(lr, used[i]) : _weekendGroups(lr, used[i]),
        ),
      );
    }

    final prepStart = firstSaturday.plusDays(-7 * lr.preparationWeeks);
    final restartSaturday = breakFirst.plusDays(7 * lr.winterBreakWeekends);
    final summerEnd = prepStart.plusDays(-1);
    final winterStart = breakFirst.plusDays(-5);
    final winterEnd = restartSaturday.plusDays(-rules.restartTrainingDays);
    final vacation = VacationPlan(
      summerStart: season.start,
      summerEnd: summerEnd,
      summerWerktage: _werktage(season.start, summerEnd),
      winterStart: winterStart,
      winterEnd: winterEnd,
      winterWerktage: _werktage(winterStart, winterEnd),
    );

    return LeagueCalendar(
      leagueKey: leagueKey,
      season: season,
      matchdays: List.unmodifiable(days),
      usableWeekends: weekends.length,
      midweekRounds: midweek,
      preparationStart: prepStart,
      firstSaturday: firstSaturday,
      winterBreakFirstSaturday: breakFirst,
      winterBreakWeekends: lr.winterBreakWeekends,
      internationalBreakSaturdays: List.unmodifiable(intlSaturdays),
      vacation: vacation,
    );
  }

  /// Working days (Monday to Saturday, no public holiday) from [from] to
  /// [to], both included.
  int _werktage(GameDate from, GameDate to) {
    var n = 0;
    for (var d = from; !d.isAfter(to); d = d.plusDays(1)) {
      if (d.weekday == 7) continue;
      if (holidays.isHoliday(d)) continue;
      n++;
    }
    return n;
  }

  /// Indices into [weekends] before which a midweek round is played. They are
  /// spread evenly and never among the first three or last three weekends.
  Set<int> _chooseMidweekWeekends(List<GameDate> weekends, int count) {
    final chosen = <int>{};
    if (count == 0) return chosen;
    const low = 3;
    final high = weekends.length - 4;
    final span = high - low;
    for (var k = 0; k < count; k++) {
      var idx = low + ((k + 1) * span) ~/ (count + 1);
      while (idx <= high && !_midweekIsFree(weekends, chosen, idx)) {
        idx++;
      }
      if (idx > high) {
        throw StateError('No free week for an English week');
      }
      chosen.add(idx);
    }
    return chosen;
  }

  bool _midweekIsFree(List<GameDate> weekends, Set<int> chosen, int idx) {
    if (chosen.contains(idx) || chosen.contains(idx - 1)) return false;
    final saturday = weekends[idx];
    // The weekend before must have been a league weekend (no break week).
    if (weekends[idx - 1].daysUntil(saturday) != 7) return false;
    final tuesday = saturday.plusDays(-4);
    final wednesday = saturday.plusDays(-3);
    return !holidays.isNoFootballDay(tuesday) &&
        !holidays.isNoFootballDay(wednesday);
  }

  List<KickoffGroup> _weekendGroups(LeagueCalendarRules lr, GameDate saturday) {
    return _merge([
      for (final s in lr.weekendSlots)
        KickoffGroup(
          holidays.playableDay(saturday.plusDays(s.weekday - 6)),
          s.minuteOfDay,
          s.matches,
        ),
    ]);
  }

  List<KickoffGroup> _finalGroups(LeagueCalendarRules lr, GameDate saturday) {
    return [
      KickoffGroup(
        holidays.playableDay(saturday.plusDays(lr.finalWeekday - 6)),
        lr.finalMinuteOfDay,
        lr.matchesPerMatchday,
      ),
    ];
  }

  List<KickoffGroup> _midweekGroups(
    LeagueCalendarRules lr,
    GameDate saturday,
    SeededRandom rng,
  ) {
    var left = lr.matchesPerMatchday;
    final groups = <KickoffGroup>[];
    for (final s in lr.midweekSlots) {
      final options = s.matchOptions;
      final n = options == null
          ? left
          : options[options.length == 1 ? 0 : rng.nextInt(options.length)];
      left -= n;
      groups.add(
        KickoffGroup(
          holidays.playableDay(saturday.plusDays(s.weekday - 6)),
          s.minuteOfDay,
          n,
        ),
      );
    }
    if (left != 0) throw StateError('Midweek slots do not fit the matches');
    return _merge(groups);
  }

  /// Sorts by time and merges groups with the same date and time.
  List<KickoffGroup> _merge(List<KickoffGroup> groups) {
    final sorted = [...groups]
      ..sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : a.minuteOfDay.compareTo(b.minuteOfDay);
      });
    final out = <KickoffGroup>[];
    for (final g in sorted) {
      if (out.isNotEmpty &&
          out.last.date == g.date &&
          out.last.minuteOfDay == g.minuteOfDay) {
        final p = out.removeLast();
        out.add(KickoffGroup(p.date, p.minuteOfDay, p.matches + g.matches));
      } else {
        out.add(g);
      }
    }
    return List.unmodifiable(out);
  }
}
