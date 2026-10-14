import '../model/attribute.dart';
import '../model/development.dart';
import '../model/position.dart';
import '../model/special_ability.dart';
import 'rules.dart';

/// Numbers for one tier (1 to 4 are the leagues, 5 is the pool).
class TierRules {
  const TierRules({
    required this.levelMean,
    required this.levelSd,
    required this.abilityCountWeights,
    required this.goldChance,
    required this.silverChance,
  });

  /// Mean prime level of attributes at this tier.
  final double levelMean;
  final double levelSd;

  /// Weight of having 0, 1, 2, 3 or 4 special abilities.
  final List<double> abilityCountWeights;
  final double goldChance;
  final double silverChance;
}

/// All numbers of the player generator, read from the `generator` section
/// of the rules file.
class GeneratorRules {
  const GeneratorRules({
    required this.squadTemplate,
    required this.tiers,
    required this.ageWeights,
    required this.developmentTypeWeights,
    required this.developmentShiftYears,
    required this.mentalShiftFactor,
    required this.growthPerYear,
    required this.declinePerYear,
    required this.attributeNoiseSd,
    required this.potentialMarginMean,
    required this.potentialMarginSd,
    required this.clubLevelSd,
    required this.clubLevelPersistence,
    required this.dynamicFrozenFromAge,
    required this.dynamicPerYear,
    required this.dynamicMax,
    required this.traitMean,
    required this.traitSd,
    required this.injuryMean,
    required this.injurySd,
    required this.goalkeeperFieldMin,
    required this.goalkeeperFieldMax,
    required this.goalkeeperOutfieldOffset,
    required this.positionProfiles,
    required this.abilityPositions,
  });

  factory GeneratorRules.fromJson(Map<String, dynamic> m) {
    Position position(String id) {
      final found = Position.values.where((p) => p.id == id);
      if (found.isEmpty) throw RulesError('Unknown position $id');
      return found.first;
    }

    Attribute attribute(String id) {
      final found = Attribute.values.where((a) => a.id == id);
      if (found.isEmpty) throw RulesError('Unknown attribute $id');
      return found.first;
    }

    DevelopmentType devType(String id) {
      final found = DevelopmentType.values.where((d) => d.id == id);
      if (found.isEmpty) throw RulesError('Unknown development type $id');
      return found.first;
    }

    double num_(Map<String, dynamic> map, String key) =>
        (map[key] as num).toDouble();

    final template = {
      for (final e in (m['squad_template'] as Map<String, dynamic>).entries)
        position(e.key): e.value as int,
    };
    if (template.length != Position.values.length) {
      throw const RulesError('squad_template needs all positions');
    }

    final tiers = <int, TierRules>{};
    for (final e in (m['tiers'] as Map<String, dynamic>).entries) {
      final t = e.value as Map<String, dynamic>;
      final weights = [
        for (final w in t['ability_count_weights'] as List<dynamic>)
          (w as num).toDouble(),
      ];
      if (weights.length != 5 || weights.every((w) => w <= 0)) {
        throw RulesError('Bad ability_count_weights in tier ${e.key}');
      }
      tiers[int.parse(e.key)] = TierRules(
        levelMean: num_(t, 'level_mean'),
        levelSd: num_(t, 'level_sd'),
        abilityCountWeights: weights,
        goldChance: num_(t, 'gold_chance'),
        silverChance: num_(t, 'silver_chance'),
      );
    }
    for (var tier = 1; tier <= 5; tier++) {
      if (!tiers.containsKey(tier)) throw RulesError('Missing tier $tier');
    }

    final ageWeights = {
      for (final e in (m['age_weights'] as Map<String, dynamic>).entries)
        int.parse(e.key): (e.value as num).toDouble(),
    };
    if (ageWeights.isEmpty || ageWeights.values.every((w) => w <= 0)) {
      throw const RulesError('age_weights must not be empty');
    }

    final devWeights = {
      for (final e
          in (m['development_type_weights'] as Map<String, dynamic>).entries)
        devType(e.key): (e.value as num).toDouble(),
    };
    final devShift = {
      for (final e
          in (m['development_shift_years'] as Map<String, dynamic>).entries)
        devType(e.key): (e.value as num).toDouble(),
    };
    if (devWeights.length != DevelopmentType.values.length ||
        devShift.length != DevelopmentType.values.length) {
      throw const RulesError('Development types incomplete');
    }

    final profiles = <Position, Map<Attribute, double>>{};
    for (final e in (m['position_profiles'] as Map<String, dynamic>).entries) {
      profiles[position(e.key)] = {
        for (final o in (e.value as Map<String, dynamic>).entries)
          attribute(o.key): (o.value as num).toDouble(),
      };
    }
    if (profiles.length != Position.values.length) {
      throw const RulesError('position_profiles needs all positions');
    }

    final abilityPositions = <SpecialAbilityType, Set<Position>>{};
    for (final e in (m['ability_positions'] as Map<String, dynamic>).entries) {
      final found = SpecialAbilityType.values.where((t) => t.id == e.key);
      if (found.isEmpty) throw RulesError('Unknown ability ${e.key}');
      abilityPositions[found.first] = {
        for (final p in e.value as List<dynamic>) position(p as String),
      };
    }
    if (abilityPositions.length != SpecialAbilityType.values.length) {
      throw const RulesError('ability_positions needs all abilities');
    }

    final age = m['age_adjust'] as Map<String, dynamic>;
    final margin = m['potential_margin'] as Map<String, dynamic>;
    final dynamic_ = m['dynamic_potential'] as Map<String, dynamic>;
    final traits = m['traits'] as Map<String, dynamic>;
    final injury = m['injury_proneness'] as Map<String, dynamic>;
    final gk = (m['goalkeeper_field_attribute_range'] as List<dynamic>)
        .map((v) => (v as num).toDouble())
        .toList();
    if (gk.length != 2 || gk[0] < 1 || gk[1] > 100 || gk[0] > gk[1]) {
      throw const RulesError('Bad goalkeeper_field_attribute_range');
    }

    return GeneratorRules(
      squadTemplate: Map.unmodifiable(template),
      tiers: Map.unmodifiable(tiers),
      ageWeights: Map.unmodifiable(ageWeights),
      developmentTypeWeights: Map.unmodifiable(devWeights),
      developmentShiftYears: Map.unmodifiable(devShift),
      mentalShiftFactor: num_(m, 'mental_shift_factor'),
      growthPerYear: num_(age, 'growth_per_year'),
      declinePerYear: num_(age, 'decline_per_year'),
      attributeNoiseSd: num_(m, 'attribute_noise_sd'),
      potentialMarginMean: num_(margin, 'mean'),
      potentialMarginSd: num_(margin, 'sd'),
      clubLevelSd: num_(m, 'club_level_sd'),
      clubLevelPersistence: num_(m, 'club_level_persistence'),
      dynamicFrozenFromAge: dynamic_['frozen_from_age'] as int,
      dynamicPerYear: num_(dynamic_, 'per_year'),
      dynamicMax: num_(dynamic_, 'max'),
      traitMean: num_(traits, 'mean'),
      traitSd: num_(traits, 'sd'),
      injuryMean: num_(injury, 'mean'),
      injurySd: num_(injury, 'sd'),
      goalkeeperFieldMin: gk[0],
      goalkeeperFieldMax: gk[1],
      goalkeeperOutfieldOffset: num_(m, 'goalkeeper_outfield_offset'),
      positionProfiles: Map.unmodifiable(profiles),
      abilityPositions: Map.unmodifiable(abilityPositions),
    );
  }

  final Map<Position, int> squadTemplate;
  final Map<int, TierRules> tiers;
  final Map<int, double> ageWeights;
  final Map<DevelopmentType, double> developmentTypeWeights;
  final Map<DevelopmentType, double> developmentShiftYears;
  final double mentalShiftFactor;
  final double growthPerYear;
  final double declinePerYear;
  final double attributeNoiseSd;
  final double potentialMarginMean;
  final double potentialMarginSd;

  /// Spread of the level of whole clubs around the mean of their tier.
  final double clubLevelSd;

  /// How much of a club's level carries over to the next year (0 to 1).
  final double clubLevelPersistence;
  final int dynamicFrozenFromAge;
  final double dynamicPerYear;
  final double dynamicMax;
  final double traitMean;
  final double traitSd;
  final double injuryMean;
  final double injurySd;
  final double goalkeeperFieldMin;
  final double goalkeeperFieldMax;
  final double goalkeeperOutfieldOffset;
  final Map<Position, Map<Attribute, double>> positionProfiles;
  final Map<SpecialAbilityType, Set<Position>> abilityPositions;

  /// Players per club according to the squad template.
  int get squadSize => squadTemplate.values.fold(0, (a, b) => a + b);
}

/// Numbers for building the start world (contracts and coaches).
class WorldRules {
  const WorldRules({
    required this.seed,
    required this.salaryBaseByTier,
    required this.salaryLevelMin,
    required this.salaryLevelMax,
    required this.remainingYearsWeightsYoung,
    required this.remainingYearsWeightsOlder,
    required this.olderFromAge,
    required this.coachSkillMeanByTier,
    required this.coachSkillSd,
    required this.coachAgeMin,
    required this.coachAgeMax,
  });

  factory WorldRules.fromJson(Map<String, dynamic> m) {
    Map<int, double> byTier(Object? raw) {
      final map = {
        for (final e in (raw as Map<String, dynamic>).entries)
          int.parse(e.key): (e.value as num).toDouble(),
      };
      for (var tier = 1; tier <= 5; tier++) {
        if (!map.containsKey(tier)) throw RulesError('Missing tier $tier');
      }
      return Map.unmodifiable(map);
    }

    List<double> weights(Object? raw) {
      final list = [
        for (final w in raw as List<dynamic>) (w as num).toDouble(),
      ];
      if (list.length != 4 || list.every((w) => w <= 0)) {
        throw const RulesError('Remaining years weights need 4 entries');
      }
      return List.unmodifiable(list);
    }

    final level = m['salary_level_factor'] as Map<String, dynamic>;
    final coach = m['coach'] as Map<String, dynamic>;
    final ageMin = coach['age_min'] as int;
    final ageMax = coach['age_max'] as int;
    if (ageMin > ageMax) throw const RulesError('Bad coach age range');
    return WorldRules(
      seed: m['seed'] as int,
      salaryBaseByTier: byTier(m['salary_base_by_tier']),
      salaryLevelMin: (level['min'] as num).toDouble(),
      salaryLevelMax: (level['max'] as num).toDouble(),
      remainingYearsWeightsYoung: weights(m['remaining_years_weights_young']),
      remainingYearsWeightsOlder: weights(m['remaining_years_weights_older']),
      olderFromAge: m['older_from_age'] as int,
      coachSkillMeanByTier: byTier(coach['skill_mean_by_tier']),
      coachSkillSd: (coach['skill_sd'] as num).toDouble(),
      coachAgeMin: ageMin,
      coachAgeMax: ageMax,
    );
  }

  /// Seed of the shipped start world.
  final int seed;
  final Map<int, double> salaryBaseByTier;
  final double salaryLevelMin;
  final double salaryLevelMax;
  final List<double> remainingYearsWeightsYoung;
  final List<double> remainingYearsWeightsOlder;
  final int olderFromAge;
  final Map<int, double> coachSkillMeanByTier;
  final double coachSkillSd;
  final int coachAgeMin;
  final int coachAgeMax;
}
