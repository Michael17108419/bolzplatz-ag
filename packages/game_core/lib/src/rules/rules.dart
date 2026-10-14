import 'dart:convert';

import '../model/attribute.dart';
import '../model/region.dart';
import '../model/special_ability.dart';
import '../result/result.dart';
import 'career_rules.dart';
import 'development_rules.dart';
import 'generator_rules.dart';
import 'match_rules.dart';
import 'season_rules.dart';
import 'tactics_rules.dart';

/// Reason why a rules file could not be used.
class RulesError {
  const RulesError(this.message);

  final String message;

  @override
  String toString() => 'RulesError: $message';
}

/// Age curve of one attribute: rises until [risesUntil], stays on a plateau
/// from [plateauFrom] to [plateauTo], declines from [declinesFrom].
class AgeCurve {
  const AgeCurve({
    required this.risesUntil,
    required this.plateauFrom,
    required this.plateauTo,
    required this.declinesFrom,
  });

  final int risesUntil;
  final int plateauFrom;
  final int plateauTo;
  final int declinesFrom;

  bool get isConsistent =>
      risesUntil < plateauFrom &&
      plateauFrom <= plateauTo &&
      plateauTo < declinesFrom;
}

/// League definition from the rules file.
class LeagueRule {
  const LeagueRule({
    required this.id,
    required this.key,
    required this.level,
    required this.teamCount,
    required this.region,
  });

  final int id;
  final String key;
  final int level;
  final int teamCount;
  final Region? region;
}

/// All balancing numbers of one season. Loaded from `rules_<season>.json`.
class Rules {
  const Rules._({
    required this.schemaVersion,
    required this.seasonStartYear,
    required this.leagues,
    required this.maxAbilitiesPerPlayer,
    required this.maxGoldAbilitiesPerPlayer,
    required this.tierMultiplier,
    required this.ageCurves,
    required this.fourthLeagueRelegatedToPool,
    required this.poolMinimumSize,
    required this.poolNeighbours,
    required this.generator,
    required this.world,
    required this.tactics,
    required this.match,
    required this.season,
    required this.development,
    required this.career,
  });

  /// The only schema version this code understands.
  static const int supportedSchemaVersion = 1;

  final int schemaVersion;
  final int seasonStartYear;
  final List<LeagueRule> leagues;
  final int maxAbilitiesPerPlayer;
  final int maxGoldAbilitiesPerPlayer;
  final Map<AbilityTier, double> tierMultiplier;
  final Map<Attribute, AgeCurve> ageCurves;

  /// Minimum number of last-placed clubs per fourth-tier league that move
  /// into the pool (more if needed to keep the league at its size).
  final int fourthLeagueRelegatedToPool;

  /// A pool that falls below this size is topped up from the largest
  /// neighbouring pool (Block 2, safety rule).
  final int poolMinimumSize;

  /// Geographic neighbours of every region, used by the safety rule.
  final Map<Region, List<Region>> poolNeighbours;

  /// Numbers for the player generator.
  final GeneratorRules generator;

  /// Numbers for building the start world.
  final WorldRules world;

  /// Numbers for tactics, roles and fit.
  final TacticsRules tactics;

  /// Numbers for the match simulation.
  final MatchRules match;

  /// Numbers for the course of a season and the cups.
  final SeasonRules season;

  /// Numbers for yearly development and squad turnover.
  final DevelopmentRules development;
  final CareerRules career;

  /// Parses and validates a rules file given as JSON text.
  static Result<Rules, RulesError> parse(String jsonText) {
    try {
      return Ok(_parse(jsonText));
    } on RulesError catch (e) {
      return Err(e);
    } on FormatException catch (e) {
      return Err(RulesError('Invalid JSON: ${e.message}'));
    } on TypeError catch (e) {
      return Err(RulesError('Wrong value type: $e'));
    }
  }

  static Rules _parse(String jsonText) {
    final root = jsonDecode(jsonText) as Map<String, dynamic>;

    final version = root['schema_version'];
    if (version != supportedSchemaVersion) {
      throw RulesError(
        'Unsupported schema_version $version, '
        'expected $supportedSchemaVersion',
      );
    }

    final leagues = [
      for (final raw in root['leagues'] as List<dynamic>)
        _league(raw as Map<String, dynamic>),
    ];
    final ids = leagues.map((l) => l.id).toSet();
    if (leagues.isEmpty || ids.length != leagues.length) {
      throw const RulesError('Leagues missing or duplicate league id');
    }

    final abilities = root['abilities'] as Map<String, dynamic>;
    final multipliers = abilities['tier_multiplier'] as Map<String, dynamic>;
    final tierMultiplier = {
      for (final tier in AbilityTier.values)
        tier: (multipliers[tier.name] as num).toDouble(),
    };
    final bronze = tierMultiplier[AbilityTier.bronze]!;
    final silver = tierMultiplier[AbilityTier.silver]!;
    final gold = tierMultiplier[AbilityTier.gold]!;
    if (!(bronze < silver && silver < gold)) {
      throw const RulesError(
        'Tier multipliers must rise bronze < silver < gold',
      );
    }

    final range = root['attribute_range'] as Map<String, dynamic>;
    final min = (range['min'] as num).toDouble();
    final max = (range['max'] as num).toDouble();
    if (min != Attribute.min || max != Attribute.max) {
      throw const RulesError('attribute_range does not match the model');
    }

    final curvesRaw = root['age_curves'] as Map<String, dynamic>;
    final knownIds = Attribute.values.map((a) => a.id).toSet();
    for (final key in curvesRaw.keys) {
      if (!knownIds.contains(key)) {
        throw RulesError('Unknown attribute in age_curves: $key');
      }
    }
    final curves = <Attribute, AgeCurve>{};
    for (final attribute in Attribute.values) {
      final raw = curvesRaw[attribute.id];
      if (raw == null) {
        throw RulesError('Missing age curve for ${attribute.id}');
      }
      final m = raw as Map<String, dynamic>;
      final curve = AgeCurve(
        risesUntil: m['rises_until'] as int,
        plateauFrom: m['plateau_from'] as int,
        plateauTo: m['plateau_to'] as int,
        declinesFrom: m['declines_from'] as int,
      );
      if (!curve.isConsistent) {
        throw RulesError('Inconsistent age curve for ${attribute.id}');
      }
      curves[attribute] = curve;
    }

    final pyramid = root['pyramid'] as Map<String, dynamic>;
    final toPool = pyramid['fourth_league_relegated_to_pool'] as int;
    if (toPool < 0) {
      throw const RulesError('fourth_league_relegated_to_pool must be >= 0');
    }
    final poolMinimum = pyramid['pool_minimum_size'] as int;
    if (poolMinimum < 1) {
      throw const RulesError('pool_minimum_size must be >= 1');
    }
    final neighbourJson = pyramid['pool_neighbours'] as Map<String, dynamic>;
    final neighbours = <Region, List<Region>>{};
    for (final region in Region.values) {
      final names = neighbourJson[region.id] as List<dynamic>?;
      if (names == null || names.isEmpty) {
        throw RulesError('pool_neighbours misses region ${region.id}');
      }
      neighbours[region] = List.unmodifiable([
        for (final n in names)
          Region.values.firstWhere(
            (r) => r.id == n,
            orElse: () => throw RulesError('Unknown region $n in neighbours'),
          ),
      ]);
    }

    return Rules._(
      schemaVersion: version as int,
      seasonStartYear: root['season_start_year'] as int,
      leagues: List.unmodifiable(leagues),
      maxAbilitiesPerPlayer: abilities['max_per_player'] as int,
      maxGoldAbilitiesPerPlayer: abilities['max_gold_per_player'] as int,
      tierMultiplier: Map.unmodifiable(tierMultiplier),
      ageCurves: Map.unmodifiable(curves),
      fourthLeagueRelegatedToPool: toPool,
      poolMinimumSize: poolMinimum,
      poolNeighbours: Map.unmodifiable(neighbours),
      generator: GeneratorRules.fromJson(
        root['generator'] as Map<String, dynamic>,
      ),
      world: WorldRules.fromJson(root['world'] as Map<String, dynamic>),
      tactics: TacticsRules.fromJson(root['tactics'] as Map<String, dynamic>),
      match: MatchRules.fromJson(root['match'] as Map<String, dynamic>),
      season: SeasonRules.fromJson(root['season'] as Map<String, dynamic>),
      development: DevelopmentRules.fromJson(
        root['development'] as Map<String, dynamic>,
      ),
      career: CareerRules.fromJson(root['career'] as Map<String, dynamic>),
    );
  }

  static LeagueRule _league(Map<String, dynamic> m) {
    final regionId = m['region'] as String?;
    Region? region;
    if (regionId != null) {
      final matches = Region.values.where((r) => r.id == regionId);
      if (matches.isEmpty) throw RulesError('Unknown region $regionId');
      region = matches.first;
    }
    final level = m['level'] as int;
    final teams = m['team_count'] as int;
    if (level < 1 || level > 4 || teams < 2 || teams.isOdd) {
      throw RulesError('Invalid league ${m['key']}');
    }
    return LeagueRule(
      id: m['id'] as int,
      key: m['key'] as String,
      level: level,
      teamCount: teams,
      region: region,
    );
  }
}
