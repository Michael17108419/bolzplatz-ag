import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10f1: types (Doc 06) and the dressing room: rank,
// captain, council, followers, mood and conflicts.

late Rules rules;
late World world;

Player _with(Player p, Map<CharacterTrait, double> set) => p.copyWith(
  traits: {for (final t in CharacterTrait.values) t: set[t] ?? 50},
);

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
  });

  List<Player> squadOf(int i) {
    final club = world.clubs[i].id;
    return [
      for (final p in world.players)
        if (p.clubId == club) p,
    ];
  }

  double strength(Player p) => WorldReport.overall(p, rules);

  test('types follow the rules of Doc 06, at most two', () {
    final r = rules.season.cabin;
    final base = world.players.first;
    expect(
      archetypesOf(
        _with(base, {
          CharacterTrait.egoism: 90,
          CharacterTrait.mediaHunger: 90,
        }),
        r,
      ),
      contains(Archetype.diva),
    );
    expect(
      archetypesOf(
        _with(base, {
          CharacterTrait.temper: 80,
          CharacterTrait.aggression: 80,
          CharacterTrait.ambition: 80,
        }),
        r,
      ),
      containsAll([Archetype.hothead, Archetype.terrier]),
    );
    expect(archetypesOf(_with(base, {}), r), isEmpty);
    var counts = <Archetype, int>{};
    for (final p in world.players) {
      final types = archetypesOf(p, r);
      expect(types.length, lessThanOrEqualTo(2));
      for (final t in types) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final typed = world.players.where((p) => archetypesOf(p, r).isNotEmpty);
    stdout.writeln(
      'CABIN-REPORT typed=${typed.length}/${world.players.length} $counts',
    );
    counts = {};
  });

  test('captain, council of four and followers by rank', () {
    final squad = squadOf(0);
    final captain = squad[3].id;
    final cabin = Cabin.of(
      squad,
      rules.season.cabin,
      today: world.season.start,
      strength: strength,
      captain: captain,
    );
    expect(cabin.roles[captain], CabinRole.captain);
    expect(cabin.council, hasLength(rules.season.cabin.councilSize));
    expect(cabin.council, isNot(contains(captain)));
    final lowest = cabin.council
        .map((id) => cabin.ranks[id]!)
        .reduce((a, b) => a < b ? a : b);
    for (final p in squad) {
      if (cabin.roles[p.id] == CabinRole.follower) {
        expect(cabin.ranks[p.id], lessThanOrEqualTo(lowest));
      }
    }
    expect(cabin.mood, inInclusiveRange(0, 1));
  });

  test('a fitting captain lifts the room, a power struggle and party '
      'animals in the council drag it, a diva outside is unhappy', () {
    final squad = squadOf(1);
    final r = rules.season.cabin;
    Cabin room(List<Player> players, PlayerId? captain) => Cabin.of(
      players,
      r,
      today: world.season.start,
      strength: strength,
      captain: captain,
    );
    final plain = [for (final p in squad) _with(p, {})];
    final neutral = room(plain, plain.first.id);
    final leader = _with(plain.first, {
      CharacterTrait.leadership: 90,
      CharacterTrait.loyalty: 90,
      CharacterTrait.professionalism: 70,
    });
    final good = room([leader, ...plain.skip(1)], leader.id);
    expect(good.mood, greaterThan(neutral.mood));

    // Four strong leaders who love parties take the council.
    final wild = [
      for (var i = 0; i < plain.length; i++)
        i < 4
            ? _with(plain[i], {
                CharacterTrait.leadership: 95,
                CharacterTrait.partyFactor: 90,
                CharacterTrait.professionalism: 20,
              })
            : plain[i],
    ];
    final bad = room(wild, null);
    expect(bad.conflicts, contains(CabinConflict.powerStruggle));
    expect(bad.conflicts, contains(CabinConflict.partyCouncil));
    expect(bad.mood, lessThan(neutral.mood));

    // A young diva at the bottom of the room.
    final young = plain.reduce(
      (a, b) => a.birthDate.isAfter(b.birthDate) ? a : b,
    );
    final diva = _with(young, {
      CharacterTrait.egoism: 90,
      CharacterTrait.mediaHunger: 90,
      CharacterTrait.leadership: 5,
    });
    final withDivaSquad = [
      for (final p in plain) p.id == young.id ? diva : p,
    ];
    final withDiva = room(withDivaSquad, plain.first.id);
    expect(withDiva.unhappy, contains(diva.id));
    expect(withDiva.conflicts, contains(CabinConflict.divaOutside));
  });
}
