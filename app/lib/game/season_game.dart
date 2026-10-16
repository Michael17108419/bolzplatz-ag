import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import 'career.dart';
import 'lineup.dart';
import 'loaded_world.dart';
import 'saves.dart';

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
    required this.initialSheet,
    List<Map<String, dynamic>>? log,
    this.revision = 0,
    this.day,
  }) : log = log ?? [];

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

  /// The line-up the season began with.
  final TeamSheet? initialSheet;

  /// What the player did, in order: line-up handed in for a match ("next"),
  /// a day on ("day") and a finished own match with the changes made in it
  /// ("done"). A saved game keeps this and plays it again when loaded.
  /// Shared by all revisions of the game.
  final List<Map<String, dynamic>> log;

  /// The log as it can be saved: a preview that was opened but not played
  /// is left out (saving happens at the end of a day).
  List<Map<String, dynamic>> get savableLog {
    final out = List<Map<String, dynamic>>.of(log);
    while (out.isNotEmpty &&
        out.last['op'] == 'next' &&
        out.last['day'] == true) {
      out.removeLast();
    }
    return out;
  }

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
    initialSheet: initialSheet,
    log: log,
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
    return _fresh(career, loaded, ref.read(lineupProvider)?.sheet);
  }

  SeasonGame _fresh(Career career, LoadedWorld loaded, TeamSheet? sheet) {
    final seed = seasonSeed(career, loaded);
    final runner = SeasonRunner(
      loaded.rules,
      calendarRules: loaded.calendarRules,
    );
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
      initialSheet: sheet,
    );
  }

  /// Builds the season of a saved game and plays the saved log again. The
  /// world stands then exactly where it stood when the game was saved.
  void restore(TeamSheet? initialSheet, List<Map<String, dynamic>> log) {
    final career = ref.read(careerProvider);
    final loaded = ref.read(loadedWorldProvider).value;
    if (career == null || loaded == null) return;
    state = _fresh(career, loaded, initialSheet);
    for (final entry in log) {
      switch (entry['op']) {
        case 'next':
          final sheet = TeamSheet.fromJson(
            entry['sheet'] as Map<String, dynamic>,
          );
          _openNext(sheet, record: false);
        case 'day':
          _advanceDay(record: false);
        case 'done':
          final game = state!;
          final session = game.day?.own?.session;
          MatchResult? result;
          if (session != null) {
            session.replay([
              for (final a in entry['actions'] as List<dynamic>)
                SessionAction.fromJson(a as Map<String, dynamic>),
            ]);
            result = session.finish();
          }
          _complete(result, record: false);
      }
    }
    final game = state!;
    game.log
      ..clear()
      ..addAll(log);
    state = game._with(clearDay: true);
  }

  /// Opens the own match of the next matchday with the current line-up.
  /// Days without a league match of the club (other leagues, cup ties of the
  /// club for now) are played in the background first. Null if the season is
  /// over or the line-up is missing.
  OwnMatch? openNext() {
    final sheet = ref.read(lineupProvider)?.sheet;
    final game = state;
    if (game == null || sheet == null || game.isOver) return null;
    return _openNext(sheet, record: true);
  }

  OwnMatch? _openNext(TeamSheet sheet, {required bool record}) {
    final game = state;
    if (game == null || game.isOver) return null;
    game.runner.setUserSheet(game.clubId, sheet);
    final run = game.run;
    var last = game.today;
    while (!run.isOver) {
      final next = game.runner.nextMatchOf(run, game.clubId);
      if (next == null) break;
      if (next.$1 == run.nextDate && next.$2 == Competition.league) {
        final day = game.runner.openDay(run, own: game.clubId, sheet: sheet);
        if (record) {
          game.log.add({'op': 'next', 'sheet': sheet.toJson(), 'day': true});
        }
        state = game._with(day: day, today: day.date);
        return day.own;
      }
      final played = game.runner.openDay(run);
      game.runner.completeDay(run, played);
      last = played.date;
    }
    if (record) {
      game.log.add({'op': 'next', 'sheet': sheet.toJson(), 'day': false});
    }
    state = game._with(clearDay: true, today: last);
    return null;
  }

  /// One day on: nothing happens on a free day, other leagues play on a day
  /// without a match of the club. The day of a league match of the club is
  /// not played here: [DayStep.ownMatch] says the match is next, the screen
  /// then opens it like "Weiter".
  DayStep advanceDay() {
    final step = _advanceDay(record: true);
    if (step == DayStep.played) ref.read(saveServiceProvider).autosave();
    return step;
  }

  DayStep _advanceDay({required bool record}) {
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
    if (record) game.log.add({'op': 'day'});
    state = game._with(today: tomorrow, clearDay: true);
    return DayStep.played;
  }

  /// Closes the matchday: plays all other matches of the day and takes the
  /// result of the own match (null if the club has no match that day).
  void complete(MatchResult? ownResult) {
    _complete(ownResult, record: true);
    ref.read(saveServiceProvider).autosave();
  }

  void _complete(MatchResult? ownResult, {required bool record}) {
    final game = state;
    final day = game?.day;
    if (game == null || day == null) return;
    if (record) {
      game.log.add({
        'op': 'done',
        'actions': [
          for (final a in day.own?.session?.actions ?? <SessionAction>[])
            a.toJson(),
        ],
      });
    }
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
