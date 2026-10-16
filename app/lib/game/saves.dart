import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'career.dart';
import 'lineup.dart';
import 'loaded_world.dart';
import 'mail_state.dart';
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
  });

  /// Bump when the format changes; older files are then refused with a hint.
  static const int version = 1;

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
  });
}

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

  /// The game as it stands, or null if there is nothing to save: no career
  /// yet, or a match is open (saving is only possible between matches).
  SaveData? snapshot({DateTime? now}) {
    final career = _ref.read(careerProvider);
    final game = _ref.read(seasonProvider);
    if (career == null || game == null || game.day != null) return null;
    final lineup = _ref.read(lineupProvider);
    return SaveData(
      savedAt: now ?? DateTime.now(),
      trainer: career.trainer.toJson(),
      seed: career.seed,
      wishClubId: career.wishClubId?.value,
      offerClubId: career.offer.club.id.value,
      clubName: career.offer.club.name,
      leagueName: career.offer.league.name,
      date: game.today,
      matchday: game.played,
      matchdays: game.ownDays,
      initialSheet: game.initialSheet?.toJson(),
      log: game.savableLog,
      lineup: lineup?.sheet.toJson(),
      lineupReviewed: lineup?.reviewed ?? false,
      mailRead: _ref.read(mailReadProvider).toList()..sort(),
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
    final loaded = await _ref.read(loadedWorldProvider.future);
    final trainer = Trainer.fromJson(data.trainer);
    final wish = data.wishClubId == null ? null : ClubId(data.wishClubId!);
    final offers = loaded.offerGenerator.generate(
      trainer: trainer,
      seed: data.seed,
      wishClubId: wish,
    );
    final offer = offers.offers
        .where((o) => o.club.id.value == data.offerClubId)
        .firstOrNull;
    if (offer == null) return false;
    _ref
        .read(careerProvider.notifier)
        .start(
          trainer: trainer,
          offer: offer,
          seed: data.seed,
          wishClubId: wish,
        );
    final lineup = _ref.read(lineupProvider.notifier);
    _ref
        .read(seasonProvider.notifier)
        .restore(
          data.initialSheet == null
              ? null
              : TeamSheet.fromJson(data.initialSheet!),
          data.log,
        );
    if (data.lineup != null) {
      lineup.restore(
        TeamSheet.fromJson(data.lineup!),
        reviewed: data.lineupReviewed,
      );
    }
    _ref.read(mailReadProvider.notifier).restore(data.mailRead.toSet());
    return true;
  }
}

final saveServiceProvider = Provider<SaveService>((ref) => SaveService(ref));
