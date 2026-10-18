import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../ui/lineup_page.dart' show captainOf;
import 'career.dart';
import 'lineup.dart';
import 'loaded_world.dart';
import 'season_game.dart';

/// The dressing room of the own club (engine 2, step 10f1): types, ranks,
/// council and mood, with the captain of the current line-up.
final cabinProvider = Provider<Cabin?>((ref) {
  final career = ref.watch(careerProvider);
  final loaded = ref.watch(loadedWorldProvider).value;
  final today = ref.watch(todayProvider);
  if (career == null || loaded == null || today == null) return null;
  final squad = clubPlayers(loaded, career.clubId);
  final sheet = ref.watch(lineupProvider)?.sheet;
  return Cabin.of(
    squad.values.toList(),
    loaded.rules.season.cabin,
    today: today,
    strength: loaded.overall,
    captain: sheet == null ? null : captainOf(sheet, squad),
  );
});
