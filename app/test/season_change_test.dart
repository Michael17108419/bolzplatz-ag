import 'dart:io';

import 'package:bolzplatz_app/game/career.dart';
import 'package:bolzplatz_app/game/lineup.dart';
import 'package:bolzplatz_app/game/loaded_world.dart';
import 'package:bolzplatz_app/game/planning.dart';
import 'package:bolzplatz_app/game/saves.dart';
import 'package:bolzplatz_app/game/season_game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

class _Repo implements SaveRepository {
  final Map<String, String> files = {};

  @override
  Future<String?> read(String slot) async => files[slot];

  @override
  Future<void> write(String slot, String text) async => files[slot] = text;

  @override
  Future<void> delete(String slot) async => files.remove(slot);
}

void main() {
  final loaded = LoadedWorld.fromTexts(
    File('../data/world_2026_27.json').readAsStringSync(),
    File('../rules/rules_2026_27.json').readAsStringSync(),
    File('../data/names_de.json').readAsStringSync(),
    File('../rules/calendar_rules.json').readAsStringSync(),
  );

  ProviderContainer container(_Repo repo) {
    final c = ProviderContainer(
      overrides: [
        worldLoaderProvider.overrideWithValue(() async => loaded),
        saveRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Career startCareer(ProviderContainer c) {
    final trainer = TrainerFactory.create(
      rules: loaded.rules,
      name: 'Hans Test',
      appearance: const TrainerAppearance(),
      backstoryId: loaded.rules.career.backstories.first.id,
      seed: 21,
    );
    final offers = loaded.offerGenerator.generate(trainer: trainer, seed: 21);
    c
        .read(careerProvider.notifier)
        .start(trainer: trainer, offer: offers.offers.first, seed: 21);
    return c.read(careerProvider)!;
  }

  /// Plays every match of the club of the season, live, as the player.
  void playSeason(ProviderContainer c) {
    final season = c.read(seasonProvider.notifier);
    while (!c.read(seasonProvider)!.isOver) {
      final own = season.openNext();
      if (own == null) break;
      final session = own.session!;
      if (own.competition == Competition.league) {
        season.complete(session.finish());
      } else {
        season.complete(null, knockout: session.finishKnockout());
      }
    }
  }

  test('a season ends, the next one starts and the world moves on', () async {
    final repo = _Repo();
    final c = container(repo);
    await c.read(loadedWorldProvider.future);
    final career = startCareer(c);
    c.read(lineupProvider);
    playSeason(c);

    final game = c.read(seasonProvider)!;
    expect(game.end, isNotNull);
    expect(game.end!.rank, inInclusiveRange(1, game.end!.teams));
    expect(c.read(inboxIdsProvider), contains(seasonEndId));

    // The days of the summer break run to the end of the season.
    final season = c.read(seasonProvider.notifier);
    expect(season.advanceToEvent({}), DayStep.seasonOver);
    expect(c.read(seasonProvider)!.today, GameDate(2027, 6, 30));

    final end = c.read(seasonProvider)!.end!;
    if (end.review.dismissed || end.nextLeague == null) {
      expect(season.startNextSeason(), isFalse);
      return;
    }
    expect(season.startNextSeason(), isTrue);
    final next = c.read(seasonProvider)!;
    expect(next.today, GameDate(2027, 7, 1));
    expect(next.played, 0);
    expect(next.end, isNull);
    expect(c.read(seasonHistoryProvider), hasLength(1));
    expect(c.read(worldStateProvider)!.startYear, 2027);
    final world = (await c.read(loadedWorldProvider.future)).world;
    expect(world.season.startYear, 2027);
    expect(next.ownLeague, c.read(careerProvider)!.league.id);
    final squad = world.players.where((p) => p.clubId == career.clubId);
    expect(squad.length, greaterThanOrEqualTo(14));

    // The new season can be played.
    final own = season.openNext();
    expect(own, isNotNull);
    season.complete(own!.session!.finish());
    expect(c.read(seasonProvider)!.played, 1);
  });

  test('a saved game of the second season loads to the same world', () async {
    final repo = _Repo();
    final a = container(repo);
    await a.read(loadedWorldProvider.future);
    startCareer(a);
    a.read(lineupProvider);
    playSeason(a);
    final season = a.read(seasonProvider.notifier);
    season.advanceToEvent({});
    final end = a.read(seasonProvider)!.end!;
    if (end.review.dismissed || end.nextLeague == null) return;
    expect(season.startNextSeason(), isTrue);
    await a.read(loadedWorldProvider.future);
    final own = season.openNext()!;
    season.complete(own.session!.finish());

    expect(await a.read(saveServiceProvider).save('1'), isTrue);
    final data = SaveData.tryParse(repo.files['1']!)!;
    expect(data.base, isNotNull);
    expect(data.seasons, hasLength(1));

    final b = container(repo);
    await b.read(loadedWorldProvider.future);
    expect(await b.read(saveServiceProvider).load(data), isTrue);
    final x = a.read(seasonProvider)!;
    final y = b.read(seasonProvider)!;
    expect(y.today, x.today);
    expect(y.played, x.played);
    expect(
      b.read(careerProvider)!.league.id,
      a.read(careerProvider)!.league.id,
    );
    expect(b.read(careerProvider)!.goal, a.read(careerProvider)!.goal);
    expect(b.read(seasonHistoryProvider), hasLength(1));
    List<String> table(SeasonGame g) => [
      for (final e in g.run.tables[g.ownLeague]!.standing)
        '${e.club.value}:${e.played}:${e.points}',
    ];
    expect(table(y), table(x));
  });
}
