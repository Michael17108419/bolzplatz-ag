import 'dart:math' as math;

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
  }) => _step(
    p,
    date: newSeasonStart,
    rng: rng,
    minutesShare: minutesShare,
    fraction: 1,
    focus: const {},
  );

  /// The player [weeks] weeks later (step 11b): that share of the year,
  /// with the noise of that time. [focus] moves the growth between the attributes (1
  /// is neutral; training a group makes it grow faster and decline slower)
  /// and [volume] scales it for the amount of training.
  Player week(
    Player p, {
    required GameDate date,
    required SeededRandom rng,
    required double minutesShare,
    Map<Attribute, double> focus = const {},
    double volume = 1,
    int weeks = 1,
  }) => _step(
    p,
    date: date,
    rng: rng,
    minutesShare: minutesShare,
    fraction: weeks / 52,
    focus: focus,
    volume: volume,
  );

  Player _step(
    Player p, {
    required GameDate date,
    required SeededRandom rng,
    required double minutesShare,
    required double fraction,
    required Map<Attribute, double> focus,
    double volume = 1,
  }) {
    final g = rules.generator;
    final dev = rules.development;
    final age = p.ageOn(date);
    final noise = math.sqrt(fraction);
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
      var delta =
          (_ageAdjust(curve, age - s) - _ageAdjust(curve, age - 1 - s)) *
          fraction;
      final f = focus[a] ?? 1;
      if (delta > 0) {
        delta *= headroom * playing * f * volume;
      } else if (delta < 0) {
        // Training an attribute slows its decline.
        delta *= (2 - f).limit(0.5, 1.5);
      }
      delta += rng.nextGaussian() * dev.annualNoiseSd * noise;
      own[a] = delta;
    }

    // A follower takes part of its change from its drivers and the rest from
    // its own age curve, so couplings move the timing of the change but do
    // not add growth on top of the age curve over a whole career.
    final coupled = <Attribute, double>{};
    final weight = <Attribute, double>{};
    for (final c in dev.couplings) {
      if (c.follower.isGoalkeeping && !isKeeper) continue;
      coupled[c.follower] =
          (coupled[c.follower] ?? 0) + c.factor * own[c.driver]!;
      weight[c.follower] = (weight[c.follower] ?? 0) + c.factor;
    }

    final values = <Attribute, double>{};
    for (final a in Attribute.values) {
      var change = own[a]! * (1 - (weight[a] ?? 0));
      final extra = coupled[a];
      if (extra != null) {
        final cap = dev.couplingCapPerSeason * fraction;
        change += extra.limit(-cap, cap);
      }
      final next = (p.attributes[a] + change).limit(
        Attribute.min,
        Attribute.max,
      );
      // A year rounds to tenths; weekly steps are too small for that.
      values[a] = fraction >= 1 ? (next * 10).round() / 10 : next;
    }

    // The dynamic part of the potential rises with playing time and with a
    // professional, ambitious character, and falls without them (also with
    // a party life). It is frozen from [dynamicFrozenFromAge].
    var dynamic = p.potentialDynamic;
    if (age < g.dynamicFrozenFromAge) {
      var change = dev.dynamicChangePerYear * (minutesShare - 0.5) * 2;
      for (final e in dev.dynamicTraitEffect.entries) {
        change += e.value * (p.traits[e.key]! - 50) / 50;
      }
      dynamic = (dynamic + change * fraction).limit(
        -dev.dynamicMax,
        dev.dynamicMax,
      );
    }

    double tenth(double x) => fraction >= 1 ? (x * 10).round() / 10 : x;
    final traits = {
      for (final e in p.traits.entries)
        e.key: tenth(
          (e.value + dev.traitDelta(e.key, age) * fraction).limit(1.0, 100.0),
        ),
    };
    return p.copyWith(
      attributes: AttributeSet.fromMap(values),
      potentialDynamic: tenth(dynamic),
      traits: traits,
    );
  }
}
