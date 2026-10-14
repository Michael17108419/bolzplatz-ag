import 'dart:convert';

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

/// First and last names of one country.
class NationalityNames {
  NationalityNames({
    required this.code,
    required this.weight,
    required List<String> first,
    required List<String> last,
  }) : first = List.unmodifiable(first),
       last = List.unmodifiable(last) {
    if (code.length != 2) throw ArgumentError('Bad country code $code');
    if (weight <= 0) throw ArgumentError('Weight of $code must be positive');
    if (first.isEmpty || last.isEmpty) {
      throw ArgumentError('Name lists of $code must not be empty');
    }
  }

  /// Two-letter country code, also the nationality of generated players.
  final String code;

  /// Relative frequency of this nationality among players.
  final double weight;
  final List<String> first;
  final List<String> last;
}

/// First and last names to draw from, read from `data/names_de.json`.
///
/// [first] and [last] belong to the home nationality [homeCode]; [others]
/// hold the names of the other countries.
class NameLists {
  NameLists({
    required List<String> first,
    required List<String> last,
    Set<String> blocked = const {},
    this.homeCode = 'DE',
    this.homeWeight = 1,
    List<NationalityNames> others = const [],
  }) : first = List.unmodifiable(first),
       last = List.unmodifiable(last),
       blocked = Set.unmodifiable(blocked),
       others = List.unmodifiable(others) {
    if (first.isEmpty || last.isEmpty) {
      throw ArgumentError('Name lists must not be empty');
    }
    if (homeWeight <= 0) throw ArgumentError('Home weight must be positive');
    final codes = {homeCode, for (final o in others) o.code};
    if (codes.length != others.length + 1) {
      throw ArgumentError('Duplicate nationality');
    }
  }

  /// Reads the name file. Throws [FormatException] for wrong content.
  factory NameLists.fromJson(String text) {
    final m = jsonDecode(text) as Map<String, dynamic>;
    List<String> list(Map<String, dynamic> map, String key) => [
      for (final v in map[key] as List<dynamic>) v as String,
    ];
    final home = (m['home_nationality'] as Map<String, dynamic>?) ?? const {};
    return NameLists(
      first: list(m, 'first_names'),
      last: list(m, 'last_names'),
      blocked: list(m, 'blocked_full_names').toSet(),
      homeCode: (home['code'] as String?) ?? 'DE',
      homeWeight: ((home['weight'] as num?) ?? 1).toDouble(),
      others: [
        for (final raw in (m['nationalities'] as List<dynamic>?) ?? const [])
          NationalityNames(
            code: (raw as Map<String, dynamic>)['code'] as String,
            weight: (raw['weight'] as num).toDouble(),
            first: list(raw, 'first_names'),
            last: list(raw, 'last_names'),
          ),
      ],
    );
  }

  final List<String> first;
  final List<String> last;

  /// Full names that must never be produced (real people).
  final Set<String> blocked;

  /// Country code of [first] and [last].
  final String homeCode;
  final double homeWeight;
  final List<NationalityNames> others;

  /// Draws a nationality by weight.
  String pickNationality(SeededRandom rng) {
    final weights = [homeWeight, for (final o in others) o.weight];
    final index = rng.weightedIndex(weights);
    return index == 0 ? homeCode : others[index - 1].code;
  }

  /// Draws (first name, last name) for [nationality]; unknown codes use the
  /// home lists.
  (String, String) pickName(SeededRandom rng, String nationality) {
    var firstList = first;
    var lastList = last;
    for (final o in others) {
      if (o.code == nationality) {
        firstList = o.first;
        lastList = o.last;
      }
    }
    return (rng.pick(firstList), rng.pick(lastList));
  }
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
    int? age,
    double levelOffset = 0,
  }) {
    final tierRules = _g.tiers[tier];
    if (tierRules == null) throw ArgumentError.value(tier, 'tier');
    final rng = world.fork('player:${id.value}');

    final playerAge = age ?? _age(rng);
    final birthDate = _birthDate(rng, playerAge);
    final devType = _developmentType(rng);

    // Prime level of this player, before age effects and position profile.
    final level = _clamp(
      tierRules.levelMean +
          levelOffset +
          rng.nextGaussian() * tierRules.levelSd,
      1,
      99,
    );

    final attributes = _attributes(rng, position, level, playerAge, devType);
    final potentialCore = _round1(
      _clamp(
        level +
            _g.potentialMarginMean +
            rng.nextGaussian() * _g.potentialMarginSd,
        level,
        100,
      ),
    );
    final potentialDynamic = _dynamicPotential(rng, playerAge);

    final identity = rng.fork('identity');
    final nationality = names.pickNationality(identity);
    final (firstName, lastName) = names.pickName(identity, nationality);
    final profile = rng.fork('profile');
    final foot = _foot(profile, position);
    final secondary = _secondaryPositions(profile, position);

    return Player(
      id: id,
      firstName: firstName,
      lastName: lastName,
      nationality: nationality,
      foot: foot,
      weakFoot: profile.weightedIndex(_g.weakFootWeights) + 1,
      secondaryPositions: secondary,
      birthDate: birthDate,
      position: position,
      attributes: attributes,
      traits: {
        for (final t in CharacterTrait.values)
          t: _round1(
            _clamp(_g.traitMean + rng.nextGaussian() * _g.traitSd, 1, 100),
          ),
      },
      injuryProneness: _round1(
        _clamp(_g.injuryMean + rng.nextGaussian() * _g.injurySd, 1, 100),
      ),
      abilities: _abilities(rng, position, tierRules),
      developmentType: devType,
      roles: _roles(position, attributes),
      potentialCore: potentialCore,
      potentialDynamic: _round1(potentialDynamic),
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
    double levelOffset = 0,
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
            levelOffset: levelOffset,
          ),
        );
      }
    }
    return players;
  }

  Foot _foot(SeededRandom rng, Position position) {
    final side = position.wideSide;
    if (side == null) {
      return rng.nextDouble() < _g.leftFootShare ? Foot.left : Foot.right;
    }
    final natural = rng.nextDouble() < _g.wideNaturalFootShare;
    if (natural) return side;
    return side == Foot.left ? Foot.right : Foot.left;
  }

  /// Zero to three secondary positions, close ones more often than far ones.
  /// Goalkeepers have none.
  Map<Position, PositionFamiliarity> _secondaryPositions(
    SeededRandom rng,
    Position position,
  ) {
    if (position.isGoalkeeper) return const {};
    final distance = rules.tactics.positionDistance[position]!;
    final candidates = [
      for (final p in Position.values)
        if (p != position &&
            !p.isGoalkeeper &&
            distance[p]! <= _g.secondaryMaxDistance)
          p,
    ];
    var count = rng.weightedIndex(_g.secondaryCountWeights);
    if (count > candidates.length) count = candidates.length;
    final result = <Position, PositionFamiliarity>{};
    while (result.length < count) {
      final weights = [
        for (final c in candidates)
          result.containsKey(c) ? 0.0 : 1 / (1 + distance[c]!),
      ];
      final chosen = candidates[rng.weightedIndex(weights)];
      result[chosen] = rng.nextDouble() < _g.trainedShare
          ? PositionFamiliarity.trained
          : PositionFamiliarity.practised;
    }
    return result;
  }

  int _age(SeededRandom rng) {
    final ages = _g.ageWeights.keys.toList()..sort();
    final index = rng.weightedIndex([for (final a in ages) _g.ageWeights[a]!]);
    return ages[index];
  }

  GameDate _birthDate(SeededRandom rng, int age) {
    // The birthday on the reference date, [age] years back, then up to 364
    // days earlier: the player is exactly [age] years old on that date.
    final day = referenceDate.month == 2 && referenceDate.day == 29
        ? 28
        : referenceDate.day;
    final anniversary = GameDate(
      referenceDate.year - age,
      referenceDate.month,
      day,
    );
    return GameDate.fromEpochDay(anniversary.epochDay - rng.nextInt(365));
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
    // Centres the key attributes of the position on [level], so the same
    // level means the same position overall for every position.
    final norm = -_keyOffsetMean(position);
    final values = <Attribute, double>{};
    for (final attribute in Attribute.values) {
      if (attribute.isGoalkeeping && !isKeeper) {
        values[attribute] = _round1(
          _g.goalkeeperFieldMin +
              rng.nextDouble() *
                  (_g.goalkeeperFieldMax - _g.goalkeeperFieldMin),
        );
        continue;
      }
      var value = level + (profile[attribute] ?? 0);
      if (isKeeper && !attribute.isGoalkeeping) {
        value += _g.goalkeeperOutfieldOffset;
      } else {
        value += norm;
      }
      final mental = attribute.group == AttributeGroup.intelligence;
      final effectiveShift = mental ? shift * _g.mentalShiftFactor : shift;
      value += _ageAdjust(rules.ageCurves[attribute]!, age - effectiveShift);
      value += rng.nextGaussian() * _g.attributeNoiseSd;
      values[attribute] = _round1(_clamp(value, Attribute.min, Attribute.max));
    }
    return AttributeSet.fromMap(values);
  }

  /// Mean profile offset of the key attributes of [position]: all goalkeeper
  /// attributes for keepers, otherwise the attributes with a positive offset.
  double _keyOffsetMean(Position position) {
    final profile = _g.positionProfiles[position]!;
    final keys = position.isGoalkeeper
        ? Attribute.values.where((a) => a.isGoalkeeping)
        : profile.entries.where((e) => e.value > 0).map((e) => e.key);
    var sum = 0.0;
    var n = 0;
    for (final k in keys) {
      sum += profile[k] ?? 0;
      n++;
    }
    return n == 0 ? 0 : sum / n;
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

  /// Best role of the position is "expert", other roles of the position with
  /// a nearly as good score are "comfortable"; the rest stay "basic".
  Map<String, RoleFamiliarity> _roles(Position position, AttributeSet attrs) {
    final scored = <(String, double)>[];
    for (final role in rules.tactics.roles) {
      if (!role.positions.contains(position)) continue;
      var sum = 0.0;
      for (final a in role.keyAttributes) {
        sum += attrs[a];
      }
      scored.add((role.id, sum / role.keyAttributes.length));
    }
    if (scored.isEmpty) return const {};
    scored.sort((a, b) {
      final d = b.$2.compareTo(a.$2);
      return d != 0 ? d : a.$1.compareTo(b.$1);
    });
    final best = scored.first.$2;
    final result = <String, RoleFamiliarity>{
      scored.first.$1: RoleFamiliarity.expert,
    };
    for (final r in scored.skip(1).take(2)) {
      if (best - r.$2 <= 3) result[r.$1] = RoleFamiliarity.comfortable;
    }
    return result;
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

  /// Rounds to one decimal so stored values are short and stable.
  static double _round1(double v) => (v * 10).round() / 10;

  static double _clamp(double v, double min, double max) =>
      v < min ? min : (v > max ? max : v);
}
