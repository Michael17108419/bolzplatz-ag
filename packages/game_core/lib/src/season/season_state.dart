import '../model/club.dart';
import '../model/ids.dart';
import '../model/player.dart';
import '../model/region.dart';
import '../world/world.dart';

/// Everything that carries from one season to the next.
class SeasonState {
  SeasonState({
    required this.startYear,
    required Map<LeagueId, List<ClubId>> members,
    required Map<Region, List<ClubId>> pools,
    required Map<ClubId, Club> clubs,
    required Map<ClubId, List<Player>> squads,
    required this.cycleYear,
    List<ClubId> pottQualifiers = const [],
    List<ClubId> thirdLeagueQualifiers = const [],
    Map<ClubId, int> previousRank = const {},
  }) : members = Map.unmodifiable({
         for (final e in members.entries) e.key: List<ClubId>.unmodifiable(e.value),
       }),
       pools = Map.unmodifiable({
         for (final e in pools.entries) e.key: List<ClubId>.unmodifiable(e.value),
       }),
       clubs = Map.unmodifiable(clubs),
       squads = Map.unmodifiable(squads),
       pottQualifiers = List.unmodifiable(pottQualifiers),
       thirdLeagueQualifiers = List.unmodifiable(thirdLeagueQualifiers),
       previousRank = Map.unmodifiable(previousRank);

  /// The start state from a generated world: first season, no cup history.
  factory SeasonState.fromWorld(World world) {
    final squads = <ClubId, List<Player>>{
      for (final c in world.clubs) c.id: <Player>[],
    };
    for (final p in world.players) {
      squads[p.clubId]!.add(p);
    }
    return SeasonState(
      startYear: world.season.startYear,
      members: {
        for (final ls in world.leagueSeasons) ls.league.id: ls.clubIds,
      },
      pools: world.pools,
      clubs: {for (final c in world.clubs) c.id: c},
      squads: squads,
      cycleYear: 0,
    );
  }

  final int startYear;

  /// Clubs of each league in this season.
  final Map<LeagueId, List<ClubId>> members;

  /// Pool clubs per region, longest waiting first.
  final Map<Region, List<ClubId>> pools;
  final Map<ClubId, Club> clubs;
  final Map<ClubId, List<Player>> squads;

  /// Position in the three-year cycle of the fourth-tier promotion places.
  final int cycleYear;

  /// The 24 clubs that qualified for this season's Bolzplatzpokal through the
  /// Pott der Provinz of the previous season. Empty in the first season.
  final List<ClubId> pottQualifiers;

  /// The best clubs of the third league of the previous season.
  final List<ClubId> thirdLeagueQualifiers;

  /// Final place in the league of the previous season (1 is best).
  final Map<ClubId, int> previousRank;

  bool get isFirstSeason => pottQualifiers.isEmpty;
}
