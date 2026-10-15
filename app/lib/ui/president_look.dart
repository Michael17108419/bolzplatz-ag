import 'package:game_core/game_core.dart';

import 'person_avatar.dart';

/// Looks and extras of one person, ready for [PersonAvatar].
class PersonLook {
  const PersonLook({required this.appearance, required this.extras});

  final TrainerAppearance appearance;
  final PortraitExtras extras;
}

class _TypeLook {
  const _TypeLook({
    required this.outfit,
    required this.colour,
    required this.colour2,
    required this.age,
    this.props = const {},
    this.hairStyles = const [1, 2],
    this.beards = const [0],
    this.glasses = const [0],
    this.whistle = false,
  });

  final int outfit;
  final int colour;
  final int colour2;

  /// Age stage (0 young, 1 from 32, 2 from 35, 3 from 40).
  final int age;
  final Set<Prop> props;
  final List<int> hairStyles;
  final List<int> beards;
  final List<int> glasses;
  final bool whistle;
}

/// The look of a president: the type decides clothes and props, the traits
/// decide the expression, the name decides the rest (document 13, portraits).
/// The same president always looks the same.
abstract final class PresidentLook {
  static const Map<String, _TypeLook> _types = {
    'construction_tycoon': _TypeLook(
      outfit: 4,
      colour: 4,
      colour2: 2,
      age: 2,
      props: {Prop.hardHat, Prop.cigar},
      beards: [0, 1, 2],
    ),
    'thrifty_butcher': _TypeLook(
      outfit: 3,
      colour: 5,
      colour2: 1,
      age: 2,
      props: {Prop.apron},
      beards: [0, 3],
    ),
    'car_dealer': _TypeLook(
      outfit: 4,
      colour: 2,
      colour2: 1,
      age: 1,
      props: {Prop.goldChain},
      hairStyles: [2],
      glasses: [3],
    ),
    'savings_bank_director': _TypeLook(
      outfit: 4,
      colour: 3,
      colour2: 6,
      age: 2,
      hairStyles: [1, 2],
      glasses: [1, 2],
    ),
    'ex_pro': _TypeLook(
      outfit: 0,
      colour: 0,
      colour2: 1,
      age: 1,
      beards: [0, 1],
      hairStyles: [1, 0],
      whistle: true,
    ),
    'rich_heir': _TypeLook(
      outfit: 3,
      colour: 7,
      colour2: 1,
      age: 0,
      props: {Prop.sweaterOnShoulders},
      hairStyles: [2, 5],
      glasses: [3],
    ),
    'patron': _TypeLook(
      outfit: 4,
      colour: 6,
      colour2: 7,
      age: 3,
      props: {Prop.monocle},
      hairStyles: [1, 0],
      beards: [3, 0],
    ),
    'club_fixture': _TypeLook(
      outfit: 5,
      colour: 0,
      colour2: 5,
      age: 3,
      props: {Prop.scarf, Prop.flatCap},
      beards: [0, 1],
      hairStyles: [0, 1],
    ),
  };

  static PersonLook of(President president) {
    final spec = _types[president.typeId] ?? _types['savings_bank_director']!;
    final rng = SeededRandom(_seed('${president.typeId}|${president.name}'));

    final gender = switch (rng.fork('gender').weightedIndex([
      85.0,
      12.0,
      3.0,
    ])) {
      1 => 1,
      2 => 2,
      _ => 0,
    };
    final skin = rng.fork('skin').weightedIndex([45.0, 30.0, 15.0, 7.0, 3.0]);
    final beard = gender == 1 ? 0 : rng.fork('beard').pick(spec.beards);
    final appearance = TrainerAppearance(
      gender: gender,
      skin: skin,
      hairStyle: rng.fork('hair').pick(spec.hairStyles),
      hairColour: rng.fork('haircolour').nextIntInRange(0, 4),
      beard: beard,
      glasses: rng.fork('glasses').pick(spec.glasses),
      outfit: spec.outfit,
      outfitColour: spec.colour,
      outfitColour2: spec.colour2,
    );

    final t = president.traits;
    final Mouth mouth;
    if (t[PresidentTrait.thrift]! >= 70) {
      mouth = Mouth.frown;
    } else if (t[PresidentTrait.vanity]! >= 70) {
      mouth = Mouth.smirk;
    } else if (t[PresidentTrait.pressCraving]! <= 35) {
      mouth = Mouth.pursed;
    } else {
      mouth = Mouth.grin;
    }
    final Brows brows;
    if (t[PresidentTrait.meddling]! >= 70) {
      brows = Brows.angry;
    } else if (t[PresidentTrait.patience]! >= 70 &&
        t[PresidentTrait.meddling]! < 45) {
      brows = Brows.calm;
    } else {
      brows = Brows.cheeky;
    }
    return PersonLook(
      appearance: appearance,
      extras: PortraitExtras(
        props: spec.props,
        mouth: mouth,
        brows: brows,
        ageStage: spec.age,
        whistle: spec.whistle,
      ),
    );
  }

  /// A stable number from a text (FNV-1a), the same on every machine.
  static int _seed(String text) {
    var h = 0x811C9DC5;
    for (final unit in text.codeUnits) {
      h = ((h ^ unit) * 0x01000193) & 0x7FFFFFFF;
    }
    return h;
  }
}
