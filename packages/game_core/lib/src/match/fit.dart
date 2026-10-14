import '../model/attribute.dart';
import '../model/development.dart';
import '../model/player.dart';
import '../model/position.dart';
import '../rules/rules.dart';
import '../rules/tactics_rules.dart';
import 'limits.dart';

/// Rating of a player on a slot: position deduction, role familiarity and
/// the key values of position and role. Pure functions of player and rules.
class Fit {
  const Fit(this.rules);

  final Rules rules;

  /// Multiplier (0.4 to 1) for playing on [slot] instead of the own position.
  /// A secondary position takes less of the distance deduction: trained
  /// (at most [TacticsRules.trainedPointsMax] points), practised (a share of
  /// it); every other position is foreign and takes all of it.
  double positionMultiplier(Player player, Position slot) {
    if (player.position == slot) return 1;
    final tactics = rules.tactics;
    final distance = tactics.positionDistance[player.position]![slot]!;
    final double points;
    switch (player.secondaryPositions[slot]) {
      case PositionFamiliarity.trained:
        points = distance < tactics.trainedPointsMax
            ? distance
            : tactics.trainedPointsMax;
      case PositionFamiliarity.practised:
        points = distance * tactics.practisedFactor;
      case null:
        points = distance * tactics.unfamiliarFactor;
    }
    return (1 - points / 100).limit(0.0, 1.0);
  }

  /// True when the foot of the player is on the side of the wide [slot];
  /// null for central slots.
  bool? naturalSide(Player player, Position slot) {
    final side = slot.wideSide;
    return side == null ? null : side == player.foot;
  }

  /// Multiplier (below 1 for a weak foot) for shots, passes and crosses of
  /// the player on [slot]. Depends on the weak-foot stars and on how often
  /// the weak foot is used on that slot.
  double weakFootMultiplier(Player player, Position slot) {
    final tactics = rules.tactics;
    final penalty = tactics.weakFootPenalty[player.weakFoot]!;
    if (penalty == 0) return 1;
    final natural = naturalSide(player, slot);
    final key = natural == null ? 'central' : (natural ? 'natural' : 'inverse');
    return 1 - penalty * tactics.weakFootExposure[key]!;
  }

  /// Change of the role key values because foot and side fit the role or not
  /// (0 when the role or the slot does not care).
  double sideFactor(Player player, Position slot, RoleRule? role) {
    final side = role?.side;
    if (side == null) return 0;
    final natural = naturalSide(player, slot);
    if (natural == null) return 0;
    final matches = (side == 'natural') == natural;
    final f = rules.tactics.sideRoleFactor;
    return matches ? f : -f;
  }

  /// Relative change of the role key values (for example 0.04 for "+").
  double roleFactor(Player player, String? roleId) {
    if (roleId == null) return 0;
    final factors = rules.tactics.roleFamiliarityFactor;
    switch (player.roles[roleId] ?? RoleFamiliarity.basic) {
      case RoleFamiliarity.unfamiliar:
        return factors['minus']!;
      case RoleFamiliarity.basic:
        return factors['zero']!;
      case RoleFamiliarity.comfortable:
        return factors['plus']!;
      case RoleFamiliarity.expert:
        return factors['plus_plus']!;
    }
  }

  /// Attributes that count for a position (positive weights in the profile).
  List<Attribute> keyAttributes(Position position) {
    if (position.isGoalkeeper) {
      return [
        for (final a in Attribute.values)
          if (a.isGoalkeeping) a,
      ];
    }
    final profile = rules.generator.positionProfiles[position]!;
    return [
      for (final e in profile.entries)
        if (e.value > 0) e.key,
    ];
  }

  /// Mean of [attributes] of [player], each scaled by [positionMult] and,
  /// for role key values, by the role factor.
  double meanAttributes(
    Player player,
    Iterable<Attribute> attributes, {
    double positionMult = 1,
    double footMult = 1,
    RoleRule? role,
    double roleFactorValue = 0,
  }) {
    final footAttributes = rules.tactics.weakFootAttributes;
    var sum = 0.0;
    var n = 0;
    for (final a in attributes) {
      var v = player.attributes[a] * positionMult;
      if (footMult != 1 && footAttributes.contains(a)) v *= footMult;
      if (role != null && role.keyAttributes.contains(a)) {
        v *= 1 + roleFactorValue;
      }
      sum += v;
      n++;
    }
    return n == 0 ? 0 : sum / n;
  }

  /// Overall of the player on [slot], with deduction for a foreign position.
  double slotScore(Player player, Position slot) {
    return meanAttributes(
      player,
      keyAttributes(slot),
      positionMult: positionMultiplier(player, slot),
      footMult: weakFootMultiplier(player, slot),
    );
  }

  /// Fit of the player in his role on the slot, 0 to 1.
  double playerFit(Player player, Position slot, String? roleId) {
    final tactics = rules.tactics;
    final role = roleId == null ? null : tactics.role(roleId);
    final keys = role?.keyAttributes ?? keyAttributes(slot);
    final value = meanAttributes(
      player,
      keys,
      positionMult: positionMultiplier(player, slot),
      footMult: weakFootMultiplier(player, slot),
      role: role,
      roleFactorValue:
          roleFactor(player, roleId) + sideFactor(player, slot, role),
    );
    final low = tactics.playerFitLow;
    final high = tactics.playerFitHigh;
    return ((value - low) / (high - low)).limit(0.0, 1.0);
  }
}
