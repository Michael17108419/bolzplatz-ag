import 'game_date.dart';

/// The 16 German federal states, used for regional public holidays.
enum Bundesland {
  badenWuerttemberg,
  bayern,
  berlin,
  brandenburg,
  bremen,
  hamburg,
  hessen,
  mecklenburgVorpommern,
  niedersachsen,
  nordrheinWestfalen,
  rheinlandPfalz,
  saarland,
  sachsen,
  sachsenAnhalt,
  schleswigHolstein,
  thueringen,
}

/// A public holiday on one date. [states] is null for a nationwide holiday.
class Holiday {
  const Holiday(this.key, this.date, [this.states]);

  /// Language file key part, for example `newYear`.
  final String key;
  final GameDate date;
  final Set<Bundesland>? states;

  bool get isNationwide => states == null;

  bool appliesTo(Bundesland state) => states == null || states!.contains(state);
}

/// Easter Sunday of [year] (anonymous Gregorian algorithm).
GameDate easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = (h + l - 7 * m + 114) % 31 + 1;
  return GameDate(year, month, day);
}

/// First Sunday of Advent: the Sunday from 27 November to 3 December.
GameDate firstAdvent(int year) {
  final start = GameDate(year, 11, 27);
  return start.plusDays((7 - start.weekday) % 7);
}

/// Sunday of the Dead (Totensonntag), the Sunday before the first Advent.
GameDate totensonntag(int year) => firstAdvent(year).plusDays(-7);

/// People's Mourning Day (Volkstrauertag), two Sundays before the first Advent.
GameDate volkstrauertag(int year) => firstAdvent(year).plusDays(-14);

/// Day of Repentance and Prayer (Buß- und Bettag), the Wednesday before
/// 23 November.
GameDate bussUndBettag(int year) {
  final d = GameDate(year, 11, 22);
  return d.plusDays(-((d.weekday - 3) % 7));
}

const Set<Bundesland> _dreiKoenige = {
  Bundesland.badenWuerttemberg,
  Bundesland.bayern,
  Bundesland.sachsenAnhalt,
};
const Set<Bundesland> _frauentag = {
  Bundesland.berlin,
  Bundesland.mecklenburgVorpommern,
};
const Set<Bundesland> _fronleichnam = {
  Bundesland.badenWuerttemberg,
  Bundesland.bayern,
  Bundesland.hessen,
  Bundesland.nordrheinWestfalen,
  Bundesland.rheinlandPfalz,
  Bundesland.saarland,
};
const Set<Bundesland> _mariaHimmelfahrt = {
  Bundesland.saarland,
  Bundesland.bayern,
};
const Set<Bundesland> _weltkindertag = {Bundesland.thueringen};
const Set<Bundesland> _reformationstag = {
  Bundesland.brandenburg,
  Bundesland.bremen,
  Bundesland.hamburg,
  Bundesland.mecklenburgVorpommern,
  Bundesland.niedersachsen,
  Bundesland.sachsen,
  Bundesland.sachsenAnhalt,
  Bundesland.schleswigHolstein,
  Bundesland.thueringen,
};
const Set<Bundesland> _allerheiligen = {
  Bundesland.badenWuerttemberg,
  Bundesland.bayern,
  Bundesland.nordrheinWestfalen,
  Bundesland.rheinlandPfalz,
  Bundesland.saarland,
};
const Set<Bundesland> _bussUndBettag = {Bundesland.sachsen};
const Set<Bundesland> _osterPfingstSonntag = {Bundesland.brandenburg};

/// All public holidays of one calendar year in Germany, sorted by date.
List<Holiday> holidaysOfYear(int year) {
  final easter = easterSunday(year);
  final list = <Holiday>[
    Holiday('newYear', GameDate(year, 1, 1)),
    Holiday('epiphany', GameDate(year, 1, 6), _dreiKoenige),
    Holiday('womensDay', GameDate(year, 3, 8), _frauentag),
    Holiday('goodFriday', easter.plusDays(-2)),
    Holiday('easterSunday', easter, _osterPfingstSonntag),
    Holiday('easterMonday', easter.plusDays(1)),
    Holiday('labourDay', GameDate(year, 5, 1)),
    Holiday('ascension', easter.plusDays(39)),
    Holiday('whitSunday', easter.plusDays(49), _osterPfingstSonntag),
    Holiday('whitMonday', easter.plusDays(50)),
    Holiday('corpusChristi', easter.plusDays(60), _fronleichnam),
    Holiday('assumption', GameDate(year, 8, 15), _mariaHimmelfahrt),
    Holiday('childrensDay', GameDate(year, 9, 20), _weltkindertag),
    Holiday('unityDay', GameDate(year, 10, 3)),
    Holiday('reformationDay', GameDate(year, 10, 31), _reformationstag),
    Holiday('allSaints', GameDate(year, 11, 1), _allerheiligen),
    Holiday('repentanceDay', bussUndBettag(year), _bussUndBettag),
    Holiday('christmasDay', GameDate(year, 12, 25)),
    Holiday('boxingDay', GameDate(year, 12, 26)),
  ];
  list.sort((a, b) => a.date.compareTo(b.date));
  return list;
}

/// Looks up holidays and the days on which no football is played.
class HolidayCalendar {
  HolidayCalendar();

  final Map<int, Map<int, List<Holiday>>> _byYear = {};

  Map<int, List<Holiday>> _year(int year) {
    return _byYear.putIfAbsent(year, () {
      final map = <int, List<Holiday>>{};
      for (final h in holidaysOfYear(year)) {
        map.putIfAbsent(h.date.epochDay, () => []).add(h);
      }
      return map;
    });
  }

  /// Holidays on [date] that apply to [state] (all nationwide ones when
  /// [state] is null, otherwise also the regional ones of that state).
  List<Holiday> holidaysOn(GameDate date, {Bundesland? state}) {
    final all = _year(date.year)[date.epochDay] ?? const <Holiday>[];
    return [
      for (final h in all)
        if (h.isNationwide || (state != null && h.appliesTo(state))) h,
    ];
  }

  bool isHoliday(GameDate date, {Bundesland? state}) =>
      holidaysOn(date, state: state).isNotEmpty;

  /// True on days without any football: Good Friday, the Sunday of the Dead,
  /// People's Mourning Day, 24 and 25 December. Games move one day earlier.
  bool isNoFootballDay(GameDate date) {
    final y = date.year;
    if (date.month == 12 && (date.day == 24 || date.day == 25)) return true;
    if (date == easterSunday(y).plusDays(-2)) return true;
    if (date == totensonntag(y) || date == volkstrauertag(y)) return true;
    return false;
  }

  /// The date a game planned for [date] is actually played: the day before
  /// if [date] is a no-football day (repeated until a free day is found).
  GameDate playableDay(GameDate date) {
    var d = date;
    while (isNoFootballDay(d)) {
      d = d.plusDays(-1);
    }
    return d;
  }

  /// True if the weekend with the given [saturday] is free because 1 May
  /// falls on a Friday, Saturday or Sunday of that weekend.
  bool isLabourDayWeekend(GameDate saturday) {
    for (var offset = -1; offset <= 1; offset++) {
      final d = saturday.plusDays(offset);
      if (d.month == 5 && d.day == 1) return true;
    }
    return false;
  }
}
