import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import 'career.dart';
import 'lineup.dart';
import 'loaded_world.dart';
import 'saves.dart';

/// The own match of a day: the live match the player coaches.
typedef OwnMatch = ConferenceMatch;

/// What came out of a match of the own club, kept for the weekly mail.
class OwnRecord {
  const OwnRecord({
    required this.date,
    required this.competition,
    required this.round,
    required this.opponent,
    required this.home,
    required this.goalsFor,
    required this.goalsAgainst,
    this.wentThrough,
  });

  final GameDate date;
  final Competition competition;
  final int round;
  final ClubId opponent;
  final bool home;
  final int goalsFor;
  final int goalsAgainst;

  /// For a cup tie: true if the club is through to the next round.
  final bool? wentThrough;
}

/// How a season ended for the club: the numbers, the verdict of the
/// president and the state of the world in the next season.
class SeasonEnd {
  const SeasonEnd({
    required this.startYear,
    required this.outcome,
    required this.review,
    required this.rank,
    required this.teams,
    required this.next,
    required this.nextLeague,
    required this.levelChange,
    required this.champion,
    required this.cupWinner,
  });

  final int startYear;
  final SeasonOutcome outcome;
  final SeasonReview review;
  final int rank;
  final int teams;

  /// The state of the world in the next season.
  final SeasonState next;

  /// The league of the club in the next season, null if it left the
  /// pyramid (pool).
  final LeagueId? nextLeague;

  /// -1 promoted, 1 relegated, 0 same league.
  final int levelChange;
  final ClubId champion;
  final ClubId? cupWinner;
}

/// Holds the end of a season; shared by all revisions of the game.
class SeasonEndBox {
  SeasonEnd? value;
}

/// One finished season of the career, kept in the saved game.
class SeasonRecord {
  const SeasonRecord({
    required this.startYear,
    required this.leagueName,
    required this.rank,
    required this.teams,
    required this.goal,
    required this.verdict,
    required this.levelChange,
  });

  factory SeasonRecord.fromJson(Map<String, dynamic> m) => SeasonRecord(
    startYear: m['year'] as int,
    leagueName: m['league'] as String,
    rank: m['rank'] as int,
    teams: m['teams'] as int,
    goal: SeasonGoal.values.byName(m['goal'] as String),
    verdict: GoalVerdict.values.byName(m['verdict'] as String),
    levelChange: m['change'] as int,
  );

  final int startYear;
  final String leagueName;
  final int rank;
  final int teams;
  final SeasonGoal goal;
  final GoalVerdict verdict;
  final int levelChange;

  Map<String, dynamic> toJson() => {
    'year': startYear,
    'league': leagueName,
    'rank': rank,
    'teams': teams,
    'goal': goal.name,
    'verdict': verdict.name,
    'change': levelChange,
  };
}

/// The seasons the career has finished so far, oldest first.
class SeasonHistoryNotifier extends Notifier<List<SeasonRecord>> {
  @override
  List<SeasonRecord> build() => const [];

  void add(SeasonRecord record) => state = [...state, record];

  void restore(Iterable<SeasonRecord> records) =>
      state = List.unmodifiable(records);

  void reset() => state = const [];
}

final seasonHistoryProvider =
    NotifierProvider<SeasonHistoryNotifier, List<SeasonRecord>>(
      SeasonHistoryNotifier.new,
    );

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
    List<OwnRecord>? history,
    SeasonEndBox? endBox,
    this.revision = 0,
    this.day,
  }) : log = log ?? [],
       history = history ?? [],
       endBox = endBox ?? SeasonEndBox();

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

  /// The matches of the own club so far, oldest first. Shared by all
  /// revisions of the game.
  final List<OwnRecord> history;

  /// How the season ended; null while the club still has matches. Shared by
  /// all revisions of the game.
  final SeasonEndBox endBox;

  SeasonEnd? get end => endBox.value;

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
  int get matchday => leagueDone ? ownDays : played + 1;

  /// True after the last matchday of the own league.
  bool get leagueDone => played >= ownDays;

  /// True when the club has no match left: the league is done and so are
  /// the cups it was in (the cup final can come after the last matchday).
  bool get isOver => leagueDone && runner.nextMatchOf(run, clubId) == null;

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
    history: history,
    endBox: endBox,
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
    final loaded = ref.watch(startWorldProvider).value;
    if (career == null || loaded == null) return null;
    final from = ref.read(worldStateProvider);
    final sheet = from == null
        ? ref.read(lineupProvider)?.sheet
        : AutoManager(loaded.rules).build(
            from.squads[career.clubId] ?? const [],
            benchSize: loaded.rules.tactics.benchSize(career.league.level),
          );
    return _fresh(career, loaded, sheet);
  }

  SeasonGame _fresh(Career career, LoadedWorld loaded, TeamSheet? sheet) {
    final from = ref.read(worldStateProvider);
    final seed = SeededRandom(career.seed)
        .fork('season:${(from?.startYear ?? loaded.world.season.startYear)}')
        .seed;
    final runner = SeasonRunner(
      loaded.rules,
      calendarRules: loaded.calendarRules,
    );
    final run = runner.begin(
      from ?? SeasonState.fromWorld(loaded.world),
      seed: seed,
      userSheets: {career.clubId: ?sheet},
    );
    return SeasonGame(
      runner: runner,
      run: run,
      clubId: career.clubId,
      ownLeague: career.league.id,
      seed: seed,
      ownDays: run.schedules[career.league.id]!.length,
      today: from == null ? loaded.today : Season(from.startYear).start,
      initialSheet: sheet,
    );
  }

  /// Builds the season of a saved game and plays the saved log again. The
  /// world stands then exactly where it stood when the game was saved.
  void restore(TeamSheet? initialSheet, List<Map<String, dynamic>> log) {
    final career = ref.read(careerProvider);
    final loaded = ref.read(startWorldProvider).value;
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
          final own = game.day?.own;
          final session = own?.session;
          final actions = [
            for (final a in entry['actions'] as List<dynamic>)
              SessionAction.fromJson(a as Map<String, dynamic>),
          ];
          MatchResult? result;
          KnockoutResult? knockout;
          if (session != null && own!.competition != Competition.league) {
            session.replay(actions, knockout: true);
            knockout = session.finishKnockout();
          } else if (session != null) {
            session.replay(actions);
            result = session.finish();
          }
          _complete(result, knockout: knockout, record: false);
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
      if (next.$1 == run.nextDate) {
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
    _checkEnd(game);
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

  /// Days on until one of [eventDays] (epoch days) is reached, the club has
  /// a match, or the season is over. One save at the end.
  DayStep advanceToEvent(Set<int> eventDays) {
    var step = DayStep.played;
    var moved = false;
    while (step == DayStep.played) {
      step = _advanceDay(record: true);
      if (step != DayStep.played) break;
      moved = true;
      final game = state;
      if (game != null && eventDays.contains(game.today.epochDay)) break;
    }
    if (moved) ref.read(saveServiceProvider).autosave();
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
      if (next != null && next.$1 == tomorrow) {
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
    _checkEnd(game);
    state = game._with(today: tomorrow, clearDay: true);
    return DayStep.played;
  }

  /// When the last day of the season is played, works out how it ended: the
  /// verdict on the goal and the world of the next season.
  void _checkEnd(SeasonGame game) {
    if (game.endBox.value != null || !game.isOver || !game.run.isOver) return;
    final career = ref.read(careerProvider);
    final loaded = ref.read(startWorldProvider).value;
    if (career == null || loaded == null) return;
    final outcome = game.runner.conclude(game.run);
    final result = game.runner.nextSeason(
      game.run.state,
      outcome,
      seed: SeededRandom(game.seed).fork('next').seed,
      names: loaded.names,
    );
    final next = result.valueOrNull;
    if (next == null) return;
    final table = outcome.standing(game.ownLeague);
    final rank = table.indexOf(game.clubId) + 1;
    LeagueId? nextLeague;
    for (final e in next.members.entries) {
      if (e.value.contains(game.clubId)) nextLeague = e.key;
    }
    final level = {for (final l in loaded.world.leagues) l.id: l.level};
    final change = nextLeague == null
        ? 1
        : level[nextLeague]! - career.league.level;
    final seed = SeededRandom(game.seed).fork('review').seed;
    var review = const SeasonReviewer().review(
      goal: career.goal,
      rank: rank,
      teams: table.length,
      levelChange: change,
      seed: seed,
    );
    if (nextLeague == null) {
      review = SeasonReview(
        goal: review.goal,
        verdict: GoalVerdict.failed,
        gap: review.gap,
        rank: rank,
        teams: table.length,
        risk: 1,
        dismissed: true,
      );
    }
    game.endBox.value = SeasonEnd(
      startYear: game.run.state.startYear,
      outcome: outcome,
      review: review,
      rank: rank,
      teams: table.length,
      next: next,
      nextLeague: nextLeague,
      levelChange: change,
      champion: table.first,
      cupWinner: outcome.bolzplatz.winner,
    );
  }

  SeasonRecord _recordOf(SeasonEnd end, Career career) => SeasonRecord(
    startYear: end.startYear,
    leagueName: career.league.name,
    rank: end.rank,
    teams: end.teams,
    goal: end.review.goal,
    verdict: end.review.verdict,
    levelChange: end.levelChange,
  );

  /// Starts the next season after the end of this one. False if the season
  /// is not over, or if the manager was dismissed (see [startJobSearch]).
  bool startNextSeason() {
    final game = state;
    final end = game?.end;
    final career = ref.read(careerProvider);
    final loaded = ref.read(startWorldProvider).value;
    if (game == null || end == null || career == null || loaded == null) {
      return false;
    }
    final leagueId = end.nextLeague;
    if (end.review.dismissed || leagueId == null) return false;
    final league = loaded.world.leagues.firstWhere((l) => l.id == leagueId);
    final nextWorld = SeasonSnapshot.worldOf(end.next, loaded.world);
    final strengths = ClubStrengths.compute(nextWorld, loaded.rules);
    final members = [...end.next.members[leagueId]!]
      ..sort((a, b) {
        final d = (strengths[b] ?? 0).compareTo(strengths[a] ?? 0);
        return d != 0 ? d : a.value.compareTo(b.value);
      });
    final goal = SeasonReviewer.goalFor(
      level: league.level,
      strengthRank: members.indexOf(game.clubId) + 1,
      teams: league.teamCount,
    );
    ref.read(seasonHistoryProvider.notifier).add(_recordOf(end, career));
    ref.read(worldStateProvider.notifier).set(end.next);
    // The new career state makes this notifier build the new season.
    ref.read(careerProvider.notifier).newSeason(league: league, goal: goal);
    ref.read(saveServiceProvider).autosave();
    return true;
  }

  /// After a dismissal: the world moves on to the next season so the job
  /// offers come from it. The caller then starts a new career.
  bool startJobSearch() {
    final game = state;
    final end = game?.end;
    final career = ref.read(careerProvider);
    if (game == null || end == null || career == null) return false;
    ref.read(seasonHistoryProvider.notifier).add(_recordOf(end, career));
    ref.read(worldStateProvider.notifier).set(end.next);
    return true;
  }

  /// Closes the matchday: plays all other matches of the day and takes the
  /// result of the own match (null if the club has no match that day).
  void complete(MatchResult? ownResult, {KnockoutResult? knockout}) {
    _complete(ownResult, knockout: knockout, record: true);
    ref.read(saveServiceProvider).autosave();
  }

  void _complete(
    MatchResult? ownResult, {
    KnockoutResult? knockout,
    required bool record,
  }) {
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
    final own = day.own;
    final played = knockout?.match ?? ownResult;
    if (own != null && played != null) {
      final home = own.fixture.home == game.clubId;
      game.history.add(
        OwnRecord(
          date: day.date,
          competition: own.competition,
          round: own.round,
          opponent: home ? own.fixture.away : own.fixture.home,
          home: home,
          goalsFor: home ? played.homeGoals : played.awayGoals,
          goalsAgainst: home ? played.awayGoals : played.homeGoals,
          wentThrough: knockout == null
              ? null
              : (knockout.winnerSide == 0) == home,
        ),
      );
    }
    game.runner.completeDay(
      game.run,
      day,
      ownResult: ownResult,
      ownKnockout: knockout,
    );
    // Leagues with more matchdays than the own one play on in the background.
    if (game.isOver) {
      while (!game.run.isOver) {
        game.runner.completeDay(game.run, game.runner.openDay(game.run));
      }
    }
    _checkEnd(game);
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
