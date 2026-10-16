import '../model/career.dart';
import '../rng/seeded_random.dart';

/// How the season ended, measured against the goal of the president.
enum GoalVerdict { exceeded, reached, missed, failed }

/// The verdict on a season and what follows from it.
class SeasonReview {
  const SeasonReview({
    required this.goal,
    required this.verdict,
    required this.gap,
    required this.rank,
    required this.teams,
    required this.risk,
    required this.dismissed,
  });

  final SeasonGoal goal;
  final GoalVerdict verdict;

  /// How many places the goal was missed by (0 if reached).
  final int gap;
  final int rank;
  final int teams;

  /// Chance (0 to 1) that the manager was dismissed.
  final double risk;
  final bool dismissed;
}

/// Judges a season. Pure and deterministic: the same inputs and seed give
/// the same verdict. Numbers are kept together here until the rules file
/// takes them.
class SeasonReviewer {
  const SeasonReviewer();

  /// The goal the president sets for a new season: from the strength rank of
  /// the club in its league (1 is the strongest) and the league level.
  static SeasonGoal goalFor({
    required int level,
    required int strengthRank,
    required int teams,
  }) {
    final quarter = ((strengthRank - 1) * 4 ~/ teams).clamp(0, 3);
    return switch (quarter) {
      0 => level == 1 ? SeasonGoal.title : SeasonGoal.promotion,
      3 => SeasonGoal.survival,
      _ => SeasonGoal.noTarget,
    };
  }

  /// [levelChange] is -1 when the club went up a league, 1 when it went
  /// down, 0 otherwise. [presidentTrust] and [squadMood] run from 0 (bad)
  /// to 1 (good); 0.5 is neutral and stands in until both are in the game.
  SeasonReview review({
    required SeasonGoal goal,
    required int rank,
    required int teams,
    required int levelChange,
    required int seed,
    double presidentTrust = 0.5,
    double squadMood = 0.5,
  }) {
    final promoted = levelChange < 0;
    final relegated = levelChange > 0;
    var verdict = GoalVerdict.reached;
    var gap = 0;
    switch (goal) {
      case SeasonGoal.title:
        if (rank == 1) {
          verdict = GoalVerdict.reached;
        } else {
          gap = rank - 1;
          verdict = gap <= 2 ? GoalVerdict.missed : GoalVerdict.failed;
        }
      case SeasonGoal.promotion:
        if (promoted) {
          verdict = rank == 1 ? GoalVerdict.exceeded : GoalVerdict.reached;
        } else {
          gap = (rank - 3).clamp(1, teams);
          verdict = gap <= 3 ? GoalVerdict.missed : GoalVerdict.failed;
        }
      case SeasonGoal.noTarget:
        if (relegated) {
          gap = 1;
          verdict = GoalVerdict.failed;
        } else if (rank <= 3 || promoted) {
          verdict = GoalVerdict.exceeded;
        }
      case SeasonGoal.survival:
      case SeasonGoal.licence:
        if (relegated) {
          gap = (rank - (teams - 3)).clamp(1, teams);
          verdict = gap <= 1 ? GoalVerdict.missed : GoalVerdict.failed;
        } else if (rank <= teams ~/ 2 || promoted) {
          verdict = GoalVerdict.exceeded;
        }
    }
    var risk = 0.0;
    if (verdict == GoalVerdict.missed) {
      risk = 0.2 + 0.05 * gap;
    } else if (verdict == GoalVerdict.failed) {
      risk = 0.55 + 0.04 * gap;
    }
    if (risk > 0) {
      risk += (0.5 - presidentTrust) * 0.6 + (0.5 - squadMood) * 0.4;
      risk = risk.clamp(0.0, 0.95);
    }
    final dismissed =
        risk > 0 && SeededRandom(seed).fork('dismissal').nextDouble() < risk;
    return SeasonReview(
      goal: goal,
      verdict: verdict,
      gap: gap,
      rank: rank,
      teams: teams,
      risk: risk,
      dismissed: dismissed,
    );
  }
}
