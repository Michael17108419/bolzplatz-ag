import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import 'loaded_world.dart';
import 'season_game.dart';

/// What a place in a league table means for the club.
///
/// The numbers mirror the movements of the pyramid (`pyramid.dart`): the
/// first league sends the last two down and the 16th into the play-off, the
/// second and third league send two up and the third into the play-off, the
/// last four of the third and fourth league go down.
enum TableZone { none, promotion, chance, playoffUp, playoffDown, relegation }

TableZone zoneOf({
  required int level,
  required int teamCount,
  required int place,
}) {
  switch (level) {
    case 1:
      if (place >= 17) return TableZone.relegation;
      if (place == 16) return TableZone.playoffDown;
      return TableZone.none;
    case 2:
      if (place <= 2) return TableZone.promotion;
      if (place == 3) return TableZone.playoffUp;
      if (place >= 17) return TableZone.relegation;
      if (place == 16) return TableZone.playoffDown;
      return TableZone.none;
    case 3:
      if (place <= 2) return TableZone.promotion;
      if (place == 3) return TableZone.playoffUp;
      if (place >= 17) return TableZone.relegation;
      return TableZone.none;
    default:
      // Fourth league: the champion may go up (depends on the region and
      // the year), the last four go down.
      if (place == 1) return TableZone.chance;
      if (place > teamCount - 4) return TableZone.relegation;
      return TableZone.none;
  }
}

/// One line of a scorer list.
class ScorerRow {
  const ScorerRow(this.player, this.count);

  final Player player;
  final int count;
}

/// Everything the statistics screens show: the tables of all leagues, the
/// two cups and the scorer lists. The screens only read this, so the matchday
/// can feed it later without a change to them.
class SeasonStats {
  SeasonStats({
    required this.startYear,
    required this.matchday,
    required this.leagues,
    required this.tables,
    required this.bolzplatz,
    required this.pottWinners,
    required this.goals,
    required this.assists,
    this.previous = const {},
  });

  /// The state before the first match: empty tables in the order of the
  /// team strength (a forecast), no cup drawn, no scorers.
  factory SeasonStats.start(LoadedWorld loaded) {
    final leagues = <League>[];
    final tables = <LeagueId, List<TableEntry>>{};
    for (final ls in loaded.world.leagueSeasons) {
      leagues.add(ls.league);
      tables[ls.league.id] = [
        for (final c in loaded.clubsOf(ls.league)) TableEntry(c.id),
      ];
    }
    leagues.sort((a, b) => a.id.value.compareTo(b.id.value));
    return SeasonStats(
      startYear: loaded.world.season.startYear,
      matchday: 0,
      leagues: leagues,
      tables: tables,
      bolzplatz: null,
      pottWinners: const {},
      goals: const [],
      assists: const [],
    );
  }

  /// The state after a played season (also the basis for the matchday).
  factory SeasonStats.fromOutcome(
    LoadedWorld loaded,
    SeasonOutcome outcome, {
    required int matchday,
    int topScorers = 20,
  }) {
    final base = SeasonStats.start(loaded);
    List<ScorerRow> top(Map<PlayerId, int> counts) {
      final rows = <ScorerRow>[];
      for (final e in counts.entries) {
        final p = loaded.player(e.key);
        if (p != null && e.value > 0) rows.add(ScorerRow(p, e.value));
      }
      rows.sort((a, b) {
        final c = b.count.compareTo(a.count);
        return c != 0 ? c : a.player.id.value.compareTo(b.player.id.value);
      });
      return rows.take(topScorers).toList();
    }

    return SeasonStats(
      startYear: base.startYear,
      matchday: matchday,
      leagues: base.leagues,
      tables: outcome.tables,
      bolzplatz: outcome.bolzplatz,
      pottWinners: outcome.pottWinners,
      goals: top(outcome.leagueGoalsByPlayer),
      assists: top(outcome.leagueAssistsByPlayer),
    );
  }

  /// The state of a season in progress.
  factory SeasonStats.fromRun(LoadedWorld loaded, SeasonGame game) {
    final base = SeasonStats.start(loaded);
    if (game.played == 0) return base;
    List<ScorerRow> top(Map<PlayerId, int> counts) {
      final rows = <ScorerRow>[];
      for (final e in counts.entries) {
        final p = loaded.player(e.key);
        if (p != null && e.value > 0) rows.add(ScorerRow(p, e.value));
      }
      rows.sort((a, b) {
        final c = b.count.compareTo(a.count);
        return c != 0 ? c : a.player.id.value.compareTo(b.player.id.value);
      });
      return rows.take(20).toList();
    }

    final run = game.run;
    return SeasonStats(
      startYear: base.startYear,
      matchday: game.played,
      leagues: base.leagues,
      tables: {for (final e in run.tables.entries) e.key: e.value.standing},
      previous: {for (final e in run.previousOrder.entries) e.key: e.value},
      bolzplatz: run.bolzplatz.roundsPlayed > 0 ? run.bolzplatz : null,
      pottWinners: {
        for (final e in run.pott.entries)
          if (e.value.winner != null) e.key: e.value.winner!,
      },
      goals: top(game.runner.leagueGoals),
      assists: top(game.runner.leagueAssists),
    );
  }

  final int startYear;

  /// Matchdays played so far; 0 before the first match.
  final int matchday;
  final List<League> leagues;
  final Map<LeagueId, List<TableEntry>> tables;

  /// Order of each table before its last matchday (for the trend arrows).
  final Map<LeagueId, List<ClubId>> previous;

  /// Null as long as the cup is not drawn.
  final KnockoutCup? bolzplatz;
  final Map<Region, ClubId> pottWinners;
  final List<ScorerRow> goals;
  final List<ScorerRow> assists;

  /// True while nothing has been played: the order of the tables is then
  /// only a forecast.
  bool get isForecast => matchday == 0;
}

/// The statistics of the running season.
final seasonStatsProvider = Provider<SeasonStats?>((ref) {
  final loaded = ref.watch(loadedWorldProvider).value;
  if (loaded == null) return null;
  final game = ref.watch(seasonProvider);
  if (game == null) return SeasonStats.start(loaded);
  return SeasonStats.fromRun(loaded, game);
});
