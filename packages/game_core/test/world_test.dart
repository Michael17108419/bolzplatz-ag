import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

final Rules _rules = Rules.parse(
  File('../../rules/rules_2026_27.json').readAsStringSync(),
).valueOrNull!;

final ClubCatalog _catalog = ClubCatalog.parse(
  File('../../tools/data/vereine_2026_27.csv').readAsStringSync(),
).valueOrNull!;

final NameLists _names = NameLists.fromJson(
  File('../../data/names_de.json').readAsStringSync(),
);

World _world({int? seed}) {
  final result = WorldGenerator.generate(
    rules: _rules,
    catalog: _catalog,
    names: _names,
    seed: seed,
  );
  expect(result.errorOrNull, isNull);
  return result.valueOrNull!;
}

final World _shared = _world();

void main() {
  test('world has 206 clubs, 4,738 players and 206 coaches', () {
    expect(_shared.clubs, hasLength(206));
    expect(_shared.players, hasLength(206 * 23));
    expect(_shared.coaches, hasLength(206));
    expect(_shared.leagues, hasLength(8));
    expect(_shared.leagueSeasons, hasLength(8));
    expect(_shared.seed, _rules.world.seed);
  });

  test('every club has a full squad with the template positions', () {
    final byClub = <ClubId, List<Player>>{};
    for (final p in _shared.players) {
      (byClub[p.clubId!] ??= []).add(p);
    }
    expect(byClub, hasLength(206));
    for (final squad in byClub.values) {
      expect(squad, hasLength(23));
      for (final e in _rules.generator.squadTemplate.entries) {
        expect(squad.where((p) => p.position == e.key), hasLength(e.value));
      }
    }
  });

  test('player ids and full names are unique, blocked names are absent', () {
    expect(_shared.players.map((p) => p.id).toSet(), hasLength(4738));
    final names = _shared.players.map((p) => p.displayName).toList();
    expect(names.toSet(), hasLength(names.length));
    expect(names.where(_names.blocked.contains), isEmpty);
  });

  test('every player has a valid contract with their club', () {
    final start = _shared.season.start;
    for (final p in _shared.players) {
      final c = p.contract!;
      expect(c.clubId, p.clubId);
      expect(c.playerId, p.id);
      expect(c.start.isAfter(start), isFalse);
      expect(c.end.isAfter(start), isTrue);
      expect(c.end.year, inInclusiveRange(2027, 2030));
      expect(c.baseSalaryPerYear, greaterThan(0));
    }
  });

  test('salaries fall from the first league to the pool', () {
    double mean(int tier) {
      final ids = _catalog.entries
          .where((e) => e.tier == tier)
          .map((e) => e.id)
          .toSet();
      final list = _shared.players.where((p) => ids.contains(p.clubId));
      return list
              .map((p) => p.contract!.baseSalaryPerYear)
              .reduce((a, b) => a + b) /
          list.length;
    }

    for (var tier = 1; tier < 5; tier++) {
      expect(mean(tier), greaterThan(mean(tier + 1)));
    }
  });

  test('coaches belong to their club and have four skills', () {
    for (final c in _shared.coaches) {
      expect(c.clubId!.value, c.id.value);
      expect(c.skills.keys, [
        'tactical_knowledge',
        'charisma',
        'negotiation',
        'talent_eye',
      ]);
    }
  });

  test('leagues are full and pools hold 12 clubs per region', () {
    for (final ls in _shared.leagueSeasons) {
      expect(ls.clubIds, hasLength(ls.league.teamCount));
    }
    for (final region in Region.values) {
      expect(_shared.pools[region], hasLength(12));
    }
  });

  test('the same seed gives the same world text, another seed does not', () {
    final a = WorldJson.encode(_shared);
    expect(WorldJson.encode(_world()), a);
    expect(WorldJson.encode(_world(seed: 99)), isNot(a));
  });

  test('the world text decodes to the same world', () {
    final text = WorldJson.encode(_shared);
    final back = WorldJson.decode(text);
    expect(back.players, hasLength(4738));
    expect(WorldJson.encode(back), text);
    final p = _shared.players[100];
    final q = back.players[100];
    expect(q.attributes, p.attributes);
    expect(q.contract!.end, p.contract!.end);
    expect(q.traits, p.traits);
    expect(q.abilities, p.abilities);
  });

  test('a broken world text is rejected with a FormatException', () {
    expect(
      () => WorldJson.decode('{"format_version": 9}'),
      throwsFormatException,
    );
    expect(() => WorldJson.decode('[]'), throwsFormatException);
  });

  test('the world fits the league pyramid', () {
    final standings = {
      for (final ls in _shared.leagueSeasons) ls.league.id: ls.clubIds,
    };
    final result = PyramidTransition.run(
      _rules,
      PyramidInput(
        standings: standings,
        clubRegion: _catalog.regionOfClub,
        pools: _shared.pools,
        cycleYear: 0,
      ),
      (higher, lower) => higher,
    );
    expect(result.errorOrNull, isNull);
  });

  test('the shipped start world file is valid and complete', () {
    final text = File('../../data/world_2026_27.json').readAsStringSync();
    final world = WorldJson.decode(text);
    expect(world.clubs, hasLength(206));
    expect(world.players, hasLength(4738));
    expect(world.coaches, hasLength(206));
    expect(world.players.map((p) => p.id).toSet(), hasLength(4738));
    expect(
      world.players.map((p) => p.displayName).toSet(),
      hasLength(4738),
    );
    expect(world.players.every((p) => p.contract != null), isTrue);
    for (final ls in world.leagueSeasons) {
      expect(ls.clubIds, hasLength(ls.league.teamCount));
    }
  });
}
