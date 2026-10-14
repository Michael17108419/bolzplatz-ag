import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

Map<CharacterTrait, double> _traits() => {
  for (final t in CharacterTrait.values) t: 50,
};

Player _player({
  List<SpecialAbility> abilities = const [],
  Contract? contract,
  double potentialCore = 60,
}) => Player(
  id: const PlayerId(1),
  firstName: 'Kalle',
  lastName: 'Kopfball',
  birthDate: GameDate(2000, 3, 15),
  position: Position.st,
  attributes: AttributeSet.filled(50),
  traits: _traits(),
  injuryProneness: 30,
  abilities: abilities,
  developmentType: DevelopmentType.normal,
  potentialCore: potentialCore,
  potentialDynamic: 10,
  contract: contract,
);

Contract _contract({PlayerId playerId = const PlayerId(1)}) => Contract(
  id: const ContractId(1),
  playerId: playerId,
  clubId: const ClubId(1),
  start: GameDate(2026, 7, 1),
  end: GameDate(2029, 6, 30),
  baseSalaryPerYear: 60000,
);

void main() {
  group('enums', () {
    test('42 attributes: 34 outfield and 8 goalkeeping', () {
      expect(Attribute.values.length, Attribute.count);
      expect(Attribute.values.where((a) => a.isGoalkeeping).length, 8);
    });

    test('attribute ids are unique', () {
      final ids = Attribute.values.map((a) => a.id).toSet();
      expect(ids.length, Attribute.count);
    });

    test('13 traits, 16 abilities, 10 positions, 5 regions', () {
      expect(CharacterTrait.values.length, 13);
      expect(SpecialAbilityType.values.length, 16);
      expect(Position.values.length, 10);
      expect(Region.values.length, 5);
    });

    test('string ids are unique per enum', () {
      expect(CharacterTrait.values.map((e) => e.id).toSet().length, 13);
      expect(SpecialAbilityType.values.map((e) => e.id).toSet().length, 16);
      expect(Position.values.map((e) => e.id).toSet().length, 10);
    });
  });

  group('AttributeSet', () {
    test('rejects out-of-range values', () {
      expect(() => AttributeSet.filled(0.5), throwsArgumentError);
      expect(() => AttributeSet.filled(100.5), throwsArgumentError);
    });

    test('rejects missing attributes', () {
      expect(() => AttributeSet.fromMap({}), throwsArgumentError);
    });

    test('withValue returns a changed copy', () {
      final a = AttributeSet.filled(50);
      final b = a.withValue(Attribute.finishing, 80);
      expect(a[Attribute.finishing], 50);
      expect(b[Attribute.finishing], 80);
      expect(a == b, isFalse);
      expect(a == AttributeSet.filled(50), isTrue);
    });

    test('toList follows attribute index', () {
      final list = AttributeSet.filled(50)
          .withValue(Attribute.gkOneOnOne, 70)
          .toList();
      expect(list.length, 42);
      expect(list[Attribute.gkOneOnOne.index], 70);
    });
  });

  group('Player', () {
    test('age on a date', () {
      final p = _player();
      expect(p.ageOn(GameDate(2026, 3, 14)), 25);
      expect(p.ageOn(GameDate(2026, 3, 15)), 26);
    });

    test('allows four abilities with one gold', () {
      final p = _player(
        abilities: const [
          SpecialAbility(SpecialAbilityType.dribbler, AbilityTier.gold),
          SpecialAbility(SpecialAbilityType.playmaker, AbilityTier.silver),
          SpecialAbility(SpecialAbilityType.passReader, AbilityTier.bronze),
          SpecialAbility(SpecialAbilityType.firstTouch, AbilityTier.bronze),
        ],
      );
      expect(p.abilities.length, 4);
    });

    test('rejects five abilities', () {
      expect(
        () => _player(
          abilities: const [
            SpecialAbility(SpecialAbilityType.dribbler, AbilityTier.bronze),
            SpecialAbility(SpecialAbilityType.playmaker, AbilityTier.bronze),
            SpecialAbility(SpecialAbilityType.passReader, AbilityTier.bronze),
            SpecialAbility(SpecialAbilityType.firstTouch, AbilityTier.bronze),
            SpecialAbility(SpecialAbilityType.allrounder, AbilityTier.bronze),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects two gold abilities', () {
      expect(
        () => _player(
          abilities: const [
            SpecialAbility(SpecialAbilityType.dribbler, AbilityTier.gold),
            SpecialAbility(SpecialAbilityType.playmaker, AbilityTier.gold),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects the same ability twice', () {
      expect(
        () => _player(
          abilities: const [
            SpecialAbility(SpecialAbilityType.dribbler, AbilityTier.bronze),
            SpecialAbility(SpecialAbilityType.dribbler, AbilityTier.silver),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects missing trait', () {
      final traits = _traits()..remove(CharacterTrait.loyalty);
      expect(
        () => Player(
          id: const PlayerId(2),
          firstName: 'A',
          lastName: 'B',
          birthDate: GameDate(2000, 1, 1),
          position: Position.tw,
          attributes: AttributeSet.filled(50),
          traits: traits,
          injuryProneness: 30,
          abilities: const [],
          developmentType: DevelopmentType.normal,
          potentialCore: 60,
          potentialDynamic: 5,
        ),
        throwsArgumentError,
      );
    });

    test('rejects potential out of range', () {
      expect(() => _player(potentialCore: 0), throwsArgumentError);
    });

    test('contract must belong to the player', () {
      expect(
        () => _player(contract: _contract(playerId: const PlayerId(9))),
        throwsArgumentError,
      );
      expect(_player(contract: _contract()).contract, isNotNull);
    });

    test('equality is by id', () {
      expect(_player() == _player(potentialCore: 70), isTrue);
    });
  });

  group('Contract', () {
    test('end must be after start', () {
      expect(
        () => Contract(
          id: const ContractId(1),
          playerId: const PlayerId(1),
          clubId: const ClubId(1),
          start: GameDate(2026, 7, 1),
          end: GameDate(2026, 7, 1),
          baseSalaryPerYear: 1000,
        ),
        throwsArgumentError,
      );
    });

    test('loan flag', () {
      expect(_contract().isLoan, isFalse);
    });
  });

  group('League', () {
    test('level and team count are validated', () {
      expect(
        () => League(id: const LeagueId(1), name: 'X', level: 5, teamCount: 18),
        throwsArgumentError,
      );
      expect(
        () => League(id: const LeagueId(1), name: 'X', level: 1, teamCount: 17),
        throwsArgumentError,
      );
    });

    test('league season needs the right number of distinct clubs', () {
      final league = League(
        id: const LeagueId(1),
        name: 'X',
        level: 1,
        teamCount: 4,
      );
      final ok = LeagueSeason(
        league: league,
        season: const Season(2026),
        clubIds: const [ClubId(1), ClubId(2), ClubId(3), ClubId(4)],
      );
      expect(ok.matchdays, 6);
      expect(
        () => LeagueSeason(
          league: league,
          season: const Season(2026),
          clubIds: const [ClubId(1), ClubId(1), ClubId(3), ClubId(4)],
        ),
        throwsArgumentError,
      );
      expect(
        () => LeagueSeason(
          league: league,
          season: const Season(2026),
          clubIds: const [ClubId(1), ClubId(2)],
        ),
        throwsArgumentError,
      );
    });
  });

  group('Coach', () {
    test('skills are validated and immutable', () {
      final c = Coach(
        id: const CoachId(1),
        firstName: 'A',
        lastName: 'B',
        birthDate: GameDate(1970, 1, 1),
        skills: {'tactics': 60},
      );
      expect(() => c.skills['tactics'] = 1, throwsUnsupportedError);
      expect(
        () => Coach(
          id: const CoachId(2),
          firstName: 'A',
          lastName: 'B',
          birthDate: GameDate(1970, 1, 1),
          skills: {'tactics': 0},
        ),
        throwsArgumentError,
      );
    });
  });
}
