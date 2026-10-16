import 'package:game_core/game_core.dart';

/// The kinds of lines the live ticker writes. Every kind has several texts
/// (in the strings), so that a match does not read like a form letter.
enum TickerKind {
  kickOff,
  goal,
  goalAssist,
  penalty,
  parade,
  miss,
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
}

/// Which ticker line an event gets; null for events the ticker leaves out
/// (corners, free kicks, half chances, extra time and shoot-out kicks).
TickerKind? tickerKindOf(MatchEvent e) {
  switch (e.type) {
    case MatchEventType.kickOff:
      return TickerKind.kickOff;
    case MatchEventType.shot:
      if (e.isGoal) {
        return e.otherPlayer == null ? TickerKind.goal : TickerKind.goalAssist;
      }
      if (e.quality == null || e.quality == ChanceQuality.half) return null;
      return e.outcome == ShotOutcome.saved
          ? TickerKind.parade
          : TickerKind.miss;
    case MatchEventType.penalty:
      return TickerKind.penalty;
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
  });

  final int minute;
  final TickerKind kind;

  /// 0 home, 1 away, -1 neutral.
  final int side;
  final int homeGoals;
  final int awayGoals;
  final String text;

  bool get isGoal => kind == TickerKind.goal || kind == TickerKind.goalAssist;
}

/// Writes the ticker line of one event, or null if the ticker skips it.
/// [index] is the position of the event in the match; it picks the text, so
/// the same match always reads the same.
TickerLine? tickerLineOf(
  MatchEvent e,
  int index, {
  required List<String> Function(TickerKind kind) templates,
  required String Function(PlayerId? id) playerName,
  required String home,
  required String away,
}) {
  final kind = tickerKindOf(e);
  if (kind == null) return null;
  final options = templates(kind);
  if (options.isEmpty) return null;
  final pick =
      options[(index * 7 + e.minute * 3 + e.homeGoals) % options.length];
  final team = e.side == 1 ? away : home;
  final other = e.side == 1 ? home : away;
  final text = pick
      .replaceAll('{p}', playerName(e.player))
      .replaceAll('{q}', playerName(e.otherPlayer))
      .replaceAll('{team}', team)
      .replaceAll('{opp}', other)
      .replaceAll('{home}', home)
      .replaceAll('{away}', away)
      .replaceAll('{score}', '${e.homeGoals}:${e.awayGoals}')
      .replaceAll('{days}', '${e.injuryDays ?? 0}');
  return TickerLine(
    minute: e.minute,
    kind: kind,
    side: e.side,
    homeGoals: e.homeGoals,
    awayGoals: e.awayGoals,
    text: text,
  );
}
