import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10e2: wrong decisions and the VAR. With VAR (league 1 and
// 2, big cup from the round of 16) wrong decisions are put right, without
// it they stand; a goal taken away is not counted.

late Rules rules;
late List<MatchTeam> tier1;
late RefereePool pool;

Referee _ref(double errors) => Referee(
  id: const RefereeId(998),
  firstName: 'Test',
  lastName: 'Kamera',
  level: 1,
  traits: {
    for (final t in RefereeTrait.values)
      t: t == RefereeTrait.errors ? errors : 50,
  },
);

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    pool = RefereePool.fromJson(
      File('../../data/referees_de.json').readAsStringSync(),
    );
    final world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    tier1 = [
      for (final club in world.clubs)
        if (club.leagueId == top)
          () {
            final squad = [
              for (final p in world.players)
                if (p.clubId == club.id) p,
            ];
            return MatchTeam(
              clubId: club.id,
              name: club.name,
              squad: squad,
              sheet: AutoManager(rules).build(squad)!,
            );
          }(),
    ];
  });

  List<MatchResult> play(
    int games, {
    required bool video,
    Referee? Function(int i)? referee,
  }) => [
    for (var i = 0; i < games; i++)
      MatchEngine(rules).simulate(
        tier1[i % tier1.length],
        tier1[(i * 5 + 1) % tier1.length],
        seed: 5000 + i,
        referee: referee?.call(i) ?? pool.pick(1, null, i * 31),
        video: video,
      ),
  ];

  const withVar = {
    'goal_overturned',
    'goal_given',
    'goal_confirmed',
    'penalty_overturned',
  };
  const withoutVar = {
    'offside_missed',
    'goal_disallowed',
    'penalty_soft',
    'red_harsh',
    'second_harsh',
    'identity',
  };

  test('with VAR wrong decisions are put right, without it they stand', () {
    final on = play(300, video: true);
    final off = play(300, video: false);
    final seenOn = <String>{};
    final seenOff = <String>{};
    for (final r in on) {
      for (final e in r.events) {
        if (e.review != null) seenOn.add(e.review!);
        if (e.type == MatchEventType.varReview) expect(e.value, 1);
      }
    }
    for (final r in off) {
      for (final e in r.events) {
        if (e.review != null) seenOff.add(e.review!);
        if (e.type == MatchEventType.varReview) expect(e.value, 0);
      }
    }
    expect(seenOn.intersection(withoutVar), isEmpty, reason: '$seenOn');
    expect(seenOff.intersection(withVar), isEmpty, reason: '$seenOff');
    expect(seenOn, contains('goal_overturned'));
    expect(seenOff, contains('offside_missed'));
  });

  test('a goal taken away does not count', () {
    for (final video in [true, false]) {
      for (final r in play(200, video: video)) {
        var home = 0;
        var away = 0;
        for (final e in r.events) {
          if (e.type == MatchEventType.shot && e.isGoal) {
            if (e.side == 0) {
              home++;
            } else {
              away++;
            }
          }
          if (e.annulled) expect(e.isGoal, isFalse);
        }
        expect(r.homeGoals, home);
        expect(r.awayGoals, away);
        expect(r.homeStats.goals, home);
      }
    }
  });

  test('an error-prone referee makes more wrong decisions', () {
    int wrong(List<MatchResult> rs) => rs.fold(
      0,
      (n, r) =>
          n +
          r.events
              .where(
                (e) =>
                    withoutVar.contains(e.review) ||
                    (e.type == MatchEventType.varReview && e.value == 0),
              )
              .length,
    );
    final bad = wrong(play(200, video: false, referee: (_) => _ref(95)));
    final good = wrong(play(200, video: false, referee: (_) => _ref(5)));
    stdout.writeln('VAR-REPORT wrong decisions bad=$bad good=$good (200)');
    expect(bad, greaterThan(good * 2));
  });

  test('VAR interventions and stoppage time in league 1 (report)', () {
    const games = 300;
    final on = play(games, video: true);
    final off = play(games, video: false);
    var interventions = 0;
    var checks = 0;
    for (final r in on) {
      for (final e in r.events) {
        if (e.type == MatchEventType.varReview ||
            e.review == 'goal_overturned' ||
            e.review == 'goal_given' ||
            e.review == 'penalty_overturned') {
          interventions++;
        }
        if (e.type == MatchEventType.varReview || withVar.contains(e.review)) {
          checks++;
        }
      }
    }
    final addOn = on.fold(0, (n, r) => n + r.length - 90) / games;
    final addOff = off.fold(0, (n, r) => n + r.length - 90) / games;
    final goalsOn = on.fold(0, (n, r) => n + r.homeGoals + r.awayGoals) / games;
    final goalsOff =
        off.fold(0, (n, r) => n + r.homeGoals + r.awayGoals) / games;
    stdout.writeln(
      'VAR-REPORT interventions/game=${(interventions / games).toStringAsFixed(2)} '
      'checks/game=${(checks / games).toStringAsFixed(2)} '
      'stoppage var=${addOn.toStringAsFixed(2)} novar=${addOff.toStringAsFixed(2)} '
      'goals var=${goalsOn.toStringAsFixed(2)} novar=${goalsOff.toStringAsFixed(2)}',
    );
    expect(interventions / games, inInclusiveRange(0.15, 0.9));
    expect(addOn, greaterThan(addOff));
  });
}
