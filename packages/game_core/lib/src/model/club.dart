import 'ids.dart';
import 'region.dart';

/// A fictional club.
class Club {
  const Club({
    required this.id,
    required this.name,
    required this.shortName,
    required this.place,
    required this.region,
    this.leagueId,
  });

  final ClubId id;
  final String name;
  final String shortName;
  final String place;
  final Region region;
  /// Null for pool clubs, which play in no league yet.
  final LeagueId? leagueId;

  @override
  bool operator ==(Object other) => other is Club && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
