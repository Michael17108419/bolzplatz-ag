import 'game_date.dart';

/// A season runs from 1 July to 30 June of the following year.
class Season implements Comparable<Season> {
  const Season(this.startYear);

  /// The season that contains [date].
  factory Season.containing(GameDate date) =>
      Season(date.month >= 7 ? date.year : date.year - 1);

  /// Calendar year in which the season starts, for example 2026.
  final int startYear;

  GameDate get start => GameDate(startYear, 7, 1);

  GameDate get end => GameDate(startYear + 1, 6, 30);

  Season get next => Season(startYear + 1);

  Season get previous => Season(startYear - 1);

  bool contains(GameDate date) => !date.isBefore(start) && !date.isAfter(end);

  /// Short label such as 2026/27.
  String get label {
    final endShort = ((startYear + 1) % 100).toString().padLeft(2, '0');
    return '$startYear/$endShort';
  }

  @override
  int compareTo(Season other) => startYear.compareTo(other.startYear);

  @override
  bool operator ==(Object other) =>
      other is Season && other.startYear == startYear;

  @override
  int get hashCode => startYear.hashCode;

  @override
  String toString() => label;
}
