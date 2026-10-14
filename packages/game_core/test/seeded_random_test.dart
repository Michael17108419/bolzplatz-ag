import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  group('SeededRandom golden values', () {
    // Reference values were computed with an independent implementation of
    // the same algorithm. If these change, every saved world changes.
    test('nextUint32 for seed 12345', () {
      final r = SeededRandom(12345);
      expect(List.generate(5, (_) => r.nextUint32()), [
        518667457,
        440444462,
        4232892992,
        3757857622,
        3939018813,
      ]);
    });

    test('nextUint32 for seed 0', () {
      final r = SeededRandom(0);
      expect(List.generate(3, (_) => r.nextUint32()), [
        3809008728,
        1133695204,
        53579671,
      ]);
    });

    test('nextInt(100) for seed 12345', () {
      final r = SeededRandom(12345);
      expect(List.generate(8, (_) => r.nextInt(100)), [
        57,
        62,
        92,
        22,
        13,
        35,
        15,
        10,
      ]);
    });

    test('nextDouble for seed 12345', () {
      final r = SeededRandom(12345);
      expect(List.generate(3, (_) => r.nextDouble()), [
        0.12076167838684437,
        0.9855472063641578,
        0.9171242811587097,
      ]);
    });

    test('fork for label club-1', () {
      final f = SeededRandom(12345).fork('club-1');
      expect(List.generate(3, (_) => f.nextUint32()), [
        1321074188,
        1681220724,
        4059657161,
      ]);
    });

    test('shuffle for seed 7', () {
      final items = List.generate(10, (i) => i);
      SeededRandom(7).shuffle(items);
      expect(items, [3, 9, 6, 5, 4, 7, 2, 1, 8, 0]);
    });
  });

  group('SeededRandom behaviour', () {
    test('same seed gives the same sequence', () {
      final a = SeededRandom(99);
      final b = SeededRandom(99);
      expect(
        List.generate(100, (_) => a.nextUint32()),
        List.generate(100, (_) => b.nextUint32()),
      );
    });

    test('different seeds give different sequences', () {
      final a = SeededRandom(1);
      final b = SeededRandom(2);
      expect(a.nextUint32(), isNot(b.nextUint32()));
    });

    test('fork does not depend on how much was drawn before', () {
      final a = SeededRandom(5);
      final b = SeededRandom(5);
      for (var i = 0; i < 50; i++) {
        b.nextUint32();
      }
      expect(a.fork('x').nextUint32(), b.fork('x').nextUint32());
    });

    test('forks with different labels differ', () {
      final r = SeededRandom(5);
      expect(r.fork('a').nextUint32(), isNot(r.fork('b').nextUint32()));
    });

    test('nextInt stays in range and covers all values', () {
      final r = SeededRandom(3);
      final seen = <int>{};
      for (var i = 0; i < 1000; i++) {
        final v = r.nextInt(6);
        expect(v, inInclusiveRange(0, 5));
        seen.add(v);
      }
      expect(seen.length, 6);
    });

    test('nextIntInRange includes both ends', () {
      final r = SeededRandom(4);
      final seen = <int>{};
      for (var i = 0; i < 500; i++) {
        seen.add(r.nextIntInRange(10, 12));
      }
      expect(seen, {10, 11, 12});
    });

    test('nextDouble is in [0, 1)', () {
      final r = SeededRandom(8);
      for (var i = 0; i < 1000; i++) {
        expect(r.nextDouble(), inInclusiveRange(0.0, 0.9999999999999999));
      }
    });

    test('nextGaussian has mean near 0 and spread near 1', () {
      final r = SeededRandom(11);
      const n = 5000;
      var sum = 0.0;
      var sumSq = 0.0;
      for (var i = 0; i < n; i++) {
        final g = r.nextGaussian();
        sum += g;
        sumSq += g * g;
      }
      final mean = sum / n;
      final variance = sumSq / n - mean * mean;
      expect(mean.abs(), lessThan(0.1));
      expect(variance, closeTo(1.0, 0.15));
    });

    test('shuffle keeps all elements', () {
      final items = List.generate(30, (i) => i);
      SeededRandom(21).shuffle(items);
      expect(items.toSet().length, 30);
      expect(items..sort(), List.generate(30, (i) => i));
    });

    test('weightedIndex respects zero weights', () {
      final r = SeededRandom(2);
      for (var i = 0; i < 200; i++) {
        expect(r.weightedIndex([0, 1, 0]), 1);
      }
    });

    test('invalid arguments are rejected', () {
      final r = SeededRandom(1);
      expect(() => r.nextInt(0), throwsArgumentError);
      expect(() => r.pick(<int>[]), throwsArgumentError);
      expect(() => r.weightedIndex([0, 0]), throwsArgumentError);
    });
  });
}
