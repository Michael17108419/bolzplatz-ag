import '../model/career.dart';
import 'rules.dart';

/// One of the twelve backstories: start levels of the nine manager values
/// and the id of the hook (the text lives in the language files).
class Backstory {
  const Backstory({required this.id, required this.hook, required this.levels});

  final String id;
  final String hook;
  final Map<ManagerValue, TraitLevel> levels;
}

/// A president type with the levels of its seven traits.
class PresidentType {
  const PresidentType({required this.id, required this.levels});

  final String id;
  final Map<PresidentTrait, TraitLevel> levels;
}

/// Numbers for the generated job offers.
class OfferRules {
  const OfferRules({
    required this.countRangeByLevel,
    required this.tierWeightsByLevel,
    required this.situationWeights,
    required this.budgetBaseByTier,
    required this.budgetFactorBySituation,
    required this.budgetSpread,
    required this.quirkWeights,
    required this.presidentTypeWeightsByTier,
  });

  /// Smallest and largest number of offers per standing level.
  final Map<TraitLevel, (int, int)> countRangeByLevel;

  /// Chance weights of the league tiers (1 to 4) per standing level.
  /// Tiers missing here are not offered at that level.
  final Map<TraitLevel, Map<int, double>> tierWeightsByLevel;

  /// Weights of each situation per quarter of the league by club strength
  /// (strongest quarter first).
  final Map<Situation, List<double>> situationWeights;
  final Map<int, double> budgetBaseByTier;
  final Map<Situation, double> budgetFactorBySituation;

  /// Budget is drawn between 1 - spread and 1 + spread times its base.
  final double budgetSpread;
  final Map<ClubQuirk, double> quirkWeights;
  final Map<int, Map<String, double>> presidentTypeWeightsByTier;
}

/// Everything of the `career` section of the rules file (document 16).
class CareerRules {
  const CareerRules({
    required this.levelValues,
    required this.valueSpreadSd,
    required this.standingThresholds,
    required this.appearanceOptions,
    required this.backstories,
    required this.offers,
    required this.presidentTypes,
  });

  factory CareerRules.fromJson(Map<String, dynamic> m) {
    TraitLevel level(Object? raw) {
      try {
        return TraitLevel.fromSymbol(raw! as String);
      } on ArgumentError {
        throw RulesError('Unknown level $raw in career');
      }
    }

    double num_(Object? v) => (v! as num).toDouble();

    final levelRaw = m['level_values'] as Map<String, dynamic>;
    final levelValues = {
      for (final l in TraitLevel.values) l: num_(levelRaw[l.symbol]),
    };
    final ordered = [for (final l in TraitLevel.values) levelValues[l]!];
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i] < 1 || ordered[i] > 100) {
        throw const RulesError('career.level_values outside 1 to 100');
      }
      if (i > 0 && ordered[i] <= ordered[i - 1]) {
        throw const RulesError('career.level_values must rise');
      }
    }

    final thresholdRaw = m['standing_thresholds'] as Map<String, dynamic>;
    final thresholds = {
      TraitLevel.middle: num_(thresholdRaw['0']),
      TraitLevel.high: num_(thresholdRaw['+']),
      TraitLevel.veryHigh: num_(thresholdRaw['++']),
    };
    if (!(thresholds[TraitLevel.middle]! < thresholds[TraitLevel.high]! &&
        thresholds[TraitLevel.high]! < thresholds[TraitLevel.veryHigh]!)) {
      throw const RulesError('career.standing_thresholds must rise');
    }

    final appearanceRaw = m['appearance_options'] as Map<String, dynamic>;
    final appearance = {
      for (final key in const [
        'gender',
        'skin',
        'hair_style',
        'hair_colour',
        'beard',
        'glasses',
        'outfit',
        'outfit_colour',
      ])
        key: appearanceRaw[key] as int,
    };
    if (appearance.values.any((n) => n < 1)) {
      throw const RulesError('career.appearance_options need at least 1');
    }

    ManagerValue managerValue(String id) => ManagerValue.values.firstWhere(
      (v) => v.id == id,
      orElse: () => throw RulesError('Unknown manager value $id'),
    );
    final backstories = <Backstory>[
      for (final raw in m['backstories'] as List<dynamic>)
        Backstory(
          id: (raw as Map<String, dynamic>)['id'] as String,
          hook: raw['hook'] as String,
          levels: {
            for (final e in (raw['levels'] as Map<String, dynamic>).entries)
              managerValue(e.key): level(e.value),
          },
        ),
    ];
    if (backstories.length != backstories.map((b) => b.id).toSet().length) {
      throw const RulesError('Duplicate backstory id');
    }
    for (final b in backstories) {
      if (b.levels.length != ManagerValue.values.length) {
        throw RulesError('Backstory ${b.id} needs all nine values');
      }
    }

    PresidentTrait presidentTrait(String id) =>
        PresidentTrait.values.firstWhere(
          (t) => t.id == id,
          orElse: () => throw RulesError('Unknown president trait $id'),
        );
    final presidentTypes = <String, PresidentType>{};
    for (final e in (m['president_types'] as Map<String, dynamic>).entries) {
      final levels = {
        for (final t in (e.value as Map<String, dynamic>).entries)
          presidentTrait(t.key): level(t.value),
      };
      if (levels.length != PresidentTrait.values.length) {
        throw RulesError('President type ${e.key} needs all seven traits');
      }
      presidentTypes[e.key] = PresidentType(id: e.key, levels: levels);
    }
    if (presidentTypes.isEmpty) {
      throw const RulesError('career.president_types is empty');
    }

    final offers = m['offers'] as Map<String, dynamic>;
    final counts = <TraitLevel, (int, int)>{};
    for (final e
        in (offers['count_range_by_level'] as Map<String, dynamic>).entries) {
      final range = e.value as List<dynamic>;
      final low = range[0] as int;
      final high = range[1] as int;
      if (low < 1 || high < low) {
        throw RulesError('Bad offer count range at level ${e.key}');
      }
      counts[level(e.key)] = (low, high);
    }
    final tierWeights = <TraitLevel, Map<int, double>>{};
    for (final e
        in (offers['tier_weights_by_level'] as Map<String, dynamic>).entries) {
      final weights = {
        for (final w in (e.value as Map<String, dynamic>).entries)
          int.parse(w.key): num_(w.value),
      };
      if (weights.isEmpty ||
          weights.keys.any((t) => t < 1 || t > 4) ||
          weights.values.any((w) => w < 0) ||
          weights.values.every((w) => w == 0)) {
        throw RulesError('Bad tier weights at level ${e.key}');
      }
      tierWeights[level(e.key)] = Map.unmodifiable(weights);
    }
    for (final l in TraitLevel.values) {
      if (!counts.containsKey(l) || !tierWeights.containsKey(l)) {
        throw RulesError('Offers need level ${l.symbol}');
      }
    }

    Situation situation(String id) => Situation.values.firstWhere(
      (s) => s.id == id,
      orElse: () => throw RulesError('Unknown situation $id'),
    );
    final situationWeights = <Situation, List<double>>{};
    for (final e
        in (offers['situation_weights_by_strength_quarter']
                as Map<String, dynamic>)
            .entries) {
      final list = [for (final w in e.value as List<dynamic>) num_(w)];
      if (list.length != 4 || list.any((w) => w < 0)) {
        throw RulesError('Situation ${e.key} needs four weights');
      }
      situationWeights[situation(e.key)] = List.unmodifiable(list);
    }
    if (situationWeights.length != Situation.values.length) {
      throw const RulesError('Every situation needs weights');
    }
    for (var q = 0; q < 4; q++) {
      if (situationWeights.values.every((w) => w[q] == 0)) {
        throw RulesError('No situation possible in quarter ${q + 1}');
      }
    }

    Map<int, double> byTier(Object? raw) {
      final map = {
        for (final e in (raw! as Map<String, dynamic>).entries)
          int.parse(e.key): num_(e.value),
      };
      for (var tier = 1; tier <= 4; tier++) {
        if (!map.containsKey(tier)) throw RulesError('Missing tier $tier');
      }
      return Map.unmodifiable(map);
    }

    final budgetFactors = {
      for (final e
          in (offers['budget_factor_by_situation'] as Map<String, dynamic>)
              .entries)
        situation(e.key): num_(e.value),
    };
    if (budgetFactors.length != Situation.values.length) {
      throw const RulesError('Every situation needs a budget factor');
    }
    final spread = num_(offers['budget_spread']);
    if (spread < 0 || spread >= 1) {
      throw const RulesError('career budget_spread must be in 0 to 1');
    }

    ClubQuirk quirk(String id) => ClubQuirk.values.firstWhere(
      (q) => q.id == id,
      orElse: () => throw RulesError('Unknown quirk $id'),
    );
    final quirkWeights = {
      for (final e in (offers['quirk_weights'] as Map<String, dynamic>).entries)
        quirk(e.key): num_(e.value),
    };
    if (quirkWeights.isEmpty || quirkWeights.values.every((w) => w <= 0)) {
      throw const RulesError('career quirk_weights are empty');
    }

    final presidentWeights = <int, Map<String, double>>{};
    for (final e
        in (offers['president_type_weights_by_tier'] as Map<String, dynamic>)
            .entries) {
      final weights = {
        for (final w in (e.value as Map<String, dynamic>).entries)
          w.key: num_(w.value),
      };
      for (final id in weights.keys) {
        if (!presidentTypes.containsKey(id)) {
          throw RulesError('Unknown president type $id in offers');
        }
      }
      if (weights.isEmpty || weights.values.every((w) => w <= 0)) {
        throw RulesError('Empty president weights for tier ${e.key}');
      }
      presidentWeights[int.parse(e.key)] = Map.unmodifiable(weights);
    }
    for (var tier = 1; tier <= 4; tier++) {
      if (!presidentWeights.containsKey(tier)) {
        throw RulesError('Missing president weights for tier $tier');
      }
    }

    return CareerRules(
      levelValues: Map.unmodifiable(levelValues),
      valueSpreadSd: num_(m['value_spread_sd']),
      standingThresholds: Map.unmodifiable(thresholds),
      appearanceOptions: Map.unmodifiable(appearance),
      backstories: List.unmodifiable(backstories),
      presidentTypes: Map.unmodifiable(presidentTypes),
      offers: OfferRules(
        countRangeByLevel: Map.unmodifiable(counts),
        tierWeightsByLevel: Map.unmodifiable(tierWeights),
        situationWeights: Map.unmodifiable(situationWeights),
        budgetBaseByTier: byTier(offers['budget_base_by_tier']),
        budgetFactorBySituation: Map.unmodifiable(budgetFactors),
        budgetSpread: spread,
        quirkWeights: Map.unmodifiable(quirkWeights),
        presidentTypeWeightsByTier: Map.unmodifiable(presidentWeights),
      ),
    );
  }

  /// Number (1 to 100) of each level before the random spread.
  final Map<TraitLevel, double> levelValues;
  final double valueSpreadSd;

  /// Lowest standing for the levels `0`, `+` and `++`; below the first
  /// threshold the level is `-`.
  final Map<TraitLevel, double> standingThresholds;

  /// Number of options per looks setting (`skin`, `hair_style`,
  /// `hair_colour`, `beard`, `glasses`, `outfit`, `outfit_colour`).
  final Map<String, int> appearanceOptions;
  final List<Backstory> backstories;
  final OfferRules offers;
  final Map<String, PresidentType> presidentTypes;

  Backstory backstory(String id) => backstories.firstWhere(
    (b) => b.id == id,
    orElse: () => throw ArgumentError('Unknown backstory $id'),
  );

  /// Level of a standing value (document 16: the reputation decides which
  /// leagues make offers).
  TraitLevel standingLevel(double standing) {
    if (standing >= standingThresholds[TraitLevel.veryHigh]!) {
      return TraitLevel.veryHigh;
    }
    if (standing >= standingThresholds[TraitLevel.high]!) {
      return TraitLevel.high;
    }
    if (standing >= standingThresholds[TraitLevel.middle]!) {
      return TraitLevel.middle;
    }
    return TraitLevel.low;
  }
}
