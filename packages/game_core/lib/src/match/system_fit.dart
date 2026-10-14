import '../model/player.dart';
import '../rules/rules.dart';
import 'limits.dart';

/// How well a group of players fits a playing system.
class SystemFit {
  const SystemFit(this.rules);

  final Rules rules;

  double _raw(List<Player> outfield, String systemId) {
    final keys = rules.tactics.system(systemId).keyAttributes;
    if (outfield.isEmpty || keys.isEmpty) return 0;
    var sum = 0.0;
    for (final p in outfield) {
      var s = 0.0;
      for (final a in keys) {
        s += p.attributes[a];
      }
      sum += s / keys.length;
    }
    return sum / outfield.length;
  }

  /// Fit relative to the mean over all systems (0 means average), plus a
  /// bonus for special abilities that belong to the system.
  double fit(List<Player> eleven, String systemId) {
    final tactics = rules.tactics;
    final outfield = [
      for (final p in eleven)
        if (!p.position.isGoalkeeper) p,
    ];
    var meanAll = 0.0;
    for (final s in tactics.systems) {
      meanAll += _raw(outfield, s.id);
    }
    meanAll /= tactics.systems.length;
    final cfg = tactics.systemFit;
    final relative = (_raw(outfield, systemId) - meanAll) / cfg.divisor;
    final wanted = tactics.system(systemId).abilities;
    var count = 0;
    for (final p in eleven) {
      for (final a in p.abilities) {
        if (wanted.contains(a.type)) count++;
      }
    }
    final bonus = (cfg.abilityBonus * count).limit(0.0, cfg.abilityCap);
    return relative + bonus;
  }

  /// Strength factor of the system bonus for the given fit.
  double scale(double fit) {
    final cfg = rules.tactics.systemFit;
    return (1 + cfg.slope * fit).limit(cfg.scaleMin, cfg.scaleMax);
  }

  String bestSystem(List<Player> eleven) {
    String? best;
    var bestFit = double.negativeInfinity;
    for (final s in rules.tactics.systems) {
      final f = fit(eleven, s.id);
      if (f > bestFit) {
        bestFit = f;
        best = s.id;
      }
    }
    return best!;
  }
}
