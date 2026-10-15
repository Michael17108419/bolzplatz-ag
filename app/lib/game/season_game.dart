import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import 'career.dart';
import 'lineup.dart';
import 'loaded_world.dart';

/// The running season of the career: the runner of the game core and the
/// season it plays. The objects of the core change in place, so every
/// change gets a new [revision] and with it a new state for the screens.
class SeasonGame {
  SeasonGame({
    required this.runner,
    required this.run,
    required this.clubId,
    required this.seed,
    required this.ownDays,
    this.revision = 0,
    this.next,
  });

  final SeasonRunner runner;
  final SeasonRun run;
  final ClubId clubId;

  /// The seed of this season (also the one of the schedule shown in the
  /// office).
  final int seed;

  /// The number of matchdays of the own league.
  final int ownDays;
  final int revision;

  /// The own match that is open (preview or live), null between matches.
  final OwnMatch? next;

  /// Matchdays played so far.
  int get played => run.day;

  /// The number of the next matchday; after the last one it stays there.
  int get matchday => played >= ownDays ? ownDays : played + 1;

  /// True after the last matchday of the own league.
  bool get isOver => played >= ownDays;

  SeasonGame _with({OwnMatch? next, bool clearNext = false}) => SeasonGame(
    runner: runner,
    run: run,
    clubId: clubId,
    seed: seed,
    ownDays: ownDays,
    revision: revision + 1,
    next: clearNext ? null : (next ?? this.next),
  );
}

class SeasonNotifier extends Notifier<SeasonGame?> {
  @override
  SeasonGame? build() {
    final career = ref.watch(careerProvider);
    final loaded = ref.watch(loadedWorldProvider).value;
    if (career == null || loaded == null) return null;
    final seed = seasonSeed(career, loaded);
    final runner = SeasonRunner(loaded.rules);
    final sheet = ref.read(lineupProvider)?.sheet;
    final run = runner.begin(
      SeasonState.fromWorld(loaded.world),
      seed: seed,
      userSheets: {career.clubId: ?sheet},
    );
    return SeasonGame(
      runner: runner,
      run: run,
      clubId: career.clubId,
      seed: seed,
      ownDays: run.schedules[career.offer.league.id]!.length,
    );
  }

  /// Opens the own match of the next matchday with the current line-up.
  /// Null if the season is over or the line-up is missing.
  OwnMatch? openNext() {
    final game = state;
    final sheet = ref.read(lineupProvider)?.sheet;
    if (game == null || sheet == null || game.isOver) return null;
    game.runner.setUserSheet(game.clubId, sheet);
    final own = game.runner.openOwnMatch(game.run, game.clubId, sheet);
    state = game._with(next: own, clearNext: own == null);
    return own;
  }

  /// Closes the matchday: plays all other matches of the day and takes the
  /// result of the own match (null if the club has no match that day).
  void complete(MatchResult? ownResult) {
    final game = state;
    if (game == null || game.isOver) return;
    final own = game.next;
    game.runner.completeMatchday(
      game.run,
      own: ownResult == null ? null : own,
      ownResult: ownResult,
    );
    // Leagues with more matchdays than the own one play on in the background.
    if (game.isOver) {
      while (!game.run.isOver) {
        game.runner.completeMatchday(game.run);
      }
    }
    state = game._with(clearNext: true);
  }
}

/// The seed of the first season of a career.
int seasonSeed(Career career, LoadedWorld loaded) =>
    SeededRandom(career.seed)
        .fork('season:${loaded.world.season.startYear}')
        .seed;

/// Null until a career is started and the world is loaded.
final seasonProvider = NotifierProvider<SeasonNotifier, SeasonGame?>(
  SeasonNotifier.new,
);

/// Players of the own club who miss the next match, with the reason.
final ownAbsencesProvider = Provider<Map<PlayerId, Absence>>((ref) {
  final game = ref.watch(seasonProvider);
  if (game == null) return const {};
  return game.runner.absences(game.run, game.clubId);
});
