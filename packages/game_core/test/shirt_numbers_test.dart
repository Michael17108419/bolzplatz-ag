import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

Player _p(int id, Position pos) => Player(
  id: PlayerId(id),
  firstName: 'A',
  lastName: 'B$id',
  birthDate: GameDate(2000, 1, 1),
  position: pos,
  attributes: AttributeSet.filled(50),
  traits: {for (final t in CharacterTrait.values) t: 50},
  injuryProneness: 30,
  abilities: const [],
  developmentType: DevelopmentType.normal,
  potentialCore: 60,
  potentialDynamic: 0,
);

void main() {
  test('classic numbers, no doubles, same result every time', () {
    final squad = [
      _p(1, Position.tw),
      _p(2, Position.tw),
      _p(3, Position.st),
      _p(4, Position.st),
      _p(5, Position.zom),
      for (var i = 6; i < 40; i++) _p(i, Position.iv),
    ];
    final a = shirtNumbers(squad);
    expect(a[const PlayerId(1)], 1);
    expect(a[const PlayerId(2)], 12);
    expect(a[const PlayerId(3)], 9);
    expect(a[const PlayerId(4)], 19);
    expect(a[const PlayerId(5)], 10);
    expect(a.values.toSet().length, squad.length);
    expect(shirtNumbers(squad.reversed), a);
  });
}
