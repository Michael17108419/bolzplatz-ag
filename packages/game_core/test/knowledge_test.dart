import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Step 11d: knowledge of the system and rehearsed set pieces.

final _calendarRules = CalendarRules.fromJsonString(
  File('../../rules/calendar_rules.json').readAsStringSync(),
);
late Rules rules;
late World world;
late List<MatchTeam> tier1;

MatchTeam _with(
  MatchTeam t, {
  double known = 50,
  (double, double) setPieces = (50, 50),
}) => MatchTeam(
  clubId: t.clubId,
  name: t.name,
  squad: t.squad,
  sheet: t.sheet,
  systemKnowledge: {t.sheet.systemId: known},
  setPieces: setPieces,
);

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
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

  test('a well known system and rehearsed set pieces pay (report)', () {
    var known = 0;
    var unknown = 0;
    var setGood = 0;
    var setPoor = 0;
    for (var i = 0; i < 200; i++) {
      final a = tier1[i % tier1.length];
      final b = tier1[(i * 7 + 3) % tier1.length];
      final r1 = MatchEngine(rules).simulate(
        _with(a, known: 95),
        _with(b),
        seed: 3300 + i,
      );
      final r2 = MatchEngine(rules).simulate(
        _with(a, known: 5),
        _with(b),
        seed: 3300 + i,
      );
      known += r1.homeGoals - r1.awayGoals;
      unknown += r2.homeGoals - r2.awayGoals;
      final s1 = MatchEngine(rules).simulate(
        _with(a, setPieces: (95, 95)),
        _with(b),
        seed: 3500 + i,
      );
      final s2 = MatchEngine(rules).simulate(
        _with(a, setPieces: (5, 5)),
        _with(b),
        seed: 3500 + i,
      );
      setGood += s1.homeGoals - s1.awayGoals;
      setPoor += s2.homeGoals - s2.awayGoals;
    }
    stdout.writeln(
      'KNOWLEDGE-REPORT goal difference known=$known unknown=$unknown '
      'set pieces good=$setGood poor=$setPoor (200 games)',
    );
    expect(known, greaterThan(unknown));
    expect(setGood, greaterThan(setPoor));
  });

  test('training the system and set pieces raises them, other systems '
      'fade (report)', () {
    final state = SeasonState.fromWorld(world);
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    final club = state.members[top]!.first;
    final runner = SeasonRunner(rules, calendarRules: _calendarRules);
    final run = runner.begin(state, seed: 93, humanClubs: {club});
    final start = Season(state.startYear).start.epochDay;
    final day = TrainingDay(const [
      TrainingSession('system', Intensity.normal),
      TrainingSession('set_pieces_attack', Intensity.normal),
      TrainingSession('set_pieces_defence', Intensity.normal),
    ]);
    for (var d = start; d < start + 200; d++) {
      runner.setTrainingDay(club, d, day);
    }
    // The first days of the season are lower leagues and cups: play on
    // until the club has some matches behind it.
    for (var i = 0; i < 45 && !run.isOver; i++) {
      runner.completeDay(run, runner.openDay(run));
    }
    final today = run.timeline.days[run.dayIndex].date.epochDay;
    runner.freshnessOf(state.squads[club]!.first.id, club: club, epochDay: today);
    final knowledge = runner.systemKnowledgeOf(club);
    final (att, def) = runner.setPiecesOf(club);
    stdout.writeln(
      'KNOWLEDGE-REPORT systems=${{for (final e in knowledge.entries) e.key: e.value.round()}} '
      'set pieces=${att.round()}/${def.round()}',
    );
    final best = knowledge.values.reduce((a, b) => a > b ? a : b);
    expect(best, greaterThan(rules.season.training['tact_start']));
    expect(att, greaterThan(rules.season.training['sp_start']));
    expect(def, greaterThan(rules.season.training['sp_start']));
  });
}
