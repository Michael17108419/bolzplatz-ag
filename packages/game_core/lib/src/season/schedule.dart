import '../model/ids.dart';
import '../rng/seeded_random.dart';

/// One match of the schedule: [home] hosts [away].
class Fixture {
  const Fixture(this.home, this.away);

  final ClubId home;
  final ClubId away;
}

/// Schedules of league seasons.
class Schedule {
  const Schedule._();

  /// Double round robin with the circle method. The club order is shuffled
  /// with [rng], so every season looks different but stays reproducible.
  /// Returns one list of fixtures per matchday; the second half mirrors the
  /// first with home and away swapped. Every club has a balanced home/away
  /// sequence (no more than two home or away games in a row).
  static List<List<Fixture>> doubleRoundRobin(
    List<ClubId> clubs,
    SeededRandom rng,
  ) {
    if (clubs.length < 2 || clubs.length.isOdd) {
      throw ArgumentError('Need an even number of at least two clubs');
    }
    final order = List<ClubId>.of(clubs);
    rng.shuffle(order);
    final n = order.length;
    final first = <List<Fixture>>[];
    var ring = List<int>.generate(n, (i) => i);
    for (var round = 0; round < n - 1; round++) {
      final day = <Fixture>[];
      for (var i = 0; i < n ~/ 2; i++) {
        final a = ring[i];
        final b = ring[n - 1 - i];
        // Swapping all pairs on odd rounds keeps home and away balanced:
        // no club has more than two home or away games in a row.
        final swap = round.isOdd;
        day.add(
          swap ? Fixture(order[b], order[a]) : Fixture(order[a], order[b]),
        );
      }
      first.add(day);
      ring = [ring[0], ring[n - 1], ...ring.sublist(1, n - 1)];
    }
    final second = [
      for (final day in first) [for (final f in day) Fixture(f.away, f.home)],
    ];
    return [...first, ...second];
  }
}
