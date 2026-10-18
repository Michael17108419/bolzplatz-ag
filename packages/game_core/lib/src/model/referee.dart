import 'dart:convert';

import 'ids.dart';
import 'region.dart';

/// What makes a referee (engine 2, step 10e1), each 1 to 100.
enum RefereeTrait {
  /// Cards: a strict referee books more.
  strictness('strictness'),

  /// Gives penalties more easily.
  penalties('penalties'),

  /// Lets play run on after a foul (advantage).
  advantage('advantage'),

  /// Whistles a little for the home team.
  homeBias('home_bias'),

  /// Wrong decisions (used by the VAR in step 10e2).
  errors('errors'),

  /// How much protest he takes before he books someone.
  authority('authority');

  const RefereeTrait(this.id);

  final String id;
}

/// A referee of the pool. Invented, only sounding real.
class Referee {
  const Referee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.level,
    required this.traits,
    this.region,
  });

  factory Referee.fromJson(Map<String, dynamic> m) {
    final t = m['traits'] as Map<String, dynamic>;
    final region = m['region'] as String?;
    return Referee(
      id: RefereeId(m['id'] as int),
      firstName: m['first_name'] as String,
      lastName: m['last_name'] as String,
      level: m['level'] as int,
      region: region == null
          ? null
          : Region.values.firstWhere((r) => r.id == region),
      traits: {
        for (final trait in RefereeTrait.values)
          trait: ((t[trait.id] as num?) ?? 50).toDouble().clamp(1, 100),
      },
    );
  }

  final RefereeId id;
  final String firstName;
  final String lastName;

  /// 1 whistles league 1 and 2, 3 league 3, 4 league 4 of [region].
  final int level;
  final Region? region;
  final Map<RefereeTrait, double> traits;

  String get name => '$firstName $lastName';

  /// A trait from -1 to 1 (50 is 0).
  double tx(RefereeTrait trait) => ((traits[trait] ?? 50) - 50) / 50;

  /// The reputation, 1 to 100: authority and few errors make a good name.
  double get reputation =>
      ((traits[RefereeTrait.authority] ?? 50) +
          (100 - (traits[RefereeTrait.errors] ?? 50))) /
      2;

  /// The trait that stands out most (for the reporter), null if none does.
  RefereeTrait? get standsOut {
    RefereeTrait? best;
    var most = 22.0;
    for (final trait in RefereeTrait.values) {
      final d = ((traits[trait] ?? 50) - 50).abs();
      if (d > most) {
        most = d;
        best = trait;
      }
    }
    return best;
  }
}

/// All referees, and who whistles which match.
class RefereePool {
  RefereePool(List<Referee> referees) : referees = List.unmodifiable(referees);

  factory RefereePool.fromJson(String text) {
    final m = jsonDecode(text) as Map<String, dynamic>;
    return RefereePool([
      for (final r in m['referees'] as List<dynamic>)
        Referee.fromJson(r as Map<String, dynamic>),
    ]);
  }

  final List<Referee> referees;

  /// The referees for a match of league [level] (1 to 4); league 4 by the
  /// [region] of the home club. Falls back to the next higher level.
  List<Referee> candidates(int level, Region? region) {
    final want = level <= 2 ? 1 : level;
    for (var l = want; l >= 1; l--) {
      final list = [
        for (final r in referees)
          if (r.level == l && (l != 4 || region == null || r.region == region))
            r,
      ];
      if (list.isNotEmpty) return list;
    }
    return referees;
  }

  /// The referee of a match: picked from the [candidates] by [hash] (a
  /// number from the seed of the match), the same every time.
  Referee? pick(int level, Region? region, int hash) {
    final list = candidates(level, region);
    if (list.isEmpty) return null;
    return list[hash.abs() % list.length];
  }
}
