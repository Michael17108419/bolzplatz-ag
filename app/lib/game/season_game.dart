import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import 'career.dart';
import 'lineup.dart';
import 'loaded_world.dart';

/// The own match of a day: the live match the player coaches.
typedef OwnMatch = ConferenceMatch;

/// The running season of the career: the runner of the game core and the
/// season it plays. The objects of the core change in place, so every
/// change gets a new [revision] and with it a new state for the screens.
class SeasonGame {
  SeasonGame({
    required this.runner,
    required this.run,
    required this.clubId,
    required this.ownLeague,
    required this.seed,
    required this.ownDays,
    required this.today,
    this.revision = 0,
    this.day,
  });

  final SeasonRunner runner;
  final SeasonRun run;
  final ClubId clubId;

  /// The league of the club of the player.
  final LeagueId ownLeague;

  /// The seed of this season (also the one of the schedule shown in the
  /// office).
  final int seed;

  /// The number of matchdays of the own league.
  final int ownDays;
  final int revision;

  /// The date the world stands on.
  final GameDate today;

  /// The day that is open (preview or live), null between matches.
  final ConferenceDay? day;

  /// The own match that is open (preview or live), null between matches.
  OwnMatch? get next => day?.own;

  /// Matchdays of the own league played so far.
  int get played => run.matchdaysPlayed(ownLeague);

  /// The number of the next matchday; after the last one it stays there.
  int get matchday => played >= ownDays ? ownDays : played + 1;

  /// True after the last matchday of the own league.
  bool get isOver => played >= ownDays;

  SeasonGame _with({
    ConferenceDay? day,
    bool clearDay = false,
    GameDate? today,
  }) => SeasonGame(
    runner: runner,
    run: run,
    clubId: clubId,
    ownLeague: ownLeague,
    seed: seed,
    ownDays: ownDays,
    today: today ?? this.today,
    revision: revision + 1,
    day: clearDay ? null : (day ?? this.day),
  );
}

/// What happened when the clock moved one day on.
enum DayStep { played, ownMatch, seasonOver }

class SeasonNotifier extends Notifier<SeasonGame?> {
  @override
  SeasonGame? build() {
    final career = ref.watch(careerProvider);
    final loaded = ref.watch(loadedWorldProvider).value;
    if (career == null || loaded == null) return null;
    final seed = seasonSeed(career, loaded);
    final runner = SeasonRunner(
      loaded.rules,
      calendarRules: loaded.calendarRules,
    );
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
      ownLeague: career.offer.league.id,
      seed: seed,
      ownDays: run.schedules[career.offer.league.id]!.length,
      today: loaded.today,
    );
  }

  /// Opens the own match of the next matchday with the current line-up.
  /// Days without a league match of the club (other leagues, cup ties of the
  /// club for now) are played in the background first. Null if the season is
  /// over or the line-up is missing.
  OwnMatch? openNext() {
    final game = state;
    final sheet = ref.read(lineupProvider)?.sheet;
    if (game == null || sheet == null || game.isOver) return null;
    game.runner.setUserSheet(game.clubId, sheet);
    final run = game.run;
    var last = game.today;
    while (!run.isOver) {
      final next = game.runner.nextMatchOf(run, game.clubId);
      if (next == null) break;
      if (next.$1 == run.nextDate && next.$2 == Competition.league) {
        final day = game.runner.openDay(run, own: game.clubId, sheet: sheet);
        state = game._with(day: day, today: day.date);
        return day.own;
      }
      final played = game.runner.openDay(run);
      game.runner.completeDay(run, played);
      last = played.date;
    }
    state = game._with(clearDay: true, today: last);
    return null;
  }

  /// One day on: nothing happens on a free day, other leagues play on a day
  /// without a match of the club. The day of a league match of the club is
  /// not played here: [DayStep.ownMatch] says the match is next, the screen
  /// then opens it like "Weiter".
  DayStep advanceDay() {
    final game = state;
    if (game == null) return DayStep.seasonOver;
    final tomorrow = game.today.plusDays(1);
    if (tomorrow.isAfter(Season.containing(game.today).end)) {
      return DayStep.seasonOver;
    }
    final run = game.run;
    if (!run.isOver && run.nextDate == tomorrow) {
      final next = game.isOver
          ? null
          : game.runner.nextMatchOf(run, game.clubId);
      if (next != null &&
          next.$1 == tomorrow &&
          next.$2 == Competition.league) {
        return DayStep.ownMatch;
      }
      game.runner.completeDay(run, game.runner.openDay(run));
      if (game.isOver) {
        while (!run.isOver) {
          game.runner.completeDay(run, game.runner.openDay(run));
        }
      }
    }
    state = game._with(today: tomorrow, clearDay: true);
    return DayStep.played;
  }

  /// Closes the matchday: plays all other matches of the day and takes the
  /// result of the own match (null if the club has no match that day).
  void complete(MatchResult? ownResult) {
    final game = state;
    final day = game?.day;
    if (game == null || day == null) return;
    game.runner.completeDay(game.run, day, ownResult: ownResult);
    // Leagues with more matchdays than the own one play on in the background.
    if (game.isOver) {
      while (!game.run.isOver) {
        game.runner.completeDay(game.run, game.runner.openDay(game.run));
      }
    }
    state = game._with(clearDay: true);
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

/// The date the world stands on (the start date until the season runs).
final todayProvider = Provider<GameDate?>((ref) {
  final game = ref.watch(seasonProvider);
  if (game != null) return game.today;
  return ref.watch(loadedWorldProvider).value?.today;
});
