import 'dart:convert';

import '../calendar/season.dart';
import '../model/club.dart';
import '../model/ids.dart';
import '../model/league.dart';
import '../model/region.dart';
import '../world/world.dart';
import '../world/world_json.dart';
import 'season_state.dart';

/// Writes and reads the state of a season as text: the picture of the world
/// at the start of a season (leagues, pools, squads with contracts). A saved
/// game keeps it so a career over many seasons does not have to be played
/// again from the first day.
class SeasonSnapshot {
  const SeasonSnapshot._();

  static const int formatVersion = 1;

  static String encode(SeasonState s) {
    final clubIds = s.squads.keys.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return jsonEncode({
      'format_version': formatVersion,
      'start_year': s.startYear,
      'cycle_year': s.cycleYear,
      'members': {
        for (final e in s.members.entries)
          '${e.key.value}': [for (final c in e.value) c.value],
      },
      'pools': {
        for (final e in s.pools.entries)
          e.key.id: [for (final c in e.value) c.value],
      },
      'pott': [for (final c in s.pottQualifiers) c.value],
      'third': [for (final c in s.thirdLeagueQualifiers) c.value],
      'previous_rank': {
        for (final e in s.previousRank.entries) '${e.key.value}': e.value,
      },
      'squads': {
        for (final c in clubIds)
          '${c.value}': [
            for (final p in s.squads[c]!) WorldJson.playerToJson(p),
          ],
      },
    });
  }

  /// Reads a snapshot. [clubs] are the clubs of the world (they never
  /// change). Throws [FormatException] for a text of another version.
  static SeasonState decode(String text, Map<ClubId, Club> clubs) {
    final root = jsonDecode(text) as Map<String, dynamic>;
    if (root['format_version'] != formatVersion) {
      throw FormatException(
        'Unknown snapshot version ${root['format_version']}',
      );
    }
    List<ClubId> ids(dynamic raw) => [
      for (final c in raw as List<dynamic>) ClubId(c as int),
    ];
    return SeasonState(
      startYear: root['start_year'] as int,
      cycleYear: root['cycle_year'] as int,
      members: {
        for (final e in (root['members'] as Map<String, dynamic>).entries)
          LeagueId(int.parse(e.key)): ids(e.value),
      },
      pools: {
        for (final e in (root['pools'] as Map<String, dynamic>).entries)
          Region.values.firstWhere((r) => r.id == e.key): ids(e.value),
      },
      clubs: clubs,
      squads: {
        for (final e in (root['squads'] as Map<String, dynamic>).entries)
          ClubId(int.parse(e.key)): [
            for (final p in e.value as List<dynamic>)
              WorldJson.playerFromJson(p as Map<String, dynamic>),
          ],
      },
      pottQualifiers: ids(root['pott']),
      thirdLeagueQualifiers: ids(root['third']),
      previousRank: {
        for (final e in (root['previous_rank'] as Map<String, dynamic>).entries)
          ClubId(int.parse(e.key)): e.value as int,
      },
    );
  }

  /// The world as it stands at the start of the season of [state], built on
  /// the leagues, clubs and coaches of [base].
  static World worldOf(SeasonState state, World base) {
    final season = Season(state.startYear);
    final clubIds = state.squads.keys.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return World(
      seed: base.seed,
      season: season,
      leagues: base.leagues,
      clubs: base.clubs,
      leagueSeasons: [
        for (final l in base.leagues)
          LeagueSeason(
            league: l,
            season: season,
            clubIds: state.members[l.id]!,
          ),
      ],
      pools: state.pools,
      players: [for (final c in clubIds) ...state.squads[c]!],
      coaches: base.coaches,
    );
  }
}
