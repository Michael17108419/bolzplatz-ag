/// The 13 hidden character traits (scale 1 to 100 like attributes).
/// Injury proneness is a separate hidden value and not part of this enum.
enum CharacterTrait {
  professionalism('professionalism'),
  temper('temper'),
  aggression('aggression'),
  egoism('egoism'),
  leadership('leadership'),
  pressureResistance('pressure_resistance'),
  creativity('creativity'),
  mediaHunger('media_hunger'),
  partyFactor('party_factor'),
  greed('greed'),
  ambition('ambition'),
  loyalty('loyalty'),
  consistency('consistency');

  const CharacterTrait(this.id);

  final String id;
}
