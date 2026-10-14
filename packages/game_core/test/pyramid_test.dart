import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

final Rules _rules = Rules.parse(
  File('../../rules/rules_2026_27.json').readAsStringSync(),
).valueOrNull!;

LeagueId _lid(int id) => LeagueId(id);

List<ClubId> _clubs(int league, int count) => [
  for (var i = 1; i <= count; i++) ClubId(league * 100 + i),
];

int _regionalLeague(Region r) =>
    _rules.leagues.firstWhere((l) => l.region == r).id;

PyramidInput _input({
  int cycleYear = 0,
  Set<ClubId> unlicensed = const {},
  Map<Region, List<ClubId>>? pools,
}) {
  final standings = <LeagueId, List<ClubId>>{
    for (final l in _rules.leagues) _lid(l.id): _clubs(l.id, l.teamCount),
  };
  final regions = <ClubId, Region>{};
  final l3 = standings[_lid(3)]!;
  for (var i = 0; i < l3.length; i++) {
    regions[l3[i]] = Region.values[i % Region.values.length];
  }
  return PyramidInput(
    standings: standings,
    clubRegion: regions,
    pools:
        pools ??
        {
          for (final r in Region.values)
            r: [for (var j = 0; j < 12; j++) ClubId(9000 + r.index * 20 + j)],
        },
    cycleYear: cycleYear,
    unlicensed: unlicensed,
  );
}

/// Higher club always wins.
ClubId _higher(ClubId a, ClubId b) => a;

/// Lower club always wins.
ClubId _lower(ClubId a, ClubId b) => b;

PyramidResult _run(
  PyramidInput input, [
  ClubId Function(ClubId, ClubId) winner = _higher,
]) {
  final result = PyramidTransition.run(_rules, input, winner);
  expect(result.errorOrNull, isNull);
  return result.valueOrNull!;
}

void main() {
  test('every league keeps its size and no club is lost or duplicated', () {
    for (final cycle in [0, 1, 2]) {
      for (final winner in [_higher, _lower]) {
        final input = _input(cycleYear: cycle);
        final r = _run(input, winner);
        for (final l in _rules.leagues) {
          expect(r.leagues[_lid(l.id)], hasLength(l.teamCount));
        }
        final before = {
          for (final t in input.standings.values) ...t,
          for (final p in input.pools.values) ...p,
        };
        final after = {
          for (final t in r.leagues.values) ...t,
          for (final p in r.pools.values) ...p,
        };
        expect(after, before);
        final inLeagues = [for (final t in r.leagues.values) ...t];
        expect(inLeagues.toSet(), hasLength(inLeagues.length));
      }
    }
  });

  test('direct promotion and relegation in the upper tiers', () {
    final r = _run(_input());
    final l1 = r.leagues[_lid(1)]!.map((c) => c.value).toSet();
    // Places 17 and 18 of the first league are gone, places 1 and 2 of the
    // second league arrived.
    expect(l1.contains(117), isFalse);
    expect(l1.contains(118), isFalse);
    expect(l1.contains(201), isTrue);
    expect(l1.contains(202), isTrue);
    final l2 = r.leagues[_lid(2)]!.map((c) => c.value).toSet();
    expect(l2.containsAll([117, 118, 301, 302]), isTrue);
    expect(l2.contains(217) || l2.contains(218), isFalse);
  });

  test('relegation play-off: the higher club wins and stays', () {
    final r = _run(_input());
    final l1 = r.leagues[_lid(1)]!.map((c) => c.value).toSet();
    final l2 = r.leagues[_lid(2)]!.map((c) => c.value).toSet();
    expect(l1.contains(116), isTrue);
    expect(l2.contains(203), isTrue);
    expect(l2.contains(216), isTrue);
  });

  test('relegation play-off: the lower club wins and swaps places', () {
    final r = _run(_input(), _lower);
    final l1 = r.leagues[_lid(1)]!.map((c) => c.value).toSet();
    final l2 = r.leagues[_lid(2)]!.map((c) => c.value).toSet();
    final l3 = r.leagues[_lid(3)]!.map((c) => c.value).toSet();
    expect(l1.contains(203), isTrue);
    expect(l2.contains(116), isTrue);
    expect(l2.contains(303), isTrue);
    expect(l3.contains(216), isTrue);
  });

  test('last four of the third tier go to their own region', () {
    final r = _run(_input());
    // Clubs 317..320 have regions nordost, west, suedwest, bayern.
    bool inLeague(Region region, int club) =>
        r.leagues[_lid(_regionalLeague(region))]!.contains(ClubId(club));
    expect(inLeague(Region.nordost, 317), isTrue);
    expect(inLeague(Region.west, 318), isTrue);
    expect(inLeague(Region.suedwest, 319), isTrue);
    expect(inLeague(Region.bayern, 320), isTrue);
  });

  test('west and southwest champions are always promoted', () {
    for (final cycle in [0, 1, 2]) {
      final r = _run(_input(cycleYear: cycle));
      final l3 = r.leagues[_lid(3)]!.map((c) => c.value).toSet();
      expect(l3.contains(_regionalLeague(Region.west) * 100 + 1), isTrue);
      expect(l3.contains(_regionalLeague(Region.suedwest) * 100 + 1), isTrue);
    }
  });

  test('three-year cycle: direct promotion goes to the right region', () {
    int champ(Region r) => _regionalLeague(r) * 100 + 1;
    Set<int> l3(int cycle, [ClubId Function(ClubId, ClubId) w = _higher]) =>
        _run(
          _input(cycleYear: cycle),
          w,
        ).leagues[_lid(3)]!.map((c) => c.value).toSet();

    // Year 0: Nordost direct, Nord against Bayern (higher argument is Nord).
    expect(
      l3(0).containsAll([champ(Region.nordost), champ(Region.nord)]),
      isTrue,
    );
    expect(l3(0).contains(champ(Region.bayern)), isFalse);
    expect(l3(0, _lower).contains(champ(Region.bayern)), isTrue);
    expect(l3(0, _lower).contains(champ(Region.nord)), isFalse);
    // Year 1: Nord direct, Nordost against Bayern.
    expect(
      l3(1).containsAll([champ(Region.nord), champ(Region.nordost)]),
      isTrue,
    );
    expect(l3(1).contains(champ(Region.bayern)), isFalse);
    // Year 2: Bayern direct, Nord against Nordost.
    expect(
      l3(2).containsAll([champ(Region.bayern), champ(Region.nord)]),
      isTrue,
    );
    expect(l3(2).contains(champ(Region.nordost)), isFalse);
    expect(l3(2, _lower).contains(champ(Region.nordost)), isTrue);
  });

  test('exactly four clubs rise from the fourth tier', () {
    final r = _run(_input());
    final rises = r.movements.where(
      (m) =>
          m.kind == MovementKind.promotion &&
          m.to == _lid(3) &&
          m.from != _lid(2),
    );
    expect(rises, hasLength(4));
  });

  test('an unlicensed champion is replaced by the next club', () {
    final west = _regionalLeague(Region.west);
    final champion = ClubId(west * 100 + 1);
    final r = _run(_input(unlicensed: {champion}));
    final l3 = r.leagues[_lid(3)]!;
    expect(l3.contains(champion), isFalse);
    expect(l3.contains(ClubId(west * 100 + 2)), isTrue);
    // The unlicensed club is treated as last and ends up in the pool.
    expect(r.pools[Region.west]!.contains(champion), isTrue);
  });

  test('pool keeps order: oldest club is pulled first, new ones go last', () {
    final input = _input();
    final r = _run(input);
    for (final region in Region.values) {
      final before = input.pools[region]!;
      final after = r.pools[region]!;
      final pulled = r.movements
          .where((m) => m.kind == MovementKind.fromPool)
          .where((m) => before.contains(m.club))
          .where((m) => m.to == _lid(_regionalLeague(region)))
          .map((m) => m.club)
          .toList();
      expect(pulled, before.take(pulled.length).toList());
      expect(
        after.take(before.length - pulled.length),
        before.skip(pulled.length),
      );
    }
  });

  test('an empty pool is reported as an error', () {
    final input = _input(pools: {for (final r in Region.values) r: []});
    final result = PyramidTransition.run(_rules, input, _higher);
    expect(result.isErr, isTrue);
  });

  test('incomplete standings are reported as an error', () {
    final input = _input();
    input.standings[_lid(1)]!.removeLast();
    expect(PyramidTransition.run(_rules, input, _higher).isErr, isTrue);
  });

  test('a play-off winner outside the tie is rejected', () {
    final result = PyramidTransition.run(
      _rules,
      _input(),
      (a, b) => const ClubId(1),
    );
    expect(result.isErr, isTrue);
  });

  test('same input gives the same result', () {
    final a = _run(_input(cycleYear: 1), _lower);
    final b = _run(_input(cycleYear: 1), _lower);
    expect(
      [for (final m in a.movements) '${m.club.value}:${m.kind.name}'],
      [for (final m in b.movements) '${m.club.value}:${m.kind.name}'],
    );
  });
}
