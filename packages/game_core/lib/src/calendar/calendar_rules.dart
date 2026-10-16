import 'dart:convert';

import '../rules/rules.dart';
import 'game_date.dart';

/// A month and day without a year, for example the 29th of August.
class MonthDay {
  const MonthDay(this.month, this.day);

  /// Parses `MM-DD`.
  factory MonthDay.parse(String text) {
    final parts = text.split('-');
    if (parts.length != 2) throw RulesError('Bad month-day "$text"');
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    if (month == null || day == null || month < 1 || month > 12) {
      throw RulesError('Bad month-day "$text"');
    }
    if (day < 1 || day > 31) throw RulesError('Bad month-day "$text"');
    return MonthDay(month, day);
  }

  final int month;
  final int day;

  /// The date in [year].
  GameDate inYear(int year) => GameDate(year, month, day);
}

/// Parses `HH:MM` into minutes after midnight.
int parseMinuteOfDay(String text) {
  final parts = text.split(':');
  final h = parts.length == 2 ? int.tryParse(parts[0]) : null;
  final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    throw RulesError('Bad time "$text"');
  }
  if (m % 30 != 0) {
    throw RulesError('Kickoff "$text" is not on the half hour grid');
  }
  return h * 60 + m;
}

/// One kickoff time on a weekend matchday.
class WeekendSlot {
  const WeekendSlot(this.weekday, this.minuteOfDay, this.matches);

  /// 1 = Monday to 7 = Sunday.
  final int weekday;
  final int minuteOfDay;
  final int matches;
}

/// One kickoff time of a midweek round. [matchOptions] has the possible
/// numbers of matches (one is picked at random); null means all matches that
/// are left after the other slots.
class MidweekSlot {
  const MidweekSlot(this.weekday, this.minuteOfDay, this.matchOptions);

  final int weekday;
  final int minuteOfDay;
  final List<int>? matchOptions;
}

/// Calendar rules of one league group (first league, second league, third
/// league and the five fourth leagues share the rules of their group).
class LeagueCalendarRules {
  const LeagueCalendarRules({
    required this.key,
    required this.matchdays,
    required this.matchesPerMatchday,
    required this.startEvenYear,
    required this.startOddYear,
    required this.preparationWeeks,
    required this.winterBreakWeekends,
    required this.internationalBreaks,
    required this.minMidweekRounds,
    required this.maxMidweekRounds,
    required this.weekendSlots,
    required this.finalWeekday,
    required this.finalMinuteOfDay,
    required this.midweekSlots,
  });

  factory LeagueCalendarRules.fromJson(String key, Map<String, dynamic> m) {
    List<WeekendSlot> weekend() => [
      for (final s in m['weekend_slots'] as List<dynamic>)
        WeekendSlot(
          (s as Map<String, dynamic>)['weekday'] as int,
          parseMinuteOfDay(s['time'] as String),
          s['matches'] as int,
        ),
    ];
    List<MidweekSlot> midweek() => [
      for (final s in m['midweek_slots'] as List<dynamic>)
        MidweekSlot(
          (s as Map<String, dynamic>)['weekday'] as int,
          parseMinuteOfDay(s['time'] as String),
          s['matches'] is List<dynamic>
              ? [for (final v in s['matches'] as List<dynamic>) v as int]
              : (s['matches'] as int) < 0
              ? null
              : [s['matches'] as int],
        ),
    ];
    final fin = m['final_slot'] as Map<String, dynamic>;
    final rules = LeagueCalendarRules(
      key: key,
      matchdays: m['matchdays'] as int,
      matchesPerMatchday: m['matches_per_matchday'] as int,
      startEvenYear: MonthDay.parse(m['start_even_year'] as String),
      startOddYear: MonthDay.parse(m['start_odd_year'] as String),
      preparationWeeks: m['preparation_weeks'] as int,
      winterBreakWeekends: m['winter_break_weekends'] as int,
      internationalBreaks: m['international_breaks'] as bool,
      minMidweekRounds: m['min_midweek_rounds'] as int,
      maxMidweekRounds: m['max_midweek_rounds'] as int,
      weekendSlots: weekend(),
      finalWeekday: fin['weekday'] as int,
      finalMinuteOfDay: parseMinuteOfDay(fin['time'] as String),
      midweekSlots: midweek(),
    );
    final slotSum = rules.weekendSlots.fold<int>(0, (a, s) => a + s.matches);
    if (slotSum != rules.matchesPerMatchday) {
      throw RulesError('$key: weekend slots do not add up to the matches');
    }
    if (rules.matchdays != (rules.matchesPerMatchday * 2 - 1) * 2) {
      throw RulesError('$key: matchdays do not fit the number of matches');
    }
    if (rules.maxMidweekRounds > 0 && rules.midweekSlots.isEmpty) {
      throw RulesError('$key: midweek rounds allowed but no midweek slots');
    }
    return rules;
  }

  final String key;
  final int matchdays;
  final int matchesPerMatchday;
  final MonthDay startEvenYear;
  final MonthDay startOddYear;
  final int preparationWeeks;
  final int winterBreakWeekends;
  final bool internationalBreaks;
  final int minMidweekRounds;
  final int maxMidweekRounds;
  final List<WeekendSlot> weekendSlots;

  /// The last two matchdays: all matches at once on this weekday and time.
  final int finalWeekday;
  final int finalMinuteOfDay;
  final List<MidweekSlot> midweekSlots;
}

/// A window of international matches that stops the leagues of the upper
/// tiers for [weekends] weekends.
class InternationalBreakRule {
  const InternationalBreakRule(this.firstSaturdayOnOrAfter, this.weekends);

  final MonthDay firstSaturdayOnOrAfter;
  final int weekends;
}

/// All calendar numbers of one season rule set. Loaded from
/// `calendar_rules.json`.
class CalendarRules {
  const CalendarRules._({
    required this.schemaVersion,
    required this.lastWeekendWeeksBeforeMay31,
    required this.lastWeekendOverrides,
    required this.winterBreakFirstSaturday,
    required this.internationalBreaks,
    required this.vacationWerktage,
    required this.vacationBlockWerktage,
    required this.restartTrainingDays,
    required this.leagues,
  });

  static const int supportedSchemaVersion = 1;

  factory CalendarRules.fromJsonString(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException catch (e) {
      throw RulesError('Calendar rules are not valid JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const RulesError('Calendar rules must be a JSON object');
    }
    if (decoded['schema_version'] != supportedSchemaVersion) {
      throw RulesError(
        'Unsupported calendar schema ${decoded['schema_version']}',
      );
    }
    final last = decoded['last_weekend'] as Map<String, dynamic>;
    final overrides = <int, GameDate>{};
    final rawOverrides = last['overrides'] as Map<String, dynamic>;
    for (final e in rawOverrides.entries) {
      final p = (e.value as String).split('-');
      overrides[int.parse(e.key)] = GameDate(
        int.parse(p[0]),
        int.parse(p[1]),
        int.parse(p[2]),
      );
    }
    final vac = decoded['vacation'] as Map<String, dynamic>;
    final leagues = <String, LeagueCalendarRules>{};
    for (final e in (decoded['leagues'] as Map<String, dynamic>).entries) {
      leagues[e.key] = LeagueCalendarRules.fromJson(
        e.key,
        e.value as Map<String, dynamic>,
      );
    }
    return CalendarRules._(
      schemaVersion: decoded['schema_version'] as int,
      lastWeekendWeeksBeforeMay31: last['weeks_before_may_31_weekend'] as int,
      lastWeekendOverrides: Map.unmodifiable(overrides),
      winterBreakFirstSaturday: MonthDay.parse(
        (decoded['winter_break']
                as Map<String, dynamic>)['first_saturday_on_or_after']
            as String,
      ),
      internationalBreaks: List.unmodifiable([
        for (final b in decoded['international_breaks'] as List<dynamic>)
          InternationalBreakRule(
            MonthDay.parse(
              (b as Map<String, dynamic>)['first_saturday_on_or_after']
                  as String,
            ),
            b['weekends'] as int,
          ),
      ]),
      vacationWerktage: vac['werktage_per_season'] as int,
      vacationBlockWerktage: vac['block_werktage'] as int,
      restartTrainingDays: vac['restart_training_days'] as int,
      leagues: Map.unmodifiable(leagues),
    );
  }

  final int schemaVersion;

  /// The last league weekend lies this many weekends before the weekend on
  /// or before 31 May (room for relegation, cup final and the like).
  final int lastWeekendWeeksBeforeMay31;

  /// Fixed last league weekends for single seasons, by start year.
  final Map<int, GameDate> lastWeekendOverrides;
  final MonthDay winterBreakFirstSaturday;
  final List<InternationalBreakRule> internationalBreaks;
  final int vacationWerktage;
  final int vacationBlockWerktage;
  final int restartTrainingDays;
  final Map<String, LeagueCalendarRules> leagues;
}
