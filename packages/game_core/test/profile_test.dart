import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

final Rules _rules = Rules.parse(
  File('../../rules/rules_2026_27.json').readAsStringSync(),
).valueOrNull!;

final NameLists _names = NameLists.fromJson(
  File('../../data/names_de.json').readAsStringSync(),
);

final Fit _fit = Fit(_rules);

Player _player({
  Position position = Position.la,
  Foot foot = Foot.left,
  int weakFoot = 5,
  Map<Position, PositionFamiliarity> secondary = const {},
}) => Player(
  id: const PlayerId(1),
  firstName: 'A',
  lastName: 'B',
  birthDate: GameDate(2000, 1, 1),
  position: position,
  attributes: AttributeSet.filled(60),
  traits: {for (final t in CharacterTrait.values) t: 50},
  injuryProneness: 30,
  abilities: const [],
  developmentType: DevelopmentType.normal,
  potentialCore: 70,
  potentialDynamic: 5,
  foot: foot,
  weakFoot: weakFoot,
  secondaryPositions: secondary,
);

List<Player> _sample(int squads) {
  final gen = PlayerGenerator(
    rules: _rules,
    names: _names,
    referenceDate: GameDate(2026, 7, 1),
  );
  final world = SeededRandom(7);
  return [
    for (var s = 0; s < squads; s++)
      ...gen.generateSquad(world: world, firstId: 1 + s * 100, tier: 3),
  ];
}

void main() {
  _agingTests();
  group('player model', () {
    test('rejects bad profile data', () {
      expect(() => _player(weakFoot: 0), throwsArgumentError);
      expect(() => _player(weakFoot: 6), throwsArgumentError);
      expect(
        () => _player(secondary: {Position.la: PositionFamiliarity.trained}),
        throwsArgumentError,
      );
      expect(
        () => _player(secondary: {Position.tw: PositionFamiliarity.trained}),
        throwsArgumentError,
      );
      expect(
        () => _player(
          secondary: {
            Position.ra: PositionFamiliarity.trained,
            Position.st: PositionFamiliarity.trained,
            Position.zom: PositionFamiliarity.practised,
            Position.zm: PositionFamiliarity.practised,
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => _player(
          position: Position.tw,
          secondary: {Position.iv: PositionFamiliarity.trained},
        ),
        throwsArgumentError,
      );
    });
  });

  group('generator profile', () {
    final players = _sample(120);

    test('feet follow the configured shares', () {
      final central = players.where((p) => p.position.wideSide == null);
      final left = central.where((p) => p.foot == Foot.left).length;
      expect(left / central.length, closeTo(0.24, 0.04));
      final wide = players.where((p) => p.position.wideSide != null);
      final natural = wide.where((p) => p.foot == p.position.wideSide).length;
      expect(natural / wide.length, closeTo(0.8, 0.06));
    });

    test('weak foot uses all five stars, most players have three', () {
      final stars = {for (final p in players) p.weakFoot};
      expect(stars, {1, 2, 3, 4, 5});
      final three = players.where((p) => p.weakFoot == 3).length;
      expect(three / players.length, greaterThan(0.3));
    });

    test('secondary positions are valid, close and absent for keepers', () {
      for (final p in players) {
        expect(p.secondaryPositions.length, lessThanOrEqualTo(3));
        if (p.position.isGoalkeeper) {
          expect(p.secondaryPositions, isEmpty);
          continue;
        }
        for (final s in p.secondaryPositions.keys) {
          expect(s, isNot(p.position));
          expect(s.isGoalkeeper, isFalse);
          expect(
            _rules.tactics.positionDistance[p.position]![s]!,
            lessThanOrEqualTo(_rules.generator.secondaryMaxDistance),
          );
        }
      }
      final withSecondary = players
          .where((p) => p.secondaryPositions.isNotEmpty)
          .length;
      expect(withSecondary / players.length, greaterThan(0.3));
      expect(withSecondary / players.length, lessThan(0.7));
    });

    test('nationalities: mostly home, some others, names from their lists', () {
      final home = players.where((p) => p.nationality == 'DE').length;
      expect(home / players.length, closeTo(0.78, 0.05));
      final codes = {for (final p in players) p.nationality};
      expect(codes.length, greaterThan(4));
      for (final p in players.where((p) => p.nationality == 'PL')) {
        final group = _names.others.firstWhere((o) => o.code == 'PL');
        expect(group.first, contains(p.firstName));
        expect(group.last, contains(p.lastName));
      }
    });

    test('the same seed gives the same profile', () {
      final again = _sample(3);
      final first = players.take(again.length).toList();
      for (var i = 0; i < again.length; i++) {
        expect(again[i].foot, first[i].foot);
        expect(again[i].weakFoot, first[i].weakFoot);
        expect(again[i].nationality, first[i].nationality);
        expect(again[i].secondaryPositions, first[i].secondaryPositions);
      }
    });
  });

  group('fit with secondary positions', () {
    final distance = _rules.tactics.positionDistance[Position.st]!;

    test('main position has no deduction', () {
      expect(_fit.positionMultiplier(_player(), Position.la), 1);
    });

    test('trained: at most two points, practised: half, foreign: all', () {
      const st = Position.st;
      final base = _player(position: st, foot: Foot.right);
      final trained = _player(
        position: st,
        foot: Foot.right,
        secondary: {Position.iv: PositionFamiliarity.trained},
      );
      final practised = _player(
        position: st,
        foot: Foot.right,
        secondary: {Position.iv: PositionFamiliarity.practised},
      );
      final d = distance[Position.iv]!;
      expect(
        _fit.positionMultiplier(base, Position.iv),
        closeTo(1 - d / 100, 1e-9),
      );
      expect(
        _fit.positionMultiplier(trained, Position.iv),
        closeTo(0.98, 1e-9),
      );
      expect(
        _fit.positionMultiplier(practised, Position.iv),
        closeTo(1 - d / 200, 1e-9),
      );
      // A secondary position does not help on other positions.
      expect(
        _fit.positionMultiplier(trained, Position.zm),
        _fit.positionMultiplier(base, Position.zm),
      );
    });
  });

  group('fit with foot and side', () {
    test('a weak weak foot lowers shots and crosses, five stars do not', () {
      final weak = _player(foot: Foot.right, weakFoot: 1);
      final both = _player(foot: Foot.right, weakFoot: 5);
      expect(
        _fit.slotScore(weak, Position.la),
        lessThan(_fit.slotScore(both, Position.la)),
      );
      expect(_fit.weakFootMultiplier(both, Position.la), 1);
    });

    test('the weak foot hurts more on the inverse side than centrally', () {
      final p = _player(foot: Foot.right, weakFoot: 1);
      final central = _fit.weakFootMultiplier(p, Position.zm);
      final natural = _fit.weakFootMultiplier(p, Position.ra);
      final inverse = _fit.weakFootMultiplier(p, Position.la);
      expect(inverse, lessThan(natural));
      expect(natural, closeTo(central, 1e-9));
      expect(central, lessThan(1));
      expect(central, greaterThan(0.8));
    });

    test('natural side suits the winger, inverse side the inside forward', () {
      final rightFoot = _player(foot: Foot.right);
      final leftFoot = _player(foot: Foot.left);
      // On the right wing a right foot is natural, a left foot inverse.
      expect(
        _fit.playerFit(rightFoot, Position.ra, 'winger'),
        greaterThan(_fit.playerFit(leftFoot, Position.ra, 'winger')),
      );
      expect(
        _fit.playerFit(leftFoot, Position.ra, 'inside_forward'),
        greaterThan(_fit.playerFit(rightFoot, Position.ra, 'inside_forward')),
      );
    });

    test('roles without a side and central slots ignore the foot', () {
      final rightFoot = _player(foot: Foot.right);
      final leftFoot = _player(foot: Foot.left);
      expect(
        _fit.playerFit(rightFoot, Position.ra, 'wide_playmaker'),
        _fit.playerFit(leftFoot, Position.ra, 'wide_playmaker'),
      );
      expect(_fit.sideFactor(rightFoot, Position.zm, null), 0);
    });
  });
}

void _agingTests() {
  group('character aging and dynamic potential', () {
    final dev = _rules.development;

    test('traits change by age as in the table', () {
      // Professionalism rises until 30, then stays.
      expect(dev.traitDelta(CharacterTrait.professionalism, 30), 1);
      expect(dev.traitDelta(CharacterTrait.professionalism, 31), 0);
      // Aggression: rises to 27, plateau to 32, then falls.
      expect(dev.traitDelta(CharacterTrait.aggression, 27), 1);
      expect(dev.traitDelta(CharacterTrait.aggression, 30), 0);
      expect(dev.traitDelta(CharacterTrait.aggression, 33), -1);
      // Party factor falls from 28, media hunger from 30.
      expect(dev.traitDelta(CharacterTrait.partyFactor, 27), 0);
      expect(dev.traitDelta(CharacterTrait.partyFactor, 28), -1);
      expect(dev.traitDelta(CharacterTrait.mediaHunger, 29), 0);
      expect(dev.traitDelta(CharacterTrait.mediaHunger, 30), -1);
      // Ambition: high until 30, falls from 32.
      expect(dev.traitDelta(CharacterTrait.ambition, 31), 0);
      expect(dev.traitDelta(CharacterTrait.ambition, 32), -1);
      // Temper does not change.
      expect(dev.traitDelta(CharacterTrait.temper, 20), 0);
      expect(dev.traitDelta(CharacterTrait.temper, 35), 0);
    });

    test('the shift between two ages adds up in both directions', () {
      const t = CharacterTrait.leadership;
      expect(dev.traitShift(t, 25, 34), 9);
      expect(dev.traitShift(t, 25, 40), 9);
      expect(dev.traitShift(t, 25, 20), -5);
      expect(dev.traitShift(t, 25, 25), 0);
    });

    test('one year of development moves the traits of the player', () {
      final p = _player(position: Position.zm);
      final next = Development(_rules).advance(
        p,
        newSeasonStart: GameDate(2027, 7, 1),
        rng: SeededRandom(1),
        minutesShare: 0.8,
      );
      final age = next.ageOn(GameDate(2027, 7, 1));
      expect(
        next.traits[CharacterTrait.professionalism],
        50 + dev.traitDelta(CharacterTrait.professionalism, age),
      );
      expect(next.traits[CharacterTrait.temper], 50);
    });

    test('the dynamic potential can fall below zero and is capped at 10', () {
      final young = Player(
        id: const PlayerId(2),
        firstName: 'A',
        lastName: 'B',
        birthDate: GameDate(2007, 1, 1),
        position: Position.zm,
        attributes: AttributeSet.filled(60),
        traits: {for (final t in CharacterTrait.values) t: 50},
        injuryProneness: 30,
        abilities: const [],
        developmentType: DevelopmentType.normal,
        potentialCore: 70,
        potentialDynamic: -9.8,
      );
      final bench = Development(_rules).advance(
        young,
        newSeasonStart: GameDate(2027, 7, 1),
        rng: SeededRandom(1),
        minutesShare: 0,
      );
      expect(bench.potentialDynamic, lessThan(-9.8));
      expect(bench.potentialDynamic, greaterThanOrEqualTo(-dev.dynamicMax));
      final star = young.copyWith(potentialDynamic: 9.9);
      final plays = Development(_rules).advance(
        star,
        newSeasonStart: GameDate(2027, 7, 1),
        rng: SeededRandom(1),
        minutesShare: 1,
      );
      expect(plays.potentialDynamic, dev.dynamicMax);
    });

    test('older players keep their dynamic potential', () {
      // Born 1995: 32 years old, so the value is frozen.
      final frozen = Player(
        id: const PlayerId(3),
        firstName: 'A',
        lastName: 'B',
        birthDate: GameDate(1995, 1, 1),
        position: Position.zm,
        attributes: AttributeSet.filled(60),
        traits: {for (final t in CharacterTrait.values) t: 50},
        injuryProneness: 30,
        abilities: const [],
        developmentType: DevelopmentType.normal,
        potentialCore: 70,
        potentialDynamic: -3,
      );
      final after = Development(_rules).advance(
        frozen,
        newSeasonStart: GameDate(2027, 7, 1),
        rng: SeededRandom(1),
        minutesShare: 1,
      );
      expect(after.potentialDynamic, -3);
    });

    test('generated traits and dynamic potential follow the age', () {
      final players = _sample(120);
      double mean(Iterable<double> v) => v.reduce((a, b) => a + b) / v.length;
      double trait(Iterable<Player> group, CharacterTrait t) =>
          mean(group.map((p) => p.traits[t]!));
      final young = players.where(
        (p) => p.ageOn(GameDate(2026, 7, 1)) <= 21,
      );
      final old = players.where((p) => p.ageOn(GameDate(2026, 7, 1)) >= 31);
      // Leadership rises until 34, so older players have more of it.
      expect(
        trait(old, CharacterTrait.leadership),
        greaterThan(trait(young, CharacterTrait.leadership)),
      );
      // The party factor falls from 28.
      expect(
        trait(old, CharacterTrait.partyFactor),
        lessThan(trait(young, CharacterTrait.partyFactor)),
      );
      // The dynamic potential has both signs among players below 28.
      final open = players.where((p) => p.ageOn(GameDate(2026, 7, 1)) < 28);
      expect(open.any((p) => p.potentialDynamic < 0), isTrue);
      expect(open.any((p) => p.potentialDynamic > 0), isTrue);
    });
  });
}
