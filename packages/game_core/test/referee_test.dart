import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10e1: referees with character, fouls with advantage,
// protest (only the captain may talk to the referee) and the keeper of a
// shot.

late Rules rules;
late List<MatchTeam> tier1;
late RefereePool pool;

Referee _ref(Map<RefereeTrait, double> traits) => Referee(
  id: const RefereeId(999),
  firstName: 'Test',
  lastName: 'Pfeife',
  level: 1,
  traits: {for (final t in RefereeTrait.values) t: traits[t] ?? 50},
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

  List<MatchResult> play(int games, Referee? Function(int i) referee) => [
    for (var i = 0; i < games; i++)
      MatchEngine(rules).simulate(
        tier1[i % tier1.length],
        tier1[(i * 5 + 1) % tier1.length],
        seed: 900 + i,
        referee: referee(i),
      ),
  ];

  int count(List<MatchResult> rs, bool Function(MatchEvent e) test) =>
      rs.fold(0, (n, r) => n + r.events.where(test).length);

  test('the pool: levels, regions, no real referees, picks are stable', () {
    expect(pool.referees.length, greaterThanOrEqualTo(70));
    expect(pool.candidates(1, null).every((r) => r.level == 1), isTrue);
    expect(pool.candidates(2, null).every((r) => r.level == 1), isTrue);
    expect(pool.candidates(3, null).every((r) => r.level == 3), isTrue);
    final bayern = pool.candidates(4, Region.bayern);
    expect(bayern, isNotEmpty);
    expect(bayern.every((r) => r.region == Region.bayern), isTrue);
    expect(pool.pick(1, null, 12345)!.id, pool.pick(1, null, 12345)!.id);
    const real = {'Aytekin', 'Zwayer', 'Stieler', 'Brych', 'Gräfe', 'Merk'};
    for (final r in pool.referees) {
      expect(real, isNot(contains(r.lastName)), reason: r.name);
      for (final t in RefereeTrait.values) {
        expect(r.traits[t], inInclusiveRange(1, 100));
      }
    }
    final names = pool.referees.map((r) => r.name).toSet();
    expect(names, hasLength(pool.referees.length));
  });

  test('a strict referee books more, a lenient one less', () {
    final strict = play(
      150,
      (_) => _ref({RefereeTrait.strictness: 95, RefereeTrait.authority: 90}),
    );
    final lenient = play(
      150,
      (_) => _ref({RefereeTrait.strictness: 5, RefereeTrait.authority: 10}),
    );
    bool yellow(MatchEvent e) =>
        e.type == MatchEventType.yellowCard ||
        e.type == MatchEventType.secondYellow;
    final a = count(strict, yellow);
    final b = count(lenient, yellow);
    stdout.writeln('REF-REPORT yellows strict=$a lenient=$b (150 games)');
    expect(a, greaterThan(b * 1.3));
  });

  test('a referee who loves advantage lets play run on more often', () {
    final runs = play(150, (_) => _ref({RefereeTrait.advantage: 95}));
    final stops = play(150, (_) => _ref({RefereeTrait.advantage: 5}));
    double share(List<MatchResult> rs) {
      final fouls = count(rs, (e) => e.type == MatchEventType.foul);
      final adv = count(
        rs,
        (e) => e.type == MatchEventType.foul && e.action == 'advantage',
      );
      return fouls == 0 ? 0 : adv / fouls;
    }

    stdout.writeln(
      'REF-REPORT advantage share runs=${share(runs).toStringAsFixed(2)} '
      'stops=${share(stops).toStringAsFixed(2)}',
    );
    expect(share(runs), greaterThan(share(stops) + 0.1));
  });

  test('only the captain may talk: protest cards never for him, no card '
      'for a Notbremse with advantage that ended in a goal', () {
    for (var i = 0; i < 200; i++) {
      final session = MatchSession(
        rules: rules,
        home: tier1[i % tier1.length],
        away: tier1[(i * 3 + 2) % tier1.length],
        seed: 4000 + i,
        referee: pool.referees[i % pool.referees.length],
      );
      final r = session.finish();
      final events = r.events;
      for (var k = 0; k < events.length; k++) {
        final e = events[k];
        if (e.type == MatchEventType.dissent && e.action == 'captain') {
          // The captain talks; no card for it right after.
          if (k + 1 < events.length) {
            final next = events[k + 1];
            expect(
              next.type == MatchEventType.yellowCard &&
                  next.player == e.player &&
                  next.action == 'dissent',
              isFalse,
            );
          }
        }
        if ((e.type == MatchEventType.yellowCard ||
                e.type == MatchEventType.secondYellow) &&
            e.action == 'dissent') {
          expect(e.player, isNot(session.captainOf(e.side)));
        }
        if (e.type == MatchEventType.foul &&
            e.action == 'advantage' &&
            e.value == 1) {
          // Find the end of this attack: the next shot of the other side.
          final shot = events
              .skip(k + 1)
              .takeWhile((x) => x.tick <= e.tick + 1)
              .where((x) => x.type == MatchEventType.shot)
              .firstOrNull;
          if (shot != null && shot.isGoal && shot.side == 1 - e.side) {
            final card = events
                .skip(k + 1)
                .takeWhile((x) => x.tick <= e.tick + 1)
                .where(
                  (x) =>
                      x.player == e.player &&
                      (x.type == MatchEventType.yellowCard ||
                          x.type == MatchEventType.redCard),
                );
            expect(card, isEmpty);
          }
        }
      }
    }
  });

  test('a shot knows the keeper who faced it', () {
    final rs = play(20, (i) => pool.referees[i]);
    final shots = [
      for (final r in rs)
        for (final e in r.events)
          if (e.type == MatchEventType.shot && e.outcome == ShotOutcome.saved)
            e,
    ];
    expect(shots, isNotEmpty);
    expect(shots.where((e) => e.keeper != null).length, shots.length);
  });

  test('averages stay where they belong with real referees (report)', () {
    const games = 400;
    final rs = play(games, (i) => pool.pick(1, null, i * 7919)!);
    double per(bool Function(MatchEvent e) test) => count(rs, test) / games;
    final goals = rs.fold(0, (n, r) => n + r.homeGoals + r.awayGoals) / games;
    final yellows = per(
      (e) =>
          e.type == MatchEventType.yellowCard ||
          e.type == MatchEventType.secondYellow,
    );
    final reds = per(
      (e) =>
          e.type == MatchEventType.redCard ||
          e.type == MatchEventType.secondYellow,
    );
    final penalties = per((e) => e.type == MatchEventType.penalty);
    final fouls = per((e) => e.type == MatchEventType.foul);
    final adv = per(
      (e) => e.type == MatchEventType.foul && e.action == 'advantage',
    );
    final dogso = per((e) => e.type == MatchEventType.foul && e.value == 1);
    final freeKicks = per((e) => e.type == MatchEventType.freeKick);
    final dissent = per((e) => e.type == MatchEventType.dissent);
    final protestCards = per(
      (e) => e.type == MatchEventType.yellowCard && e.action == 'dissent',
    );
    var home = 0;
    var draw = 0;
    for (final r in rs) {
      if (r.homeGoals > r.awayGoals) {
        home++;
      } else if (r.homeGoals == r.awayGoals) {
        draw++;
      }
    }
    stdout.writeln(
      'REF-REPORT goals=${goals.toStringAsFixed(2)} '
      'yellows=${yellows.toStringAsFixed(2)} reds=${reds.toStringAsFixed(2)} '
      'penalties=${penalties.toStringAsFixed(2)} '
      'fouls=${fouls.toStringAsFixed(2)} advantage=${adv.toStringAsFixed(2)} '
      'notbremse=${dogso.toStringAsFixed(2)} '
      'freekicks=${freeKicks.toStringAsFixed(2)} '
      'dissent=${dissent.toStringAsFixed(2)} '
      'protestcards=${protestCards.toStringAsFixed(2)} '
      'home=${(home / games).toStringAsFixed(2)} '
      'draw=${(draw / games).toStringAsFixed(2)}',
    );
    expect(goals, inInclusiveRange(2.8, 3.9));
    expect(yellows, inInclusiveRange(3.0, 5.5));
    expect(reds, lessThan(0.35));
    expect(penalties, inInclusiveRange(0.15, 0.5));
  });
}
