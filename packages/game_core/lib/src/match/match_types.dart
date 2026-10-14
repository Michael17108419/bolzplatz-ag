import '../model/ids.dart';

enum MatchEventType {
  kickOff,
  shot,
  freeKick,
  corner,
  penalty,
  yellowCard,
  secondYellow,
  redCard,
  injury,
  substitution,
  tacticChange,
  halfTime,
  extraTime,
  shootoutKick,
  fullTime,
}

enum ShotOutcome { goal, saved, blocked, offTarget }

enum ChanceQuality { half, chance, big }

/// One thing that happened in a match. Texts are made later from these.
class MatchEvent {
  const MatchEvent({
    required this.minute,
    required this.type,
    required this.side,
    required this.homeGoals,
    required this.awayGoals,
    this.player,
    this.otherPlayer,
    this.shotType,
    this.quality,
    this.outcome,
    this.injuryDays,
  });

  final int minute;
  final MatchEventType type;

  /// 0 for the home team, 1 for the away team, -1 for neutral events.
  final int side;
  final int homeGoals;
  final int awayGoals;

  /// Main player: shooter, carded player, injured player, player coming on.
  final PlayerId? player;

  /// Second player: player going off, or the one who made the foul.
  final PlayerId? otherPlayer;

  /// Id of the shot type from the rules, or `header` for set-piece headers.
  final String? shotType;
  final ChanceQuality? quality;
  final ShotOutcome? outcome;
  final int? injuryDays;

  bool get isGoal => outcome == ShotOutcome.goal;
}

/// Counted values of one team in one match.
class TeamStats {
  int goals = 0;
  int shots = 0;
  int shotsOnTarget = 0;
  int possessionPhases = 0;
  int corners = 0;
  int freeKicks = 0;
  int penalties = 0;
  int yellowCards = 0;
  int redCards = 0;
  int injuries = 0;
  int substitutions = 0;
}

/// An injury that came out of a match.
class MatchInjury {
  const MatchInjury({
    required this.player,
    required this.minute,
    required this.days,
  });

  final PlayerId player;
  final int minute;
  final int days;
}

/// Outcome of a finished match.
class MatchResult {
  const MatchResult({
    required this.homeGoals,
    required this.awayGoals,
    required this.events,
    required this.homeStats,
    required this.awayStats,
    required this.injuries,
    required this.minutesPlayed,
  });

  final int homeGoals;
  final int awayGoals;
  final List<MatchEvent> events;
  final TeamStats homeStats;
  final TeamStats awayStats;
  final List<MatchInjury> injuries;

  /// Minutes played by each player who took part.
  final Map<PlayerId, int> minutesPlayed;

  bool get isDraw => homeGoals == awayGoals;
}

/// Result of a cup tie played in one match: with extra time and a penalty
/// shoot-out if needed.
class KnockoutResult {
  const KnockoutResult({
    required this.match,
    required this.winnerSide,
    required this.extraTime,
    this.shootoutHome,
    this.shootoutAway,
  });

  /// The match including extra time. Shoot-out kicks are not in the goals.
  final MatchResult match;

  /// 0 if the home team went through, 1 for the away team.
  final int winnerSide;
  final bool extraTime;
  final int? shootoutHome;
  final int? shootoutAway;

  bool get decidedByShootout => shootoutHome != null;
}
