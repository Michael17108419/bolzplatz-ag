import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

final Rules _rules = Rules.parse(
  File('../../rules/rules_2026_27.json').readAsStringSync(),
).valueOrNull!;

final NameLists _names = NameLists(
  first: ['Karl', 'Jens', 'Uwe', 'Timo'],
  last: ['Meier', 'Schulz', 'Brandt', 'Vogt'],
);

PlayerGenerator _generator() => PlayerGenerator(
  rules: _rules,
  names: _names,
  referenceDate: GameDate(2026, 7, 1),
);

double _outfieldAverage(Player p) {
  var sum = 0.0;
  var n = 0;
  for (final a in Attribute.values.where((a) => !a.isGoalkeeping)) {
    sum += p.attributes[a];
    n++;
  }
  return sum / n;
}

List<Player> _tierSample(int tier, int squads) {
  final gen = _generator();
  final world = SeededRandom(2026);
  return [
    for (var s = 0; s < squads; s++)
      ...gen.generateSquad(world: world, firstId: 1 + s * 100, tier: tier),
  ];
}

void main() {
  test('squad follows the template: 23 players', () {
    expect(_rules.generator.squadSize, 23);
    final squad = _generator().generateSquad(
      world: SeededRandom(1),
      firstId: 1,
      tier: 3,
      clubId: const ClubId(5),
    );
    expect(squad, hasLength(23));
    expect(squad.where((p) => p.position == Position.tw), hasLength(2));
    expect(squad.where((p) => p.position == Position.iv), hasLength(4));
    expect(squad.every((p) => p.clubId == const ClubId(5)), isTrue);
    expect(squad.map((p) => p.id).toSet(), hasLength(23));
  });

  test('the same seed gives the same players', () {
    List<String> describe(int seed) => [
      for (final p in _generator().generateSquad(
        world: SeededRandom(seed),
        firstId: 1,
        tier: 2,
      ))
        '${p.displayName}|${p.birthDate.epochDay}|${p.attributes.toList().join(",")}',
    ];
    expect(describe(7), describe(7));
    expect(describe(7), isNot(describe(8)));
  });

  test('a player does not depend on the order of generation', () {
    final gen = _generator();
    final a = gen.generate(
      world: SeededRandom(3),
      id: const PlayerId(50),
      position: Position.st,
      tier: 1,
    );
    final world = SeededRandom(3);
    for (var i = 0; i < 10; i++) {
      gen.generate(
        world: world,
        id: PlayerId(i),
        position: Position.zm,
        tier: 4,
      );
    }
    final b = gen.generate(
      world: world,
      id: const PlayerId(50),
      position: Position.st,
      tier: 1,
    );
    expect(a.attributes, b.attributes);
    expect(a.displayName, b.displayName);
  });

  test('all players are valid and in range', () {
    for (final tier in [1, 2, 3, 4, 5]) {
      for (final p in _tierSample(tier, 20)) {
        final age = p.ageOn(GameDate(2026, 7, 1));
        expect(age, inInclusiveRange(17, 37));
        expect(p.birthDate.isBefore(GameDate(2010, 1, 1)), isTrue);
        expect(p.abilities.length, lessThanOrEqualTo(4));
        expect(
          p.abilities.where((a) => a.tier == AbilityTier.gold).length,
          lessThanOrEqualTo(1),
        );
        expect(p.potentialCore, greaterThanOrEqualTo(1));
        expect(p.potentialCore, lessThanOrEqualTo(100));
        expect(p.potentialDynamic, inInclusiveRange(0, 12));
        if (age >= 28) expect(p.potentialDynamic, 0);
      }
    }
  });

  test('higher tiers have clearly better players', () {
    double mean(int tier) {
      final players = _tierSample(tier, 40);
      return players.map(_outfieldAverage).reduce((a, b) => a + b) /
          players.length;
    }

    final means = [
      for (final t in [1, 2, 3, 4, 5]) mean(t),
    ];
    for (var i = 0; i < means.length - 1; i++) {
      expect(means[i], greaterThan(means[i + 1]), reason: 'tier ${i + 1}');
    }
    expect(means.first - means.last, greaterThan(15));
  });

  test('potential is never below the prime level and pyramid is ordered', () {
    double mean(int tier) {
      final players = _tierSample(tier, 40);
      return players.map((p) => p.potentialCore).reduce((a, b) => a + b) /
          players.length;
    }

    expect(mean(1), greaterThan(mean(2)));
    expect(mean(2), greaterThan(mean(3)));
    expect(mean(4), greaterThan(mean(5)));
  });

  test('goalkeepers: keeper attributes high, other positions low', () {
    final squad = _tierSample(2, 30);
    final keepers = squad.where((p) => p.position == Position.tw);
    final others = squad.where((p) => p.position != Position.tw);
    for (final p in others) {
      for (final a in Attribute.values.where((a) => a.isGoalkeeping)) {
        expect(p.attributes[a], inInclusiveRange(5, 20));
      }
    }
    double keeperMean(Player p) =>
        Attribute.values
            .where((a) => a.isGoalkeeping)
            .map((a) => p.attributes[a])
            .reduce((a, b) => a + b) /
        8;
    for (final p in keepers) {
      expect(keeperMean(p), greaterThan(30));
    }
  });

  test('strikers shoot better than centre backs, centre backs defend', () {
    final squad = _tierSample(2, 60);
    double avg(Position pos, Attribute a) {
      final list = squad.where((p) => p.position == pos).toList();
      return list.map((p) => p.attributes[a]).reduce((x, y) => x + y) /
          list.length;
    }

    expect(
      avg(Position.st, Attribute.finishing),
      greaterThan(avg(Position.iv, Attribute.finishing) + 15),
    );
    expect(
      avg(Position.iv, Attribute.standingTackle),
      greaterThan(avg(Position.st, Attribute.standingTackle) + 15),
    );
  });

  test('young players are weaker than prime-age players', () {
    final squad = _tierSample(2, 80);
    double mean(bool Function(int age) test) {
      final list = squad
          .where((p) => test(p.ageOn(GameDate(2026, 7, 1))))
          .where((p) => p.position != Position.tw)
          .toList();
      return list.map(_outfieldAverage).reduce((a, b) => a + b) / list.length;
    }

    expect(mean((a) => a <= 19), lessThan(mean((a) => a >= 25 && a <= 29)));
  });

  test('abilities fit the position', () {
    final squad = _tierSample(1, 40);
    for (final p in squad) {
      for (final a in p.abilities) {
        expect(
          _rules.generator.abilityPositions[a.type]!.contains(p.position),
          isTrue,
          reason: '${a.type.id} on ${p.position.id}',
        );
      }
    }
    // Gold and ability counts are higher in the top tier than in the pool.
    int abilities(int tier) =>
        _tierSample(tier, 40).fold(0, (sum, p) => sum + p.abilities.length);
    expect(abilities(1), greaterThan(abilities(5)));
  });

  test('development types appear in the configured proportions', () {
    final squad = _tierSample(3, 80);
    final late = squad
        .where((p) => p.developmentType == DevelopmentType.lateBloomer)
        .length;
    final share = late / squad.length;
    expect(share, inInclusiveRange(0.14, 0.26));
  });

  test('rules without generator section are rejected', () {
    final text = File('../../rules/rules_2026_27.json').readAsStringSync();
    final broken = text.replaceFirst('"generator"', '"generatorX"');
    expect(Rules.parse(broken).isErr, isTrue);
  });
}
