import '../calendar/game_date.dart';
import '../match/limits.dart';
import '../model/attribute.dart';
import '../model/attribute_set.dart';
import '../model/player.dart';
import '../rng/seeded_random.dart';
import '../rules/rules.dart';
import '../world/world_report.dart';

/// Yearly development of a player: age curves shifted by the development
/// type, the 14 couplings, growth limited by the potential.
class Development {
  const Development(this.rules);

  final Rules rules;

  /// Points to add (zero or negative) for a player of [effectiveAge]; the
  /// same function the generator uses to set the starting values.
  double _ageAdjust(AgeCurve curve, double effectiveAge) {
    final g = rules.generator;
    if (effectiveAge < curve.risesUntil) {
      return -(curve.risesUntil - effectiveAge) * g.growthPerYear;
    }
    if (effectiveAge >= curve.declinesFrom) {
      return -(effectiveAge - curve.declinesFrom + 1) * g.declinePerYear;
    }
    return 0;
  }

  /// The player one year later, at [newSeasonStart]. [minutesShare] is the
  /// share of possible minutes he played (0 to 1).
  Player advance(
    Player p, {
    required GameDate newSeasonStart,
    required SeededRandom rng,
    required double minutesShare,
  }) {
    final g = rules.generator;
    final dev = rules.development;
    final age = p.ageOn(newSeasonStart);
    final shift = g.developmentShiftYears[p.developmentType]!;
    final isKeeper = p.position.isGoalkeeper;
    final overall = WorldReport.overall(p, rules);
    final potential = p.potentialCore + p.potentialDynamic;
    final headroom = ((potential - overall) / dev.potentialHeadroom).limit(
      0.0,
      1.0,
    );
    final playing = (1 + dev.minutesEffect * (minutesShare - 0.5) * 2).limit(
      0.0,
      2.0,
    );

    final own = <Attribute, double>{};
    for (final a in Attribute.values) {
      if (a.isGoalkeeping && !isKeeper) {
        own[a] = 0;
        continue;
      }
      final mental = a.group == AttributeGroup.intelligence;
      final s = mental ? shift * g.mentalShiftFactor : shift;
      final curve = rules.ageCurves[a]!;
      var delta = _ageAdjust(curve, age - s) - _ageAdjust(curve, age - 1 - s);
      if (delta > 0) {
        delta *= headroom * playing;
      }
      delta += rng.nextGaussian() * dev.annualNoiseSd;
      own[a] = delta;
    }

    final coupled = <Attribute, double>{};
    for (final c in dev.couplings) {
      if (c.follower.isGoalkeeping && !isKeeper) continue;
      coupled[c.follower] =
          (coupled[c.follower] ?? 0) + c.factor * own[c.driver]!;
    }

    final values = <Attribute, double>{};
    for (final a in Attribute.values) {
      var change = own[a]! * (1 - (weight[a] ?? 0));
      final extra = coupled[a];
      if (extra != null) {
        change += extra.limit(
          -dev.couplingCapPerSeason,
          dev.couplingCapPerSeason,
        );
      }
      final next = p.attributes[a] + change;
      values[a] = (next.limit(Attribute.min, Attribute.max) * 10).round() / 10;
    }

    var dynamic = p.potentialDynamic;
    if (age < g.dynamicFrozenFromAge) {
      dynamic += dev.dynamicChangePerYear * (minutesShare - 0.5) * 2;
      dynamic = dynamic.limit(0.0, dev.dynamicMax);
    }
    return p.copyWith(
      attributes: AttributeSet.fromMap(values),
      potentialDynamic: (dynamic * 10).round() / 10,
    );
  }
}
