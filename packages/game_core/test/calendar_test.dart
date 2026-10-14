import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  group('GameDate', () {
    test('epoch day of known dates', () {
      expect(GameDate(1970, 1, 1).epochDay, 0);
      expect(GameDate(1969, 12, 31).epochDay, -1);
      expect(GameDate(2026, 7, 1).epochDay, 20635);
      expect(GameDate(2028, 2, 29).epochDay, 21243);
    });

    test('round trip through epoch day', () {
      for (final d in [
        GameDate(1969, 12, 31),
        GameDate(2026, 7, 1),
        GameDate(2028, 2, 29),
        GameDate(2100, 3, 1),
      ]) {
        expect(GameDate.fromEpochDay(d.epochDay), d);
      }
    });

    test('weekday: 1 = Monday', () {
      expect(GameDate(1970, 1, 1).weekday, 4); // Thursday
      expect(GameDate(2026, 7, 1).weekday, 3); // Wednesday
    });

    test('plusDays crosses month, year and leap day', () {
      expect(GameDate(2028, 2, 28).plusDays(2), GameDate(2028, 3, 1));
      expect(GameDate(2027, 2, 28).plusDays(1), GameDate(2027, 3, 1));
      expect(GameDate(2026, 12, 31).plusDays(1), GameDate(2027, 1, 1));
      expect(GameDate(2026, 7, 1).plusDays(-1), GameDate(2026, 6, 30));
    });

    test('daysUntil and ordering', () {
      final a = GameDate(2026, 7, 1);
      final b = GameDate(2026, 8, 31);
      expect(a.daysUntil(b), 61);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.compareTo(a), 0);
    });

    test('toString uses ISO format', () {
      expect(GameDate(2026, 7, 1).toString(), '2026-07-01');
    });

    test('invalid dates are rejected', () {
      expect(() => GameDate(2027, 2, 29), throwsArgumentError);
      expect(() => GameDate(2026, 13, 1), throwsArgumentError);
      expect(() => GameDate(2026, 4, 31), throwsArgumentError);
    });
  });

  group('Season', () {
    test('2026/27 runs from 1 July to 30 June', () {
      const s = Season(2026);
      expect(s.start, GameDate(2026, 7, 1));
      expect(s.end, GameDate(2027, 6, 30));
      expect(s.label, '2026/27');
    });

    test('label wraps at the century', () {
      expect(const Season(2099).label, '2099/00');
    });

    test('containing picks the right season', () {
      expect(Season.containing(GameDate(2026, 7, 1)), const Season(2026));
      expect(Season.containing(GameDate(2027, 6, 30)), const Season(2026));
      expect(Season.containing(GameDate(2027, 7, 1)), const Season(2027));
      expect(Season.containing(GameDate(2027, 1, 15)), const Season(2026));
    });

    test('contains, next and previous', () {
      const s = Season(2026);
      expect(s.contains(GameDate(2027, 6, 30)), isTrue);
      expect(s.contains(GameDate(2027, 7, 1)), isFalse);
      expect(s.next, const Season(2027));
      expect(s.previous, const Season(2025));
    });
  });
}
