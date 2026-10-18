import '../calendar/game_date.dart';
import 'career.dart';
import 'ids.dart';

/// A coach. Skill keys are string ids defined in the rules, so the set of
/// coach values can change without touching this class.
class Coach {
  Coach({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required Map<String, double> skills,
    this.clubId,
  }) : skills = Map.unmodifiable(skills) {
    for (final entry in skills.entries) {
      if (entry.value < 1 || entry.value > 100) {
        throw ArgumentError('Coach skill ${entry.key} outside 1 to 100');
      }
    }
  }

  final CoachId id;
  final String firstName;
  final String lastName;
  final GameDate birthDate;
  final Map<String, double> skills;
  final ClubId? clubId;

  String get displayName => '$firstName $lastName';

  @override
  bool operator ==(Object other) => other is Coach && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// What a coach brings to his team (engine 2, step 10f3): tactical
/// knowledge for changes in a match, charisma and motivation for team
/// talks, man management for the mood of the players. All 1 to 100, 50 is
/// an average coach.
class CoachProfile {
  const CoachProfile({
    this.tactics = 50,
    this.charisma = 50,
    this.motivation = 50,
    this.leadership = 50,
    this.strain = 0,
  });

  /// An AI coach of the world. Coaches of the world know no motivation and
  /// man management yet: those follow charisma and tactical knowledge.
  factory CoachProfile.ofCoach(Coach c) {
    final tactics = c.skills['tactical_knowledge'] ?? 50;
    final charisma = c.skills['charisma'] ?? 50;
    return CoachProfile(
      tactics: tactics,
      charisma: charisma,
      motivation: c.skills['motivation'] ?? charisma,
      leadership: c.skills['man_management'] ?? (charisma + tactics) / 2,
    );
  }

  /// The manager of the player.
  factory CoachProfile.ofTrainer(Trainer t) => CoachProfile(
    tactics: t[ManagerValue.tacticalKnowledge],
    charisma: t[ManagerValue.charisma],
    motivation: t[ManagerValue.motivation],
    leadership: t[ManagerValue.manManagement],
  );

  final double tactics;
  final double charisma;
  final double motivation;
  final double leadership;

  /// Share a stressed manager loses of his team talks (step 11e), 0 to 1.
  final double strain;

  /// The same coach under [strain].
  CoachProfile withStrain(double strain) => CoachProfile(
    tactics: tactics,
    charisma: charisma,
    motivation: motivation,
    leadership: leadership,
    strain: strain,
  );

  /// How strongly a team talk lands: 0.5 for a dull coach, 1.5 for a
  /// fiery one, less under stress.
  double get talk => (0.5 + (charisma + motivation) / 200) * (1 - strain);
}
