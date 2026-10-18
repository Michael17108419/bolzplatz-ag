import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10f3: mood per player, team talks, talks with one player,
// the coach profile.

final _calendarRules = CalendarRules.fromJsonString(
  File('../../rules/calendar_rules.json').readAsStringSync(),
);
late Rules rules;
late World world;
late List<MatchTeam> tier1;

MatchTeam _tuned(
  MatchTeam t, {
  double? mood,
  CoachProfile coach = const CoachProfile(),
  bool auto = true,
}) => MatchTeam(
  clubId: t.clubId,
  name: t.name,
  squad: t.squad,
  sheet: t.sheet,
  mood: {
    if (mood != null)
      for (final p in t.squad) p.id: mood,
  },
  coach: coach,
  autoManage: auto,
);

/// Plays [s] up to the half-time break.
void _toBreak(MatchSession s) {
  while (!(s.inBreak && s.minute > 0) && !s.isFinished) {
    s.advanceTo(s.minute + 1);
  }
}

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

  test('the coach profile: AI coaches follow charisma and tactical '
      'knowledge, a saved trainer without the new values starts at his '
      'charisma', () {
    final coach = world.coaches.first;
    final p = CoachProfile.ofCoach(coach);
    expect(p.charisma, coach.skills['charisma']);
    expect(p.motivation, coach.skills['charisma']);
    expect(p.talk, inInclusiveRange(0.5, 1.5));
    final t = Trainer.fromJson({
      'name': 'Kalle',
      'appearance': const TrainerAppearance().toJson(),
      'backstory': 'pub_landlord',
      'values': {
        for (final v in ManagerValue.values)
          if (v != ManagerValue.motivation && v != ManagerValue.manManagement)
            v.id: v == ManagerValue.charisma ? 77.0 : 40.0,
      },
    });
    expect(t[ManagerValue.motivation], 77);
    expect(t[ManagerValue.manManagement], 77);
    expect(CoachProfile.ofTrainer(t).talk, closeTo(1.27, 0.001));
  });

  test('a happy team plays better than a sulking one (report)', () {
    var happy = 0;
    var sulking = 0;
    for (var i = 0; i < 200; i++) {
      final a = tier1[i % tier1.length];
      final b = tier1[(i * 7 + 3) % tier1.length];
      final up = MatchEngine(rules).simulate(
        _tuned(a, mood: 95),
        _tuned(b),
        seed: 9800 + i,
      );
      final down = MatchEngine(rules).simulate(
        _tuned(a, mood: 15),
        _tuned(b),
        seed: 9800 + i,
      );
      happy += up.homeGoals - up.awayGoals;
      sulking += down.homeGoals - down.awayGoals;
    }
    stdout.writeln(
      'MOOD-REPORT goal difference happy=$happy sulking=$sulking (200 games)',
    );
    expect(happy, greaterThan(sulking));
  });

  test('team talks: once per break, firing up a trailing team lands, '
      'praising it backfires; a replay reads the same', () {
    var fired = 0;
    var praised = 0;
    var checked = 0;
    for (var i = 0; i < 80 && checked < 12; i++) {
      final a = tier1[i % tier1.length];
      final b = tier1[(i * 3 + 5) % tier1.length];
      if (a.clubId == b.clubId) continue;
      MatchSession make() => MatchSession(
        rules: rules,
        // The side of the player: the AI coach would talk at the break.
        home: _tuned(
          a,
          coach: const CoachProfile(charisma: 85, motivation: 85),
          auto: false,
        ),
        away: _tuned(b),
        seed: 7700 + i,
      );
      // Before kick-off: one talk, then no second one.
      final pre = make();
      expect(pre.canTalk(0), isTrue);
      expect(pre.teamTalk(0, TeamTalk.fire), isNotNull);
      expect(pre.canTalk(0), isFalse);
      expect(pre.teamTalk(0, TeamTalk.calm), isNull);
      expect(pre.canTalk(1), isTrue);

      final s = make();
      _toBreak(s);
      if (s.homeGoals >= s.awayGoals) continue;
      checked++;
      fired += s.teamTalk(0, TeamTalk.fire)!;
      final t = make();
      _toBreak(t);
      praised += t.teamTalk(0, TeamTalk.praise)!;
      final r = s.finish();
      final again = make()..replay(s.actions);
      final r2 = again.finish();
      expect(r2.homeGoals, r.homeGoals);
      expect(r2.awayGoals, r.awayGoals);
      expect(
        r.events.where(
          (e) => e.type == MatchEventType.teamTalk && e.side == 0,
        ),
        hasLength(1),
      );
    }
    stdout.writeln(
      'MOOD-REPORT talks behind at the break: fire=$fired praise=$praised '
      '($checked games)',
    );
    expect(checked, greaterThan(3));
    expect(fired, greaterThan(0));
    expect(praised, lessThan(0));
  });

  test('over weeks: winners are happier than losers, a broken promise '
      'hurts, one talk per week (report)', () {
    final coaches = {
      for (final c in world.coaches)
        if (c.clubId != null) c.clubId!: CoachProfile.ofCoach(c),
    };
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    final state = SeasonState.fromWorld(world);
    final club = state.members[top]!.first;
    // The weakest player with little professionalism waits in vain.
    final strength = {
      for (final p in state.squads[club]!) p.id: WorldReport.overall(p, rules),
    };
    final fringe = [...state.squads[club]!]
      ..sort((a, b) => strength[a.id]!.compareTo(strength[b.id]!));
    final waiting = fringe
        .take(5)
        .reduce(
          (a, b) =>
              (a.traits[CharacterTrait.professionalism] ?? 50) <=
                  (b.traits[CharacterTrait.professionalism] ?? 50)
              ? a
              : b,
        )
        .id;

    (SeasonRunner, SeasonRun) season({required bool promise}) {
      final runner = SeasonRunner(rules, calendarRules: _calendarRules);
      final run = runner.begin(state, seed: 61, coaches: coaches);
      final day0 = run.timeline.days.first.date.epochDay;
      if (promise) {
        expect(runner.canTalkTo(club, day0), isTrue);
        expect(
          runner.talkTo(club, waiting, PlayerTalk.promise, day0),
          1,
        );
        expect(runner.hasPromise(waiting), isTrue);
        expect(runner.canTalkTo(club, day0), isFalse);
        expect(runner.talkTo(club, waiting, PlayerTalk.warn, day0), isNull);
        expect(runner.canTalkTo(club, day0 + 7), isTrue);
      }
      var days = 0;
      while (!run.isOver && days < 50) {
        runner.completeDay(run, runner.openDay(run));
        days++;
      }
      return (runner, run);
    }

    final (runner, run) = season(promise: true);
    final (control, _) = season(promise: false);
    final table = run.tables[top]!.standing;
    double mean(Iterable<ClubId> clubs) {
      final moods = [
        for (final c in clubs)
          for (final p in run.state.squads[c]!) runner.moodOf(p.id),
      ];
      return moods.reduce((a, b) => a + b) / moods.length;
    }

    final up = mean(table.take(3).map((e) => e.club));
    final down = mean(table.reversed.take(3).map((e) => e.club));
    final all = [
      for (final c in run.state.members[top]!)
        for (final p in run.state.squads[c]!) runner.moodOf(p.id),
    ]..sort();
    stdout.writeln(
      'MOOD-REPORT top three=${up.toStringAsFixed(1)} '
      'bottom three=${down.toStringAsFixed(1)} '
      'mean=${(all.reduce((a, b) => a + b) / all.length).toStringAsFixed(1)} '
      'min=${all.first.toStringAsFixed(0)} max=${all.last.toStringAsFixed(0)} '
      'promised=${runner.moodOf(waiting).toStringAsFixed(1)} '
      'control=${control.moodOf(waiting).toStringAsFixed(1)}',
    );
    expect(up, greaterThan(down));
    expect(all.last - all.first, greaterThan(15));
    // Neither a league of grumblers nor one of sunshine.
    expect(
      all.reduce((a, b) => a + b) / all.length,
      inInclusiveRange(52, 70),
    );
    expect(runner.hasPromise(waiting), isFalse);
    expect(runner.moodOf(waiting), lessThan(control.moodOf(waiting)));
  });
}
