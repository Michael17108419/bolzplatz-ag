import 'dart:io';

import 'package:bolzplatz_app/database.dart';
import 'package:bolzplatz_app/repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

/// Milestone M0: create the world, store it, load it again, compare it and
/// measure the time. The timing lines start with "M0-REPORT" so the pipeline
/// can show them.
void main() {
  test('M0: generate, store, load and compare the whole world', () async {
    final watch = Stopwatch()..start();
    final timings = <String, int>{};
    void lap(String label) {
      timings[label] = watch.elapsedMilliseconds;
      watch.reset();
      watch.start();
    }

    final rules = Rules.parse(
      File('../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    final catalog = ClubCatalog.parse(
      File('../tools/data/vereine_2026_27.csv').readAsStringSync(),
    ).valueOrNull!;
    final names = NameLists.fromJson(
      File('../data/names_de.json').readAsStringSync(),
    );
    lap('read rules and lists');

    final generated = WorldGenerator.generate(
      rules: rules,
      catalog: catalog,
      names: names,
    ).valueOrNull!;
    lap('generate world');

    final shippedText = File('../data/world_2026_27.json').readAsStringSync();
    final shipped = WorldJson.decode(shippedText);
    lap('decode shipped world file');

    // The shipped file is the generated world (unless it was corrected by
    // hand, in which case only the counts have to match).
    expect(shipped.players, hasLength(generated.players.length));
    expect(shipped.clubs, hasLength(generated.clubs.length));

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GameRepository(db);

    await repo.saveWorld(shipped);
    lap('save world to database');

    final loaded = await repo.loadWorld();
    lap('load world from database');
    expect(loaded, isNotNull);

    final before = WorldJson.encode(shipped);
    final after = WorldJson.encode(loaded!);
    lap('encode both worlds');
    expect(after, before);

    // Run the loaded world through the pyramid as a last sanity check.
    final standings = {
      for (final ls in loaded.leagueSeasons) ls.league.id: ls.clubIds,
    };
    final next = PyramidTransition.run(
      rules,
      PyramidInput(
        standings: standings,
        clubRegion: catalog.regionOfClub,
        pools: loaded.pools,
        cycleYear: 0,
      ),
      (higher, lower) => higher,
    );
    expect(next.errorOrNull, isNull);
    lap('one season change');

    // ignore: avoid_print
    print(
      'M0-REPORT players=${loaded.players.length} '
      'clubs=${loaded.clubs.length} coaches=${loaded.coaches.length}',
    );
    for (final e in timings.entries) {
      // ignore: avoid_print
      print('M0-REPORT ${e.key}: ${e.value} ms');
    }
    final total = timings.values.fold<int>(0, (a, b) => a + b);
    expect(total, lessThan(120000), reason: 'M0 steps took $total ms');
  });

  test('an empty database has no world', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await GameRepository(db).loadWorld(), isNull);
  });
}
