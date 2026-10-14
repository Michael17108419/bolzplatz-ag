import '../calendar/season.dart';
import '../model/club.dart';
import '../model/coach.dart';
import '../model/ids.dart';
import '../model/league.dart';
import '../model/player.dart';
import '../model/region.dart';

/// The complete start world: leagues, clubs, players with contracts and
/// coaches. Pure data, no behaviour.
class World {
  const World({
    required this.seed,
    required this.season,
    required this.leagues,
    required this.clubs,
    required this.leagueSeasons,
    required this.pools,
    required this.players,
    required this.coaches,
  });

  /// Seed the world was generated with.
  final int seed;
  final Season season;
  final List<League> leagues;
  final List<Club> clubs;
  final List<LeagueSeason> leagueSeasons;

  /// Pool clubs per region, longest waiting first.
  final Map<Region, List<ClubId>> pools;
  final List<Player> players;
  final List<Coach> coaches;
}
