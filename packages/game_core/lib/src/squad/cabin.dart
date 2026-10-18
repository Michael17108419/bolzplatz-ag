import 'dart:math' as math;

import '../calendar/game_date.dart';
import '../model/character.dart';
import '../model/ids.dart';
import '../model/player.dart';
import '../rules/season_rules.dart';

/// The twelve types of Doc 06 (engine 2, step 10f1). Labels only: what a
/// player does comes from his traits, a label never counts twice.
enum Archetype {
  captain('captain'),
  modelPro('model_pro'),
  diva('diva'),
  hothead('hothead'),
  mercenary('mercenary'),
  clubLegend('club_legend'),
  partyAnimal('party_animal'),
  rock('rock'),
  flawedGenius('flawed_genius'),
  terrier('terrier'),
  mediaDarling('media_darling'),
  workhorse('workhorse');

  const Archetype(this.id);

  final String id;
}

/// Where a player stands in the dressing room (Doc 06).
enum CabinRole { captain, council, follower }

/// Conflicts in the dressing room (Doc 06).
enum CabinConflict {
  /// A diva without a seat in the council: unhappy.
  divaOutside,

  /// Two strong leaders in the council fight for power.
  powerStruggle,

  /// Party animals in the council take the followers along.
  partyCouncil,

  /// A mercenary in the council weakens the bond to the club.
  mercenaryCouncil,
}

/// The types of [p]: at most two, those that fit best.
List<Archetype> archetypesOf(Player p, CabinRules r) {
  double t(CharacterTrait trait) => p.traits[trait] ?? 50;
  final hi = r.high;
  final lo = r.low;
  final ex = r.extreme;
  // How far above (or below) the thresholds; null if a rule fails.
  double? over(List<(CharacterTrait, double, bool)> rules) {
    var sum = 0.0;
    for (final (trait, limit, up) in rules) {
      final v = t(trait);
      final d = up ? v - limit : limit - v;
      if (d < 0) return null;
      sum += d;
    }
    return sum;
  }

  const lead = CharacterTrait.leadership;
  const loy = CharacterTrait.loyalty;
  const pro = CharacterTrait.professionalism;
  const party = CharacterTrait.partyFactor;
  const cons = CharacterTrait.consistency;
  const ego = CharacterTrait.egoism;
  const media = CharacterTrait.mediaHunger;
  const temper = CharacterTrait.temper;
  const aggr = CharacterTrait.aggression;
  const greed = CharacterTrait.greed;
  const press = CharacterTrait.pressureResistance;
  const crea = CharacterTrait.creativity;
  const amb = CharacterTrait.ambition;
  final scores = <Archetype, double?>{
    Archetype.captain: over([
      (lead, hi, true),
      (loy, hi, true),
      (pro, 50, true),
    ]),
    Archetype.modelPro: over([
      (pro, ex, true),
      (party, lo, false),
      (cons, hi, true),
    ]),
    Archetype.diva: over([(ego, hi, true), (media, hi, true)]),
    Archetype.hothead: over([(temper, hi, true), (aggr, hi, true)]),
    Archetype.mercenary: over([(greed, hi, true), (loy, lo, false)]),
    Archetype.clubLegend: over([(loy, ex, true), (greed, lo, false)]),
    Archetype.partyAnimal: over([(party, hi, true), (pro, lo, false)]),
    Archetype.rock: over([(press, hi, true), (cons, hi, true)]),
    Archetype.flawedGenius: over([(crea, hi, true), (cons, lo, false)]),
    Archetype.terrier: over([(aggr, hi, true), (amb, hi, true)]),
    Archetype.mediaDarling: over([
      (media, hi, true),
      (ego, lo, false),
      (party, hi, true),
    ]),
    Archetype.workhorse: over([
      (pro, hi, true),
      (amb, hi, true),
      (media, lo, false),
      (ego, lo, false),
    ]),
  };
  final fits = [
    for (final e in scores.entries)
      if (e.value != null) (e.key, e.value!),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final f in fits.take(2)) f.$1];
}

/// The dressing room of a squad (engine 2, step 10f1, Doc 06): the rank
/// of every player from leadership, age, years at the club and strength;
/// the captain, the council (the highest ranks) and the followers; the
/// mood of the dressing room the council sets, and its conflicts.
class Cabin {
  Cabin._({
    required this.ranks,
    required this.roles,
    required this.types,
    required this.mood,
    required this.conflicts,
    required this.unhappy,
    required this.captain,
  });

  /// The cabin of [squad] on [today]. [captain] wears the armband (named
  /// by the manager); [strength] gives the strength of a player (0 to 100).
  factory Cabin.of(
    List<Player> squad,
    CabinRules r, {
    required GameDate today,
    required double Function(Player p) strength,
    PlayerId? captain,
  }) {
    final ranks = <PlayerId, double>{};
    final types = <PlayerId, List<Archetype>>{};
    for (final p in squad) {
      final age = (p.birthDate.daysUntil(today) / 365.25).clamp(16.0, 40.0);
      final start = p.contract?.start;
      final years = start == null
          ? 0.0
          : (start.daysUntil(today) / 365.25).clamp(0.0, 10.0);
      ranks[p.id] =
          r.rankLeadership * (p.traits[CharacterTrait.leadership] ?? 50) / 100 +
          r.rankAge * (age - 16) / 20 +
          r.rankYears * years / 10 +
          r.rankStrength * strength(p) / 100;
      types[p.id] = archetypesOf(p, r);
    }
    final order = [...squad]
      ..sort((a, b) => ranks[b.id]!.compareTo(ranks[a.id]!));
    final roles = <PlayerId, CabinRole>{};
    var seats = r.councilSize;
    for (final p in order) {
      if (p.id == captain) {
        roles[p.id] = CabinRole.captain;
      } else if (seats > 0) {
        roles[p.id] = CabinRole.council;
        seats--;
      } else {
        roles[p.id] = CabinRole.follower;
      }
    }
    final byId = {for (final p in squad) p.id: p};
    final leaders = [
      for (final p in squad)
        if (roles[p.id] != CabinRole.follower) p,
    ];
    double tx(Player p, CharacterTrait t) => ((p.traits[t] ?? 50) - 50) / 50;
    var mood = 0.5;
    final conflicts = <CabinConflict>[];
    final unhappy = <PlayerId>{};
    // The captain: a fitting one lifts the room, a weak one drags it.
    final cap = captain == null ? null : byId[captain];
    if (cap != null) {
      final fit = types[cap.id]!.any(
        (a) =>
            a == Archetype.captain ||
            a == Archetype.clubLegend ||
            a == Archetype.modelPro,
      );
      if (fit) mood += r.captainFit;
      if ((cap.traits[CharacterTrait.leadership] ?? 50) < r.low) {
        mood -= r.captainWeak;
      }
    }
    if (leaders.isNotEmpty) {
      var pro = 0.0;
      for (final p in leaders) {
        pro += tx(p, CharacterTrait.professionalism);
      }
      mood += r.councilProfessionalism * pro / leaders.length;
    }
    final strong = leaders
        .where((p) => (p.traits[CharacterTrait.leadership] ?? 50) >= r.high)
        .length;
    if (strong >= 2) {
      conflicts.add(CabinConflict.powerStruggle);
      mood -= r.powerStruggle;
    }
    final party = leaders
        .where((p) => types[p.id]!.contains(Archetype.partyAnimal))
        .length;
    if (party > 0) {
      conflicts.add(CabinConflict.partyCouncil);
      mood -= r.partyCouncil * party;
    }
    final mercs = leaders
        .where((p) => types[p.id]!.contains(Archetype.mercenary))
        .length;
    if (mercs > 0) {
      conflicts.add(CabinConflict.mercenaryCouncil);
      mood -= r.mercenaryCouncil * mercs;
    }
    for (final p in squad) {
      if (roles[p.id] == CabinRole.follower &&
          types[p.id]!.contains(Archetype.diva)) {
        unhappy.add(p.id);
      }
    }
    if (unhappy.isNotEmpty) {
      conflicts.add(CabinConflict.divaOutside);
      mood -= r.divaOutside * math.min(unhappy.length, 3);
    }
    return Cabin._(
      ranks: Map.unmodifiable(ranks),
      roles: Map.unmodifiable(roles),
      types: Map.unmodifiable(types),
      mood: mood.clamp(0.0, 1.0),
      conflicts: List.unmodifiable(conflicts),
      unhappy: Set.unmodifiable(unhappy),
      captain: captain,
    );
  }

  /// Rank in the room, higher is more say.
  final Map<PlayerId, double> ranks;
  final Map<PlayerId, CabinRole> roles;
  final Map<PlayerId, List<Archetype>> types;

  /// Mood of the dressing room, 0 (bad) to 1 (great), 0.5 neutral.
  final double mood;
  final List<CabinConflict> conflicts;

  /// Players unhappy with their place in the room (a diva outside the
  /// council).
  final Set<PlayerId> unhappy;
  final PlayerId? captain;

  /// The council, highest rank first.
  List<PlayerId> get council {
    final ids = [
      for (final e in roles.entries)
        if (e.value == CabinRole.council) e.key,
    ]..sort((a, b) => ranks[b]!.compareTo(ranks[a]!));
    return ids;
  }
}
