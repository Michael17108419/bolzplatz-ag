import '../calendar/game_date.dart';
import '../model/ids.dart';
import 'conference.dart';

/// Where a case of the sports court stands (engine 2, step 10e3).
enum CourtStatus {
  /// The motion of the control committee waits for the club: accept or
  /// appeal. The player is banned as moved until then.
  open,

  /// The club accepted the motion (other clubs always do).
  accepted,

  /// The club appealed; the sports court decided ([CourtCase.verdict]).
  appealed,

  /// Proceedings stopped: the referee sent off the wrong player.
  stopped,
}

/// A case of the sports court after a straight red card (DFB procedure):
/// the motion of the control committee the working day after the match, a
/// ban in matches of the competition or in weeks on the calendar.
class CourtCase {
  CourtCase({
    required this.id,
    required this.player,
    required this.club,
    required this.competition,
    required this.kind,
    required this.epochDay,
    required this.motion,
    required this.weeks,
    required this.status,
    this.review,
    this.verdict,
  });

  /// Day and player: unique within a season.
  final String id;
  final PlayerId player;
  final ClubId club;
  final Competition competition;

  /// Kind of the red card: `dogso` (Notbremse), `rough`, `violent`,
  /// `insult` or `other`.
  final String kind;

  /// What the referee got wrong, if anything (`red_harsh`, `identity`).
  final String? review;

  /// The day of the match.
  final int epochDay;

  /// The ban the control committee moves.
  final int motion;

  /// True for a ban in weeks, false for one in matches.
  final bool weeks;
  CourtStatus status;

  /// The ban the sports court set after an appeal.
  int? verdict;

  GameDate get date => GameDate.fromEpochDay(epochDay);

  /// The ban that holds now.
  int get ban => status == CourtStatus.stopped ? 0 : (verdict ?? motion);
}
