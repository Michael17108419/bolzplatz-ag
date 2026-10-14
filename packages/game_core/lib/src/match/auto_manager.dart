import '../model/ids.dart';
import '../model/player.dart';
import '../model/position.dart';
import '../rules/rules.dart';
import '../rules/tactics_rules.dart';
import 'fit.dart';
import 'system_fit.dart';
import 'team_sheet.dart';

/// Builds a sensible team sheet for AI clubs and for the autopilot:
/// best formation for the squad, best role per slot, best system.
class AutoManager {
  const AutoManager(this.rules);

  final Rules rules;

  /// Picks the best eleven for [formation], goalkeeper slot first.
  /// Returns the players in slot order and the sum of their slot scores.
  ({List<Player> players, double score})? pickEleven(
    List<Player> available,
    FormationRule formation,
  ) {
    final fit = Fit(rules);
    final slots = formation.slots;
    // Fill the scarcest positions first: goalkeeper, then the rest in order
    // of how few natural candidates exist.
    final order = List<int>.generate(slots.length, (i) => i)
      ..sort((a, b) {
        final ca = available.where((p) => p.position == slots[a]).length;
        final cb = available.where((p) => p.position == slots[b]).length;
        return ca != cb ? ca.compareTo(cb) : a.compareTo(b);
      });
    final taken = <PlayerId>{};
    final chosen = List<Player?>.filled(slots.length, null);
    var total = 0.0;
    for (final index in order) {
      Player? best;
      var bestScore = -1.0;
      for (final p in available) {
        if (taken.contains(p.id)) continue;
        if (slots[index].isGoalkeeper != p.position.isGoalkeeper) continue;
        final s = fit.slotScore(p, slots[index]);
        if (s > bestScore) {
          bestScore = s;
          best = p;
        }
      }
      if (best == null) return null;
      taken.add(best.id);
      chosen[index] = best;
      total += bestScore;
    }
    return (players: [for (final p in chosen) p!], score: total);
  }

  /// Best role for [player] on [slot] given the formation.
  String? bestRole(Player player, Position slot, FormationRule formation) {
    final fit = Fit(rules);
    String? best;
    var bestFit = -1.0;
    for (final role in rules.tactics.roles) {
      if (!role.positions.contains(slot)) continue;
      if (role.onlyWithBackThreeOrFive && formation.backLine == 4) continue;
      final f = fit.playerFit(player, slot, role.id);
      if (f > bestFit) {
        bestFit = f;
        best = role.id;
      }
    }
    return best;
  }

  /// Complete sheet for [squad]. [exclude] holds players who cannot play.
  /// Returns null if no formation can be filled.
  TeamSheet? build(
    List<Player> squad, {
    Set<PlayerId> exclude = const {},
    String? formationId,
  }) {
    final available = [
      for (final p in squad)
        if (!exclude.contains(p.id)) p,
    ];
    final formations = formationId == null
        ? rules.tactics.formations
        : [rules.tactics.formation(formationId)];
    FormationRule? bestFormation;
    List<Player>? bestEleven;
    var bestScore = -1.0;
    for (final f in formations) {
      final picked = pickEleven(available, f);
      if (picked == null) continue;
      if (picked.score > bestScore) {
        bestScore = picked.score;
        bestFormation = f;
        bestEleven = picked.players;
      }
    }
    if (bestFormation == null || bestEleven == null) return null;

    final roles = [
      for (var i = 0; i < bestEleven.length; i++)
        bestRole(bestEleven[i], bestFormation.slots[i], bestFormation),
    ];
    final used = {for (final p in bestEleven) p.id};
    final rest = [
      for (final p in available)
        if (!used.contains(p.id)) p,
    ]..sort((a, b) => _overall(b).compareTo(_overall(a)));
    final bench = <Player>[];
    final keeper = rest.where((p) => p.position.isGoalkeeper).firstOrNull;
    if (keeper != null) bench.add(keeper);
    for (final p in rest) {
      if (bench.length >= 7) break;
      if (p.position.isGoalkeeper) continue;
      if (!bench.contains(p)) bench.add(p);
    }
    final system = SystemFit(rules).bestSystem(bestEleven);
    return TeamSheet(
      formationId: bestFormation.id,
      systemId: system,
      startingXi: [for (final p in bestEleven) p.id],
      slotRoles: roles,
      bench: [for (final p in bench) p.id],
    );
  }

  double _overall(Player p) => Fit(rules).slotScore(p, p.position);
}
