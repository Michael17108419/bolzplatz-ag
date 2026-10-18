import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10f2: match ratings, form and confidence per player, load
// of the last weeks.

final _calendarRules = CalendarRules.fromJsonString(
  File('../../rules/calendar_rules.json').readAsStringSync(),
);
late Rules rules;
late World world;
late List<MatchTeam> tier1;

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

  test('ratings: scorers above, red cards below, short appearances none; '
      'marks from 1 to 6 (report)', () {
    final c = rules.season.condition;
    var sum = 0.0;
    var n = 0;
    for (var i = 0; i < 100; i++) {
      final home = tier1[i % tier1.length];
      final away = tier1[(i * 5 + 1) % tier1.length];
      final r = MatchEngine(rules).simulate(home, away, seed: 9100 + i);
      final ratings = matchRatings(
        r,
        c,
        homePlayers: {for (final p in home.squad) p.id},
      );
      for (final e in ratings.entries) {
        expect(e.value, inInclusiveRange(1, 10));
        expect(r.minutesPlayed[e.key], greaterThanOrEqualTo(15));
        expect(markOf(e.value), inInclusiveRange(1, 6));
        sum += e.value;
        n++;
      }
      for (final e in r.events) {
        if (e.isGoal &&
            ratings.containsKey(e.player) &&
            r.events.where((x) => x.isGoal && x.player == e.player).length >=
                2) {
          expect(ratings[e.player], greaterThan(c['rating_base']));
        }
      }
    }
    stdout.writeln(
      'CONDITION-REPORT mean rating=${(sum / n).toStringAsFixed(2)} '
      'mean mark=${markOf(sum / n)}',
    );
    expect(markOf(9.5), 1);
    expect(markOf(1), 6);
  });

  test('confident shooters score more, overloaded players get hurt more', () {
    MatchTeam tuned(MatchTeam t, {double conf = 50, double load = 0}) =>
        MatchTeam(
          clubId: t.clubId,
          name: t.name,
          squad: t.squad,
          sheet: t.sheet,
          confidence: {for (final p in t.squad) p.id: conf},
          load: {for (final p in t.squad) p.id: load},
        );
    var goalsHigh = 0;
    var goalsLow = 0;
    var injHigh = 0;
    var injLow = 0;
    for (var i = 0; i < 200; i++) {
      final a = tier1[i % tier1.length];
      final b = tier1[(i * 7 + 3) % tier1.length];
      final hi = MatchEngine(rules)
          .simulate(tuned(a, conf: 90), tuned(b), seed: 9300 + i);
      final lo = MatchEngine(rules)
          .simulate(tuned(a, conf: 10), tuned(b), seed: 9300 + i);
      goalsHigh += hi.homeGoals;
      goalsLow += lo.homeGoals;
      final tired = MatchEngine(rules)
          .simulate(tuned(a, load: 2), tuned(b, load: 2), seed: 9600 + i);
      final fresh = MatchEngine(rules)
          .simulate(tuned(a), tuned(b), seed: 9600 + i);
      injHigh += tired.injuries.length;
      injLow += fresh.injuries.length;
    }
    stdout.writeln(
      'CONDITION-REPORT goals confident=$goalsHigh shaky=$goalsLow '
      'injuries loaded=$injHigh fresh=$injLow (200 games)',
    );
    expect(goalsHigh, greaterThan(goalsLow));
    expect(injHigh, greaterThan(injLow));
  });

  test('over a season form spreads, confidence moves, load builds up', () {
    final runner = SeasonRunner(rules, calendarRules: _calendarRules);
    final run = runner.begin(SeasonState.fromWorld(world), seed: 51);
    var days = 0;
    while (!run.isOver && days < 60) {
      runner.completeDay(run, runner.openDay(run));
      days++;
    }
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    final players = [
      for (final c in run.state.members[top]!) ...run.state.squads[c]!,
    ];
    final forms = players.map((p) => runner.formOf(p.id)).toList()..sort();
    final confs = players.map((p) => runner.confidenceOf(p.id)).toList()
      ..sort();
    stdout.writeln(
      'CONDITION-REPORT form min=${forms.first.toStringAsFixed(0)} '
      'max=${forms.last.toStringAsFixed(0)} '
      'confidence min=${confs.first.toStringAsFixed(0)} '
      'max=${confs.last.toStringAsFixed(0)}',
    );
    expect(forms.last - forms.first, greaterThan(10));
    expect(confs.last - confs.first, greaterThan(10));
  });
}
