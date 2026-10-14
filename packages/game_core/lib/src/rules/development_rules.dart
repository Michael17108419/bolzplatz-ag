import '../model/attribute.dart';
import '../model/character.dart';
import 'rules.dart';

/// One coupling: when [driver] changes by itself, [follower] moves along by
/// [factor] times that change.
class CouplingRule {
  const CouplingRule({
    required this.driver,
    required this.follower,
    required this.factor,
  });

  final Attribute driver;
  final Attribute follower;
  final double factor;
}

/// How one character trait changes with age: it rises by
/// [DevelopmentRules.traitRisePerYear] each year of age below [riseUntil] and
/// falls by [DevelopmentRules.traitFallPerYear] each year from [fallFrom] on.
/// Null means no rise or no fall.
class TraitAging {
  const TraitAging({this.riseUntil, this.fallFrom});

  final int? riseUntil;
  final int? fallFrom;
}

/// Numbers for the yearly development of players and the squad turnover.
class DevelopmentRules {
  const DevelopmentRules({
    required this.retireFromAge,
    required this.retireChancePerYearAbove,
    required this.youthAgeMin,
    required this.youthAgeMax,
    required this.poolMinutesShare,
    required this.annualNoiseSd,
    required this.minutesEffect,
    required this.potentialHeadroom,
    required this.couplingCapPerSeason,
    required this.dynamicChangePerYear,
    required this.dynamicMax,
    required this.dynamicTraitEffect,
    required this.traitReferenceAge,
    required this.traitRisePerYear,
    required this.traitFallPerYear,
    required this.traitAging,
    required this.contractExtensionYears,
    required this.couplings,
  });

  factory DevelopmentRules.fromJson(Map<String, dynamic> m) {
    Attribute attribute(Object? id) => Attribute.values.firstWhere(
      (a) => a.id == id,
      orElse: () => throw RulesError('Unknown attribute $id in couplings'),
    );
    final couplings = [
      for (final raw in m['couplings'] as List<dynamic>)
        CouplingRule(
          driver: attribute((raw as Map<String, dynamic>)['driver']),
          follower: attribute(raw['follower']),
          factor: (raw['factor'] as num).toDouble(),
        ),
    ];
    // No circle: following the "follower" links must never come back.
    final next = <Attribute, List<Attribute>>{};
    for (final c in couplings) {
      (next[c.driver] ??= []).add(c.follower);
    }
    bool reaches(Attribute from, Attribute target, Set<Attribute> seen) {
      for (final n in next[from] ?? const <Attribute>[]) {
        if (n == target) return true;
        if (seen.add(n) && reaches(n, target, seen)) return true;
      }
      return false;
    }

    for (final c in couplings) {
      if (c.driver == c.follower || reaches(c.follower, c.driver, {})) {
        throw RulesError('Circular coupling at ${c.driver.id}');
      }
    }
    final years = [
      for (final y in m['contract_extension_years'] as List<dynamic>) y as int,
    ];
    if (years.isEmpty || years.any((y) => y < 1)) {
      throw const RulesError('contract_extension_years must be positive');
    }
    CharacterTrait trait(String id) => CharacterTrait.values.firstWhere(
      (t) => t.id == id,
      orElse: () => throw RulesError('Unknown character trait $id'),
    );
    final effect = {
      for (final e
          in (m['dynamic_trait_effect'] as Map<String, dynamic>).entries)
        trait(e.key): (e.value as num).toDouble(),
    };
    final agingRaw = m['trait_aging'] as Map<String, dynamic>;
    final aging = {
      for (final e in (agingRaw['traits'] as Map<String, dynamic>).entries)
        trait(e.key): TraitAging(
          riseUntil: (e.value as Map<String, dynamic>)['rise_until'] as int?,
          fallFrom: e.value['fall_from'] as int?,
        ),
    };
    final rise = (agingRaw['rise_per_year'] as num).toDouble();
    final fall = (agingRaw['fall_per_year'] as num).toDouble();
    if (rise < 0 || fall < 0) {
      throw const RulesError('trait_aging rates must not be negative');
    }
    final dynamicMax = (m['dynamic_max'] as num).toDouble();
    if (dynamicMax <= 0 || dynamicMax > 100) {
      throw const RulesError('dynamic_max must be in 0 to 100');
    }
    return DevelopmentRules(
      retireFromAge: m['retire_from_age'] as int,
      retireChancePerYearAbove: (m['retire_chance_per_year_above'] as num)
          .toDouble(),
      youthAgeMin: m['youth_age_min'] as int,
      youthAgeMax: m['youth_age_max'] as int,
      poolMinutesShare: (m['pool_minutes_share'] as num).toDouble(),
      annualNoiseSd: (m['annual_noise_sd'] as num).toDouble(),
      minutesEffect: (m['minutes_effect'] as num).toDouble(),
      potentialHeadroom: (m['potential_headroom'] as num).toDouble(),
      couplingCapPerSeason: (m['coupling_cap_per_season'] as num).toDouble(),
      dynamicChangePerYear: (m['dynamic_change_per_year'] as num).toDouble(),
      dynamicMax: dynamicMax,
      dynamicTraitEffect: Map.unmodifiable(effect),
      traitReferenceAge: m['trait_reference_age'] as int,
      traitRisePerYear: rise,
      traitFallPerYear: fall,
      traitAging: Map.unmodifiable(aging),
      contractExtensionYears: List.unmodifiable(years),
      couplings: List.unmodifiable(couplings),
    );
  }

  final int retireFromAge;

  /// Retirement chance per year of age above [retireFromAge] minus one.
  final double retireChancePerYearAbove;
  final int youthAgeMin;
  final int youthAgeMax;

  /// Assumed share of playing time for players of pool clubs.
  final double poolMinutesShare;
  final double annualNoiseSd;

  /// Share of growth gained or lost for a full or empty season of playing
  /// time (0.5 means 0.5 to 1.5 times the normal growth for young players).
  final double minutesEffect;

  /// Growth is reduced to zero when the player is this close to his potential.
  final double potentialHeadroom;
  final double couplingCapPerSeason;
  final double dynamicChangePerYear;

  /// The dynamic part of the potential lies between minus and plus this value.
  final double dynamicMax;

  /// Yearly change of the dynamic potential per trait: trait value (1 to 100)
  /// relative to 50, scaled to -1..1, times this number.
  final Map<CharacterTrait, double> dynamicTraitEffect;

  /// Generated trait values are the values at this age.
  final int traitReferenceAge;
  final double traitRisePerYear;
  final double traitFallPerYear;

  /// Traits not listed here do not change with age.
  final Map<CharacterTrait, TraitAging> traitAging;
  final List<int> contractExtensionYears;
  final List<CouplingRule> couplings;

  /// Change of [trait] in the year in which the player turns [newAge]:
  /// positive while he is at most [TraitAging.riseUntil], negative from
  /// [TraitAging.fallFrom] on, otherwise zero.
  double traitDelta(CharacterTrait trait, int newAge) {
    final aging = traitAging[trait];
    if (aging == null) return 0;
    final riseUntil = aging.riseUntil;
    if (riseUntil != null && newAge <= riseUntil) return traitRisePerYear;
    final fallFrom = aging.fallFrom;
    if (fallFrom != null && newAge >= fallFrom) return -traitFallPerYear;
    return 0;
  }

  /// Total change of [trait] between the ages [fromAge] and [toAge]
  /// (negative when [toAge] is younger).
  double traitShift(CharacterTrait trait, int fromAge, int toAge) {
    var sum = 0.0;
    if (toAge >= fromAge) {
      for (var age = fromAge + 1; age <= toAge; age++) {
        sum += traitDelta(trait, age);
      }
    } else {
      for (var age = toAge + 1; age <= fromAge; age++) {
        sum -= traitDelta(trait, age);
      }
    }
    return sum;
  }
}
