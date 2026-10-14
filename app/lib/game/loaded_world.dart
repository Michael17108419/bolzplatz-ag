import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

/// The start world with its rules and a few numbers the screens need.
class LoadedWorld {
  LoadedWorld({
    required this.world,
    required this.rules,
    required this.strength,
  });

  /// Reads world and rules from their JSON texts.
  factory LoadedWorld.fromTexts(String worldText, String rulesText) {
    final world = WorldJson.decode(worldText);
    final rules = Rules.parse(rulesText).valueOrNull;
    if (rules == null) throw const FormatException('rules file is invalid');
    final byClub = <int, List<double>>{};
    for (final p in world.players) {
      final club = p.clubId;
      if (club == null) continue;
      byClub.putIfAbsent(club.value, () => []).add(
        WorldReport.overall(p, rules),
      );
    }
    final strength = <int, double>{};
    for (final e in byClub.entries) {
      final sorted = e.value..sort((a, b) => b.compareTo(a));
      final top = sorted.take(14).toList();
      strength[e.key] = top.reduce((a, b) => a + b) / top.length;
    }
    return LoadedWorld(world: world, rules: rules, strength: strength);
  }

  final World world;
  final Rules rules;

  /// Club strength: mean overall of the 14 best players, by club id.
  final Map<int, double> strength;

  Club club(ClubId id) => world.clubs.firstWhere((c) => c.id == id);

  /// The clubs of a league in the start season, strongest first.
  List<Club> clubsOf(League league) {
    final season = world.leagueSeasons.firstWhere(
      (ls) => ls.league.id == league.id,
    );
    final clubs = [for (final id in season.clubIds) club(id)];
    clubs.sort(
      (a, b) =>
          (strength[b.id.value] ?? 0).compareTo(strength[a.id.value] ?? 0),
    );
    return clubs;
  }
}

/// How the world is loaded. Tests replace this with a loader that reads the
/// files directly.
final worldLoaderProvider = Provider<Future<LoadedWorld> Function()>((ref) {
  return () async {
    final worldText = await rootBundle.loadString(
      'assets/data/world_2026_27.json',
    );
    final rulesText = await rootBundle.loadString(
      'assets/data/rules_2026_27.json',
    );
    // Let the loading screen draw once before the parsing blocks the thread.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return LoadedWorld.fromTexts(worldText, rulesText);
  };
});

final loadedWorldProvider = FutureProvider<LoadedWorld>((ref) {
  return ref.watch(worldLoaderProvider)();
});
