import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

late Rules rules;
late World world;
late NameLists names;

final _calendarRules = CalendarRules.fromJsonString(
  File('../../rules/calendar_rules.json').readAsStringSync(),
);

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    names = NameLists.fromJson(
      File('../../data/names_de.json').readAsStringSync(),
    );
  });

  test('a young player grows, an old player declines', () {
    final dev = Development(rules);
    double overall(Player p) => WorldReport.overall(p, rules);
    final start = GameDate(2027, 7, 1);
    final young = world.players.firstWhere(
      (p) => p.ageOn(GameDate(2026, 7, 1)) <= 19 && !p.position.isGoalkeeper,
    );
    final old = world.players.firstWhere(
      (p) => p.ageOn(GameDate(2026, 7, 1)) >= 33 && !p.position.isGoalkeeper,
    );
    var yd = 0.0;
    var od = 0.0;
    for (var i = 0; i < 20; i++) {
      yd +=
          overall(
            dev.advance(
              young,
              newSeasonStart: start,
              rng: SeededRandom(i),
              minutesShare: 0.8,
            ),
          ) -
          overall(young);
      od +=
          overall(
            dev.advance(
              old,
              newSeasonStart: start,
              rng: SeededRandom(i),
              minutesShare: 0.8,
            ),
          ) -
          overall(old);
    }
    expect(yd / 20 > 0, isTrue, reason: 'young ${yd / 20}');
    expect(od / 20 < 0, isTrue, reason: 'old ${od / 20}');
  });

  test('turnover keeps squad size, positions and unique ids and names', () {
    var state = SeasonState.fromWorld(world);
    final runner = SeasonRunner(rules, calendarRules: _calendarRules);
    var retired = 0;
    for (var year = 0; year < 3; year++) {
      final outcome = runner.play(state, seed: 10 + year);
      final next = runner.nextSeason(
        state,
        outcome,
        seed: 20 + year,
        names: names,
      );
      expect(next.errorOrNull, isNull);
      final before = state;
      state = next.valueOrNull!;
      final ids = <int>{};
      final full = <String>{};
      for (final e in state.squads.entries) {
        expect(e.value, hasLength(rules.generator.squadSize));
        final old = before.squads[e.key]!;
        for (var i = 0; i < old.length; i++) {
          expect(e.value[i].position, old[i].position);
          if (e.value[i].id != old[i].id) retired++;
        }
        for (final p in e.value) {
          expect(ids.add(p.id.value), isTrue);
          expect(full.add(p.displayName), isTrue, reason: p.displayName);
          expect(p.contract, isNotNull);
          expect(
            p.contract!.end.isBefore(GameDate(state.startYear, 7, 1)),
            isFalse,
          );
        }
      }
    }
    expect(retired > 0, isTrue);
  });
}
