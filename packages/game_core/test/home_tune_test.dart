import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Temporary (step 10h1): home wins in seasons with grounds and crowds.

void main() {
  final text = File('../../rules/rules_2026_27.json').readAsStringSync();
  final world = WorldJson.decode(
    File('../../data/world_2026_27.json').readAsStringSync(),
  );
  final calendar = CalendarRules.fromJsonString(
    File('../../rules/calendar_rules.json').readAsStringSync(),
  );
  final venues = VenueData.fromJson(
    File('../../data/venues_de.json').readAsStringSync(),
  );
  final referees = RefereePool.fromJson(
    File('../../data/referees_de.json').readAsStringSync(),
  );
  for (final base in ['0.08', '0.1', '0.12']) {
    test('home_base $base', () {
      final rules = Rules.parse(
        text.replaceFirst(RegExp(r'"home_base": [0-9.]+'), '"home_base": $base'),
      ).valueOrNull!;
      final runner = SeasonRunner(
        rules,
        calendarRules: calendar,
        venues: venues,
        referees: referees,
      );
      var hw = 0, dr = 0, aw = 0;
      for (var y = 0; y < 3; y++) {
        final o = runner.play(SeasonState.fromWorld(world), seed: 800 + y);
        hw += o.homeWins;
        dr += o.draws;
        aw += o.awayWins;
      }
      final t = hw + dr + aw;
      stdout.writeln(
        'HOME base=$base H/D/A=${(hw / t).toStringAsFixed(3)}/'
        '${(dr / t).toStringAsFixed(3)}/${(aw / t).toStringAsFixed(3)}',
      );
    });
  }
}
