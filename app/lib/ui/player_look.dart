import 'package:game_core/game_core.dart';

import 'person_avatar.dart';
import 'president_look.dart';

/// The comic portrait of a player, made from his id and numbers: nationality
/// decides skin and hair, the character decides brows and mouth, the age
/// decides the age stage, the club colour the shirt (document 08, portraits).
/// The same player always looks the same.
abstract final class PlayerLook {
  /// Jersey colour index (into [PersonLooks.outfit]) for each of the twelve
  /// crest colours.
  static const List<int> _jersey = [7, 3, 0, 7, 0, 1, 3, 7, 0, 2, 6, 7];

  static const Map<String, List<double>> _skinByNation = {
    'DE': [55, 30, 12, 3, 0],
    'PL': [60, 28, 10, 2, 0],
    'HR': [50, 32, 14, 4, 0],
    'NL': [55, 28, 12, 4, 1],
    'FR': [38, 28, 16, 12, 6],
    'IT': [25, 45, 25, 5, 0],
    'ES': [25, 45, 25, 5, 0],
    'TR': [22, 45, 25, 8, 0],
    'BR': [10, 25, 30, 25, 10],
    'GH': [0, 0, 6, 34, 60],
    'NG': [0, 0, 5, 35, 60],
  };

  static PersonLook of(Player p, {required int age, required int crestColour}) {
    final rng = SeededRandom(_seed('player|${p.id.value}'));
    final skin = rng
        .fork('skin')
        .weightedIndex(_skinByNation[p.nationality] ?? _skinByNation['DE']!);
    final darkSkin = skin >= 3;
    final hairColour = darkSkin
        ? rng.fork('haircolour').weightedIndex([90, 8, 0, 2, 0])
        : rng.fork('haircolour').weightedIndex([25, 35, 20, 15, 5]);
    final goalkeeper = p.position.isGoalkeeper;
    final appearance = TrainerAppearance(
      skin: skin,
      hairStyle: rng.fork('hair').nextIntInRange(0, 5),
      hairColour: hairColour,
      beard: rng.fork('beard').weightedIndex([62, 20, 12, 6]),
      glasses: rng.fork('glasses').weightedIndex([94, 3, 2, 1]),
      outfit: 1,
      outfitColour: goalkeeper ? 4 : _jersey[crestColour % _jersey.length],
      outfitColour2: 5,
    );
    final t = p.traits;
    double tr(CharacterTrait c) => t[c]!;
    final Brows brows;
    if (tr(CharacterTrait.temper) >= 70 || tr(CharacterTrait.aggression) >= 80) {
      brows = Brows.angry;
    } else if (tr(CharacterTrait.professionalism) >= 70 &&
        tr(CharacterTrait.temper) < 45) {
      brows = Brows.calm;
    } else {
      brows = Brows.cheeky;
    }
    final Mouth mouth;
    if (tr(CharacterTrait.partyFactor) >= 70) {
      mouth = Mouth.smirk;
    } else if (tr(CharacterTrait.professionalism) >= 75) {
      mouth = Mouth.pursed;
    } else if (tr(CharacterTrait.egoism) >= 80) {
      mouth = Mouth.frown;
    } else {
      mouth = Mouth.grin;
    }
    return PersonLook(
      appearance: appearance,
      extras: PortraitExtras(
        mouth: mouth,
        brows: brows,
        ageStage: PortraitExtras.stageForAge(age),
        whistle: false,
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
