import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10e3: the sports court after a straight red (DFB): a
// motion by kind of the red card, in matches or weeks; other clubs accept,
// a human club accepts or appeals; the court can go milder, the same or
// harder; proceedings stop for a red to the wrong player.

final _calendarRules = CalendarRules.fromJsonString(
  File('../../rules/calendar_rules.json').readAsStringSync(),
);
late Rules rules;
late World world;
late RefereePool pool;

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    pool = RefereePool.fromJson(
      File('../../data/referees_de.json').readAsStringSync(),
    );
  });

  (SeasonRunner, SeasonRun, Set<ClubId>) season(int seed) {
    final state = SeasonState.fromWorld(world);
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    final humans = state.members[top]!.toSet();
    final runner = SeasonRunner(
      rules,
      calendarRules: _calendarRules,
      referees: pool,
    );
    final run = runner.begin(state, seed: seed, humanClubs: humans);
    while (!run.isOver) {
      runner.completeDay(run, runner.openDay(run));
    }
    return (runner, run, humans);
  }

  test('every straight red opens a case within the range of its kind', () {
    final (runner, run, humans) = season(21);
    final cases = [for (final c in run.state.clubs.keys) ...runner.casesOf(c)];
    expect(cases, isNotEmpty);
    final kinds = <String, int>{};
    for (final c in cases) {
      kinds[c.kind] = (kinds[c.kind] ?? 0) + 1;
      final range = rules.season.court.banFor(c.kind);
      expect(c.weeks, range.weeks, reason: c.kind);
      if (c.status == CourtStatus.stopped) {
        expect(c.review, 'identity');
        expect(c.ban, 0);
        continue;
      }
      expect(c.motion, inInclusiveRange(range.min, range.max));
      expect(
        c.status,
        humans.contains(c.club) ? CourtStatus.open : CourtStatus.accepted,
      );
    }
    stdout.writeln('COURT-REPORT cases=${cases.length} kinds=$kinds');
  });

  test('accept or appeal: once, milder, the same or harder, the same for '
      'the same seed', () {
    List<String> decide() {
      final (runner, run, humans) = season(22);
      final out = <String>[];
      var i = 0;
      for (final club in humans) {
        for (final c in runner.casesOf(club)) {
          if (c.status != CourtStatus.open) continue;
          final appeal = i++ % 2 == 0;
          expect(runner.decideCase(c.id, appeal: appeal), isTrue);
          expect(runner.decideCase(c.id, appeal: appeal), isFalse);
          if (appeal) {
            expect(c.status, CourtStatus.appealed);
            final v = c.verdict!;
            if (c.review == 'red_harsh') {
              expect(v == 1 || v == c.motion || v == c.motion + 1, isTrue);
            } else {
              expect(v, inInclusiveRange(c.motion - 1, c.motion + 1));
            }
            expect(v, greaterThanOrEqualTo(1));
          } else {
            expect(c.status, CourtStatus.accepted);
            expect(c.verdict, isNull);
          }
          out.add('${c.id}:${c.ban}');
        }
      }
      return out;
    }

    final a = decide();
    expect(a, isNotEmpty);
    expect(decide(), a);
  });

  test('a ban in weeks keeps the player out until it ends', () {
    final (runner, run, humans) = season(23);
    final weeks = [
      for (final club in humans)
        for (final c in runner.casesOf(club))
          if (c.weeks && c.status == CourtStatus.open) c,
    ];
    if (weeks.isEmpty) {
      markTestSkipped('no ban in weeks this season');
      return;
    }
    final c = weeks.first;
    final day = c.epochDay;
    expect(runner.isSuspended(c.player, Competition.league, day + 1), isTrue);
    expect(
      runner.isSuspended(c.player, Competition.pott, day + c.motion * 7 - 1),
      isTrue,
    );
    // Lowered on appeal or not, after the longest possible ban he is free.
    runner.decideCase(c.id, appeal: true);
    expect(
      runner.isSuspended(
        c.player,
        Competition.league,
        day + (c.motion + 1) * 7 + 1,
      ),
      isFalse,
    );
  });
}
