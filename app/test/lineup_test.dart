import 'dart:io';

import 'package:bolzplatz_app/game/lineup.dart';
import 'package:bolzplatz_app/game/loaded_world.dart';
import 'package:bolzplatz_app/ui/lineup_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

LoadedWorld _load() => LoadedWorld.fromTexts(
  File('../data/world_2026_27.json').readAsStringSync(),
  File('../rules/rules_2026_27.json').readAsStringSync(),
  File('../data/names_de.json').readAsStringSync(),
  File('../rules/calendar_rules.json').readAsStringSync(),
);

void main() {
  final loaded = _load();
  final club = loaded.world.clubs.first.id;
  final squad = clubPlayers(loaded, club);

  test('every formation has eleven distinct spots on the pitch', () {
    for (final f in loaded.rules.tactics.formations) {
      final spots = slotPositions(f);
      expect(spots.length, 11, reason: f.id);
      expect(spots.toSet().length, 11, reason: f.id);
      for (final o in spots) {
        expect(o.dx, inInclusiveRange(0, 1), reason: f.id);
        expect(o.dy, inInclusiveRange(0, 1), reason: f.id);
      }
      // The goalkeeper stands deepest.
      expect(
        spots[0].dy,
        spots.map((o) => o.dy).reduce((a, b) => a > b ? a : b),
        reason: f.id,
      );
    }
  });

  test('the assistant sheet is valid and has a preview', () {
    final sheet = AutoManager(loaded.rules).build(squad.values.toList())!;
    final formation = loaded.rules.tactics.formation(sheet.formationId);
    expect(checkLineup(sheet, formation, squad), LineupProblem.none);
    final preview = previewLineup(sheet, squad, loaded.rules);
    expect(preview.strength, greaterThan(20));
    expect(preview.roleFit, inInclusiveRange(0, 1));
    expect(preview.slotFits.length, 11);
  });

  test('a broken sheet is recognised', () {
    final sheet = AutoManager(loaded.rules).build(squad.values.toList())!;
    final formation = loaded.rules.tactics.formation(sheet.formationId);
    final twice = sheet.copyWith(
      startingXi: [...sheet.startingXi.take(10), sheet.startingXi[3]],
    );
    expect(checkLineup(twice, formation, squad), LineupProblem.duplicate);
    final short = sheet.copyWith(
      startingXi: sheet.startingXi.take(10).toList(),
    );
    expect(checkLineup(short, formation, squad), LineupProblem.wrongCount);
    final fieldInGoal = sheet.copyWith(
      startingXi: [
        sheet.startingXi[1],
        sheet.startingXi[0],
        ...sheet.startingXi.skip(2),
      ],
    );
    expect(checkLineup(fieldInGoal, formation, squad), LineupProblem.keeper);
  });
}
