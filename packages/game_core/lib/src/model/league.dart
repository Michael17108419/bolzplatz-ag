import '../calendar/season.dart';
import 'ids.dart';
import 'region.dart';

/// A league of the pyramid. [level] 1 is the top tier.
class League {
  League({
    required this.id,
    required this.name,
    required this.level,
    required this.teamCount,
    this.region,
  }) {
    if (level < 1 || level > 4) {
      throw ArgumentError.value(level, 'level', 'must be 1 to 4');
    }
    if (teamCount < 2 || teamCount.isOdd) {
      throw ArgumentError.value(teamCount, 'teamCount', 'must be even, >= 2');
    }
  }

  final LeagueId id;
  final String name;
  final int level;
  final int teamCount;

  /// Only set for the regional fourth tier.
  final Region? region;

  @override
  bool operator ==(Object other) => other is League && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// One league in one season with its participating clubs.
class LeagueSeason {
  LeagueSeason({
    required this.league,
    required this.season,
    required List<ClubId> clubIds,
  }) : clubIds = List.unmodifiable(clubIds) {
    if (clubIds.length != league.teamCount) {
      throw ArgumentError('Expected ${league.teamCount} clubs');
    }
    if (clubIds.toSet().length != clubIds.length) {
      throw ArgumentError('Duplicate club in league season');
    }
  }

  final League league;
  final Season season;
  final List<ClubId> clubIds;

  /// Number of matchdays in a double round robin.
  int get matchdays => (league.teamCount - 1) * 2;
}
