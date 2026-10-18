import '../model/ids.dart';
import '../model/position.dart';

/// Chemistry of a team (engine 2, step 10f4): how well the players on the
/// pitch know each other. A pair grows together with the minutes they play
/// side by side this season; years together at the club count in advance.

/// One number for an unordered pair of players.
int pairKey(PlayerId a, PlayerId b) => a.value < b.value
    ? a.value * 100000 + b.value
    : b.value * 100000 + a.value;

/// The line of a position: 0 keeper, 1 defence, 2 midfield, 3 attack.
int lineOf(Position p) => switch (p) {
  Position.tw => 0,
  Position.iv || Position.lv || Position.rv => 1,
  Position.zdm || Position.zm || Position.zom => 2,
  Position.la || Position.ra || Position.st => 3,
};

/// Chemistry of a pair, 0 to 1, from [minutes] played together and
/// [years] together at the club: 0.5 at one "unit" ([minutesUnit] minutes
/// or [yearsUnit] years), then slower towards 1. [base] is what the summer
/// preparation gives every pair (in units).
double pairChemistry(
  double minutes,
  double years, {
  required double minutesUnit,
  required double yearsUnit,
  double base = 0,
}) {
  final x = base + minutes / minutesUnit + years / yearsUnit;
  return x / (1 + x);
}

/// Chemistry of the players on the pitch, 0 to 1: the mean over all pairs
/// in the same or a neighbouring line (a keeper and a striker need not know
/// each other). 0.5 when there are no pairs.
double teamChemistry(
  List<(PlayerId, Position)> players,
  double Function(PlayerId a, PlayerId b) pair,
) {
  var sum = 0.0;
  var n = 0;
  for (var i = 0; i < players.length; i++) {
    for (var j = i + 1; j < players.length; j++) {
      if ((lineOf(players[i].$2) - lineOf(players[j].$2)).abs() > 1) continue;
      sum += pair(players[i].$1, players[j].$1);
      n++;
    }
  }
  return n == 0 ? 0.5 : sum / n;
}
