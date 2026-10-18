import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'career.dart';
import 'lineup.dart';
import 'loaded_world.dart';
import 'mail_state.dart';
import 'planning.dart';
import 'season_game.dart';

/// The places a game can be saved to: the automatic one and three of the
/// player's own.
const List<String> saveSlots = ['auto', '1', '2', '3'];

/// One saved game. It keeps what the player did, not the state of the
/// world: the game core is deterministic, so playing the same inputs again
/// gives the same world.
class SaveData {
  SaveData({
    required this.savedAt,
    required this.trainer,
    required this.seed,
    required this.wishClubId,
    required this.offerClubId,
    required this.clubName,
    required this.leagueName,
    required this.date,
    required this.matchday,
    required this.matchdays,
    required this.initialSheet,
    required this.log,
    required this.lineup,
    required this.lineupReviewed,
    required this.mailRead,
    this.vacation,
    this.offerData,
    this.leagueId,
    this.goal,
    this.base,
    this.seasons = const [],
    this.live,
  });

  /// Bump when the format changes; older files are then refused with a hint.
  /// 2: engine 2 (zones, protocol, stoppage time) replays matches
  /// differently, so saves of version 1 can not be continued.
  /// 3: step 10e (referees, VAR, sports court, grounds, weather) plays
  /// matches differently again and logs court decisions.
  /// 4: steps 10f to 10h (mood, chemistry, coaches, instructions, plans,
  /// shouts, home advantage) play matches differently again and log talks
  /// and instructions.
  static const int version = 4;

  factory SaveData.fromJson(Map<String, dynamic> m) {
    if (m['version'] != version) {
      throw FormatException('Unknown save version ${m['version']}');
    }
    final date = m['date'] as List<dynamic>;
    return SaveData(
      savedAt: DateTime.parse(m['saved_at'] as String),
      trainer: m['trainer'] as Map<String, dynamic>,
      seed: m['seed'] as int,
      wishClubId: m['wish'] as int?,
      offerClubId: m['offer'] as int,
      clubName: m['club'] as String,
      leagueName: m['league'] as String,
      date: GameDate(date[0] as int, date[1] as int, date[2] as int),
      matchday: m['matchday'] as int,
      matchdays: m['matchdays'] as int,
      initialSheet: m['initial_sheet'] as Map<String, dynamic>?,
      log: [
        for (final e in m['log'] as List<dynamic>) e as Map<String, dynamic>,
      ],
      lineup: m['lineup'] as Map<String, dynamic>?,
      lineupReviewed: m['lineup_reviewed'] as bool,
      mailRead: [for (final e in m['mail'] as List<dynamic>) e as String],
      vacation: m['vacation'] == null
          ? null
          : [for (final e in m['vacation'] as List<dynamic>) e as int],
      offerData: m['offer_data'] as Map<String, dynamic>?,
      leagueId: m['league_id'] as int?,
      goal: m['goal'] as String?,
      base: m['base'] as String?,
      seasons: [
        for (final e in (m['seasons'] as List<dynamic>?) ?? const [])
          SeasonRecord.fromJson(e as Map<String, dynamic>),
      ],
      live: m['live'] as Map<String, dynamic>?,
    );
  }

  /// Null if [text] is not a save of this version.
  static SaveData? tryParse(String text) {
    try {
      return SaveData.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  final DateTime savedAt;
  final Map<String, dynamic> trainer;
  final int seed;
  final int? wishClubId;
  final int offerClubId;
  final String clubName;
  final String leagueName;

  /// The date in the game.
  final GameDate date;

  /// Matchdays of the own league played so far, and in all.
  final int matchday;
  final int matchdays;
  final Map<String, dynamic>? initialSheet;
  final List<Map<String, dynamic>> log;
  final Map<String, dynamic>? lineup;
  final bool lineupReviewed;
  final List<String> mailRead;

  /// The free days of the squad (epoch days); null in older saves.
  final List<int>? vacation;

  /// The accepted offer as it was; older saves regenerate it from the seed.
  final Map<String, dynamic>? offerData;

  /// League and goal of the running season (null in the first season).
  final int? leagueId;
  final String? goal;

  /// The world at the start of the season, packed (gzip, base64). Null in
  /// the first season of a career.
  final String? base;

  /// The seasons finished so far.
  final List<SeasonRecord> seasons;

  /// A match that was under way when the game was saved: its minute and the
  /// changes made so far. The log then ends with the line-up it started
  /// with. Null between matches.
  final Map<String, dynamic>? live;

  String get trainerName => trainer['name'] as String;

  String encode() => jsonEncode({
    'version': version,
    'saved_at': savedAt.toIso8601String(),
    'trainer': trainer,
    'seed': seed,
    'wish': wishClubId,
    'offer': offerClubId,
    'club': clubName,
    'league': leagueName,
    'date': [date.year, date.month, date.day],
    'matchday': matchday,
    'matchdays': matchdays,
    'initial_sheet': initialSheet,
    'log': log,
    'lineup': lineup,
    'lineup_reviewed': lineupReviewed,
    'mail': mailRead,
    'vacation': vacation,
    'offer_data': offerData,
    'league_id': leagueId,
    'goal': goal,
    'base': base,
    'seasons': [for (final r in seasons) r.toJson()],
    'live': live,
  });
}

/// The state of a season as packed text (gzip, base64).
String packSeasonState(SeasonState state) => base64.encode(
  GZipEncoder().encodeBytes(utf8.encode(SeasonSnapshot.encode(state))),
);

/// Reads a state written by [packSeasonState].
SeasonState unpackSeasonState(String text, Map<ClubId, Club> clubs) =>
    SeasonSnapshot.decode(
      utf8.decode(GZipDecoder().decodeBytes(base64.decode(text))),
      clubs,
    );

/// Like [unpackSeasonState], but on another isolate (on the web: in a
/// worker-less fallback): a saved game of a later
/// season carries a few megabytes, and the window must not freeze meanwhile.
Future<SeasonState> unpackSeasonStateInBackground(
  String text,
  Map<ClubId, Club> clubs,
) => compute(_unpack, (text, clubs));

SeasonState _unpack((String, Map<ClubId, Club>) args) =>
    unpackSeasonState(args.$1, args.$2);

/// Where the saved games are kept (one text per slot).
abstract class SaveRepository {
  Future<String?> read(String slot);

  Future<void> write(String slot, String text);

  Future<void> delete(String slot);
}

/// Keeps the saves in the local storage of the app.
class PrefsSaveRepository implements SaveRepository {
  String _key(String slot) => 'save_$slot';

  @override
  Future<String?> read(String slot) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(slot));
  }

  @override
  Future<void> write(String slot, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(slot), text);
  }

  @override
  Future<void> delete(String slot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(slot));
  }
}

final saveRepositoryProvider = Provider<SaveRepository>(
  (ref) => PrefsSaveRepository(),
);

/// A slot as the list shows it: empty, a game, or a file that cannot be
/// read (other version, damaged).
class SaveSlotView {
  const SaveSlotView(this.slot, this.data, {this.unreadable = false});

  final String slot;
  final SaveData? data;
  final bool unreadable;

  bool get isEmpty => data == null && !unreadable;
}

/// Saves and loads games, and saves the automatic slot.
class SaveService {
  SaveService(this._ref);

  final Ref _ref;

  // The packed state of the current season is kept until the season changes.
  SeasonState? _packedFor;
  String? _packed;

  String? _packedBase() {
    final state = _ref.read(worldStateProvider);
    if (state == null) return null;
    if (!identical(state, _packedFor)) {
      _packed = packSeasonState(state);
      _packedFor = state;
    }
    return _packed;
  }

  /// The game as it stands, or null if there is nothing to save (no career
  /// yet). A match under way is saved with its minute and changes; a preview
  /// that was only opened is not.
  SaveData? snapshot({DateTime? now}) {
    final career = _ref.read(careerProvider);
    final game = _ref.read(seasonProvider);
    if (career == null || game == null) return null;
    final live = game.liveState;
    final lineup = _ref.read(lineupProvider);
    return SaveData(
      savedAt: now ?? DateTime.now(),
      trainer: career.trainer.toJson(),
      seed: career.seed,
      wishClubId: career.wishClubId?.value,
      offerClubId: career.offer.club.id.value,
      clubName: career.offer.club.name,
      leagueName: career.league.name,
      date: game.today,
      matchday: game.played,
      matchdays: game.ownDays,
      initialSheet: game.initialSheet?.toJson(),
      log: live == null ? game.savableLog : game.log,
      live: live,
      lineup: lineup?.sheet.toJson(),
      lineupReviewed: lineup?.reviewed ?? false,
      mailRead: _ref.read(mailReadProvider).toList()..sort(),
      vacation: _ref.read(vacationProvider).toList()..sort(),
      offerData: career.offer.toJson(),
      leagueId: career.league.id.value,
      goal: career.goal.name,
      base: _packedBase(),
      seasons: _ref.read(seasonHistoryProvider),
    );
  }

  /// Saves to [slot]. False if there is nothing to save right now.
  Future<bool> save(String slot) async {
    final data = snapshot();
    if (data == null) return false;
    await _ref.read(saveRepositoryProvider).write(slot, data.encode());
    return true;
  }

  /// Saves the automatic slot; a failure only means no automatic save.
  Future<void> autosave() async {
    try {
      await save('auto');
    } catch (_) {
      // No storage (for example in tests): the game goes on.
    }
  }

  Future<void> delete(String slot) =>
      _ref.read(saveRepositoryProvider).delete(slot);

  /// All slots in order.
  Future<List<SaveSlotView>> slots() async {
    final repo = _ref.read(saveRepositoryProvider);
    final out = <SaveSlotView>[];
    for (final slot in saveSlots) {
      String? text;
      try {
        text = await repo.read(slot);
      } catch (_) {
        text = null;
      }
      if (text == null) {
        out.add(SaveSlotView(slot, null));
        continue;
      }
      final data = SaveData.tryParse(text);
      out.add(SaveSlotView(slot, data, unreadable: data == null));
    }
    return out;
  }

  /// Puts the game back as it was saved. False if the saved career does
  /// not fit the world any more.
  Future<bool> load(SaveData data) async {
    final start = await _ref.read(startWorldProvider.future);
    final world = start.world;
    final clubs = {for (final c in world.clubs) c.id: c};
    final leagues = {for (final l in world.leagues) l.id: l};
    final trainer = Trainer.fromJson(data.trainer);
    final wish = data.wishClubId == null ? null : ClubId(data.wishClubId!);
    JobOffer? offer;
    if (data.offerData != null) {
      offer = JobOffer.fromJson(
        data.offerData!,
        clubs: clubs,
        leagues: leagues,
      );
    } else {
      final offers = start.offerGenerator.generate(
        trainer: trainer,
        seed: data.seed,
        wishClubId: wish,
      );
      offer = offers.offers
          .where((o) => o.club.id.value == data.offerClubId)
          .firstOrNull;
    }
    if (offer == null) return false;
    // The world of the saved season, then the career in it.
    final base = data.base;
    final state = base == null
        ? null
        : await unpackSeasonStateInBackground(base, clubs);
    _ref.read(worldStateProvider.notifier).set(state);
    _ref.read(seasonHistoryProvider.notifier).restore(data.seasons);
    _ref
        .read(careerProvider.notifier)
        .start(
          trainer: trainer,
          offer: offer,
          seed: data.seed,
          wishClubId: wish,
        );
    final leagueId = data.leagueId;
    final goal = data.goal;
    if (leagueId != null &&
        goal != null &&
        leagues[LeagueId(leagueId)] != null) {
      _ref
          .read(careerProvider.notifier)
          .newSeason(
            league: leagues[LeagueId(leagueId)]!,
            goal: SeasonGoal.values.byName(goal),
          );
    }
    // Wait for the screens' world to be built from that state before the
    // line-up and the season are put back.
    await _ref.read(loadedWorldProvider.future);
    final lineup = _ref.read(lineupProvider.notifier);
    _ref
        .read(seasonProvider.notifier)
        .restore(
          data.initialSheet == null
              ? null
              : TeamSheet.fromJson(data.initialSheet!),
          data.log,
          live: data.live,
        );
    if (data.lineup != null) {
      lineup.restore(
        TeamSheet.fromJson(data.lineup!),
        reviewed: data.lineupReviewed,
      );
    }
    _ref.read(mailReadProvider.notifier).restore(data.mailRead.toSet());
    final vacation = data.vacation;
    if (vacation != null) {
      _ref.read(vacationProvider.notifier).restore(vacation);
    }
    return true;
  }
}

final saveServiceProvider = Provider<SaveService>((ref) => SaveService(ref));
