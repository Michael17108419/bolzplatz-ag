import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

late Rules rules;
late World world;
late NameLists names;
late Map<ClubId, double> strengths;
late OfferGenerator generator;

Trainer _trainer(String backstory, {int seed = 1}) => TrainerFactory.create(
  rules: rules,
  name: 'Uschi Muster',
  appearance: const TrainerAppearance(),
  backstoryId: backstory,
  seed: seed,
);

Trainer _withStanding(double standing) {
  final base = _trainer('failed_pro');
  return Trainer(
    name: base.name,
    appearance: base.appearance,
    backstoryId: base.backstoryId,
    values: {...base.values, ManagerValue.standing: standing},
  );
}

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    names = NameLists.fromJson(
      File('../../data/names_de.json').readAsStringSync(),
    );
    strengths = ClubStrengths.compute(world, rules);
    generator = OfferGenerator(
      rules: rules,
      world: world,
      names: names,
      strengths: strengths,
    );
  });

  group('rules', () {
    test('twelve backstories with all manager values, eight president types', () {
      final career = rules.career;
      expect(career.backstories, hasLength(12));
      for (final b in career.backstories) {
        expect(b.levels, hasLength(ManagerValue.values.length), reason: b.id);
        expect(b.hook, startsWith('hook_'));
      }
      expect(career.presidentTypes, hasLength(8));
    });

    test('start levels of document 16 for some backstories', () {
      final b = rules.career;
      expect(
        b.backstory('pub_landlord').levels[ManagerValue.standing],
        TraitLevel.low,
      );
      expect(
        b.backstory('pub_landlord').levels[ManagerValue.contacts],
        TraitLevel.high,
      );
      expect(
        b.backstory('club_fixture').levels[ManagerValue.presidentTrust],
        TraitLevel.veryHigh,
      );
      expect(
        b.backstory('tactics_streamer').levels[ManagerValue.tacticalKnowledge],
        TraitLevel.veryHigh,
      );
      expect(
        b.backstory('motivation_guru').levels[ManagerValue.charisma],
        TraitLevel.veryHigh,
      );
      expect(
        b.backstory('business_student').levels[ManagerValue.negotiation],
        TraitLevel.veryHigh,
      );
      expect(
        b.backstory('youth_coach').levels[ManagerValue.talentEye],
        TraitLevel.veryHigh,
      );
    });

    test('the standing decides the level', () {
      final c = rules.career;
      expect(c.standingLevel(10), TraitLevel.low);
      expect(c.standingLevel(50), TraitLevel.middle);
      expect(c.standingLevel(70), TraitLevel.high);
      expect(c.standingLevel(95), TraitLevel.veryHigh);
    });

    test('levels that do not rise are rejected', () {
      final text = File('../../rules/rules_2026_27.json').readAsStringSync();
      final broken = text.replaceFirst(
        '"level_values": { "-": 25, "0": 50, "+": 72, "++": 90 }',
        '"level_values": { "-": 90, "0": 50, "+": 72, "++": 25 }',
      );
      expect(broken, isNot(text));
      expect(Rules.parse(broken).errorOrNull, isNotNull);
    });
  });

  group('trainer', () {
    test('values follow the levels of the backstory', () {
      final t = _trainer('pub_landlord');
      expect(t[ManagerValue.standing], lessThan(40));
      expect(t[ManagerValue.charisma], greaterThan(50));
      expect(t[ManagerValue.tacticalKnowledge], lessThan(45));
      final g = _trainer('motivation_guru');
      expect(g[ManagerValue.charisma], greaterThan(75));
    });

    test('the same seed gives the same trainer, another seed differs', () {
      final a = _trainer('failed_pro', seed: 5);
      final b = _trainer('failed_pro', seed: 5);
      final c = _trainer('failed_pro', seed: 6);
      expect(a.toJson(), b.toJson());
      expect(a.toJson(), isNot(c.toJson()));
    });

    test('json round trip', () {
      final a = _trainer('ex_referee', seed: 9);
      final b = Trainer.fromJson(a.toJson());
      expect(b.toJson(), a.toJson());
      expect(b.appearance, a.appearance);
    });

    test('bad input is rejected', () {
      expect(() => _trainer('nonsense'), throwsArgumentError);
      expect(
        () => TrainerFactory.create(
          rules: rules,
          name: 'X',
          appearance: const TrainerAppearance(beard: 9),
          backstoryId: 'failed_pro',
          seed: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => TrainerFactory.create(
          rules: rules,
          name: '   ',
          appearance: const TrainerAppearance(),
          backstoryId: 'failed_pro',
          seed: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('offers', () {
    test('a low reputation only gets fourth-league offers', () {
      for (var seed = 0; seed < 20; seed++) {
        final set = generator.generate(
          trainer: _trainer('pub_landlord'),
          seed: seed,
        );
        expect(set.level, TraitLevel.low);
        expect(set.offers, hasLength(3));
        expect(set.offers.every((o) => o.tier == 4), isTrue);
      }
    });

    test('a middle reputation also gets third and second league offers', () {
      final tiers = <int>{};
      for (var seed = 0; seed < 60; seed++) {
        final set = generator.generate(
          trainer: _trainer('failed_pro'),
          seed: seed,
        );
        expect(set.level, TraitLevel.middle);
        expect(set.offers.length, inInclusiveRange(3, 4));
        tiers.addAll(set.offers.map((o) => o.tier));
      }
      expect(tiers, {2, 3, 4});
    });

    test('a high reputation reaches the first league', () {
      final tiers = <int>{};
      for (var seed = 0; seed < 60; seed++) {
        final set = generator.generate(trainer: _withStanding(70), seed: seed);
        expect(set.offers.length, inInclusiveRange(4, 5));
        tiers.addAll(set.offers.map((o) => o.tier));
      }
      expect(tiers, {1, 2, 3, 4});
      final top = generator.generate(trainer: _withStanding(90), seed: 3);
      expect(top.offers.every((o) => o.tier <= 3), isTrue);
    });

    test('same seed same offers, other seeds other offers', () {
      final t = _trainer('failed_pro');
      List<int> ids(OfferSet s) => [for (final o in s.offers) o.club.id.value];
      expect(
        ids(generator.generate(trainer: t, seed: 4)),
        ids(generator.generate(trainer: t, seed: 4)),
      );
      final sets = {
        for (var seed = 0; seed < 30; seed++)
          ids(generator.generate(trainer: t, seed: seed)).join(','),
      };
      expect(sets.length, greaterThan(20));
    });

    test('offers are different clubs of real leagues', () {
      for (var seed = 0; seed < 30; seed++) {
        final set = generator.generate(trainer: _withStanding(70), seed: seed);
        final ids = set.offers.map((o) => o.club.id).toSet();
        expect(ids, hasLength(set.offers.length));
        for (final o in set.offers) {
          expect(o.club.leagueId, isNotNull);
          expect(o.strengthRank, inInclusiveRange(1, o.league.teamCount));
          expect(o.lastSeasonRank, inInclusiveRange(1, o.league.teamCount));
        }
      }
    });

    test('an offer is complete and consistent', () {
      for (var seed = 0; seed < 80; seed++) {
        final set = generator.generate(trainer: _withStanding(70), seed: seed);
        for (final o in set.offers) {
          expect(o.budget, greaterThan(0));
          expect(o.budget % 1000, 0);
          expect(o.president.name.trim(), isNotEmpty);
          for (final t in PresidentTrait.values) {
            expect(o.president[t], inInclusiveRange(1, 100));
          }
          switch (o.situation) {
            case Situation.favourite:
              expect(
                o.goal,
                o.tier == 1 ? SeasonGoal.title : SeasonGoal.promotion,
              );
              expect(o.lastSeasonRank, lessThanOrEqualTo(4));
            case Situation.midTable:
              expect(o.goal, SeasonGoal.noTarget);
            case Situation.relegation:
              expect(o.goal, SeasonGoal.survival);
              expect(o.lastSeasonRank, greaterThan(o.league.teamCount - 6));
            case Situation.bankrupt:
              expect(o.goal, SeasonGoal.licence);
              expect(o.quirk, ClubQuirk.debtMountain);
          }
          // The strongest quarter is never in a relegation battle.
          if (o.strengthRank <= o.league.teamCount ~/ 4) {
            expect(o.situation, isNot(Situation.relegation));
          }
        }
      }
    });

    test('strong clubs are more often favourites than weak ones', () {
      var strongFavourite = 0;
      var strong = 0;
      var weakRelegation = 0;
      var weak = 0;
      for (var seed = 0; seed < 300; seed++) {
        final set = generator.generate(trainer: _withStanding(70), seed: seed);
        for (final o in set.offers) {
          final n = o.league.teamCount;
          if (o.strengthRank <= n ~/ 4) {
            strong++;
            if (o.situation == Situation.favourite) strongFavourite++;
          }
          if (o.strengthRank > n - n ~/ 4) {
            weak++;
            if (o.situation == Situation.relegation) weakRelegation++;
          }
        }
      }
      expect(strongFavourite / strong, greaterThan(0.4));
      expect(weakRelegation / weak, greaterThan(0.4));
    });

    test('the budget depends on tier and situation', () {
      final budgets = <int, List<int>>{};
      var bankrupt = 0;
      var favourite = 0;
      var bankruptSum = 0;
      var favouriteSum = 0;
      for (var seed = 0; seed < 300; seed++) {
        final set = generator.generate(trainer: _withStanding(70), seed: seed);
        for (final o in set.offers) {
          budgets.putIfAbsent(o.tier, () => []).add(o.budget);
          if (o.tier != 4) continue;
          if (o.situation == Situation.bankrupt) {
            bankrupt++;
            bankruptSum += o.budget;
          }
          if (o.situation == Situation.favourite) {
            favourite++;
            favouriteSum += o.budget;
          }
        }
      }
      double mean(List<int> v) => v.reduce((a, b) => a + b) / v.length;
      expect(mean(budgets[1]!), greaterThan(mean(budgets[2]!)));
      expect(mean(budgets[2]!), greaterThan(mean(budgets[3]!)));
      expect(mean(budgets[3]!), greaterThan(mean(budgets[4]!)));
      expect(bankrupt, greaterThan(0));
      expect(favourite, greaterThan(0));
      expect(bankruptSum / bankrupt, lessThan(favouriteSum / favourite / 3));
    });
  });

  group('wish club', () {
    Club clubOfTier(int tier) {
      final level = {for (final l in world.leagues) l.id: l.level};
      return world.clubs.firstWhere(
        (c) => c.leagueId != null && level[c.leagueId] == tier,
      );
    }

    test('a reachable wish club is the first offer', () {
      final wish = clubOfTier(4);
      final set = generator.generate(
        trainer: _trainer('pub_landlord'),
        seed: 2,
        wishClubId: wish.id,
      );
      expect(set.wish?.offered, isTrue);
      expect(set.offers.first.club.id, wish.id);
      expect(set.offers.where((o) => o.club.id == wish.id), hasLength(1));
      expect(set.offers, hasLength(3));
    });

    test('an unreachable wish club shows what is missing', () {
      final wish = clubOfTier(1);
      final set = generator.generate(
        trainer: _trainer('pub_landlord'),
        seed: 2,
        wishClubId: wish.id,
      );
      expect(set.wish?.offered, isFalse);
      expect(set.wish?.requiredLevel, TraitLevel.high);
      expect(set.offers.any((o) => o.club.id == wish.id), isFalse);
      final second = generator.generate(
        trainer: _trainer('failed_pro'),
        seed: 2,
        wishClubId: clubOfTier(3).id,
      );
      expect(second.wish?.offered, isTrue);
    });

    test('a pool club cannot be wished for', () {
      final pool = world.clubs.firstWhere((c) => c.leagueId == null);
      expect(
        () => generator.generate(
          trainer: _trainer('pub_landlord'),
          seed: 1,
          wishClubId: pool.id,
        ),
        throwsArgumentError,
      );
    });
  });
}
