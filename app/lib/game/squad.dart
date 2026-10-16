import 'package:game_core/game_core.dart';

import 'loaded_world.dart';

/// Which players the squad list shows.
enum SquadFilter {
  all,
  goalkeepers,
  defenders,
  midfielders,
  attackers;

  bool accepts(Position position) => switch (this) {
    SquadFilter.all => true,
    SquadFilter.goalkeepers => position == Position.tw,
    SquadFilter.defenders =>
      position == Position.iv ||
          position == Position.lv ||
          position == Position.rv,
    SquadFilter.midfielders =>
      position == Position.zdm ||
          position == Position.zm ||
          position == Position.zom,
    SquadFilter.attackers =>
      position == Position.la ||
          position == Position.ra ||
          position == Position.st,
  };
}

/// What the squad list is sorted by.
enum SquadSort { position, strength, age, name, contract }

/// One line of the squad list.
class SquadRow {
  const SquadRow({
    required this.player,
    required this.overall,
    required this.age,
    this.number,
  });

  final Player player;
  final double overall;
  final int age;

  /// Shirt number in the club, see [shirtNumbers].
  final int? number;
}

/// The players of a club with their strength and age at the world's date.
List<SquadRow> squadOf(LoadedWorld loaded, ClubId club) {
  final today = loaded.today;
  final players = [
    for (final p in loaded.world.players)
      if (p.clubId == club) p,
  ];
  final numbers = shirtNumbers(players);
  return [
    for (final p in players)
      SquadRow(
        player: p,
        overall: loaded.overall(p),
        age: p.ageOn(today),
        number: numbers[p.id],
      ),
  ];
}

/// The rows sorted and filtered. The natural order of each sort is the
/// useful one (strongest first, youngest first, A to Z, contract ending
/// first); [reversed] turns it around.
List<SquadRow> arrangeSquad(
  List<SquadRow> rows, {
  required SquadSort sort,
  required SquadFilter filter,
  bool reversed = false,
}) {
  final out = [
    for (final r in rows)
      if (filter.accepts(r.player.position)) r,
  ];
  int byStrength(SquadRow a, SquadRow b) => b.overall.compareTo(a.overall);
  out.sort((a, b) {
    final c = switch (sort) {
      SquadSort.position => () {
        final d = a.player.position.index.compareTo(b.player.position.index);
        return d != 0 ? d : byStrength(a, b);
      }(),
      SquadSort.strength => byStrength(a, b),
      SquadSort.age => () {
        final d = a.age.compareTo(b.age);
        return d != 0 ? d : byStrength(a, b);
      }(),
      SquadSort.name => () {
        final d = a.player.lastName.compareTo(b.player.lastName);
        return d != 0 ? d : a.player.firstName.compareTo(b.player.firstName);
      }(),
      SquadSort.contract => () {
        final ea = a.player.contract?.end;
        final eb = b.player.contract?.end;
        if (ea == null || eb == null) return byStrength(a, b);
        final d = ea.compareTo(eb);
        return d != 0 ? d : byStrength(a, b);
      }(),
    };
    return reversed ? -c : c;
  });
  return out;
}

/// The 4 display levels of a hidden value from 1 to 100: 0 low (1 to 30),
/// 1 middle (31 to 55), 2 high (56 to 80), 3 extreme (81 to 100).
int displayLevel(double value) {
  if (value <= 30) return 0;
  if (value <= 55) return 1;
  if (value <= 80) return 2;
  return 3;
}

/// Potential shown roughly, 1 to 5.
int potentialStars(Player p) {
  final v = p.potentialCore;
  if (v < 55) return 1;
  if (v < 65) return 2;
  if (v < 75) return 3;
  if (v < 85) return 4;
  return 5;
}

/// The roles a player can be rated on: those of his main and secondary
/// positions (the back-three-only roles included, they are marked in the UI).
List<RoleRule> rolesOf(Player p, Rules rules) {
  final positions = {p.position, ...p.secondaryPositions.keys};
  return [
    for (final r in rules.tactics.roles)
      if (r.positions.any(positions.contains)) r,
  ];
}

/// The role the player is best at on his main position, or null.
RoleRule? mainRoleOf(Player p, Rules rules) {
  final onPosition = [
    for (final r in rules.tactics.roles)
      if (r.positions.contains(p.position)) r,
  ];
  if (onPosition.isEmpty) return null;
  int rank(RoleFamiliarity f) => switch (f) {
    RoleFamiliarity.expert => 3,
    RoleFamiliarity.comfortable => 2,
    RoleFamiliarity.basic => 1,
    RoleFamiliarity.unfamiliar => 0,
  };
  RoleRule? best;
  var bestRank = -1;
  for (final r in onPosition) {
    final f = p.roles[r.id] ?? RoleFamiliarity.basic;
    if (rank(f) > bestRank) {
      best = r;
      bestRank = rank(f);
    }
  }
  return best;
}
