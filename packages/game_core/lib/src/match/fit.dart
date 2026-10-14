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
  /// Without secondary positions in the model, any other position counts as
  /// unfamiliar and takes the full distance deduction.
  double positionMultiplier(Player player, Position slot) {
    if (player.position == slot) return 1;
    final tactics = rules.tactics;
    final points =
        tactics.positionDistance[player.position]![slot]! *
        tactics.unfamiliarFactor;
    return (1 - points / 100).limit(0.0, 1.0);
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
    RoleRule? role,
    double roleFactorValue = 0,
  }) {
    var sum = 0.0;
    var n = 0;
    for (final a in attributes) {
      var v = player.attributes[a] * positionMult;
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
      role: role,
      roleFactorValue: roleFactor(player, roleId),
    );
    final low = tactics.playerFitLow;
    final high = tactics.playerFitHigh;
    return ((value - low) / (high - low)).limit(0.0, 1.0);
  }
}
