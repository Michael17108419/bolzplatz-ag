import '../calendar/game_date.dart';
import 'ids.dart';

/// A player contract. Money amounts are whole euros.
class Contract {
  Contract({
    required this.id,
    required this.playerId,
    required this.clubId,
    required this.start,
    required this.end,
    required this.baseSalaryPerYear,
    this.salaryStages = const [],
    this.appearanceBonus = 0,
    this.goalBonus = 0,
    this.titleBonus = 0,
    this.signingBonus = 0,
    this.releaseClause,
    this.rolePromise,
    this.loanFromClubId,
  }) {
    if (!end.isAfter(start)) {
      throw ArgumentError('Contract end must be after start');
    }
    if (baseSalaryPerYear < 0 ||
        appearanceBonus < 0 ||
        goalBonus < 0 ||
        titleBonus < 0 ||
        signingBonus < 0 ||
        (releaseClause ?? 0) < 0) {
      throw ArgumentError('Contract amounts must not be negative');
    }
  }

  final ContractId id;
  final PlayerId playerId;

  /// The club the player plays for (the borrowing club on a loan).
  final ClubId clubId;
  final GameDate start;
  final GameDate end;
  final int baseSalaryPerYear;

  /// Optional salary per contract year; empty means a flat salary.
  final List<int> salaryStages;
  final int appearanceBonus;
  final int goalBonus;
  final int titleBonus;
  final int signingBonus;

  /// Release clause amount, null when there is none.
  final int? releaseClause;

  /// Role id promised to the player (see rules), null when none.
  final String? rolePromise;

  /// Owning club when this is a loan, null otherwise.
  final ClubId? loanFromClubId;

  bool get isLoan => loanFromClubId != null;
}
