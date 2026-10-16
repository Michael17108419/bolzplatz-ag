import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  test('the lower club hosts until the semifinals, the final is neutral', () {
    final clubs = [for (var i = 1; i <= 8; i++) ClubId(i)];
    // Clubs 1-4 play in tier 1, clubs 5-8 in tier 2.
    int tier(ClubId c) => c.value <= 4 ? 1 : 2;
    final cup = KnockoutCup.provinz(
      name: 'test',
      participants: clubs,
      byePriority: const [],
      bracketSize: 8,
      tier: tier,
      rng: SeededRandom(7),
    );
    final rounds = <List<CupTie>>[];
    while (!cup.isFinished) {
      final neutralBefore = cup.nextRoundIsNeutral;
      final ties = cup.playNextRound((h, a) => h);
      expect(ties.every((t) => t.neutral == neutralBefore), isTrue);
      rounds.add(ties);
    }
    expect(rounds.length, 3);
    for (final round in rounds.take(2)) {
      for (final t in round) {
        expect(round.first.neutral, isFalse);
        if (tier(t.home) != tier(t.away)) {
          expect(tier(t.home), greaterThan(tier(t.away)));
        }
      }
    }
    expect(rounds.last.single.neutral, isTrue);
  });
}
