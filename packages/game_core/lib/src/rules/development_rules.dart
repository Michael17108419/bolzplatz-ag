import '../model/attribute.dart';
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
      dynamicMax: (m['dynamic_max'] as num).toDouble(),
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
  final double dynamicMax;
  final List<int> contractExtensionYears;
  final List<CouplingRule> couplings;
}
