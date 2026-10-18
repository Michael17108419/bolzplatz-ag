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

  /// The defending team won the ball in a dangerous zone (engine 2): [side]
  /// is the team that won it, [MatchEvent.player] the winner and
  /// [MatchEvent.otherPlayer] the player who lost it.
  ballWon,

  /// A ball won in midfield starts a counter attack (engine 2): [side] is
  /// the countering team, [MatchEvent.player] won the ball and
  /// [MatchEvent.otherPlayer] lost it; column and lane are where the
  /// counter starts, seen from the countering team.
  counterAttack,

  /// The fourth official shows the stoppage time (engine 2): [MatchEvent.value]
  /// is the number of minutes added to the half.
  addedTime,

  /// A delay punished by the Laws (engine 2): [side] is the team that
  /// wasted time, [MatchEvent.action] says how (`keeper_eight_seconds`,
  /// `goal_kick_countdown`, `throw_in_countdown`, `sub_ten_seconds`),
  /// [MatchEvent.player] is the culprit.
  timeWasting,

  /// A foul in an attack (engine 2, step 10e1): [side] is the team that
  /// fouled, [MatchEvent.player] the fouler, [MatchEvent.otherPlayer] the
  /// player fouled; [MatchEvent.action] is `whistle` or `advantage` (play
  /// ran on), [MatchEvent.value] 1 if it denied a clear chance (Notbremse).
  foul,

  /// Protest against the referee (engine 2, step 10e1): [side] protests,
  /// [MatchEvent.player] is the one who talks; [MatchEvent.action] is
  /// `captain` (allowed, IFAB 2025/26) or `protest` (anyone else).
  dissent,

  /// A decision checked by the VAR or a wrong decision without one (engine
  /// 2, step 10e2), when it is not part of a goal, penalty or card event:
  /// [MatchEvent.action] is `penalty_given` (VAR gives a penalty),
  /// `penalty_missed` (no VAR, a penalty not given), `red_given` (VAR sends
  /// a player off), `red_missed` (no VAR, a red not seen), `red_downgraded`
  /// (VAR makes a red a yellow), `identity` (VAR corrects the player),
  /// `second_cancelled` (VAR takes back a second yellow). [side] is the
  /// team the decision is about, [MatchEvent.value] 1 with VAR, 0 without.
  varReview,

  /// A player is treated on the pitch (engine 2, step 10e6) and must stay
  /// off for a minute ([MatchEvent.value] 1; 0 for the keeper, who may
  /// stay).
  treatment,

  /// A team talk in the dressing room (engine 2, step 10f3), before
  /// kick-off or at a break: [side] is the team, [MatchEvent.action] the
  /// kind (`calm`, `fire`, `praise`), [MatchEvent.value] how it landed (1
  /// well, 0 flat, -1 badly).
  teamTalk,
}

/// What the coach says in the dressing room (engine 2, step 10f3): calm
/// the team down, fire it up or praise it.
enum TeamTalk { calm, fire, praise }

enum ShotOutcome { goal, saved, blocked, offTarget }

enum ChanceQuality { half, chance, big }

/// One step of an attack (engine 2): the player on the ball, what he did,
/// where, against whom and how it went. The ticker tells attacks from these.
class AttackStep {
  const AttackStep({
    required this.player,
    required this.action,
    required this.column,
    required this.lane,
    required this.won,
    this.opponent,
    this.flags = 0,
  });

  /// Under pressure from the defender.
  static const int pressure = 1;

  /// Clearly won or clearly lost.
  static const int clear = 2;

  /// Only just (won or lost by a hair).
  static const int close = 4;

  /// Nicely done.
  static const int pretty = 8;

  /// At speed (counter attack, a sprinter on the ball).
  static const int fast = 16;

  final PlayerId player;

  /// Action id of the rules (short_pass, dribble, cross ...).
  final String action;

  /// Column and lane where the step started (view of the team on the ball).
  final int column;
  final int lane;

  /// True if the step got through.
  final bool won;

  /// The defender of the zone.
  final PlayerId? opponent;
  final int flags;

  bool has(int flag) => flags & flag != 0;
}

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
    this.column,
    this.lane,
    this.chain = const [],
    this.action,
    this.added = 0,
    int? tick,
    this.value,
    this.spot,
    this.steps = const [],
    this.keeper,
    this.review,
  }) : tick = tick ?? minute;

  /// Minute on the clock (45 and 90 during stoppage time, see [added]).
  final int minute;

  /// Minute of stoppage time (45+2 is minute 45, added 2), 0 otherwise.
  final int added;

  /// Minutes played since kick-off including stoppage time: orders events
  /// and lets other matches of a conference follow the own clock.
  final int tick;
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

  /// Zone of the action (engine 2), seen from the team that had the ball:
  /// column 0 (own goal) to 4 (goal of the opponent), lane 0 left, 1 centre,
  /// 2 right. Null for events without a place.
  final int? column;
  final int? lane;

  /// Players of the attacking team who carried the ball in this attack, in
  /// order (shots only). The shooter is not part of it.
  final List<PlayerId> chain;

  /// Id of the action from the rules (engine 2): for a shot the last action
  /// of the attack before it (`long_shot` for a shot from distance the
  /// player chose), for a lost ball the action that failed. For a card the
  /// reason (`foul`, `dogso`, `dogso_box`, `advantage`, `dissent`), null for
  /// a card without a told reason.
  final String? action;

  /// A number that belongs to the event: minutes of stoppage time.
  final int? value;

  /// Where a chance from open play came from (engine 2): 0 edge of the box,
  /// 1 box, 2 six-yard box; null for shots from distance and set pieces.
  final int? spot;

  /// The steps of the attack that led to a shot, a lost ball or a counter
  /// (engine 2); empty for other events.
  final List<AttackStep> steps;

  /// The keeper who faced a shot (engine 2, step 10e1).
  final PlayerId? keeper;

  /// What became of a goal, penalty or card under review (engine 2, step
  /// 10e2). Goals: `goal_overturned` (VAR: offside, no goal),
  /// `goal_given` (VAR: the flag was wrong, goal), `goal_confirmed` (VAR
  /// checked, goal stands), `offside_missed` (no VAR, an offside goal
  /// stands), `goal_disallowed` (no VAR, a fair goal flagged off).
  /// Penalties: `penalty_overturned` (VAR: no foul, no penalty),
  /// `penalty_soft` (no VAR, a penalty without a foul). Cards: `red_harsh`
  /// and `second_harsh` (no VAR, too hard), `identity` (no VAR, the wrong
  /// player; the real culprit is [otherPlayer]).
  final String? review;

  /// A goal taken away (by the VAR or a wrong flag): told, but not counted.
  bool get annulled =>
      review == 'goal_overturned' || review == 'goal_disallowed';

  /// The minute as shown: "45+2" in stoppage time, else "45".
  String get clockLabel => added > 0 ? '$minute+$added' : '$minute';

  bool get isGoal => outcome == ShotOutcome.goal && !annulled;
}

/// Where and how a match is played (engine 2, step 10e4): the ground, the
/// crowd, whether it is a derby and how far the guests travelled.
class MatchSetting {
  const MatchSetting({
    this.stadium,
    this.capacity = 0,
    this.attendance = 0,
    this.derby = 0,
    this.derbyName,
    this.travelKm = 0,
    this.travel = 0,
    this.pitch = 70,
    this.weather = 'cloudy',
    this.ground = 'good',
  });

  final String? stadium;
  final int capacity;
  final int attendance;

  /// 0 none to 3 (city derby, great rivalry).
  final int derby;
  final String? derbyName;

  /// Road kilometres of the guests.
  final int travelKm;

  /// Share of energy the guests lost on the road (0.02 is 2 %).
  final double travel;

  /// Quality of the grass of the home ground, 1 to 100.
  final int pitch;

  /// Weather (engine 2, step 10e5): sunny, cloudy, rain, heavy_rain, snow,
  /// heat or wind.
  final String weather;

  /// State of the ground: good, wet, heavy or frozen.
  final String ground;

  /// How full the ground is, 0 to 1.
  double get fill => capacity == 0 ? 0 : (attendance / capacity).clamp(0, 1);
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

  /// Balls won from the opponent in open play (engine 2).
  int ballsWon = 0;
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
    this.length = 90,
  });

  final int homeGoals;
  final int awayGoals;
  final List<MatchEvent> events;
  final TeamStats homeStats;
  final TeamStats awayStats;
  final List<MatchInjury> injuries;

  /// Minutes played by each player who took part.
  final Map<PlayerId, int> minutesPlayed;

  /// Minutes the match lasted including stoppage and extra time.
  final int length;

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
