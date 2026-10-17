import '../calendar/game_date.dart';
import '../match/match_session.dart';
import '../match/match_types.dart';
import '../model/ids.dart';
import '../model/region.dart';
import 'schedule.dart';

/// The competition a match belongs to.
enum Competition { league, bolzplatz, pott }

/// One match of a calendar day. Matches of other clubs are simulated in
/// advance; [reveal] shows how the score develops during the match. The own
/// league match is played live ([session]) and has no result yet.
class ConferenceMatch {
  ConferenceMatch({
    required this.competition,
    required this.fixture,
    required this.date,
    required this.minuteOfDay,
    required this.round,
    this.league,
    this.region,
    this.result,
    this.knockout,
    this.session,
    this.isOwn = false,
    this.applied = false,
    this.sheetReplaced = false,
  });

  final Competition competition;

  /// Set for league matches.
  final LeagueId? league;

  /// Set for matches of the Pott der Provinz.
  final Region? region;
  final Fixture fixture;
  final GameDate date;

  /// Kickoff, minutes after midnight.
  final int minuteOfDay;

  /// Matchday of the league, or round of the cup (starting at 0).
  final int round;

  /// Result of a match that is simulated in advance.
  final MatchResult? result;

  /// Result of a cup tie, with extra time and shoot-out.
  final KnockoutResult? knockout;

  /// Live session of the own league match.
  final MatchSession? session;

  /// True if the club of the player plays in this match.
  final bool isOwn;

  /// True if the result is already part of the season (a cup tie of a later
  /// window of a round that was applied on its first day).
  bool applied;

  /// True if the handed-in line-up had players who are out, so the
  /// assistant set up the team for this match.
  final bool sheetReplaced;

  bool get isLive => session != null;

  bool get isLeague => competition == Competition.league;

  /// The match result seen so far, or null for a live own match.
  MatchResult? get finalResult => knockout?.match ?? result;

  /// Score after [minute] minutes of play (stoppage time included). For
  /// matches that are played live, use the session instead.
  (int, int) scoreAt(int minute) {
    final r = finalResult;
    if (r == null) return (0, 0);
    var home = 0;
    var away = 0;
    for (final e in r.events) {
      if (e.tick > minute) break;
      home = e.homeGoals;
      away = e.awayGoals;
    }
    return (home, away);
  }

  /// The clock of this match after [minute] minutes of play: "67" or
  /// "90+3", or null before kick-off.
  String? clockAt(int minute) {
    final r = finalResult;
    if (r == null || minute <= 0) return null;
    var clock = minute;
    MatchEvent? last;
    for (final e in r.events) {
      if (e.tick > minute) break;
      last = e;
    }
    if (last == null) return '$clock';
    // Minutes since the last event run on its clock (or its stoppage).
    final since = minute - last.tick;
    if (since == 0) return last.clockLabel;
    if (last.type == MatchEventType.halfTime ||
        last.type == MatchEventType.extraTime) {
      return '${last.minute + since}';
    }
    if (last.added > 0 || last.type == MatchEventType.addedTime) {
      return '${last.minute}+${last.added + since}';
    }
    clock = last.minute + since;
    return '$clock';
  }

  /// Minutes after kickoff at which the match is over, with stoppage time
  /// (and extra time).
  int get lengthMinutes => finalResult?.length ?? 90;
}

/// All matches of one calendar day in kickoff order, ready to be shown as a
/// conference. [SeasonRunner.completeDay] makes them part of the season.
class ConferenceDay {
  ConferenceDay({
    required this.date,
    required this.matches,
    required this.own,
    required this.openedIndex,
    required this.cupPlans,
  });

  final GameDate date;
  final List<ConferenceMatch> matches;

  /// The own league match, if the club plays one today.
  final ConferenceMatch? own;

  /// Index of the day in the timeline.
  final int openedIndex;

  /// Cup rounds that start today (kept for [SeasonRunner.completeDay]).
  final List<CupRoundPlan> cupPlans;

  /// The kickoff times of today in order.
  List<int> get kickoffs =>
      ({for (final m in matches) m.minuteOfDay}).toList()..sort();

  /// Matches of one league.
  List<ConferenceMatch> ofLeague(LeagueId league) => [
    for (final m in matches)
      if (m.league == league) m,
  ];

  /// Leagues that play today.
  List<LeagueId> get leagues {
    final seen = <LeagueId>[];
    for (final m in matches) {
      final l = m.league;
      if (l != null && !seen.contains(l)) seen.add(l);
    }
    return seen;
  }
}

/// A cup round that is decided on its first day: all its ties with their
/// results, the windows they are spread over and the winners.
class CupRoundPlan {
  CupRoundPlan({
    required this.competition,
    required this.region,
    required this.round,
    required this.ties,
  });

  final Competition competition;
  final Region? region;
  final int round;
  final List<ConferenceMatch> ties;
}
