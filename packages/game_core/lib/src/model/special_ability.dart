/// Tier of a special ability.
enum AbilityTier {
  bronze,
  silver,
  gold,
}

/// The 16 special abilities of the MVP.
enum SpecialAbilityType {
  dribbler('dribbler'),
  longShooter('long_shooter'),
  volleySpecialist('volley_specialist'),
  goalPoacher('goal_poacher'),
  headerMonster('header_monster'),
  playmaker('playmaker'),
  targetMan('target_man'),
  counterPlayer('counter_player'),
  setPieceSpecialist('set_piece_specialist'),
  ballShield('ball_shield'),
  firstTouch('first_touch'),
  vacuumCleaner('vacuum_cleaner'),
  pressingMachine('pressing_machine'),
  passReader('pass_reader'),
  penaltyKiller('penalty_killer'),
  allrounder('allrounder');

  const SpecialAbilityType(this.id);

  final String id;
}

/// One ability of a player with its tier.
class SpecialAbility {
  const SpecialAbility(this.type, this.tier);

  final SpecialAbilityType type;
  final AbilityTier tier;

  @override
  bool operator ==(Object other) =>
      other is SpecialAbility && other.type == type && other.tier == tier;

  @override
  int get hashCode => Object.hash(type, tier);
}
