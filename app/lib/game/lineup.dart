import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import 'career.dart';
import 'loaded_world.dart';
import 'season_game.dart';

/// What is wrong with a line-up, if anything. A wrong line-up blocks
/// "Weiter" (document "Büro als Schreibtisch-Szene", section 4).
enum LineupProblem { none, missing, wrongCount, keeper, duplicate, foreign }

/// The line-up of the own club: the team sheet plus whether the manager has
/// looked at it ("Passt so").
class LineupState {
  const LineupState({required this.sheet, this.reviewed = false});

  final TeamSheet sheet;
  final bool reviewed;

  LineupState copyWith({TeamSheet? sheet, bool? reviewed}) => LineupState(
    sheet: sheet ?? this.sheet,
    reviewed: reviewed ?? this.reviewed,
  );
}

/// The number of bench places of the own club: it depends on the league
/// level and comes from the rules.
int benchPlaces(Rules rules, Career career) =>
    rules.tactics.benchSize(career.league.level);

/// Checks a sheet against the squad.
LineupProblem checkLineup(
  TeamSheet sheet,
  FormationRule formation,
  Map<PlayerId, Player> squad,
) {
  final xi = sheet.startingXi;
  if (xi.length != formation.slots.length) return LineupProblem.wrongCount;
  if (xi.toSet().length != xi.length ||
      xi.any(sheet.bench.contains) ||
      sheet.bench.toSet().length != sheet.bench.length) {
    return LineupProblem.duplicate;
  }
  for (final id in [...xi, ...sheet.bench]) {
    if (!squad.containsKey(id)) return LineupProblem.foreign;
  }
  for (var i = 0; i < xi.length; i++) {
    if (squad[xi[i]]!.position.isGoalkeeper !=
        formation.slots[i].isGoalkeeper) {
      return LineupProblem.keeper;
    }
  }
  return LineupProblem.none;
}

/// Numbers for the team preview.
class LineupPreview {
  const LineupPreview({
    required this.strength,
    required this.roleFit,
    required this.systemFit,
    required this.outOfPosition,
    required this.slotScores,
    required this.slotFits,
  });

  /// Mean rating of the eleven on their slots (0 to 100).
  final double strength;

  /// Mean fit of the eleven in their roles (0 to 1).
  final double roleFit;

  /// Fit of the eleven to the chosen system (0 means average).
  final double systemFit;

  /// Number of players not on their main position.
  final int outOfPosition;

  final List<double> slotScores;
  final List<double> slotFits;
}

/// Rates a sheet. Pure function of sheet, squad and rules.
LineupPreview previewLineup(
  TeamSheet sheet,
  Map<PlayerId, Player> squad,
  Rules rules,
) {
  final formation = rules.tactics.formation(sheet.formationId);
  final fit = Fit(rules);
  final eleven = [for (final id in sheet.startingXi) squad[id]!];
  final scores = <double>[];
  final fits = <double>[];
  var out = 0;
  for (var i = 0; i < eleven.length; i++) {
    final slot = formation.slots[i];
    scores.add(fit.slotScore(eleven[i], slot));
    fits.add(fit.playerFit(eleven[i], slot, sheet.slotRoles[i]));
    if (eleven[i].position != slot) out++;
  }
  double mean(List<double> v) =>
      v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
  return LineupPreview(
    strength: mean(scores),
    roleFit: mean(fits),
    systemFit: SystemFit(rules).fit(eleven, sheet.systemId),
    outOfPosition: out,
    slotScores: scores,
    slotFits: fits,
  );
}

/// The players of the own club, by id.
Map<PlayerId, Player> clubPlayers(LoadedWorld loaded, ClubId club) => {
  for (final p in loaded.world.players)
    if (p.clubId == club) p.id: p,
};

class LineupNotifier extends Notifier<LineupState?> {
  @override
  LineupState? build() {
    final career = ref.watch(careerProvider);
    final loaded = ref.watch(loadedWorldProvider).value;
    if (career == null || loaded == null) return null;
    final squad = clubPlayers(loaded, career.clubId).values.toList();
    final sheet = AutoManager(loaded.rules)
        .build(squad, benchSize: benchPlaces(loaded.rules, career));
    return sheet == null ? null : LineupState(sheet: sheet);
  }

  ({Rules rules, Map<PlayerId, Player> squad, int bench})? _context() {
    final career = ref.read(careerProvider);
    final loaded = ref.read(loadedWorldProvider).value;
    if (career == null || loaded == null) return null;
    return (
      rules: loaded.rules,
      squad: clubPlayers(loaded, career.clubId),
      bench: benchPlaces(loaded.rules, career),
    );
  }

  void _set(TeamSheet sheet) {
    final now = state;
    if (now == null) return;
    state = now.copyWith(sheet: sheet, reviewed: true);
  }

  /// The assistant builds a sheet without the players who are out.
  TeamSheet? _build(
    Rules rules,
    Map<PlayerId, Player> squad, {
    required String formationId,
    int? bench,
  }) {
    final out = ref.read(ownAbsencesProvider).keys.toSet();
    final auto = AutoManager(rules);
    final players = squad.values.toList();
    return auto.build(
          players,
          exclude: out,
          formationId: formationId,
          benchSize: bench,
        ) ??
        auto.build(players, formationId: formationId, benchSize: bench);
  }

  /// Switches the formation; the assistant picks the eleven anew, system and
  /// sliders stay.
  void setFormation(String id) {
    final now = state;
    final c = _context();
    if (now == null || c == null) return;
    final built = _build(c.rules, c.squad, formationId: id, bench: c.bench);
    if (built == null) return;
    _set(
      built.copyWith(
        systemId: now.sheet.systemId,
        pressing: now.sheet.pressing,
        tempo: now.sheet.tempo,
        defensiveLine: now.sheet.defensiveLine,
      ),
    );
  }

  /// The assistant picks the eleven, the bench and the best system anew for
  /// the current formation.
  void autoPick() {
    final now = state;
    final c = _context();
    if (now == null || c == null) return;
    final built = _build(c.rules, c.squad, formationId: now.sheet.formationId);
    if (built == null) return;
    _set(
      built.copyWith(
        pressing: now.sheet.pressing,
        tempo: now.sheet.tempo,
        defensiveLine: now.sheet.defensiveLine,
      ),
    );
  }

  /// Puts [playerId] on [slot]. A player who is already in the eleven swaps
  /// places, a bench player hands his bench place to the one he replaces.
  /// Returns false if a goalkeeper and a field slot would be mixed up.
  bool assign(int slot, PlayerId playerId) {
    final now = state;
    final c = _context();
    if (now == null || c == null) return false;
    final player = c.squad[playerId];
    if (player == null) return false;
    final sheet = now.sheet;
    final formation = c.rules.tactics.formation(sheet.formationId);
    if (formation.slots[slot].isGoalkeeper != player.position.isGoalkeeper) {
      return false;
    }
    final auto = AutoManager(c.rules);
    final xi = [...sheet.startingXi];
    final roles = [...sheet.slotRoles];
    final bench = [...sheet.bench];
    final old = xi[slot];
    if (old == playerId) return true;
    final other = xi.indexOf(playerId);
    if (other >= 0) {
      final oldPlayer = c.squad[old]!;
      if (formation.slots[other].isGoalkeeper !=
          oldPlayer.position.isGoalkeeper) {
        return false;
      }
      xi[other] = old;
      roles[other] = auto.bestRole(
        oldPlayer,
        formation.slots[other],
        formation,
      );
    } else {
      final at = bench.indexOf(playerId);
      if (at >= 0) {
        bench[at] = old;
      } else if (bench.length < c.bench) {
        bench.add(old);
      }
    }
    xi[slot] = playerId;
    roles[slot] = auto.bestRole(player, formation.slots[slot], formation);
    _set(sheet.copyWith(startingXi: xi, slotRoles: roles, bench: bench));
    return true;
  }

  /// Bench place on or off for a player who is not in the eleven. Returns
  /// false if the bench is full.
  bool toggleBench(PlayerId playerId) {
    final now = state;
    final c = _context();
    if (now == null || c == null) return false;
    final sheet = now.sheet;
    if (sheet.startingXi.contains(playerId)) return false;
    final bench = [...sheet.bench];
    if (bench.remove(playerId)) {
      _set(sheet.copyWith(bench: bench));
      return true;
    }
    if (bench.length >= c.bench) return false;
    bench.add(playerId);
    _set(sheet.copyWith(bench: bench));
    return true;
  }

  void setRole(int slot, String? role) {
    final now = state;
    if (now == null) return;
    final roles = [...now.sheet.slotRoles];
    roles[slot] = role;
    _set(now.sheet.copyWith(slotRoles: roles));
  }

  void setSystem(String id) {
    final now = state;
    if (now == null) return;
    _set(now.sheet.copyWith(systemId: id));
  }

  /// [slider] is a slider id of the rules; [level] 0 to 2.
  void setSlider(String slider, int level) {
    final now = state;
    if (now == null) return;
    final s = now.sheet;
    _set(switch (slider) {
      'pressing' => s.copyWith(pressing: level),
      'tempo' => s.copyWith(tempo: level),
      _ => s.copyWith(defensiveLine: level),
    });
  }

  /// Takes over the line-up of a saved game.
  void restore(TeamSheet sheet, {required bool reviewed}) {
    if (state == null) return;
    state = LineupState(sheet: sheet, reviewed: reviewed);
  }

  /// "Passt so": the manager has looked at the line-up.
  void review() {
    final now = state;
    if (now == null || now.reviewed) return;
    state = now.copyWith(reviewed: true);
  }
}

final lineupProvider = NotifierProvider<LineupNotifier, LineupState?>(
  LineupNotifier.new,
);

/// What blocks "Weiter" because of the line-up; none if it can be played.
LineupProblem lineupProblemOf(WidgetRef ref) {
  final lineup = ref.read(lineupProvider);
  final career = ref.read(careerProvider);
  final loaded = ref.read(loadedWorldProvider).value;
  if (lineup == null || career == null || loaded == null) {
    return LineupProblem.missing;
  }
  return checkLineup(
    lineup.sheet,
    loaded.rules.tactics.formation(lineup.sheet.formationId),
    clubPlayers(loaded, career.clubId),
  );
}
