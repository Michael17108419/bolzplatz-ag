import 'package:game_core/game_core.dart';

import 'career.dart';
import 'loaded_world.dart';

/// What the office (home screen) shows before the first match of the career.
class OfficeView {
  const OfficeView({
    required this.startYear,
    required this.matchday,
    required this.seasonOver,
    required this.opponent,
    required this.atHome,
    required this.ownStrength,
    required this.opponentStrength,
    required this.leagueSize,
    required this.squadSize,
  });

  /// Builds the view from the real schedule of the first season, the same
  /// one the season is played with later.
  factory OfficeView.of(
    Career career,
    LoadedWorld loaded, {
    int matchday = 1,
    bool seasonOver = false,
  }) {
    final offer = career.offer;
    final season = loaded.world.leagueSeasons.firstWhere(
      (ls) => ls.league.id == offer.league.id,
    );
    final seed = SeededRandom(career.seed)
        .fork('season:${loaded.world.season.startYear}')
        .seed;
    final schedule = SeasonRunner.leagueSchedule(
      season.clubIds,
      offer.league.id,
      seed,
    );
    final own = offer.club.id;
    final day = matchday.clamp(1, schedule.length);
    final fixture = schedule[day - 1].firstWhere(
      (f) => f.home == own || f.away == own,
    );
    final atHome = fixture.home == own;
    final opponentId = atHome ? fixture.away : fixture.home;
    return OfficeView(
      startYear: loaded.world.season.startYear,
      matchday: day,
      seasonOver: seasonOver,
      opponent: loaded.club(opponentId),
      atHome: atHome,
      ownStrength: loaded.strengths[own] ?? 0,
      opponentStrength: loaded.strengths[opponentId] ?? 0,
      leagueSize: season.clubIds.length,
      squadSize: loaded.world.players.where((p) => p.clubId == own).length,
    );
  }

  final int startYear;
  final int matchday;

  /// True after the last matchday; the season change is not built yet.
  final bool seasonOver;
  final Club opponent;
  final bool atHome;
  final double ownStrength;
  final double opponentStrength;
  final int leagueSize;
  final int squadSize;
}
