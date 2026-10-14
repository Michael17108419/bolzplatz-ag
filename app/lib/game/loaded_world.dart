import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

/// The start world with its rules and a few numbers the screens need.
class LoadedWorld {
  LoadedWorld({
    required this.world,
    required this.rules,
    required this.names,
    required this.strengths,
  });

  /// Reads world, rules and name lists from their JSON texts.
  factory LoadedWorld.fromTexts(
    String worldText,
    String rulesText,
    String namesText,
  ) {
    final world = WorldJson.decode(worldText);
    final rules = Rules.parse(rulesText).valueOrNull;
    if (rules == null) throw const FormatException('rules file is invalid');
    return LoadedWorld(
      world: world,
      rules: rules,
      names: NameLists.fromJson(namesText),
      strengths: ClubStrengths.compute(world, rules),
    );
  }

  final World world;
  final Rules rules;
  final NameLists names;

  /// Club strength: mean overall of the 14 best players.
  final Map<ClubId, double> strengths;

  late final OfferGenerator offerGenerator = OfferGenerator(
    rules: rules,
    world: world,
    names: names,
    strengths: strengths,
  );

  Club club(ClubId id) => world.clubs.firstWhere((c) => c.id == id);

  /// The clubs of a league in the start season, strongest first.
  List<Club> clubsOf(League league) {
    final season = world.leagueSeasons.firstWhere(
      (ls) => ls.league.id == league.id,
    );
    final clubs = [for (final id in season.clubIds) club(id)];
    clubs.sort(
      (a, b) => (strengths[b.id] ?? 0).compareTo(strengths[a.id] ?? 0),
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
    final namesText = await rootBundle.loadString('assets/data/names_de.json');
    // Let the loading screen draw once before the parsing blocks the thread.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return LoadedWorld.fromTexts(worldText, rulesText, namesText);
  };
});

final loadedWorldProvider = FutureProvider<LoadedWorld>((ref) {
  return ref.watch(worldLoaderProvider)();
});
