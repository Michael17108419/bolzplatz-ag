import 'dart:math' as math;

import '../match/match_types.dart';
import '../model/ids.dart';
import '../rules/season_rules.dart';

/// Ratings of the players of a match, 1 (awful) to 10 (world class)
/// around the base of the rules (engine 2, step 10f2): goals, assists,
/// won duels and pretty moves, balls won and lost, saves and goals against
/// for the keeper, cards and protest, and the result for everyone who
/// played. Players under the minimum minutes get no rating. [homePlayers]
/// tells which players played for the home team.
Map<PlayerId, double> matchRatings(
  MatchResult r,
  ConditionRules c, {
  required Set<PlayerId> homePlayers,
}) {
  final rating = <PlayerId, double>{
    for (final e in r.minutesPlayed.entries)
      if (e.value > 0) e.key: c['rating_base'],
  };
  void add(PlayerId? id, double d) {
    if (id == null) return;
    final v = rating[id];
    if (v != null) rating[id] = v + d;
  }

  MatchEvent? prev;
  for (final e in r.events) {
    for (final s in e.steps) {
      if (!s.won) continue;
      add(s.player, c['rating_step']);
      if (s.has(AttackStep.pretty)) add(s.player, c['rating_pretty']);
    }
    switch (e.type) {
      case MatchEventType.shot:
        final pen =
            prev != null &&
            prev.type == MatchEventType.penalty &&
            prev.tick == e.tick &&
            prev.side == e.side;
        if (e.isGoal) {
          add(e.player, pen ? c['rating_penalty_goal'] : c['rating_goal']);
          add(e.otherPlayer, c['rating_assist']);
          add(e.keeper, -c['rating_conceded']);
        } else {
          if (pen) add(e.player, -c['rating_penalty_miss']);
          if (e.quality == ChanceQuality.big) add(e.player, -c['rating_big_miss']);
          if (e.outcome == ShotOutcome.saved) add(e.keeper, c['rating_save']);
        }
      case MatchEventType.ballWon:
      case MatchEventType.counterAttack:
        add(e.player, c['rating_ball_won']);
        add(e.otherPlayer, -c['rating_ball_lost']);
      case MatchEventType.yellowCard:
        add(e.player, -c['rating_yellow']);
      case MatchEventType.secondYellow:
        add(e.player, -c['rating_second']);
      case MatchEventType.redCard:
        add(e.player, -c['rating_red']);
      case MatchEventType.dissent:
        if (e.action == 'protest') add(e.player, -c['rating_protest']);
      default:
        break;
    }
    prev = e;
  }
  final diff = r.homeGoals - r.awayGoals;
  final out = <PlayerId, double>{};
  for (final e in rating.entries) {
    final minutes = r.minutesPlayed[e.key] ?? 0;
    if (minutes < c['min_minutes_rating']) continue;
    final home = homePlayers.contains(e.key);
    final mine = home ? diff : -diff;
    final share = math.min(1.0, minutes / 90);
    final result = mine > 0
        ? c['rating_win']
        : mine < 0
        ? -c['rating_loss']
        : 0.0;
    out[e.key] = (e.value + result * share).clamp(1.0, 10.0);
  }
  return out;
}

/// A rating as a school mark like in the papers: 1 (best) to 6, in half
/// steps.
double markOf(double rating) {
  final raw = (1 + (9 - rating) * 0.83).clamp(1.0, 6.0);
  return (raw * 2).round() / 2;
}
