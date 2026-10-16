import 'ids.dart';
import 'player.dart';
import 'position.dart';

/// The shirt numbers of one squad. Nothing is stored: the numbers follow
/// from the squad itself, so every old save has them too. Each position has
/// its classic numbers (1 keeper, 9 striker, 10 playmaker ...); when two
/// players want the same one, the lower player id gets it and the other
/// takes the next free number of his position, at last any free one from 14.
Map<PlayerId, int> shirtNumbers(Iterable<Player> squad) {
  const wanted = <Position, List<int>>{
    Position.tw: [1, 12, 13, 21, 25, 30],
    Position.iv: [4, 5, 15, 16, 23, 24],
    Position.lv: [3, 17, 18, 19],
    Position.rv: [2, 20, 22, 26],
    Position.zdm: [6, 8, 14, 18],
    Position.zm: [8, 6, 14, 16],
    Position.zom: [10, 8, 14, 20],
    Position.la: [11, 17, 19, 27],
    Position.ra: [7, 18, 22, 28],
    Position.st: [9, 19, 29, 11],
  };
  final sorted = [...squad]..sort((a, b) => a.id.value.compareTo(b.id.value));
  final taken = <int>{};
  final out = <PlayerId, int>{};
  for (final p in sorted) {
    var number = 0;
    for (final n in wanted[p.position]!) {
      if (!taken.contains(n)) {
        number = n;
        break;
      }
    }
    if (number == 0) {
      number = 14;
      while (taken.contains(number)) {
        number++;
      }
    }
    taken.add(number);
    out[p.id] = number;
  }
  return out;
}
