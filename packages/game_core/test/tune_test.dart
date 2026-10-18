import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Temporary: measures variants of the rules for step 10h (not committed to
// engine-2).

final _calendarRules = CalendarRules.fromJsonString(
  File('../../rules/calendar_rules.json').readAsStringSync(),
);

double _strength(List<Player> squad, Rules rules) {
  final o = [for (final p in squad) WorldReport.overall(p, rules)]
    ..sort((a, b) => b.compareTo(a));
  final top = o.take(14).toList();
  return top.reduce((a, b) => a + b) / top.length;
}

void main() {
  final text = File('../../rules/rules_2026_27.json').readAsStringSync();
  final world = WorldJson.decode(
    File('../../data/world_2026_27.json').readAsStringSync(),
  );
  final names = NameLists.fromJson(
    File('../../data/names_de.json').readAsStringSync(),
  );
  final variants = {
    'home108': {'"home_advantage": 1.02': '"home_advantage": 1.08'},
    'home108_form08': {
      '"home_advantage": 1.02': '"home_advantage": 1.08',
      '"day_form_spread": 0.05': '"day_form_spread": 0.08',
    },
    'home108_duel045': {
      '"home_advantage": 1.02': '"home_advantage": 1.08',
      '"duel_exponent": 0.5': '"duel_exponent": 0.45',
    },
  };
  for (final v in variants.entries) {
    test(v.key, () {
      var t = text;
      for (final r in v.value.entries) {
        expect(t.contains(r.key), isTrue, reason: r.key);
        t = t.replaceFirst(r.key, r.value);
      }
      final rules = Rules.parse(t).valueOrNull!;
      final runner = SeasonRunner(rules, calendarRules: _calendarRules);
      var state = SeasonState.fromWorld(world);
      var hw = 0, dr = 0, aw = 0, goals = 0, matches = 0;
      var champ = 0, leagues = 0;
      for (var y = 0; y < 6; y++) {
        final o = runner.play(state, seed: 500 + y);
        hw += o.homeWins;
        dr += o.draws;
        aw += o.awayWins;
        goals += o.goalsScored;
        matches += o.matchesPlayed;
        for (final table in o.tables.values) {
          final s = [
            for (final e in table) _strength(state.squads[e.club]!, rules),
          ];
          var best = 0;
          for (var i = 1; i < s.length; i++) {
            if (s[i] > s[best]) best = i;
          }
          leagues++;
          if (best == 0) champ++;
        }
        state = runner
            .nextSeason(state, o, seed: 900 + y, names: names)
            .valueOrNull!;
      }
      final total = hw + dr + aw;
      String f(num x) => x.toStringAsFixed(3);
      stdout.writeln(
        'TUNE ${v.key} H/D/A=${f(hw / total)}/${f(dr / total)}/${f(aw / total)} '
        'goals=${f(goals / matches)} strongestChampion=${f(champ / leagues)} '
        '($leagues leagues)',
      );
    });
  }
}
