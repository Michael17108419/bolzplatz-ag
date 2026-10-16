import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  late Rules rules;
  late World world;

  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
  });

  test('a snapshot gives back the same season state', () {
    final state = SeasonState.fromWorld(world);
    final text = SeasonSnapshot.encode(state);
    final clubs = {for (final c in world.clubs) c.id: c};
    final back = SeasonSnapshot.decode(text, clubs);
    expect(back.startYear, state.startYear);
    expect(back.members.keys, state.members.keys);
    for (final e in state.members.entries) {
      expect(back.members[e.key], e.value);
    }
    expect(back.squads.length, state.squads.length);
    for (final e in state.squads.entries) {
      final other = back.squads[e.key]!;
      expect(other.map((p) => p.id), e.value.map((p) => p.id));
    }
    expect(SeasonSnapshot.encode(back), text);
  });

  test('a snapshot after a season plays on like the original', () {
    final calendar = CalendarRules.fromJsonString(
      File('../../rules/calendar_rules.json').readAsStringSync(),
    );
    final runner = SeasonRunner(rules, calendarRules: calendar);
    final names = NameLists.fromJson(
      File('../../data/names_de.json').readAsStringSync(),
    );
    final first = SeasonState.fromWorld(world);
    final outcome = runner.play(first, seed: 11);
    final next = runner
        .nextSeason(first, outcome, seed: 12, names: names)
        .valueOrNull!;
    final clubs = {for (final c in world.clubs) c.id: c};
    final copy = SeasonSnapshot.decode(SeasonSnapshot.encode(next), clubs);
    final a = runner.play(next, seed: 13);
    final b = runner.play(copy, seed: 13);
    for (final e in a.tables.entries) {
      expect(
        [for (final t in b.tables[e.key]!) t.club],
        [for (final t in e.value) t.club],
      );
      expect(
        [for (final t in b.tables[e.key]!) t.points],
        [for (final t in e.value) t.points],
      );
    }
    final w = SeasonSnapshot.worldOf(next, world);
    expect(w.season.startYear, 2027);
    expect(w.leagueSeasons, hasLength(world.leagues.length));
    expect(w.players.length, next.squads.values.expand((s) => s).length);
  });

  group('season review', () {
    late SeasonReviewer reviewer;
    setUpAll(() => reviewer = SeasonReviewer(rules.season.review));

    SeasonReview review(
      SeasonGoal goal,
      int rank, {
      int teams = 18,
      int change = 0,
      double trust = 0.5,
      double mood = 0.5,
      int seed = 1,
    }) => reviewer.review(
      goal: goal,
      rank: rank,
      teams: teams,
      levelChange: change,
      seed: seed,
      presidentTrust: trust,
      squadMood: mood,
    );

    test('a reached goal never costs the job', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(review(SeasonGoal.title, 1, seed: seed).dismissed, isFalse);
        expect(
          review(SeasonGoal.promotion, 2, change: -1, seed: seed).dismissed,
          isFalse,
        );
        expect(review(SeasonGoal.survival, 12, seed: seed).dismissed, isFalse);
      }
    });

    test('verdicts follow the goal', () {
      expect(review(SeasonGoal.title, 1).verdict, GoalVerdict.reached);
      expect(review(SeasonGoal.title, 2).verdict, GoalVerdict.missed);
      expect(review(SeasonGoal.title, 9).verdict, GoalVerdict.failed);
      expect(
        review(SeasonGoal.promotion, 1, change: -1).verdict,
        GoalVerdict.exceeded,
      );
      expect(review(SeasonGoal.promotion, 5).verdict, GoalVerdict.missed);
      expect(review(SeasonGoal.promotion, 14).verdict, GoalVerdict.failed);
      expect(review(SeasonGoal.noTarget, 2).verdict, GoalVerdict.exceeded);
      expect(review(SeasonGoal.noTarget, 10).verdict, GoalVerdict.reached);
      expect(
        review(SeasonGoal.survival, 17, change: 1).verdict,
        isIn([GoalVerdict.missed, GoalVerdict.failed]),
      );
      expect(review(SeasonGoal.licence, 4).verdict, GoalVerdict.exceeded);
    });

    test('a bigger miss and worse relations raise the risk', () {
      final small = review(SeasonGoal.title, 2);
      final big = review(SeasonGoal.title, 12);
      expect(big.risk, greaterThan(small.risk));
      final bad = review(SeasonGoal.title, 2, trust: 0.1, mood: 0.1);
      final good = review(SeasonGoal.title, 2, trust: 0.9, mood: 0.9);
      expect(bad.risk, greaterThan(small.risk));
      expect(good.risk, lessThan(small.risk));
    });

    test('the same input gives the same verdict', () {
      final a = review(SeasonGoal.title, 8, seed: 5);
      final b = review(SeasonGoal.title, 8, seed: 5);
      expect(a.dismissed, b.dismissed);
      expect(a.risk, b.risk);
    });
  });

  test('a job offer survives a round trip through JSON', () {
    final names = NameLists.fromJson(
      File('../../data/names_de.json').readAsStringSync(),
    );
    final strengths = ClubStrengths.compute(world, rules);
    final generator = OfferGenerator(
      rules: rules,
      world: world,
      names: names,
      strengths: strengths,
    );
    final trainer = TrainerFactory.create(
      rules: rules,
      name: 'Hans Test',
      appearance: const TrainerAppearance(),
      backstoryId: rules.career.backstories.first.id,
      seed: 3,
    );
    final offer = generator.generate(trainer: trainer, seed: 3).offers.first;
    final back = JobOffer.fromJson(
      offer.toJson(),
      clubs: {for (final c in world.clubs) c.id: c},
      leagues: {for (final l in world.leagues) l.id: l},
    );
    expect(back.club.id, offer.club.id);
    expect(back.league.id, offer.league.id);
    expect(back.goal, offer.goal);
    expect(back.budget, offer.budget);
    expect(back.president.name, offer.president.name);
    expect(
      back.president[PresidentTrait.vanity],
      offer.president[PresidentTrait.vanity],
    );
    expect(back.toJson(), offer.toJson());
  });

  test('the goal for a new season follows the strength rank', () {
    expect(
      SeasonReviewer.goalFor(level: 1, strengthRank: 1, teams: 18),
      SeasonGoal.title,
    );
    expect(
      SeasonReviewer.goalFor(level: 2, strengthRank: 2, teams: 18),
      SeasonGoal.promotion,
    );
    expect(
      SeasonReviewer.goalFor(level: 2, strengthRank: 9, teams: 18),
      SeasonGoal.noTarget,
    );
    expect(
      SeasonReviewer.goalFor(level: 3, strengthRank: 18, teams: 20),
      SeasonGoal.survival,
    );
  });
}
