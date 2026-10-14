import '../calendar/game_date.dart';
import '../model/attribute.dart';
import '../model/attribute_set.dart';
import '../model/character.dart';
import '../model/development.dart';
import '../model/ids.dart';
import '../model/player.dart';
import '../model/position.dart';
import '../model/special_ability.dart';
import '../rng/seeded_random.dart';
import '../rules/generator_rules.dart';
import '../rules/rules.dart';

/// First and last names to draw from. Real lists come from a data file.
class NameLists {
  NameLists({required List<String> first, required List<String> last})
    : first = List.unmodifiable(first),
      last = List.unmodifiable(last) {
    if (first.isEmpty || last.isEmpty) {
      throw ArgumentError('Name lists must not be empty');
    }
  }

  final List<String> first;
  final List<String> last;
}

/// Creates players from the numbers in the rules.
///
/// Every player is drawn from its own fork of the world random generator,
/// labelled with the player id, so the result does not depend on the order
/// in which players are generated.
class PlayerGenerator {
  PlayerGenerator({
    required this.rules,
    required this.names,
    required this.referenceDate,
  });

  final Rules rules;
  final NameLists names;

  /// Ages are counted on this date (start of the season).
  final GameDate referenceDate;

  GeneratorRules get _g => rules.generator;

  /// Generates one player for a club on [tier] (1 to 4, 5 for pool clubs).
  Player generate({
    required SeededRandom world,
    required PlayerId id,
    required Position position,
    required int tier,
    ClubId? clubId,
  }) {
    final tierRules = _g.tiers[tier];
    if (tierRules == null) throw ArgumentError.value(tier, 'tier');
    final rng = world.fork('player:${id.value}');

    final age = _age(rng);
    final birthDate = _birthDate(rng, age);
    final devType = _developmentType(rng);

    // Prime level of this player, before age effects and position profile.
    final level = _clamp(
      tierRules.levelMean + rng.nextGaussian() * tierRules.levelSd,
      1,
      99,
    );

    final attributes = _attributes(rng, position, level, age, devType);
    final potentialCore = _clamp(
      level +
          _g.potentialMarginMean +
          rng.nextGaussian() * _g.potentialMarginSd,
      level,
      100,
    );
    final potentialDynamic = _dynamicPotential(rng, age);

    return Player(
      id: id,
      firstName: rng.pick(names.first),
      lastName: rng.pick(names.last),
      birthDate: birthDate,
      position: position,
      attributes: attributes,
      traits: {
        for (final t in CharacterTrait.values)
          t: _clamp(_g.traitMean + rng.nextGaussian() * _g.traitSd, 1, 100),
      },
      injuryProneness: _clamp(
        _g.injuryMean + rng.nextGaussian() * _g.injurySd,
        1,
        100,
      ),
      abilities: _abilities(rng, position, tierRules),
      developmentType: devType,
      potentialCore: potentialCore,
      potentialDynamic: potentialDynamic,
      clubId: clubId,
    );
  }

  /// Generates a full squad following the squad template. Player ids are
  /// assigned from [firstId] upwards in a fixed position order.
  List<Player> generateSquad({
    required SeededRandom world,
    required int firstId,
    required int tier,
    ClubId? clubId,
  }) {
    final players = <Player>[];
    var next = firstId;
    for (final position in Position.values) {
      final count = _g.squadTemplate[position] ?? 0;
      for (var i = 0; i < count; i++) {
        players.add(
          generate(
            world: world,
            id: PlayerId(next++),
            position: position,
            tier: tier,
            clubId: clubId,
          ),
        );
      }
    }
    return players;
  }

  int _age(SeededRandom rng) {
    final ages = _g.ageWeights.keys.toList()..sort();
    final index = rng.weightedIndex([for (final a in ages) _g.ageWeights[a]!]);
    return ages[index];
  }

  GameDate _birthDate(SeededRandom rng, int age) {
    // age years back from the reference date, plus up to a year more, so
    // the player is exactly [age] years old on the reference date.
    final daysBack = age * 365 + age ~/ 4 + rng.nextInt(365);
    return GameDate.fromEpochDay(referenceDate.epochDay - daysBack);
  }

  DevelopmentType _developmentType(SeededRandom rng) {
    const order = DevelopmentType.values;
    final index = rng.weightedIndex([
      for (final d in order) _g.developmentTypeWeights[d]!,
    ]);
    return order[index];
  }

  AttributeSet _attributes(
    SeededRandom rng,
    Position position,
    double level,
    int age,
    DevelopmentType devType,
  ) {
    final profile = _g.positionProfiles[position]!;
    final shift = _g.developmentShiftYears[devType]!;
    final isKeeper = position.isGoalkeeper;
    final values = <Attribute, double>{};
    for (final attribute in Attribute.values) {
      if (attribute.isGoalkeeping && !isKeeper) {
        values[attribute] =
            _g.goalkeeperFieldMin +
            rng.nextDouble() * (_g.goalkeeperFieldMax - _g.goalkeeperFieldMin);
        continue;
      }
      var value = level + (profile[attribute] ?? 0);
      if (isKeeper && !attribute.isGoalkeeping) {
        value += _g.goalkeeperOutfieldOffset;
      }
      final mental = attribute.group == AttributeGroup.intelligence;
      final effectiveShift = mental ? shift * _g.mentalShiftFactor : shift;
      value += _ageAdjust(rules.ageCurves[attribute]!, age - effectiveShift);
      value += rng.nextGaussian() * _g.attributeNoiseSd;
      values[attribute] = _clamp(value, Attribute.min, Attribute.max);
    }
    return AttributeSet.fromMap(values);
  }

  /// Points to add (zero or negative) for a player of [effectiveAge].
  double _ageAdjust(AgeCurve curve, double effectiveAge) {
    if (effectiveAge < curve.risesUntil) {
      return -(curve.risesUntil - effectiveAge) * _g.growthPerYear;
    }
    if (effectiveAge >= curve.declinesFrom) {
      return -(effectiveAge - curve.declinesFrom + 1) * _g.declinePerYear;
    }
    return 0;
  }

  double _dynamicPotential(SeededRandom rng, int age) {
    if (age >= _g.dynamicFrozenFromAge) return 0;
    final base = (_g.dynamicFrozenFromAge - age) * _g.dynamicPerYear;
    final value = base * (0.5 + rng.nextDouble());
    return value > _g.dynamicMax ? _g.dynamicMax : value;
  }

  List<SpecialAbility> _abilities(
    SeededRandom rng,
    Position position,
    TierRules tier,
  ) {
    final allowed = [
      for (final type in SpecialAbilityType.values)
        if (_g.abilityPositions[type]!.contains(position)) type,
    ];
    var count = rng.weightedIndex(tier.abilityCountWeights);
    if (count > allowed.length) count = allowed.length;
    if (count > rules.maxAbilitiesPerPlayer) {
      count = rules.maxAbilitiesPerPlayer;
    }
    rng.shuffle(allowed);
    final result = <SpecialAbility>[];
    var hasGold = false;
    for (final type in allowed.take(count)) {
      AbilityTier level;
      final roll = rng.nextDouble();
      if (!hasGold &&
          rules.maxGoldAbilitiesPerPlayer > 0 &&
          roll < tier.goldChance) {
        level = AbilityTier.gold;
        hasGold = true;
      } else if (roll < tier.goldChance + tier.silverChance) {
        level = AbilityTier.silver;
      } else {
        level = AbilityTier.bronze;
      }
      result.add(SpecialAbility(type, level));
    }
    return result;
  }

  static double _clamp(double v, double min, double max) =>
      v < min ? min : (v > max ? max : v);
}
