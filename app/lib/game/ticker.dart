import 'package:game_core/game_core.dart';

/// The kinds of lines the live ticker writes. Every kind has several texts
/// (in the strings), so that a match does not read like a form letter.
enum TickerKind {
  kickOff,
  goal,
  goalAssist,

  /// The lines right after a goal: who scored, who laid it on.
  scorer,
  assist,
  penalty,
  parade,
  miss,
  blocked,

  /// A half chance that came to nothing: told quietly.
  halfChance,
  yellow,
  secondYellow,
  red,
  injury,
  substitution,
  tactic,
  halfTime,
  fullTime,
  extraTime,
  shootout,

  /// The fourth official shows the stoppage time.
  addedTime,

  /// Balls lost in the attacking third, told by what went wrong.
  lostCross,
  lostThroughBall,
  lostDribble,
  lostLongBall,

  /// A ball won in midfield starts a counter attack.
  counter,
  corner,

  /// Delays punished by the Laws.
  keeperEightSeconds,
  goalKickCountdown,
  throwInCountdown,

  /// The captain leaves the pitch (substitution, injury, sending-off).
  captainOff,

  /// Lines only the radio reporter writes (step 10d2): a step of an attack,
  /// the moment before the shot, a free kick, colour (memory, wit, what a
  /// goal means) and a line for a quiet phase.
  play,
  shotUp,
  freeKick,
  colour,
  calm,
}

/// The kinds only the reporter writes; the plain ticker has no texts for them.
const reporterOnlyKinds = {
  TickerKind.play,
  TickerKind.shotUp,
  TickerKind.freeKick,
  TickerKind.colour,
  TickerKind.calm,
};

/// The symbol before a highlight; plain story lines have none.
enum TickerSymbol {
  whistle,
  goal,
  yellow,
  yellowRed,
  red,
  injury,
  sub,
  time,
  bigChance,
}

/// How long a line needs to be read: story, chance or card, big moment.
enum TickerWeight { light, normal, heavy }

TickerSymbol? _symbolOf(TickerKind kind) => switch (kind) {
  TickerKind.kickOff ||
  TickerKind.halfTime ||
  TickerKind.fullTime ||
  TickerKind.extraTime ||
  TickerKind.shootout => TickerSymbol.whistle,
  TickerKind.goal || TickerKind.goalAssist => TickerSymbol.goal,
  TickerKind.yellow => TickerSymbol.yellow,
  TickerKind.secondYellow => TickerSymbol.yellowRed,
  TickerKind.red => TickerSymbol.red,
  TickerKind.injury => TickerSymbol.injury,
  TickerKind.substitution => TickerSymbol.sub,
  TickerKind.addedTime ||
  TickerKind.keeperEightSeconds ||
  TickerKind.goalKickCountdown ||
  TickerKind.throwInCountdown => TickerSymbol.time,
  TickerKind.penalty => TickerSymbol.bigChance,
  _ => null,
};

TickerWeight _weightOf(TickerKind kind) => switch (kind) {
  TickerKind.goal ||
  TickerKind.goalAssist ||
  TickerKind.penalty ||
  TickerKind.red ||
  TickerKind.secondYellow => TickerWeight.heavy,
  TickerKind.parade ||
  TickerKind.miss ||
  TickerKind.yellow ||
  TickerKind.injury ||
  TickerKind.substitution ||
  TickerKind.counter ||
  TickerKind.addedTime ||
  TickerKind.halfTime ||
  TickerKind.fullTime ||
  TickerKind.captainOff ||
  TickerKind.shotUp ||
  TickerKind.keeperEightSeconds ||
  TickerKind.goalKickCountdown => TickerWeight.normal,
  _ => TickerWeight.light,
};

/// Which ticker line an event gets; null for events the ticker leaves out
/// (free kicks, shoot-out kicks, quiet lost passes). Also used by the match
/// report for the kind of a card.
TickerKind? tickerKindOf(MatchEvent e) {
  switch (e.type) {
    case MatchEventType.kickOff:
      return TickerKind.kickOff;
    case MatchEventType.shot:
      if (e.isGoal) {
        return e.otherPlayer == null ? TickerKind.goal : TickerKind.goalAssist;
      }
      if (e.quality == ChanceQuality.half) {
        // A blocked half chance is not worth a line.
        return e.outcome == ShotOutcome.blocked ? null : TickerKind.halfChance;
      }
      return switch (e.outcome) {
        ShotOutcome.saved => TickerKind.parade,
        ShotOutcome.blocked => TickerKind.blocked,
        _ => TickerKind.miss,
      };
    case MatchEventType.penalty:
      return TickerKind.penalty;
    case MatchEventType.corner:
      return TickerKind.corner;
    case MatchEventType.yellowCard:
      return TickerKind.yellow;
    case MatchEventType.secondYellow:
      return TickerKind.secondYellow;
    case MatchEventType.redCard:
      return TickerKind.red;
    case MatchEventType.injury:
      return TickerKind.injury;
    case MatchEventType.substitution:
      return TickerKind.substitution;
    case MatchEventType.tacticChange:
      return TickerKind.tactic;
    case MatchEventType.halfTime:
      return TickerKind.halfTime;
    case MatchEventType.fullTime:
      return TickerKind.fullTime;
    case MatchEventType.extraTime:
      return TickerKind.extraTime;
    case MatchEventType.addedTime:
      return TickerKind.addedTime;
    case MatchEventType.counterAttack:
      return TickerKind.counter;
    case MatchEventType.ballWon:
      return switch (e.action) {
        'cross' => TickerKind.lostCross,
        'through_ball' => TickerKind.lostThroughBall,
        'dribble' => TickerKind.lostDribble,
        'long_ball' => TickerKind.lostLongBall,
        // A plain lost pass is not worth a line.
        _ => null,
      };
    case MatchEventType.timeWasting:
      return switch (e.action) {
        'keeper_eight_seconds' => TickerKind.keeperEightSeconds,
        'goal_kick_countdown' => TickerKind.goalKickCountdown,
        _ => TickerKind.throwInCountdown,
      };
    default:
      return null;
  }
}

/// Events after which the live match stops by itself so the manager can
/// react: injuries, red cards and half time (document "Bauabschnitt 7").
bool pausesMatch(MatchEvent e) =>
    e.type == MatchEventType.injury ||
    e.type == MatchEventType.redCard ||
    e.type == MatchEventType.secondYellow ||
    e.type == MatchEventType.halfTime ||
    e.type == MatchEventType.extraTime;

/// One line of the ticker.
class TickerLine {
  const TickerLine({
    required this.minute,
    required this.kind,
    required this.side,
    required this.homeGoals,
    required this.awayGoals,
    required this.text,
    this.clock,
  });

  final int minute;

  /// The clock as shown ("45+2"); [minute] when null.
  final String? clock;
  final TickerKind kind;

  /// 0 home, 1 away, -1 neutral.
  final int side;
  final int homeGoals;
  final int awayGoals;
  final String text;

  bool get isGoal => kind == TickerKind.goal || kind == TickerKind.goalAssist;

  String get clockLabel => clock ?? '$minute';

  /// The symbol before the line, null for plain story lines.
  TickerSymbol? get symbol => _symbolOf(kind);

  /// Lines after a goal and big chances need more time to be read.
  TickerWeight get weight => _weightOf(kind);
}

const _neutral = {
  TickerKind.kickOff,
  TickerKind.halfTime,
  TickerKind.fullTime,
  TickerKind.extraTime,
  TickerKind.addedTime,
};

/// Writes the ticker lines of one event; none if the ticker skips it. A goal
/// gets three lines: the goal, then the scorer and the one who laid it on.
/// [index] is the position of the event in the match; it picks the text, so
/// the same match always reads the same. [lead] gives a short sentence that
/// tells how the attack before a shot went (by the action of the rules);
/// [captainOf] adds a line when a captain leaves the pitch.
List<TickerLine> tickerLinesOf(
  MatchEvent e,
  int index, {
  required List<String> Function(TickerKind kind) templates,
  required String Function(PlayerId? id) playerName,
  required String home,
  required String away,
  String Function(String action)? lead,
  PlayerId? Function(int side)? captainOf,
}) {
  final kind = tickerKindOf(e);
  if (kind == null) return const [];
  final team = e.side == 1 ? away : home;
  final other = e.side == 1 ? home : away;
  String fill(String pick) => pick
      .replaceAll('{p}', playerName(e.player))
      .replaceAll('{q}', playerName(e.otherPlayer))
      .replaceAll('{team}', team)
      .replaceAll('{opp}', other)
      .replaceAll('{home}', home)
      .replaceAll('{away}', away)
      .replaceAll('{score}', '${e.homeGoals}:${e.awayGoals}')
      .replaceAll('{days}', '${e.injuryDays ?? 0}')
      .replaceAll('{n}', '${e.value ?? 0}');
  String pickFor(TickerKind k, int salt) {
    final options = templates(k);
    if (options.isEmpty) return '';
    return options[(index * 7 + e.minute * 3 + e.homeGoals + salt) %
        options.length];
  }

  TickerLine line(TickerKind k, String text) => TickerLine(
    minute: e.minute,
    clock: e.clockLabel,
    kind: k,
    side: _neutral.contains(k) ? -1 : e.side,
    homeGoals: e.homeGoals,
    awayGoals: e.awayGoals,
    text: text,
  );

  var main = fill(pickFor(kind, 0));
  if (main.isEmpty) return const [];
  // The build-up before a shot: "Flanke von Müller." and then the shot.
  final passer = e.chain.isEmpty ? null : e.chain.last;
  final action = e.action;
  if (e.type == MatchEventType.shot &&
      lead != null &&
      action != null &&
      action != 'long_shot' &&
      passer != null) {
    final before = lead(action).replaceAll('{q}', playerName(passer));
    if (before.isNotEmpty) main = '$before $main';
  }
  final lines = [line(kind, main)];
  if (e.isGoal && e.type == MatchEventType.shot) {
    lines.add(line(TickerKind.scorer, fill(pickFor(TickerKind.scorer, 1))));
    if (e.otherPlayer != null) {
      lines.add(line(TickerKind.assist, fill(pickFor(TickerKind.assist, 2))));
    }
  }
  // The captain leaves: the armband goes elsewhere.
  final captain = e.side < 0 ? null : captainOf?.call(e.side);
  final leaving = switch (e.type) {
    MatchEventType.substitution => e.otherPlayer,
    MatchEventType.injury ||
    MatchEventType.redCard ||
    MatchEventType.secondYellow => e.player,
    _ => null,
  };
  if (captain != null && leaving == captain) {
    final text = pickFor(
      TickerKind.captainOff,
      3,
    ).replaceAll('{p}', playerName(captain)).replaceAll('{team}', team);
    if (text.isNotEmpty) lines.add(line(TickerKind.captainOff, text));
  }
  return lines;
}

/// Time a line should stay before the match runs on, at ticker [speed]
/// (0 slow, 1 medium, 2 fast): big moments longer than story lines.
Duration readingTime(TickerLine line, int speed) {
  const factor = [1.0, 0.6, 0.3];
  final ms = switch (line.weight) {
    TickerWeight.heavy => 2400,
    TickerWeight.normal => 1500,
    TickerWeight.light => 900,
  };
  return Duration(milliseconds: (ms * factor[speed.clamp(0, 2)]).round());
}
