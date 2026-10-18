import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

/// The start world with its rules and a few numbers the screens need.
class LoadedWorld {
  LoadedWorld({
    required this.world,
    required this.rules,
    required this.names,
    required this.calendarRules,
    required this.strengths,
    this.referees,
  });

  /// Reads world, rules and name lists from their JSON texts.
  factory LoadedWorld.fromTexts(
    String worldText,
    String rulesText,
    String namesText,
    String calendarText, {
    String? refereesText,
  }) {
    final world = WorldJson.decode(worldText);
    final rules = Rules.parse(rulesText).valueOrNull;
    if (rules == null) throw const FormatException('rules file is invalid');
    return LoadedWorld(
      world: world,
      rules: rules,
      names: NameLists.fromJson(namesText),
      calendarRules: CalendarRules.fromJsonString(calendarText),
      strengths: ClubStrengths.compute(world, rules),
      referees: refereesText == null
          ? null
          : RefereePool.fromJson(refereesText),
    );
  }

  final World world;

  /// The referees of the matches (engine 2, step 10e1); null in tests that
  /// do not load them (every match then has a plain referee).
  final RefereePool? referees;
  final Rules rules;
  final NameLists names;

  /// Where matches, breaks and holidays lie on the calendar.
  final CalendarRules calendarRules;

  /// Club strength: mean overall of the 14 best players.
  final Map<ClubId, double> strengths;

  late final OfferGenerator offerGenerator = OfferGenerator(
    rules: rules,
    world: world,
    names: names,
    strengths: strengths,
  );

  Club club(ClubId id) => world.clubs.firstWhere((c) => c.id == id);

  late final Map<PlayerId, Player> _playersById = {
    for (final p in world.players) p.id: p,
  };

  /// A player of the start world by id, null if there is none.
  Player? player(PlayerId id) => _playersById[id];

  /// The overall strength of a player on his position (0 to 100).
  double overall(Player p) => WorldReport.overall(p, rules);

  /// The date the screens show the world at (the start of the season).
  GameDate get today => world.season.start;

  /// The same rules and clubs with the squads and leagues of the season
  /// described by [state].
  LoadedWorld atSeason(SeasonState state) {
    final next = SeasonSnapshot.worldOf(state, world);
    return LoadedWorld(
      world: next,
      rules: rules,
      names: names,
      calendarRules: calendarRules,
      strengths: ClubStrengths.compute(next, rules),
      referees: referees,
    );
  }

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
    final calendarText = await rootBundle.loadString(
      'assets/data/calendar_rules.json',
    );
    final refereesText = await rootBundle.loadString(
      'assets/data/referees_de.json',
    );
    // Let the loading screen draw once before the parsing blocks the thread.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return LoadedWorld.fromTexts(
      worldText,
      rulesText,
      namesText,
      calendarText,
      refereesText: refereesText,
    );
  };
});

/// The world as it was generated (first season).
final startWorldProvider = FutureProvider<LoadedWorld>((ref) {
  return ref.watch(worldLoaderProvider)();
});

/// The state of the world at the start of the current season, null while
/// the first season runs (the start world is then the current one).
class WorldStateNotifier extends Notifier<SeasonState?> {
  @override
  SeasonState? build() => null;

  void set(SeasonState? state) => this.state = state;
}

final worldStateProvider = NotifierProvider<WorldStateNotifier, SeasonState?>(
  WorldStateNotifier.new,
);

/// The world the screens show: the start world in the first season, later
/// the one built from the state of the current season.
final loadedWorldProvider = FutureProvider<LoadedWorld>((ref) async {
  final base = await ref.watch(startWorldProvider.future);
  final state = ref.watch(worldStateProvider);
  return state == null ? base : base.atSeason(state);
});
