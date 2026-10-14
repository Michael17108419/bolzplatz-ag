import '../model/ids.dart';
import '../model/region.dart';
import '../result/result.dart';
import '../rules/rules.dart';

/// Why a club changed league.
enum MovementKind {
  promotion,
  relegation,
  playoffPromotion,
  playoffRelegation,
  toPool,
  fromPool,
}

/// One club moving between leagues. A null league means the pool.
class Movement {
  const Movement(this.club, this.from, this.to, this.kind);

  final ClubId club;
  final LeagueId? from;
  final LeagueId? to;
  final MovementKind kind;
}

class PyramidError {
  const PyramidError(this.message);

  final String message;

  @override
  String toString() => 'PyramidError: $message';
}

/// Everything needed to move from one season to the next.
class PyramidInput {
  const PyramidInput({
    required this.standings,
    required this.clubRegion,
    required this.pools,
    required this.cycleYear,
    this.unlicensed = const {},
  });

  /// Final table of every league, best club first.
  final Map<LeagueId, List<ClubId>> standings;

  /// Region of each club, used for clubs relegated from the third tier.
  final Map<ClubId, Region> clubRegion;

  /// Pool clubs per region, longest waiting first.
  final Map<Region, List<ClubId>> pools;

  /// Position in the fixed three-year cycle for the last two places in the
  /// third tier (0, 1 or 2).
  final int cycleYear;

  /// Clubs without a license. They count as last in their table.
  final Set<ClubId> unlicensed;
}

class PyramidResult {
  const PyramidResult({
    required this.leagues,
    required this.pools,
    required this.movements,
  });

  /// New members of every league, sorted by club id.
  final Map<LeagueId, List<ClubId>> leagues;
  final Map<Region, List<ClubId>> pools;
  final List<Movement> movements;
}

/// Promotion and relegation between the four tiers (Block 2).
///
/// The second-team rule is not part of this function; the world generator
/// marks affected clubs as [PyramidInput.unlicensed].
class PyramidTransition {
  const PyramidTransition._();

  /// Computes the next season. [playoffWinner] decides a two-leg tie and
  /// must return one of its two arguments; the first argument is the club
  /// from the higher league.
  static Result<PyramidResult, PyramidError> run(
    Rules rules,
    PyramidInput input,
    ClubId Function(ClubId higher, ClubId lower) playoffWinner,
  ) {
    try {
      return Ok(_run(rules, input, playoffWinner));
    } on PyramidError catch (e) {
      return Err(e);
    }
  }

  static PyramidResult _run(
    Rules rules,
    PyramidInput input,
    ClubId Function(ClubId, ClubId) playoffWinner,
  ) {
    LeagueRule single(int level) {
      final found = rules.leagues.where((l) => l.level == level).toList();
      if (found.length != 1) {
        throw PyramidError('Expected exactly one league on level $level');
      }
      return found.first;
    }

    final l1 = single(1);
    final l2 = single(2);
    final l3 = single(3);
    final regional = <Region, LeagueRule>{};
    for (final l in rules.leagues.where((l) => l.level == 4)) {
      final region = l.region;
      if (region == null || regional.containsKey(region)) {
        throw const PyramidError('Fourth tier needs one league per region');
      }
      regional[region] = l;
    }
    if (regional.length != Region.values.length) {
      throw const PyramidError('Fourth tier needs all five regions');
    }
    if (input.cycleYear < 0 || input.cycleYear > 2) {
      throw const PyramidError('cycleYear must be 0, 1 or 2');
    }

    List<ClubId> ordered(LeagueRule l) {
      final table = input.standings[LeagueId(l.id)];
      if (table == null || table.length != l.teamCount) {
        throw PyramidError('Standings of ${l.key} are missing or incomplete');
      }
      if (table.toSet().length != table.length) {
        throw PyramidError('Duplicate club in standings of ${l.key}');
      }
      return [
        ...table.where((c) => !input.unlicensed.contains(c)),
        ...table.where(input.unlicensed.contains),
      ];
    }

    final s1 = ordered(l1);
    final s2 = ordered(l2);
    final s3 = ordered(l3);
    final s4 = {for (final e in regional.entries) e.key: ordered(e.value)};

    final members = <int, List<ClubId>>{
      l1.id: [...s1],
      l2.id: [...s2],
      l3.id: [...s3],
      for (final e in regional.entries) e.value.id: [...s4[e.key]!],
    };
    final pools = {
      for (final r in Region.values) r: [...?input.pools[r]],
    };
    final movements = <Movement>[];

    void move(ClubId club, int? from, int? to, MovementKind kind) {
      if (from != null) members[from]!.remove(club);
      if (to != null) members[to]!.add(club);
      movements.add(
        Movement(
          club,
          from == null ? null : LeagueId(from),
          to == null ? null : LeagueId(to),
          kind,
        ),
      );
    }

    // Direct movements between the upper three tiers.
    for (final c in s1.sublist(16)) {
      move(c, l1.id, l2.id, MovementKind.relegation);
    }
    for (final c in s2.sublist(0, 2)) {
      move(c, l2.id, l1.id, MovementKind.promotion);
    }
    for (final c in s2.sublist(16)) {
      move(c, l2.id, l3.id, MovementKind.relegation);
    }
    for (final c in s3.sublist(0, 2)) {
      move(c, l3.id, l2.id, MovementKind.promotion);
    }

    // Third tier to fourth tier: last four, into their own region.
    final incoming = {for (final r in Region.values) r: <ClubId>[]};
    for (final c in s3.sublist(16)) {
      final region = input.clubRegion[c];
      if (region == null) {
        throw PyramidError('No region known for club ${c.value}');
      }
      incoming[region]!.add(c);
      move(c, l3.id, regional[region]!.id, MovementKind.relegation);
    }

    // Relegation play-offs between tiers.
    void playoff(ClubId higher, ClubId lower, int upper, int under) {
      final winner = playoffWinner(higher, lower);
      if (winner != higher && winner != lower) {
        throw const PyramidError('Play-off winner must be one of the clubs');
      }
      if (winner == lower) {
        move(lower, under, upper, MovementKind.playoffPromotion);
        move(higher, upper, under, MovementKind.playoffRelegation);
      }
    }

    playoff(s1[15], s2[2], l1.id, l2.id);
    playoff(s2[15], s3[2], l2.id, l3.id);

    // Fourth tier to third tier: champions per fixed cycle.
    final champion = {for (final r in Region.values) r: s4[r]!.first};
    final promoted = <Region>{Region.west, Region.suedwest};
    switch (input.cycleYear) {
      case 0:
        promoted.add(Region.nordost);
        promoted.add(_tie(champion, Region.nord, Region.bayern, playoffWinner));
      case 1:
        promoted.add(Region.nord);
        promoted.add(
          _tie(champion, Region.nordost, Region.bayern, playoffWinner),
        );
      default:
        promoted.add(Region.bayern);
        promoted.add(
          _tie(champion, Region.nord, Region.nordost, playoffWinner),
        );
    }
    for (final r in Region.values.where(promoted.contains)) {
      move(champion[r]!, regional[r]!.id, l3.id, MovementKind.promotion);
    }

    // Refill every regional league to its size through the pool.
    for (final r in Region.values) {
      final rule = regional[r]!;
      final up = promoted.contains(r) ? 1 : 0;
      final inCount = incoming[r]!.length;
      final poolDown = [
        rules.fourthLeagueRelegatedToPool,
        inCount - up,
      ].reduce((a, b) => a > b ? a : b);
      final base = s4[r]!.where((c) => !(up == 1 && c == champion[r])).toList();
      if (poolDown > base.length) {
        throw PyramidError('Not enough clubs to relegate in ${rule.key}');
      }
      final down = base.sublist(base.length - poolDown);
      for (final c in down) {
        move(c, rule.id, null, MovementKind.toPool);
      }
      final pull = up + poolDown - inCount;
      final pool = pools[r]!;
      if (pool.length < pull) {
        throw PyramidError('Pool of ${r.id} has too few clubs');
      }
      for (final c in pool.sublist(0, pull)) {
        move(c, null, rule.id, MovementKind.fromPool);
      }
      pools[r] = [...pool.sublist(pull), ...down];
    }

    // Check the sizes and return stable, sorted membership.
    final leagues = <LeagueId, List<ClubId>>{};
    for (final l in rules.leagues) {
      final list = members[l.id]!;
      if (list.length != l.teamCount) {
        throw PyramidError('League ${l.key} ends with ${list.length} clubs');
      }
      leagues[LeagueId(l.id)] = (List.of(list)
        ..sort((a, b) => a.value.compareTo(b.value)));
    }
    return PyramidResult(
      leagues: leagues,
      pools: pools,
      movements: List.unmodifiable(movements),
    );
  }

  /// Plays the tie between two regional champions and returns the region
  /// of the winner.
  static Region _tie(
    Map<Region, ClubId> champion,
    Region a,
    Region b,
    ClubId Function(ClubId, ClubId) playoffWinner,
  ) {
    final winner = playoffWinner(champion[a]!, champion[b]!);
    if (winner == champion[a]) return a;
    if (winner == champion[b]) return b;
    throw const PyramidError('Play-off winner must be one of the clubs');
  }
}
