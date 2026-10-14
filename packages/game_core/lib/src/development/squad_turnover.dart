import '../calendar/game_date.dart';
import '../calendar/season.dart';
import '../generation/player_generator.dart';
import '../model/contract.dart';
import '../model/ids.dart';
import '../model/player.dart';
import '../rng/seeded_random.dart';
import '../rules/rules.dart';
import '../world/world_generator.dart';
import 'development.dart';

/// What changes in the squads between two seasons: players age and develop,
/// old players retire and are replaced by youth players of the same
/// position, expired contracts are extended.
class SquadTurnover {
  SquadTurnover(this.rules, this.names)
    : _development = Development(rules);

  final Rules rules;
  final NameLists names;
  final Development _development;

  /// Returns the squads for the season starting in [newStartYear].
  /// [tiers] gives the tier (1 to 4, 5 for pool clubs) of each club in the
  /// new season, [minutesShare] the share of possible minutes per player.
  Map<ClubId, List<Player>> apply(
    Map<ClubId, List<Player>> squads, {
    required int newStartYear,
    required Map<ClubId, int> tiers,
    required Map<PlayerId, double> minutesShare,
    required SeededRandom rng,
  }) {
    final season = Season(newStartYear);
    final dev = rules.development;
    final generator = PlayerGenerator(
      rules: rules,
      names: names,
      referenceDate: season.start,
    );
    final clubIds = squads.keys.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final used = <String>{
      for (final s in squads.values)
        for (final p in s) p.displayName,
    };
    var nextId = 0;
    for (final s in squads.values) {
      for (final p in s) {
        if (p.id.value > nextId) nextId = p.id.value;
      }
    }
    nextId++;

    final result = <ClubId, List<Player>>{};
    for (final club in clubIds) {
      final tier = tiers[club] ?? 5;
      final next = <Player>[];
      for (final p in squads[club]!) {
        final prng = rng.fork('dev:${p.id.value}');
        final age = p.ageOn(season.start);
        final retires =
            age >= dev.retireFromAge &&
            rng.fork('retire:${p.id.value}').nextBool(
              dev.retireChancePerYearAbove,
            );
        if (retires) {
          final youth = generator.generate(
            world: rng.fork('youth:$nextId'),
            id: PlayerId(nextId),
            position: p.position,
            tier: tier,
            clubId: club,
            age: rng.fork('youth-age:$nextId').nextIntInRange(
              dev.youthAgeMin,
              dev.youthAgeMax,
            ),
          );
          nextId++;
          final named = WorldGenerator.uniqueName(youth, names, used, rng);
          next.add(
            named.copyWith(
              contract: _fresh(named, tier, rng, season, club),
            ),
          );
          continue;
        }
        var q = _development.advance(
          p,
          newSeasonStart: season.start,
          rng: prng,
          minutesShare: minutesShare[p.id] ?? 0.5,
        );
        final c = q.contract;
        if (c == null || c.end.isBefore(season.start)) {
          q = q.copyWith(contract: _fresh(q, tier, rng, season, club));
        }
        next.add(q);
      }
      result[club] = next;
    }
    return result;
  }

  Contract _fresh(
    Player player,
    int tier,
    SeededRandom rng,
    Season season,
    ClubId club,
  ) {
    final base = WorldGenerator.contractFor(
      rules,
      player,
      tier,
      rng,
      season,
    );
    final years = rng
        .fork('ext:${player.id.value}')
        .pick(rules.development.contractExtensionYears);
    return Contract(
      id: base.id,
      playerId: player.id,
      clubId: club,
      start: season.start,
      end: GameDate(season.startYear + years, 6, 30),
      baseSalaryPerYear: base.baseSalaryPerYear,
      appearanceBonus: base.appearanceBonus,
      goalBonus: base.goalBonus,
      titleBonus: base.titleBonus,
    );
  }
}
