import 'game_date.dart';
import 'holidays.dart';
import 'season.dart';

/// How the free days of a plan compare with the rule.
enum VacationLevel { less, exact, more }

/// The result of checking a vacation plan.
class VacationCheck {
  const VacationCheck({
    required this.total,
    required this.longestBlock,
    required this.minTotal,
    required this.minBlock,
  });

  /// Working days (Monday to Saturday without public holidays) in the plan.
  final int total;

  /// The longest stretch of planned working days in a row. Sundays and
  /// holidays between two planned days do not break it.
  final int longestBlock;
  final int minTotal;
  final int minBlock;

  VacationLevel get level => total < minTotal
      ? VacationLevel.less
      : total == minTotal
      ? VacationLevel.exact
      : VacationLevel.more;

  bool get blockKept => longestBlock >= minBlock;

  /// True if the plan keeps the rule: enough days and one long block.
  bool get kept => total >= minTotal && blockKept;
}

/// Plans the free days of the whole squad. The manager picks the days; the
/// rule is 30 working days a season with one block of at least 12.
class VacationPlanner {
  VacationPlanner(
    this.holidays, {
    required this.minTotal,
    required this.minBlock,
  });

  final HolidayCalendar holidays;
  final int minTotal;
  final int minBlock;

  /// Monday to Saturday, no public holiday.
  bool isWerktag(GameDate d) => d.weekday != 7 && !holidays.isHoliday(d);

  /// The days of [season] on which a day off can be planned: working days
  /// that are not in [blocked] (epoch days of matches of the club).
  Set<int> allowedDays(Season season, Set<int> blocked) {
    final out = <int>{};
    for (
      var d = season.start;
      !d.isAfter(season.end);
      d = d.plusDays(1)
    ) {
      if (isWerktag(d) && !blocked.contains(d.epochDay)) out.add(d.epochDay);
    }
    return out;
  }

  /// A plan with exactly [minTotal] days, taken from the longest free
  /// stretches first so that one block is long enough. The assistant hands
  /// it in when the manager has not planned anything.
  Set<int> suggest(Season season, Set<int> allowed) {
    final runs = <List<int>>[];
    var current = <int>[];
    for (
      var d = season.start;
      !d.isAfter(season.end);
      d = d.plusDays(1)
    ) {
      if (!isWerktag(d)) continue;
      if (allowed.contains(d.epochDay)) {
        current.add(d.epochDay);
      } else if (current.isNotEmpty) {
        runs.add(current);
        current = <int>[];
      }
    }
    if (current.isNotEmpty) runs.add(current);
    runs.sort((a, b) => b.length.compareTo(a.length));
    final picked = <int>{};
    for (final run in runs) {
      for (final day in run) {
        if (picked.length >= minTotal) break;
        picked.add(day);
      }
      if (picked.length >= minTotal) break;
    }
    return picked;
  }

  VacationCheck check(Season season, Set<int> days) {
    var total = 0;
    var run = 0;
    var longest = 0;
    for (
      var d = season.start;
      !d.isAfter(season.end);
      d = d.plusDays(1)
    ) {
      if (!isWerktag(d)) continue;
      if (days.contains(d.epochDay)) {
        total++;
        run++;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }
    return VacationCheck(
      total: total,
      longestBlock: longest,
      minTotal: minTotal,
      minBlock: minBlock,
    );
  }
}
