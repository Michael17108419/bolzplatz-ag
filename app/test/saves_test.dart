import 'dart:io';

import 'package:bolzplatz_app/game/career.dart';
import 'package:bolzplatz_app/game/lineup.dart';
import 'package:bolzplatz_app/game/loaded_world.dart';
import 'package:bolzplatz_app/game/saves.dart';
import 'package:bolzplatz_app/game/season_game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

class _MemoryRepository implements SaveRepository {
  final Map<String, String> files = {};

  @override
  Future<String?> read(String slot) async => files[slot];

  @override
  Future<void> write(String slot, String text) async => files[slot] = text;

  @override
  Future<void> delete(String slot) async => files.remove(slot);
}

LoadedWorld _load() => LoadedWorld.fromTexts(
  File('../data/world_2026_27.json').readAsStringSync(),
  File('../rules/rules_2026_27.json').readAsStringSync(),
  File('../data/names_de.json').readAsStringSync(),
  File('../rules/calendar_rules.json').readAsStringSync(),
);

ProviderContainer _container(LoadedWorld loaded, _MemoryRepository repo) =>
    ProviderContainer(
      overrides: [
        worldLoaderProvider.overrideWithValue(() async => loaded),
        saveRepositoryProvider.overrideWithValue(repo),
      ],
    );

/// Plays one own match, with a substitution and a tactic change by hand.
void _playMatch(ProviderContainer c) {
  final season = c.read(seasonProvider.notifier);
  final own = season.openNext();
  expect(own, isNotNull);
  final session = own!.session!;
  final side = own.fixture.home == c.read(careerProvider)!.clubId ? 0 : 1;
  session.advanceTo(40);
  final squad = {
    for (final p in c.read(loadedWorldProvider).value!.world.players) p.id: p,
  };
  final off = session
      .onPitch(side)
      .firstWhere((id) => !squad[id]!.position.isGoalkeeper);
  final on = session
      .benchOf(side)
      .firstWhere((id) => !squad[id]!.position.isGoalkeeper);
  session.substitute(side, off, on);
  session.advanceTo(66);
  session.changeTactics(side, pressing: 2);
  final result = session.finish();
  season.complete(result);
}

List<String> _table(ProviderContainer c) {
  final game = c.read(seasonProvider)!;
  return [
    for (final e in game.run.tables[game.ownLeague]!.standing)
      '${e.club.value}:${e.played}:${e.points}:${e.goalsFor}:${e.goalsAgainst}',
  ];
}

void main() {
  final loaded = _load();

  Career startCareer(ProviderContainer c) {
    final trainer = TrainerFactory.create(
      rules: loaded.rules,
      name: 'Hans Test',
      appearance: const TrainerAppearance(),
      backstoryId: loaded.rules.career.backstories.first.id,
      seed: 77,
    );
    final offers = loaded.offerGenerator.generate(trainer: trainer, seed: 77);
    c
        .read(careerProvider.notifier)
        .start(trainer: trainer, offer: offers.offers.first, seed: 77);
    return c.read(careerProvider)!;
  }

  test('a saved game loads to exactly the same world', () async {
    final repo = _MemoryRepository();
    final a = _container(loaded, repo);
    addTearDown(a.dispose);
    await a.read(loadedWorldProvider.future);
    startCareer(a);
    a.read(lineupProvider);
    final season = a.read(seasonProvider.notifier);
    _playMatch(a);
    expect(season.advanceDay(), DayStep.played);
    expect(season.advanceDay(), isNot(DayStep.seasonOver));
    _playMatch(a);

    final service = a.read(saveServiceProvider);
    expect(await service.save('2'), isTrue);
    final text = repo.files['2']!;
    final data = SaveData.tryParse(text);
    expect(data, isNotNull);
    expect(data!.trainerName, 'Hans Test');

    final before = a.read(seasonProvider)!;
    final b = _container(loaded, repo);
    addTearDown(b.dispose);
    await b.read(loadedWorldProvider.future);
    expect(await b.read(saveServiceProvider).load(data), isTrue);
    final after = b.read(seasonProvider)!;

    expect(after.today, before.today);
    expect(after.played, before.played);
    expect(_table(b), _table(a));
    expect(b.read(careerProvider)!.clubId, a.read(careerProvider)!.clubId);
    expect(b.read(careerProvider)!.trainer.name, 'Hans Test');
    expect(
      b.read(lineupProvider)!.sheet.startingXi,
      a.read(lineupProvider)!.sheet.startingXi,
    );

    // The loaded game goes on like the original.
    _playMatch(a);
    _playMatch(b);
    expect(_table(b), _table(a));
    expect(b.read(seasonProvider)!.today, a.read(seasonProvider)!.today);
  });

  test('talks with a player and team talks load to the same moods '
      '(step 10f3)', () async {
    final repo = _MemoryRepository();
    final a = _container(loaded, repo);
    addTearDown(a.dispose);
    await a.read(loadedWorldProvider.future);
    final career = startCareer(a);
    a.read(lineupProvider);
    final season = a.read(seasonProvider.notifier);
    final squad = a.read(seasonProvider)!.run.state.squads[career.clubId]!;
    final promised = squad.last.id;
    expect(season.talkTo(promised, PlayerTalk.promise), 1);
    expect(season.talkTo(squad.first.id, PlayerTalk.warn), isNull);
    expect(a.read(seasonProvider)!.runner.hasPromise(promised), isTrue);
    final own = season.openNext()!;
    final session = own.session!;
    final side = own.fixture.home == career.clubId ? 0 : 1;
    expect(session.teamTalk(side, TeamTalk.fire), isNotNull);
    while (!(session.inBreak && session.minute > 0)) {
      session.advanceTo(session.minute + 1);
    }
    expect(session.teamTalk(side, TeamTalk.calm), isNotNull);
    season.complete(session.finish());
    expect(season.advanceDay(), DayStep.played);

    final service = a.read(saveServiceProvider);
    expect(await service.save('3'), isTrue);
    final data = SaveData.tryParse(repo.files['3']!)!;
    final b = _container(loaded, repo);
    addTearDown(b.dispose);
    await b.read(loadedWorldProvider.future);
    expect(await b.read(saveServiceProvider).load(data), isTrue);
    final ra = a.read(seasonProvider)!.runner;
    final rb = b.read(seasonProvider)!.runner;
    for (final p in squad) {
      expect(rb.moodOf(p.id), ra.moodOf(p.id), reason: '${p.id.value}');
    }
    expect(rb.hasPromise(promised), ra.hasPromise(promised));
    expect(_table(b), _table(a));
  });

  test('training days load to the same freshness (step 11a)', () async {
    final repo = _MemoryRepository();
    final a = _container(loaded, repo);
    addTearDown(a.dispose);
    await a.read(loadedWorldProvider.future);
    final career = startCareer(a);
    a.read(lineupProvider);
    final season = a.read(seasonProvider.notifier);
    final today = a.read(seasonProvider)!.today.epochDay;
    final hard = TrainingDay(const [
      TrainingSession('endurance', Intensity.hard),
      TrainingSession('pressing', Intensity.hard),
    ]);
    for (var d = today; d < today + 5; d++) {
      season.setTrainingDay(d, hard);
    }
    _playMatch(a);
    expect(season.advanceDay(), DayStep.played);
    final service = a.read(saveServiceProvider);
    expect(await service.save('2'), isTrue);
    final data = SaveData.tryParse(repo.files['2']!)!;
    final b = _container(loaded, repo);
    addTearDown(b.dispose);
    await b.read(loadedWorldProvider.future);
    expect(await b.read(saveServiceProvider).load(data), isTrue);
    final ga = a.read(seasonProvider)!;
    final gb = b.read(seasonProvider)!;
    for (final p in ga.run.state.squads[career.clubId]!) {
      expect(
        gb.runner.freshnessOf(
          p.id,
          club: career.clubId,
          epochDay: gb.today.epochDay,
        ),
        ga.runner.freshnessOf(
          p.id,
          club: career.clubId,
          epochDay: ga.today.epochDay,
        ),
        reason: '${p.id.value}',
      );
    }
    expect(_table(b), _table(a));
  });

  test('the licence question and a course load the same (step 11e)', () async {
    final repo = _MemoryRepository();
    final a = _container(loaded, repo);
    addTearDown(a.dispose);
    await a.read(loadedWorldProvider.future);
    final career = startCareer(a);
    a.read(lineupProvider);
    final season = a.read(seasonProvider.notifier);
    final game = a.read(seasonProvider)!;
    final runner = game.runner;
    final club = career.clubId;
    if (runner.licenceMissing(club) != null) {
      expect(season.setLicenceCover(LicenceCover.strawMan), isTrue);
      expect(season.setLicenceCover(LicenceCover.waiver), isFalse);
    }
    int? day;
    for (final w in runner.courseWindowsOf(club)) {
      for (var d = w.$1; d <= w.$2 && day == null; d++) {
        if (d > game.today.epochDay && runner.courseBlock(club, d) == null) {
          day = d;
        }
      }
    }
    if (day != null) {
      expect(season.bookCourse(day, ManagerValue.charisma), isTrue);
    }
    _playMatch(a);
    expect(season.advanceDay(), DayStep.played);
    expect(await a.read(saveServiceProvider).save('2'), isTrue);
    final data = SaveData.tryParse(repo.files['2']!)!;
    final b = _container(loaded, repo);
    addTearDown(b.dispose);
    await b.read(loadedWorldProvider.future);
    expect(await b.read(saveServiceProvider).load(data), isTrue);
    final ga = a.read(seasonProvider)!;
    final gb = b.read(seasonProvider)!;
    expect(
      gb.runner.progressOf(club)!.cover,
      ga.runner.progressOf(club)!.cover,
    );
    expect(
      gb.runner.progressOf(club)!.courses.length,
      ga.runner.progressOf(club)!.courses.length,
    );
    expect(
      gb.runner.trainerOf(club)!.toJson(),
      ga.runner.trainerOf(club)!.toJson(),
    );
    expect(b.read(careerProvider)!.trainer.licence, career.trainer.licence);
  });

  test('a preview that is only open is not saved', () async {
    final repo = _MemoryRepository();
    final c = _container(loaded, repo);
    addTearDown(c.dispose);
    await c.read(loadedWorldProvider.future);
    startCareer(c);
    c.read(lineupProvider);
    c.read(seasonProvider.notifier).openNext();
    expect(await c.read(saveServiceProvider).save('1'), isTrue);
    final data = SaveData.tryParse(repo.files['1']!)!;
    expect(data.live, isNull);
    expect(data.log, isEmpty);
  });

  test('a match under way is saved and goes on from its minute', () async {
    final repo = _MemoryRepository();
    final a = _container(loaded, repo);
    addTearDown(a.dispose);
    await a.read(loadedWorldProvider.future);
    startCareer(a);
    a.read(lineupProvider);
    _playMatch(a);
    a.read(seasonProvider.notifier).advanceDay();
    final own = a.read(seasonProvider.notifier).openNext()!;
    final session = own.session!;
    final side = own.fixture.home == a.read(careerProvider)!.clubId ? 0 : 1;
    session.advanceTo(38);
    final players = {
      for (final p in a.read(loadedWorldProvider).value!.world.players) p.id: p,
    };
    final off = session
        .onPitch(side)
        .firstWhere((id) => !players[id]!.position.isGoalkeeper);
    final on = session
        .benchOf(side)
        .firstWhere((id) => !players[id]!.position.isGoalkeeper);
    session.substitute(side, off, on);
    session.advanceTo(57);

    expect(await a.read(saveServiceProvider).save('1'), isTrue);
    final data = SaveData.tryParse(repo.files['1']!)!;
    expect(data.live, isNotNull);
    expect(data.live!['minute'], 57);

    final b = _container(loaded, repo);
    addTearDown(b.dispose);
    await b.read(loadedWorldProvider.future);
    expect(await b.read(saveServiceProvider).load(data), isTrue);
    expect(b.read(seasonProvider.notifier).resumeLive, isTrue);
    final again = b.read(seasonProvider)!.next!.session!;
    expect(again.minute, 57);
    expect(again.homeGoals, session.homeGoals);
    expect(again.awayGoals, session.awayGoals);
    expect(again.events.length, session.events.length);
    expect(again.actions.length, session.actions.length);

    // Both go on alike: the same result, the same table.
    final r1 = session.finish();
    final r2 = again.finish();
    expect(r2.homeGoals, r1.homeGoals);
    expect(r2.awayGoals, r1.awayGoals);
    a.read(seasonProvider.notifier).complete(r1);
    b.read(seasonProvider.notifier).complete(r2);
    expect(_table(b), _table(a));
  });

  test('the automatic slot is written after a match and after a day', () async {
    final repo = _MemoryRepository();
    final c = _container(loaded, repo);
    addTearDown(c.dispose);
    await c.read(loadedWorldProvider.future);
    startCareer(c);
    c.read(lineupProvider);
    _playMatch(c);
    await Future<void>.delayed(Duration.zero);
    expect(repo.files, contains('auto'));
    final first = SaveData.tryParse(repo.files['auto']!)!;
    c.read(seasonProvider.notifier).advanceDay();
    await Future<void>.delayed(Duration.zero);
    final second = SaveData.tryParse(repo.files['auto']!)!;
    expect(second.log.length, first.log.length + 1);
    expect(second.date, first.date.plusDays(1));
  });

  test('slots show empty, saved and unreadable files', () async {
    final repo = _MemoryRepository();
    final c = _container(loaded, repo);
    addTearDown(c.dispose);
    await c.read(loadedWorldProvider.future);
    startCareer(c);
    c.read(lineupProvider);
    c.read(seasonProvider);
    await c.read(saveServiceProvider).save('1');
    repo.files['3'] = '{"version": 99}';
    final slots = await c.read(saveServiceProvider).slots();
    expect(slots.map((s) => s.slot), ['auto', '1', '2', '3']);
    expect(slots[0].isEmpty, isTrue);
    expect(slots[1].data, isNotNull);
    expect(slots[2].isEmpty, isTrue);
    expect(slots[3].unreadable, isTrue);
  });
}
