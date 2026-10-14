import '../calendar/game_date.dart';
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
