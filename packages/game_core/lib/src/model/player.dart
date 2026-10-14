import '../calendar/game_date.dart';
import 'attribute_set.dart';
import 'character.dart';
import 'contract.dart';
import 'development.dart';
import 'ids.dart';
import 'position.dart';
import 'special_ability.dart';

/// A player. Immutable; state changes create a new instance.
class Player {
  Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.position,
    required this.attributes,
    required Map<CharacterTrait, double> traits,
    required this.injuryProneness,
    required List<SpecialAbility> abilities,
    required this.developmentType,
    required this.potentialCore,
    required this.potentialDynamic,
    Map<String, RoleFamiliarity> roles = const {},
    this.foot = Foot.right,
    this.weakFoot = 3,
    this.nationality = 'DE',
    Map<Position, PositionFamiliarity> secondaryPositions = const {},
    this.clubId,
    this.contract,
  }) : traits = Map.unmodifiable(traits),
       abilities = List.unmodifiable(abilities),
       roles = Map.unmodifiable(roles),
       secondaryPositions = Map.unmodifiable(secondaryPositions) {
    for (final trait in CharacterTrait.values) {
      final value = traits[trait];
      if (value == null || value < 1 || value > 100) {
        throw ArgumentError('Trait ${trait.id} missing or outside 1 to 100');
      }
    }
    if (injuryProneness < 1 || injuryProneness > 100) {
      throw ArgumentError('Injury proneness outside 1 to 100');
    }
    if (potentialCore < 1 || potentialCore > 100) {
      throw ArgumentError('Potential core outside 1 to 100');
    }
    if (potentialDynamic < 0 || potentialDynamic > 100) {
      throw ArgumentError('Potential dynamic share outside 0 to 100');
    }
    if (weakFoot < 1 || weakFoot > 5) {
      throw ArgumentError('Weak foot outside 1 to 5 stars');
    }
    if (nationality.length != 2) {
      throw ArgumentError('Nationality must be a two-letter code');
    }
    if (secondaryPositions.length > 3) {
      throw ArgumentError('At most three secondary positions');
    }
    if (secondaryPositions.containsKey(position) ||
        (!position.isGoalkeeper &&
            secondaryPositions.containsKey(Position.tw))) {
      throw ArgumentError('Bad secondary position');
    }
    if (position.isGoalkeeper && secondaryPositions.isNotEmpty) {
      throw ArgumentError('A goalkeeper has no secondary positions');
    }
    _checkAbilities(abilities);
    if (contract != null && contract!.playerId != id) {
      throw ArgumentError('Contract belongs to another player');
    }
  }

  final PlayerId id;
  final String firstName;
  final String lastName;
  final GameDate birthDate;
  final Position position;
  final AttributeSet attributes;

  /// Hidden character traits, all 13 present.
  final Map<CharacterTrait, double> traits;
  final double injuryProneness;

  /// At most four abilities, at most one on gold, no type twice.
  final List<SpecialAbility> abilities;
  final DevelopmentType developmentType;

  /// Fixed part of the potential (does not change).
  final double potentialCore;

  /// Dynamic part of the potential (moves with development and play).
  final double potentialDynamic;

  /// Role id (from rules) to familiarity. Missing means basic (no bonus, no deduction).
  final Map<String, RoleFamiliarity> roles;

  /// Preferred foot.
  final Foot foot;

  /// Weak foot, 1 to 5 stars (5 means two-footed).
  final int weakFoot;

  /// Two-letter country code (flag and name pool).
  final String nationality;

  /// Up to three secondary positions with their familiarity.
  final Map<Position, PositionFamiliarity> secondaryPositions;

  /// Null for free agents without a club.
  final ClubId? clubId;
  final Contract? contract;

  /// Copy with other name, contract, attributes, dynamic potential, traits,
  /// weak foot or secondary positions.
  /// Everything else is kept.
  Player copyWith({
    String? firstName,
    String? lastName,
    Contract? contract,
    AttributeSet? attributes,
    double? potentialDynamic,
    Map<CharacterTrait, double>? traits,
    int? weakFoot,
    Map<Position, PositionFamiliarity>? secondaryPositions,
  }) {
    return Player(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate,
      position: position,
      attributes: attributes ?? this.attributes,
      traits: traits ?? this.traits,
      injuryProneness: injuryProneness,
      abilities: abilities,
      developmentType: developmentType,
      potentialCore: potentialCore,
      potentialDynamic: potentialDynamic ?? this.potentialDynamic,
      roles: roles,
      foot: foot,
      weakFoot: weakFoot ?? this.weakFoot,
      nationality: nationality,
      secondaryPositions: secondaryPositions ?? this.secondaryPositions,
      clubId: clubId,
      contract: contract ?? this.contract,
    );
  }

  String get displayName => '$firstName $lastName';

  int ageOn(GameDate date) {
    var age = date.year - birthDate.year;
    if (date.month < birthDate.month ||
        (date.month == birthDate.month && date.day < birthDate.day)) {
      age -= 1;
    }
    return age;
  }

  static void _checkAbilities(List<SpecialAbility> abilities) {
    if (abilities.length > 4) {
      throw ArgumentError('At most four special abilities');
    }
    final gold = abilities.where((a) => a.tier == AbilityTier.gold).length;
    if (gold > 1) {
      throw ArgumentError('At most one gold ability');
    }
    final types = abilities.map((a) => a.type).toSet();
    if (types.length != abilities.length) {
      throw ArgumentError('Duplicate special ability');
    }
  }

  @override
  bool operator ==(Object other) => other is Player && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
