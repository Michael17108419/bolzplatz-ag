import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10d: stoppage time (IFAB Law 7) and time wasting.

late Rules rules;
late List<MatchTeam> tier1;

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
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

  test('both halves get stoppage time, the clock shows 45+x and 90+x', () {
    final s = MatchSession(rules: rules, home: tier1[0], away: tier1[1], seed: 4);
    final r = s.finish();
    final added = [
      for (final e in r.events)
        if (e.type == MatchEventType.addedTime) e,
    ];
    expect(added, hasLength(2));
    expect(added[0].minute, 45);
    expect(added[1].minute, 90);
    final half = r.events.firstWhere((e) => e.type == MatchEventType.halfTime);
    final end = r.events.firstWhere((e) => e.type == MatchEventType.fullTime);
    expect(half.minute, 45);
    expect(half.added, added[0].value);
    expect(end.minute, 90);
    expect(end.added, added[1].value);
    expect(r.length, 90 + added[0].value! + added[1].value!);
    if (end.added > 0) expect(end.clockLabel, '90+${end.added}');
    // Ticks run on without gaps, the clock never goes past 90.
    var lastTick = 0;
    for (final e in r.events) {
      expect(e.tick, greaterThanOrEqualTo(lastTick));
      expect(e.minute, lessThanOrEqualTo(90));
      lastTick = e.tick;
    }
  });

  test('stoppage time is about ten minutes, goals stay as before (report)', () {
    final engine = MatchEngine(rules);
    var added = 0;
    var goals = 0;
    const games = 200;
    for (var i = 0; i < games; i++) {
      final r = engine.simulate(
        tier1[i % tier1.length],
        tier1[(i * 5 + 1) % tier1.length],
        seed: 50 + i,
      );
      added += r.length - 90;
      goals += r.homeGoals + r.awayGoals;
    }
    stdout.writeln(
      'ADDED-REPORT stoppage/game=${(added / games).toStringAsFixed(2)} '
      'goals/game=${(goals / games).toStringAsFixed(2)}',
    );
    expect(added / games, inInclusiveRange(6, 13));
  });

  test('extra time has its own stoppage and ends after 120 plus', () {
    final s = MatchSession(rules: rules, home: tier1[2], away: tier1[3], seed: 9)
      ..finish();
    s.startExtraTime();
    expect(s.inBreak, isTrue);
    expect(s.clock, 90);
    s.advanceTo(1 << 20);
    expect(s.isFinished, isTrue);
    final ends = [
      for (final e in s.events)
        if (e.type == MatchEventType.addedTime) e.minute,
    ];
    expect(ends, [45, 90, 105, 120]);
    expect(s.clock, 120);
  });

  test('time wasting only by the leading team late on', () {
    final engine = MatchEngine(rules);
    var wasted = 0;
    for (var i = 0; i < 150; i++) {
      final r = engine.simulate(
        tier1[i % tier1.length],
        tier1[(i * 3 + 2) % tier1.length],
        seed: 700 + i,
      );
      for (final e in r.events) {
        if (e.type != MatchEventType.timeWasting) continue;
        wasted++;
        expect(e.minute, greaterThanOrEqualTo(rules.match.timeWasting.fromMinute));
        final lead = e.side == 0
            ? e.homeGoals - e.awayGoals
            : e.awayGoals - e.homeGoals;
        expect(lead, greaterThan(0));
        expect(e.action, isNotNull);
      }
    }
    stdout.writeln('ADDED-REPORT time wasting in 150 games: $wasted');
    expect(wasted, greaterThan(0));
  });

  test('a conference shows the clock of another match with stoppage time', () {
    final r = MatchEngine(rules).simulate(tier1[4], tier1[5], seed: 3);
    final first = r.events
        .firstWhere((e) => e.type == MatchEventType.addedTime)
        .value!;
    final m = ConferenceMatch(
      competition: Competition.league,
      fixture: Fixture(tier1[4].clubId, tier1[5].clubId),
      date: GameDate(2026, 8, 8),
      minuteOfDay: 15 * 60 + 30,
      round: 0,
      result: r,
    );
    expect(m.clockAt(30), '30');
    if (first > 0) expect(m.clockAt(46), '45+1');
    expect(m.clockAt(45 + first + 1), '46');
    expect(m.lengthMinutes, r.length);
  });
}
