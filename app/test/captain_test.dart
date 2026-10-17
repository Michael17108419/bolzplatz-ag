import 'dart:io';

import 'package:bolzplatz_app/game/career.dart';
import 'package:bolzplatz_app/game/lineup.dart';
import 'package:bolzplatz_app/game/loaded_world.dart';
import 'package:bolzplatz_app/game/saves.dart';
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

  test('the captain is named, kept in the save and can be cleared', () async {
    final repo = _Repo();
    final a = start(repo);
    await a.read(loadedWorldProvider.future);
    final sheet = a.read(lineupProvider)!.sheet;
    final named = sheet.startingXi[4];
    a.read(lineupProvider.notifier).setCaptain(named);
    expect(a.read(lineupProvider)!.sheet.captain, named);
    expect(await a.read(saveServiceProvider).save('1'), isTrue);

    final b = ProviderContainer(
      overrides: [
        worldLoaderProvider.overrideWithValue(() async => loaded),
        saveRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(b.dispose);
    await b.read(loadedWorldProvider.future);
    final data = SaveData.tryParse(repo.files['1']!)!;
    expect(await b.read(saveServiceProvider).load(data), isTrue);
    expect(b.read(lineupProvider)!.sheet.captain, named);

    b.read(lineupProvider.notifier).setCaptain(null);
    expect(b.read(lineupProvider)!.sheet.captain, isNull);
  });
}
