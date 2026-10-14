import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

String _csv() =>
    File('../../tools/data/vereine_2026_27.csv').readAsStringSync();

final Rules _rules = Rules.parse(
  File('../../rules/rules_2026_27.json').readAsStringSync(),
).valueOrNull!;

void main() {
  test('the reviewed club list loads: 206 clubs with fixed ids', () {
    final result = ClubCatalog.parse(_csv());
    expect(result.errorOrNull, isNull);
    final catalog = result.valueOrNull!;
    expect(catalog.entries, hasLength(206));
    expect(catalog.entries.first.id, const ClubId(1));
    expect(catalog.entries.last.id, const ClubId(206));
    expect(catalog.entries.first.name, 'FC Monopol München');
  });

  test('every league tier and region has the right number of clubs', () {
    final catalog = ClubCatalog.parse(_csv()).valueOrNull!;
    for (final region in Region.values) {
      expect(
        catalog.entries.where((e) => e.tier == 4 && e.region == region),
        hasLength(18),
      );
      expect(catalog.pools[region], hasLength(12));
    }
  });

  test('clubs get the league from the rules, pool clubs none', () {
    final catalog = ClubCatalog.parse(_csv()).valueOrNull!;
    final clubs = catalog.clubs(_rules).valueOrNull!;
    expect(clubs, hasLength(206));
    expect(clubs.where((c) => c.leagueId == null), hasLength(60));
    final perLeague = <LeagueId, int>{};
    for (final c in clubs) {
      final id = c.leagueId;
      if (id != null) perLeague[id] = (perLeague[id] ?? 0) + 1;
    }
    for (final l in _rules.leagues) {
      expect(perLeague[LeagueId(l.id)], l.teamCount, reason: l.key);
    }
  });

  test('every club has a region, also in the first three tiers', () {
    final catalog = ClubCatalog.parse(_csv()).valueOrNull!;
    expect(catalog.regionOfClub, hasLength(206));
    final munich = catalog.entries.firstWhere((e) => e.place == 'München');
    expect(munich.region, Region.bayern);
    final dortmund = catalog.entries.firstWhere((e) => e.place == 'Dortmund');
    expect(dortmund.region, Region.west);
  });

  test('club names are unique and second teams are marked', () {
    final catalog = ClubCatalog.parse(_csv()).valueOrNull!;
    expect(catalog.entries.map((e) => e.name).toSet(), hasLength(206));
    expect(catalog.entries.where((e) => e.secondTeam), isNotEmpty);
  });

  test('catalog and pyramid fit together', () {
    final catalog = ClubCatalog.parse(_csv()).valueOrNull!;
    final clubs = catalog.clubs(_rules).valueOrNull!;
    final standings = <LeagueId, List<ClubId>>{};
    for (final c in clubs) {
      final id = c.leagueId;
      if (id != null) (standings[id] ??= []).add(c.id);
    }
    final result = PyramidTransition.run(
      _rules,
      PyramidInput(
        standings: standings,
        clubRegion: catalog.regionOfClub,
        pools: catalog.pools,
        cycleYear: 0,
      ),
      (higher, lower) => higher,
    );
    expect(result.errorOrNull, isNull);
  });

  test('rejects a missing column and a wrong club count', () {
    expect(ClubCatalog.parse('Ebene;Ort\n1;X').isErr, isTrue);
    final lines = _csv().split('\n');
    final shortened = lines.take(lines.length - 3).join('\n');
    expect(ClubCatalog.parse(shortened).isErr, isTrue);
  });

  test('parses quoted fields, CRLF and a byte order mark', () {
    const text =
        '﻿Ebene;Fiktiver Verein;Ort;Zweitmannschaft;Heimatregion\r\n'
        '1;"FC ""Test""; Nord";Ort;Nein;nord\r\n';
    final result = ClubCatalog.parse(text);
    // Counts do not match, but the error must come from the count check.
    expect(result.errorOrNull?.message, contains('Tier'));
  });
}
