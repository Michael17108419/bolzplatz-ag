/// A calendar date in the game world, without time of day and time zone.
///
/// Implemented with integer arithmetic only, so it never touches the
/// system clock.
class GameDate implements Comparable<GameDate> {
  /// Creates a date and checks that it exists.
  GameDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12 || day < 1 || day > daysInMonth(year, month)) {
      throw ArgumentError('Invalid date $year-$month-$day');
    }
  }

  /// Creates a date from a day count where 0 is 1970-01-01.
  factory GameDate.fromEpochDay(int epochDay) {
    final z = epochDay + 719468;
    final era = (z >= 0 ? z : z - 146096) ~/ 146097;
    final doe = z - era * 146097;
    final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
    final doy = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
    final mp = (5 * doy + 2) ~/ 153;
    final day = doy - (153 * mp + 2) ~/ 5 + 1;
    final month = mp < 10 ? mp + 3 : mp - 9;
    final year = yoe + era * 400 + (month <= 2 ? 1 : 0);
    return GameDate(year, month, day);
  }

  final int year;
  final int month;
  final int day;

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  static int daysInMonth(int year, int month) {
    const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && isLeapYear(year)) return 29;
    return lengths[month - 1];
  }

  /// Days since 1970-01-01 (negative before).
  int get epochDay {
    final y = month <= 2 ? year - 1 : year;
    final era = (y >= 0 ? y : y - 399) ~/ 400;
    final yoe = y - era * 400;
    final mp = month > 2 ? month - 3 : month + 9;
    final doy = (153 * mp + 2) ~/ 5 + day - 1;
    final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
    return era * 146097 + doe - 719468;
  }

  /// Day of the week, 1 = Monday to 7 = Sunday.
  int get weekday {
    final w = (epochDay + 3) % 7; // 1970-01-01 was a Thursday
    return (w < 0 ? w + 7 : w) + 1;
  }

  GameDate plusDays(int days) => GameDate.fromEpochDay(epochDay + days);

  /// Number of days from this date to [other] (negative if earlier).
  int daysUntil(GameDate other) => other.epochDay - epochDay;

  bool isBefore(GameDate other) => compareTo(other) < 0;

  bool isAfter(GameDate other) => compareTo(other) > 0;

  @override
  int compareTo(GameDate other) => epochDay.compareTo(other.epochDay);

  @override
  bool operator ==(Object other) =>
      other is GameDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// ISO format, for example 2026-07-01.
  @override
  String toString() {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }
}
