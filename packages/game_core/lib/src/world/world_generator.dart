import 'dart:math' as math;

import '../calendar/game_date.dart';
import '../calendar/season.dart';
import '../generation/player_generator.dart';
import '../model/attribute.dart';
import '../model/coach.dart';
import '../model/contract.dart';
import '../model/ids.dart';
import '../model/league.dart';
import '../model/player.dart';
import '../model/position.dart';
import '../result/result.dart';
import '../rng/seeded_random.dart';
import '../rules/rules.dart';
import 'club_catalog.dart';
import 'world.dart';

class WorldError {
  const WorldError(this.message);

  final String message;

  @override
  String toString() => 'WorldError: $message';
}

/// Builds the start world once from the rules, the club list and the name
/// lists. The result is stored as a data file and shipped with the game.
class WorldGenerator {
  const WorldGenerator._();

  static Result<World, WorldError> generate({
    required Rules rules,
    required ClubCatalog catalog,
    required NameLists names,
    int? seed,
  }) {
    final worldSeed = seed ?? rules.world.seed;
    final season = Season(rules.seasonStartYear);
    final clubsResult = catalog.clubs(rules);
    final clubs = clubsResult.valueOrNull;
    if (clubs == null) {
      return Err(WorldError(clubsResult.errorOrNull!.message));
    }

    final rng = SeededRandom(worldSeed);
    final playerGen = PlayerGenerator(
      rules: rules,
      names: names,
      referenceDate: season.start,
    );
    final squadSize = rules.generator.squadSize;

    final leagues = [
      for (final l in rules.leagues)
        League(
          id: LeagueId(l.id),
          name: l.key,
          level: l.level,
          teamCount: l.teamCount,
          region: l.region,
        ),
    ];

    final leagueSeasons = <LeagueSeason>[];
    for (final league in leagues) {
      final members = [
        for (final c in clubs)
          if (c.leagueId == league.id) c.id,
      ];
      if (members.length != league.teamCount) {
        return Err(WorldError('League ${league.name} has ${members.length}'));
      }
      leagueSeasons.add(
        LeagueSeason(league: league, season: season, clubIds: members),
      );
    }

    final players = <Player>[];
    final coaches = <Coach>[];
    final usedNames = <String>{};
    for (final entry in catalog.entries) {
      final club = clubs[entry.id.value - 1];
      final squad = playerGen.generateSquad(
        world: rng,
        firstId: (entry.id.value - 1) * squadSize + 1,
        tier: entry.tier,
        clubId: club.id,
        levelOffset: clubLevelOffset(rules, worldSeed, club.id),
      );
      for (final raw in squad) {
        final named = uniqueName(raw, names, usedNames, rng);
        players.add(
          named.copyWith(
            contract: contractFor(rules, named, entry.tier, rng, season),
          ),
        );
      }
      coaches.add(_coach(rules, entry, rng, names, season));
    }

    return Ok(
      World(
        seed: worldSeed,
        season: season,
        leagues: List.unmodifiable(leagues),
        clubs: List.unmodifiable(clubs),
        leagueSeasons: List.unmodifiable(leagueSeasons),
        pools: catalog.pools,
        players: List.unmodifiable(players),
        coaches: List.unmodifiable(coaches),
      ),
    );
  }

  /// How much stronger or weaker than its tier a club is [year] years after
  /// the start. The level follows a yearly random walk that falls back to the
  /// tier mean, so clubs rise and fall over the decades. It is fixed by the
  /// world seed, the club id and the year alone.
  static double clubLevelOffset(
    Rules rules,
    int worldSeed,
    ClubId club, {
    int year = 0,
  }) {
    final g = rules.generator;
    final root = SeededRandom(worldSeed).fork('club-level:${club.value}');
    var level = root.nextGaussian() * g.clubLevelSd;
    final rho = g.clubLevelPersistence;
    final step = g.clubLevelSd * math.sqrt(1 - rho * rho);
    for (var y = 1; y <= year; y++) {
      level = level * rho + root.fork('year:$y').nextGaussian() * step;
    }
    return level;
  }

  /// Draws new names until the full name is neither blocked nor taken.
  static Player uniqueName(
    Player player,
    NameLists names,
    Set<String> used,
    SeededRandom world,
  ) {
    var current = player;
    var attempt = 0;
    while (true) {
      final full = current.displayName;
      if (!names.blocked.contains(full) && used.add(full)) return current;
      attempt++;
      final rng = world.fork('name:${player.id.value}:$attempt');
      current = current.copyWith(
        firstName: rng.pick(names.first),
        lastName: rng.pick(names.last),
      );
      if (attempt > 1000) {
        throw StateError('No free name for player ${player.id.value}');
      }
    }
  }

  static Contract contractFor(
    Rules rules,
    Player player,
    int tier,
    SeededRandom world,
    Season season,
  ) {
    final w = rules.world;
    final rng = world.fork('contract:${player.id.value}');
    final age = player.ageOn(season.start);
    final weights = age >= w.olderFromAge
        ? w.remainingYearsWeightsOlder
        : w.remainingYearsWeightsYoung;
    final remaining = 1 + rng.weightedIndex(weights);
    final elapsed = rng.nextInt(3);
    final endYear = season.startYear + remaining;
    final startYear = endYear - remaining - elapsed;

    var sum = 0.0;
    var n = 0;
    for (final a in Attribute.values.where((a) => !a.isGoalkeeping)) {
      sum += player.attributes[a];
      n++;
    }
    final strength = (sum / n) / 100;
    final factor =
        w.salaryLevelMin + (w.salaryLevelMax - w.salaryLevelMin) * strength;
    final salary = _roundTo((w.salaryBaseByTier[tier]! * factor), 1000);
    final scorer =
        player.position == Position.st ||
        player.position == Position.la ||
        player.position == Position.ra ||
        player.position == Position.zom;

    return Contract(
      id: ContractId(player.id.value),
      playerId: player.id,
      clubId: player.clubId!,
      start: GameDate(startYear, 7, 1),
      end: GameDate(endYear, 6, 30),
      baseSalaryPerYear: salary,
      appearanceBonus: _roundTo(salary * 0.01, 100),
      goalBonus: scorer ? _roundTo(salary * 0.01, 100) : 0,
      titleBonus: _roundTo(salary * 0.1, 1000),
    );
  }

  static Coach _coach(
    Rules rules,
    ClubEntry entry,
    SeededRandom world,
    NameLists names,
    Season season,
  ) {
    final w = rules.world;
    final rng = world.fork('coach:${entry.id.value}');
    final age = rng.nextIntInRange(w.coachAgeMin, w.coachAgeMax);
    final birth = GameDate.fromEpochDay(
      GameDate(season.startYear - age, 7, 1).epochDay - rng.nextInt(365),
    );
    final mean = w.coachSkillMeanByTier[entry.tier]!;
    double skill() {
      final v = mean + rng.nextGaussian() * w.coachSkillSd;
      final clamped = v < 1 ? 1.0 : (v > 100 ? 100.0 : v);
      return (clamped * 10).round() / 10;
    }

    return Coach(
      id: CoachId(entry.id.value),
      firstName: rng.pick(names.first),
      lastName: rng.pick(names.last),
      birthDate: birth,
      skills: {
        'tactical_knowledge': skill(),
        'charisma': skill(),
        'negotiation': skill(),
        'talent_eye': skill(),
      },
      clubId: entry.id,
    );
  }

  static int _roundTo(double value, int step) => (value / step).round() * step;
}
