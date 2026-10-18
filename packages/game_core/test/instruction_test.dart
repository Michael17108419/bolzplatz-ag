import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10g1: instructions for single players and the team.

late Rules rules;
late List<MatchTeam> tier1;

MatchTeam _told(
  MatchTeam t, {
  PlayerInstruction? all,
  Map<PlayerId, PlayerInstruction> some = const {},
  Wing? wing,
  bool waste = false,
}) {
  final keeper = t.sheet.startingXi.first;
  return MatchTeam(
    clubId: t.clubId,
    name: t.name,
    squad: t.squad,
    sheet: t.sheet.copyWith(
      instructions: {
        if (all != null)
          for (final id in t.sheet.startingXi)
            if (id != keeper) id: all,
        ...some,
      },
      wing: wing,
      wasteTime: waste,
    ),
    autoManage: false,
  );
}

/// Plays [games] pairs with and without the instructions for the home side
/// and sums [count] over both.
(int, int) _compare(
  int games,
  int seed,
  MatchTeam Function(MatchTeam) told,
  int Function(MatchResult r, MatchTeam home) count,
) {
  var withIt = 0;
  var without = 0;
  for (var i = 0; i < games; i++) {
    final a = tier1[i % tier1.length];
    final b = tier1[(i * 7 + 3) % tier1.length];
    if (a.clubId == b.clubId) continue;
    final r1 = MatchEngine(rules).simulate(told(a), b, seed: seed + i);
    final r0 = MatchEngine(rules).simulate(a, b, seed: seed + i);
    withIt += count(r1, a);
    without += count(r0, a);
  }
  return (withIt, without);
}

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
              // No AI coach: only the instructions of the test count.
              autoManage: false,
            );
          }(),
    ];
  });

  test('instructions are saved with the sheet; old sheets load without', () {
    final sheet = _told(
      tier1.first,
      all: PlayerInstruction.hard,
      wing: Wing.left,
      waste: true,
    ).sheet;
    final back = TeamSheet.fromJson(sheet.toJson());
    expect(back.instructions, sheet.instructions);
    expect(back.wing, Wing.left);
    expect(back.wasteTime, isTrue);
    final old = tier1.first.sheet.toJson()
      ..remove('instr')
      ..remove('wing')
      ..remove('waste');
    final plain = TeamSheet.fromJson(old);
    expect(plain.instructions, isEmpty);
    expect(plain.wing, isNull);
    expect(plain.wasteTime, isFalse);
  });

  test('every instruction does what it says (report)', () {
    int side(MatchResult r, MatchTeam home, bool Function(MatchEvent) f) =>
        r.events.where((e) => e.side == 0 && f(e)).length;

    final shots = _compare(
      150,
      8100,
      (t) => _told(t, all: PlayerInstruction.shootMore),
      (r, h) => side(r, h, (e) => e.shotType == 'long_shot'),
    );
    final fouls = _compare(
      150,
      8300,
      (t) => _told(t, all: PlayerInstruction.hard),
      (r, h) => side(r, h, (e) => e.type == MatchEventType.foul),
    );
    // Steps of the home side lost, per mille of all its steps: more short
    // passes mean more steps, but fewer of them go wrong.
    int lostShare(MatchResult r, MatchTeam h) {
      final steps = [
        for (final e in r.events)
          if (e.side == 0) ...e.steps,
      ];
      if (steps.isEmpty) return 0;
      return (1000 * steps.where((st) => !st.won).length / steps.length)
          .round();
    }

    final lost = _compare(
      150,
      8500,
      (t) => _told(t, all: PlayerInstruction.safe),
      lostShare,
    );
    final through = _compare(
      150,
      8700,
      (t) => _told(t, all: PlayerInstruction.through),
      (r, h) => [
        for (final e in r.events)
          if (e.side == 0)
            for (final st in e.steps)
              if (st.action == 'through_ball') st,
      ].length,
    );
    final left = _compare(
      150,
      8900,
      (t) => _told(t, wing: Wing.left),
      (r, h) => [
        for (final e in r.events)
          if (e.side == 0 && e.steps.isNotEmpty && e.steps.first.lane <= 1) e,
      ].length,
    );
    final waste = _compare(
      150,
      9100,
      (t) => _told(t, waste: true),
      (r, h) => side(r, h, (e) => e.type == MatchEventType.timeWasting),
    );
    stdout.writeln(
      'INSTRUCTION-REPORT long shots ${shots.$1}/${shots.$2} '
      'fouls ${fouls.$1}/${fouls.$2} lost steps (sum of per mille) '
      '${lost.$1}/${lost.$2} '
      'through balls ${through.$1}/${through.$2} '
      'left starts ${left.$1}/${left.$2} time wasting ${waste.$1}/${waste.$2} '
      '(told/not told, 150 games each)',
    );
    expect(shots.$1, greaterThan(shots.$2));
    expect(fouls.$1, greaterThan(fouls.$2));
    expect(lost.$1, lessThan(lost.$2));
    expect(through.$1, greaterThan(through.$2));
    expect(left.$1, greaterThan(left.$2));
    expect(waste.$1, greaterThan(waste.$2));
  });

  test('a man marker takes the most dangerous attacker out of the game '
      '(report)', () {
    var wonMarked = 0;
    var allMarked = 0;
    var wonFree = 0;
    var allFree = 0;
    for (var i = 0; i < 120; i++) {
      final a = tier1[i % tier1.length];
      final b = tier1[(i * 5 + 2) % tier1.length];
      if (a.clubId == b.clubId) continue;
      final marker = a.sheet.startingXi[2];
      final told = _told(a, some: {marker: PlayerInstruction.manMark});
      final s = MatchSession(rules: rules, home: told, away: b, seed: 7300 + i);
      final targets = s.markedBy(0);
      expect(targets, hasLength(1));
      final target = targets.first;
      final r = s.finish();
      final r0 = MatchEngine(rules).simulate(a, b, seed: 7300 + i);
      for (final (res, marked) in [(r, true), (r0, false)]) {
        for (final e in res.events) {
          for (final st in e.steps) {
            if (st.player != target) continue;
            if (marked) {
              allMarked++;
              if (st.won) wonMarked++;
            } else {
              allFree++;
              if (st.won) wonFree++;
            }
          }
        }
      }
    }
    final m = wonMarked / allMarked;
    final f = wonFree / allFree;
    stdout.writeln(
      'INSTRUCTION-REPORT marked player wins ${(m * 100).toStringAsFixed(1)} % '
      'of his steps, free ${(f * 100).toStringAsFixed(1)} %',
    );
    expect(m, lessThan(f));
  });

  test('instructions in the match are recorded and replay the same', () {
    final a = tier1[0];
    final b = tier1[1];
    MatchSession make() =>
        MatchSession(rules: rules, home: a, away: b, seed: 99);
    final s = make();
    final id = a.sheet.startingXi[5];
    s.advanceTo(30);
    s.instruct(0, id, PlayerInstruction.shootMore);
    s.instruct(0, id, PlayerInstruction.shootMore);
    s.advanceTo(70);
    s.teamInstructions(0, wing: Wing.right, wasteTime: true);
    s.instruct(0, id, null);
    expect(s.actions, hasLength(3));
    expect(s.sheetOf(0).instructions, isEmpty);
    expect(s.sheetOf(0).wing, Wing.right);
    final json = [for (final x in s.actions) x.toJson()];
    final r = s.finish();
    final again = make()
      ..replay([for (final j in json) SessionAction.fromJson(j)]);
    final r2 = again.finish();
    expect(r2.homeGoals, r.homeGoals);
    expect(r2.awayGoals, r.awayGoals);
    expect(r2.events.length, r.events.length);
  });
}
