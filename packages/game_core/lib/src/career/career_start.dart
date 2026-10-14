import '../generation/player_generator.dart';
import '../match/limits.dart';
import '../model/career.dart';
import '../model/club.dart';
import '../model/ids.dart';
import '../model/league.dart';
import '../rng/seeded_random.dart';
import '../rules/career_rules.dart';
import '../rules/rules.dart';
import '../world/world.dart';
import '../world/world_report.dart';

/// Creates the manager of a new career (document 16, steps 1 and 2).
class TrainerFactory {
  const TrainerFactory._();

  /// A trainer with the start levels of the backstory plus a small random
  /// spread. The same [seed] gives the same trainer.
  static Trainer create({
    required Rules rules,
    required String name,
    required TrainerAppearance appearance,
    required String backstoryId,
    required int seed,
  }) {
    final career = rules.career;
    final backstory = career.backstory(backstoryId);
    checkAppearance(career, appearance);
    final rng = SeededRandom(seed).fork('trainer');
    final values = <ManagerValue, double>{};
    for (final v in ManagerValue.values) {
      final base = career.levelValues[backstory.levels[v]!]!;
      final noise = rng.fork(v.id).nextGaussian() * career.valueSpreadSd;
      final x = (base + noise).limit(1.0, 100.0);
      values[v] = (x * 10).round() / 10;
    }
    return Trainer(
      name: name.trim(),
      appearance: appearance,
      backstoryId: backstoryId,
      values: values,
    );
  }

  /// Throws [ArgumentError] when an index is outside the options of the rules.
  static void checkAppearance(CareerRules career, TrainerAppearance a) {
    final options = career.appearanceOptions;
    final chosen = a.toJson();
    for (final e in chosen.entries) {
      final count = options[e.key]!;
      if (e.value < 0 || e.value >= count) {
        throw ArgumentError('${e.key} ${e.value} outside 0 to ${count - 1}');
      }
    }
  }
}

/// Strength of every club: mean overall of its 14 best players.
class ClubStrengths {
  const ClubStrengths._();

  static Map<ClubId, double> compute(World world, Rules rules) {
    final byClub = <ClubId, List<double>>{};
    for (final p in world.players) {
      final club = p.clubId;
      if (club == null) continue;
      byClub.putIfAbsent(club, () => []).add(WorldReport.overall(p, rules));
    }
    final result = <ClubId, double>{};
    for (final e in byClub.entries) {
      final sorted = e.value..sort((a, b) => b.compareTo(a));
      final top = sorted.take(14).toList();
      result[e.key] = top.reduce((a, b) => a + b) / top.length;
    }
    return Map.unmodifiable(result);
  }
}

/// One job offer of a club.
class JobOffer {
  const JobOffer({
    required this.club,
    required this.league,
    required this.strength,
    required this.strengthRank,
    required this.situation,
    required this.lastSeasonRank,
    required this.goal,
    required this.budget,
    required this.quirk,
    required this.president,
  });

  final Club club;
  final League league;

  /// Mean overall of the 14 best players.
  final double strength;

  /// Rank by strength within the league (1 is the strongest).
  final int strengthRank;
  final Situation situation;

  /// Invented final table place of the last season.
  final int lastSeasonRank;
  final SeasonGoal goal;

  /// Transfer budget in euros (draft; the economy comes in phase 3).
  final int budget;
  final ClubQuirk quirk;
  final President president;

  int get tier => league.level;
}

/// What happened to the wish club (document 16: it becomes one of the offers
/// when the reputation is high enough, otherwise the game shows what is
/// missing).
class WishOutcome {
  const WishOutcome({required this.club, required this.requiredLevel});

  final Club club;

  /// Null when the club is among the offers; otherwise the lowest standing
  /// level at which the league of the club makes offers.
  final TraitLevel? requiredLevel;

  bool get offered => requiredLevel == null;
}

class OfferSet {
  OfferSet({required List<JobOffer> offers, required this.level, this.wish})
    : offers = List.unmodifiable(offers);

  final List<JobOffer> offers;

  /// Standing level of the trainer that decided the leagues.
  final TraitLevel level;
  final WishOutcome? wish;
}

/// Draws the random job offers of a new career (document 16, step 4).
class OfferGenerator {
  OfferGenerator({
    required this.rules,
    required this.world,
    required this.names,
    required Map<ClubId, double> strengths,
  }) : strengths = Map.unmodifiable(strengths) {
    final season = <ClubId, (LeagueSeason, int)>{};
    for (final ls in world.leagueSeasons) {
      final sorted = [...ls.clubIds]
        ..sort((a, b) {
          final d = (strengths[b] ?? 0).compareTo(strengths[a] ?? 0);
          return d != 0 ? d : a.value.compareTo(b.value);
        });
      for (var i = 0; i < sorted.length; i++) {
        season[sorted[i]] = (ls, i + 1);
      }
    }
    _placement = season;
    _byTier = {
      for (var tier = 1; tier <= 4; tier++)
        tier: [
          for (final c in world.clubs)
            if (season[c.id]?.$1.league.level == tier) c,
        ],
    };
  }

  final Rules rules;
  final World world;
  final NameLists names;
  final Map<ClubId, double> strengths;
  late final Map<ClubId, (LeagueSeason, int)> _placement;
  late final Map<int, List<Club>> _byTier;

  OfferRules get _o => rules.career.offers;

  /// Offers for [trainer]; the same [seed] gives the same offers.
  OfferSet generate({
    required Trainer trainer,
    required int seed,
    ClubId? wishClubId,
  }) {
    final career = rules.career;
    final level = career.standingLevel(trainer[ManagerValue.standing]);
    final rng = SeededRandom(seed).fork('offers');
    final tierWeights = _o.tierWeightsByLevel[level]!;
    final range = _o.countRangeByLevel[level]!;
    final count = rng.fork('count').nextIntInRange(range.$1, range.$2);

    final chosen = <Club>[];
    WishOutcome? wish;
    if (wishClubId != null) {
      final club = world.clubs.firstWhere((c) => c.id == wishClubId);
      final placement = _placement[club.id];
      if (placement == null) {
        throw ArgumentError('The wish club does not play in a league');
      }
      final tier = placement.$1.league.level;
      if ((tierWeights[tier] ?? 0) > 0) {
        chosen.add(club);
        wish = WishOutcome(club: club, requiredLevel: null);
      } else {
        wish = WishOutcome(club: club, requiredLevel: _requiredLevel(tier));
      }
    }

    final pick = rng.fork('clubs');
    var guard = 0;
    while (chosen.length < count && guard++ < 1000) {
      final tiers = tierWeights.keys.toList()..sort();
      final tier = tiers[pick.weightedIndex([
        for (final t in tiers) tierWeights[t]!,
      ])];
      final club = pick.pick(_byTier[tier]!);
      if (chosen.any((c) => c.id == club.id)) continue;
      chosen.add(club);
    }

    // Keep the wish club first, the rest in the strongest league first.
    final offers = [for (final c in chosen) _offerFor(c, seed)];
    final wishId = wish?.club.id;
    offers.sort((a, b) {
      if (a.club.id == wishId) return -1;
      if (b.club.id == wishId) return 1;
      final byTier = a.tier.compareTo(b.tier);
      return byTier != 0 ? byTier : a.club.id.value.compareTo(b.club.id.value);
    });
    return OfferSet(offers: offers, level: level, wish: wish);
  }

  /// Lowest standing level whose offers include [tier].
  TraitLevel _requiredLevel(int tier) {
    for (final l in TraitLevel.values) {
      if ((_o.tierWeightsByLevel[l]![tier] ?? 0) > 0) return l;
    }
    return TraitLevel.veryHigh;
  }

  JobOffer _offerFor(Club club, int seed) {
    final (ls, rank) = _placement[club.id]!;
    final league = ls.league;
    final size = league.teamCount;
    final rng = SeededRandom(seed).fork('club:${club.id.value}');

    final quarter = ((rank - 1) * 4 ~/ size).limit(0, 3);
    final situations = Situation.values;
    final situation = situations[rng.fork('situation').weightedIndex([
      for (final s in situations) _o.situationWeights[s]![quarter],
    ])];

    final lastRank = _lastSeasonRank(rng.fork('rank'), situation, size);
    final goal = switch (situation) {
      Situation.favourite =>
        league.level == 1 ? SeasonGoal.title : SeasonGoal.promotion,
      Situation.midTable => SeasonGoal.noTarget,
      Situation.relegation => SeasonGoal.survival,
      Situation.bankrupt => SeasonGoal.licence,
    };

    final spread = _o.budgetSpread;
    final budgetRng = rng.fork('budget');
    final factor = 1 - spread + budgetRng.nextDouble() * 2 * spread;
    final budget =
        (_o.budgetBaseByTier[league.level]! *
                _o.budgetFactorBySituation[situation]! *
                factor /
                1000)
            .round() *
        1000;

    final quirk = situation == Situation.bankrupt
        ? ClubQuirk.debtMountain
        : _quirk(rng.fork('quirk'));

    return JobOffer(
      club: club,
      league: league,
      strength: strengths[club.id] ?? 0,
      strengthRank: rank,
      situation: situation,
      lastSeasonRank: lastRank,
      goal: goal,
      budget: budget,
      quirk: quirk,
      president: _president(rng.fork('president'), league.level),
    );
  }

  int _lastSeasonRank(SeededRandom rng, Situation situation, int size) {
    final (low, high) = switch (situation) {
      Situation.favourite => (2, 4),
      Situation.midTable => ((size * 0.35).round(), (size * 0.65).round()),
      Situation.relegation => (size - 5, size - 2),
      Situation.bankrupt => ((size * 0.5).round(), size),
    };
    return rng.nextIntInRange(low.limit(1, size), high.limit(1, size));
  }

  ClubQuirk _quirk(SeededRandom rng) {
    final quirks = ClubQuirk.values;
    return quirks[rng.weightedIndex([
      for (final q in quirks) _o.quirkWeights[q] ?? 0,
    ])];
  }

  President _president(SeededRandom rng, int tier) {
    final weights = _o.presidentTypeWeightsByTier[tier]!;
    final ids = weights.keys.toList()..sort();
    final typeId = ids[rng.fork('type').weightedIndex([
      for (final id in ids) weights[id]!,
    ])];
    final type = rules.career.presidentTypes[typeId]!;
    final traitRng = rng.fork('traits');
    final traits = <PresidentTrait, double>{};
    for (final t in PresidentTrait.values) {
      final base = rules.career.levelValues[type.levels[t]!]!;
      final noise =
          traitRng.fork(t.id).nextGaussian() * rules.career.valueSpreadSd;
      traits[t] = ((base + noise).limit(1.0, 100.0) * 10).round() / 10;
    }
    final nameRng = rng.fork('name');
    final (first, last) = names.pickName(nameRng, names.homeCode);
    return President(typeId: typeId, name: '$first $last', traits: traits);
  }
}
