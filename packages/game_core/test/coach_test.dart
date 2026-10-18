import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10f5: the coaches of the AI clubs and the assistant.

late Rules rules;
late List<MatchTeam> tier1;

MatchTeam _coached(MatchTeam t, double tactics, {bool auto = true}) =>
    MatchTeam(
      clubId: t.clubId,
      name: t.name,
      squad: t.squad,
      sheet: t.sheet,
      coach: CoachProfile(tactics: tactics, charisma: tactics),
      autoManage: auto,
    );

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

  test('coaches chase when behind and hold when ahead; good ones see it '
      'earlier, only weak ones panic; every AI side talks at half time '
      '(report)', () {
    final first = <bool, List<int>>{true: [], false: []};
    var panicStrong = 0;
    var panicWeak = 0;
    var holds = 0;
    var talks = 0;
    var games = 0;
    for (var i = 0; i < 300; i++) {
      final a = tier1[i % tier1.length];
      final b = tier1[(i * 7 + 3) % tier1.length];
      if (a.clubId == b.clubId) continue;
      games++;
      final strong = i.isEven;
      final q = strong ? 90.0 : 10.0;
      final r = MatchEngine(rules)
          .simulate(_coached(a, q), _coached(b, q), seed: 5100 + i);
      final changes = r.events.where(
        (e) => e.type == MatchEventType.tacticChange,
      );
      for (final e in changes) {
        if (e.action == 'chase') first[strong]!.add(e.minute);
        if (e.action == 'hold') holds++;
        if (e.action == 'panic') {
          strong ? panicStrong++ : panicWeak++;
        }
      }
      talks += r.events.where((e) => e.type == MatchEventType.teamTalk).length;
    }
    double mean(List<int> l) => l.reduce((x, y) => x + y) / l.length;
    stdout.writeln(
      'COACH-REPORT chase minute strong=${mean(first[true]!).toStringAsFixed(1)} '
      'weak=${mean(first[false]!).toStringAsFixed(1)} holds=$holds '
      'panic strong=$panicStrong weak=$panicWeak talks=$talks ($games games)',
    );
    expect(first[true], isNotEmpty);
    expect(first[false], isNotEmpty);
    expect(mean(first[true]!), lessThan(mean(first[false]!)));
    expect(holds, greaterThan(0));
    expect(panicStrong, 0);
    expect(panicWeak, greaterThan(0));
    expect(talks, greaterThanOrEqualTo(games * 2));
  });

  test('the club of the player gets no coach until it hands over; a replay '
      'with the hand-over reads the same', () {
    final a = tier1[0];
    final b = tier1[1];
    MatchSession make() => MatchSession(
      rules: rules,
      home: _coached(a, 50, auto: false),
      away: _coached(b, 50),
      seed: 4242,
    );
    final alone = make().finish();
    expect(
      alone.events.where(
        (e) =>
            e.side == 0 &&
            (e.type == MatchEventType.tacticChange ||
                e.type == MatchEventType.teamTalk),
      ),
      isEmpty,
    );
    final s = make();
    s.advanceTo(20);
    s.handOver(0);
    s.handOver(0);
    expect(s.actions.where((x) => x.handOver), hasLength(1));
    final r = s.finish();
    final again = make()..replay(s.actions);
    final r2 = again.finish();
    expect(r2.homeGoals, r.homeGoals);
    expect(r2.awayGoals, r.awayGoals);
    expect(r2.events.length, r.events.length);
    expect(
      r.events.where((e) => e.side == 0 && e.type == MatchEventType.teamTalk),
      isNotEmpty,
    );
  });

  test('AI coaches prepare: a plan from what they see, good ones put a man '
      'marker on a key player and play for time when ahead (report)', () {
    var plansStrong = 0;
    var plansWeak = 0;
    var markersStrong = 0;
    var markersWeak = 0;
    var games = 0;
    for (var i = 0; i < 100; i++) {
      final a = tier1[i % tier1.length];
      final b = tier1[(i * 3 + 1) % tier1.length];
      if (a.clubId == b.clubId) continue;
      games++;
      for (final q in [90.0, 10.0]) {
        final s = MatchSession(
          rules: rules,
          home: _coached(a, q),
          away: _coached(b, q),
          seed: 2200 + i,
        );
        final plans = s.events
            .where((e) => e.type == MatchEventType.matchPlan)
            .length;
        final markers = [
          for (final side in [0, 1])
            ...s
                .sheetOf(side)
                .instructions
                .values
                .where((x) => x == PlayerInstruction.manMark),
        ].length;
        if (q > 50) {
          plansStrong += plans;
          markersStrong += markers;
        } else {
          plansWeak += plans;
          markersWeak += markers;
        }
        expect(s.actions, isEmpty);
      }
    }
    stdout.writeln(
      'COACH-REPORT plans strong=$plansStrong weak=$plansWeak '
      'man markers strong=$markersStrong weak=$markersWeak ($games games)',
    );
    expect(plansStrong, greaterThan(0));
    expect(markersStrong, greaterThan(markersWeak));
  });
}
