import 'package:bolzplatz_app/ui/person_avatar.dart';
import 'package:bolzplatz_app/ui/president_look.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

President _president(String type, String name, {double trait = 50}) =>
    President(
      typeId: type,
      name: name,
      traits: {for (final t in PresidentTrait.values) t: trait},
    );

void main() {
  const types = [
    'construction_tycoon',
    'thrifty_butcher',
    'car_dealer',
    'savings_bank_director',
    'ex_pro',
    'rich_heir',
    'patron',
    'club_fixture',
  ];

  test('the same president always looks the same', () {
    final a = PresidentLook.of(_president('car_dealer', 'Max Muster'));
    final b = PresidentLook.of(_president('car_dealer', 'Max Muster'));
    expect(a.appearance, b.appearance);
    expect(a.extras, b.extras);
  });

  test('every president type has its own clothes or props', () {
    final signatures = <String>{};
    for (final type in types) {
      final look = PresidentLook.of(_president(type, 'Test Person'));
      signatures.add(
        '${look.appearance.outfit}-${look.appearance.outfitColour}-'
        '${look.extras.props.map((p) => p.name).toList()..sort()}',
      );
    }
    expect(signatures.length, types.length);
  });

  test('traits decide the expression', () {
    final thrifty = PresidentLook.of(
      President(
        typeId: 'thrifty_butcher',
        name: 'Karl Knapp',
        traits: {
          for (final t in PresidentTrait.values)
            t: t == PresidentTrait.thrift ? 90 : 50,
        },
      ),
    );
    expect(thrifty.extras.mouth, Mouth.frown);
    final meddler = PresidentLook.of(
      President(
        typeId: 'ex_pro',
        name: 'Otto Rein',
        traits: {
          for (final t in PresidentTrait.values)
            t: t == PresidentTrait.meddling ? 90 : 50,
        },
      ),
    );
    expect(meddler.extras.brows, Brows.angry);
  });

  test('age stages follow 32, 35 and 40', () {
    expect(PortraitExtras.stageForAge(31), 0);
    expect(PortraitExtras.stageForAge(32), 1);
    expect(PortraitExtras.stageForAge(35), 2);
    expect(PortraitExtras.stageForAge(40), 3);
  });
}
