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

  ProviderContainer start(_Repo repo) {
    final c = ProviderContainer(
      overrides: [
        worldLoaderProvider.overrideWithValue(() async => loaded),
        saveRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    final trainer = TrainerFactory.create(
      rules: loaded.rules,
      name: 'Hans Test',
      appearance: const TrainerAppearance(),
      backstoryId: loaded.rules.career.backstories.first.id,
      seed: 5,
    );
    final offers = loaded.offerGenerator.generate(trainer: trainer, seed: 5);
    c
        .read(careerProvider.notifier)
        .start(trainer: trainer, offer: offers.offers.first, seed: 5);
    return c;
  }

  test('the plan starts with the suggestion and keeps the rule', () async {
    final c = start(_Repo());
    await c.read(loadedWorldProvider.future);
    c.read(lineupProvider);
    final check = c.read(vacationCheckProvider)!;
    expect(check.kept, isTrue);
    expect(check.total, check.minTotal);
  });

  test('editing the plan changes the check; only allowed days count', () async {
    final c = start(_Repo());
    await c.read(loadedWorldProvider.future);
    c.read(lineupProvider);
    final notifier = c.read(vacationProvider.notifier);
    notifier.clear();
    expect(c.read(vacationCheckProvider)!.total, 0);
    final today = c.read(todayProvider)!;
    final allowed = c.read(vacationAllowedProvider);
    final day = [
      for (var i = 0; i < 300; i++)
        if (allowed.contains(today.plusDays(i).epochDay)) today.plusDays(i),
    ].first;
    notifier.toggle(day);
    expect(c.read(vacationProvider), contains(day.epochDay));
    // A Sunday is never allowed.
    var sunday = today;
    while (sunday.weekday != 7) {
      sunday = sunday.plusDays(1);
    }
    notifier.toggle(sunday);
    expect(c.read(vacationProvider), isNot(contains(sunday.epochDay)));
    notifier.useSuggestion();
    expect(c.read(vacationCheckProvider)!.kept, isTrue);
  });

  test('appointments become mails when they are due', () async {
    final c = start(_Repo());
    await c.read(loadedWorldProvider.future);
    c.read(lineupProvider);
    final all = c.read(appointmentsProvider);
    expect(all, isNotEmpty);
    final before = c.read(inboxIdsProvider).length;
    final season = c.read(seasonProvider.notifier);
    for (var i = 0; i < 20; i++) {
      final step = season.advanceDay();
      if (step == DayStep.ownMatch) break;
    }
    expect(c.read(inboxIdsProvider).length, greaterThanOrEqualTo(before));
    expect(c.read(inboxIdsProvider).last, 'news');
  });

  test('the vacation plan survives saving and loading', () async {
    final repo = _Repo();
    final a = start(repo);
    await a.read(loadedWorldProvider.future);
    a.read(lineupProvider);
    a.read(vacationProvider.notifier).clear();
    expect(await a.read(saveServiceProvider).save('1'), isTrue);
    final data = SaveData.tryParse(repo.files['1']!)!;
    expect(data.vacation, isEmpty);

    final b = ProviderContainer(
      overrides: [
        worldLoaderProvider.overrideWithValue(() async => loaded),
        saveRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(b.dispose);
    await b.read(loadedWorldProvider.future);
    expect(await b.read(saveServiceProvider).load(data), isTrue);
    expect(b.read(vacationProvider), isEmpty);
  });
}
