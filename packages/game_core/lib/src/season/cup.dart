import '../model/ids.dart';
import '../rng/seeded_random.dart';

/// One tie of a cup round.
class CupTie {
  const CupTie(this.home, this.away, this.winner, {this.neutral = false});

  /// True for the final: it is played at a neutral venue, nobody is host.
  final bool neutral;
  final ClubId home;
  final ClubId away;
  final ClubId winner;
}

/// A single-leg knockout cup. The cup keeps the clubs still in, draws the
/// next round when asked and records the winners.
class KnockoutCup {
  KnockoutCup._({
    required this.name,
    required List<(ClubId, ClubId)> firstRound,
    required List<ClubId> byes,
    required int Function(ClubId) tier,
    required SeededRandom rng,
  }) : _pending = List.of(firstRound),
       _waiting = List.of(byes),
       _tier = tier,
       _rng = rng;

  /// Bolzplatzpokal: the clubs of [top] (first and second league) and
  /// [lower] (28 clubs) make the round of 64. In round 1 every lower club
  /// plays a club from [top]; the remaining top clubs play each other.
  factory KnockoutCup.bolzplatz({
    required List<ClubId> top,
    required List<ClubId> lower,
    required int Function(ClubId) tier,
    required SeededRandom rng,
  }) {
    if (top.length < lower.length) {
      throw ArgumentError('Need at least as many top clubs as lower clubs');
    }
    final shuffledTop = List<ClubId>.of(top);
    rng.shuffle(shuffledTop);
    final ties = <(ClubId, ClubId)>[];
    for (var i = 0; i < lower.length; i++) {
      ties.add((lower[i], shuffledTop[i]));
    }
    final rest = shuffledTop.sublist(lower.length);
    for (var i = 0; i + 1 < rest.length; i += 2) {
      ties.add((rest[i], rest[i + 1]));
    }
    return KnockoutCup._(
      name: 'bolzplatz',
      firstRound: [for (final t in ties) _homeFirst(t.$1, t.$2, tier)],
      byes: const [],
      tier: tier,
      rng: rng,
    );
  }

  /// Regional cup with a bracket of [bracketSize]. The clubs of
  /// [byePriority] get the byes first (in this order).
  factory KnockoutCup.provinz({
    required String name,
    required List<ClubId> participants,
    required List<ClubId> byePriority,
    required int bracketSize,
    required int Function(ClubId) tier,
    required SeededRandom rng,
  }) {
    final n = participants.length;
    var size = 2;
    while (size < n) {
      size *= 2;
    }
    if (size > bracketSize * 4) {
      throw ArgumentError('Too many participants for the bracket');
    }
    final byeCount = size - n;
    final inPriority = <ClubId>[
      for (final c in byePriority)
        if (participants.contains(c)) c,
    ];
    final byes = <ClubId>[...inPriority.take(byeCount)];
    for (final c in participants) {
      if (byes.length >= byeCount) break;
      if (!byes.contains(c)) byes.add(c);
    }
    final playing = [
      for (final c in participants)
        if (!byes.contains(c)) c,
    ];
    rng.shuffle(playing);
    final ties = <(ClubId, ClubId)>[
      for (var i = 0; i + 1 < playing.length; i += 2)
        _homeFirst(playing[i], playing[i + 1], tier),
    ];
    return KnockoutCup._(
      name: name,
      firstRound: ties,
      byes: byes,
      tier: tier,
      rng: rng,
    );
  }

  final String name;
  final List<(ClubId, ClubId)> _pending;
  final List<ClubId> _waiting;
  final int Function(ClubId) _tier;
  final SeededRandom _rng;
  final List<List<CupTie>> rounds = [];

  /// Clubs knocked out in each round, in the order of the rounds.
  final List<List<ClubId>> eliminated = [];
  ClubId? _winner;

  /// True if the pending round is the final (neutral venue).
  bool _finalPending = false;

  /// The next round is the final and has no home advantage.
  bool get nextRoundIsNeutral => _finalPending;

  ClubId? get winner => _winner;
  bool get isFinished => _winner != null;
  int get roundsPlayed => rounds.length;

  static (ClubId, ClubId) _homeFirst(
    ClubId a,
    ClubId b,
    int Function(ClubId) tier,
  ) {
    // The lower-ranked club (higher tier number) has home advantage.
    return tier(b) > tier(a) ? (b, a) : (a, b);
  }

  /// Plays the next round. [playTie] returns the winner of a tie.
  List<CupTie> playNextRound(
    ClubId Function(ClubId home, ClubId away) playTie,
  ) {
    if (isFinished) throw StateError('The cup is finished');
    final neutral = _finalPending;
    final ties = <CupTie>[];
    final out = <ClubId>[];
    final winners = <ClubId>[];
    for (final t in _pending) {
      final w = playTie(t.$1, t.$2);
      if (w != t.$1 && w != t.$2) {
        throw StateError('Winner is not one of the clubs');
      }
      ties.add(CupTie(t.$1, t.$2, w, neutral: neutral));
      winners.add(w);
      out.add(w == t.$1 ? t.$2 : t.$1);
    }
    rounds.add(ties);
    eliminated.add(out);
    final next = [...winners, ..._waiting];
    _waiting.clear();
    _pending.clear();
    if (next.length == 1) {
      _winner = next.first;
      return ties;
    }
    _rng.shuffle(next);
    _finalPending = next.length == 2;
    for (var i = 0; i + 1 < next.length; i += 2) {
      // The final has no host: keep the drawn order, no home right.
      _pending.add(
        _finalPending
            ? (next[i], next[i + 1])
            : _homeFirst(next[i], next[i + 1], _tier),
      );
    }
    return ties;
  }

  /// Clubs still in the cup after the rounds played so far.
  List<ClubId> get remaining {
    if (_winner != null) return [_winner!];
    return [
      for (final t in _pending) ...[t.$1, t.$2],
      ..._waiting,
    ];
  }
}
