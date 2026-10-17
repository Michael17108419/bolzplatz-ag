import '../model/ids.dart';
import '../model/player.dart';

/// The line-up and tactics a manager hands in before kick-off.
class TeamSheet {
  TeamSheet({
    required this.formationId,
    required this.systemId,
    required List<PlayerId> startingXi,
    List<String?>? slotRoles,
    List<PlayerId> bench = const [],
    this.pressing = 1,
    this.tempo = 1,
    this.defensiveLine = 1,
    this.captain,
  }) : startingXi = List.unmodifiable(startingXi),
       slotRoles = List.unmodifiable(
         slotRoles ?? List<String?>.filled(startingXi.length, null),
       ),
       bench = List.unmodifiable(bench);

  factory TeamSheet.fromJson(Map<String, dynamic> m) {
    List<PlayerId> ids(String key) {
      final out = <PlayerId>[];
      for (final v in m[key] as List<dynamic>) {
        out.add(PlayerId(v as int));
      }
      return out;
    }

    final roles = <String?>[];
    for (final v in m['roles'] as List<dynamic>) {
      roles.add(v as String?);
    }
    return TeamSheet(
      formationId: m['formation'] as String,
      systemId: m['system'] as String,
      startingXi: ids('xi'),
      slotRoles: roles,
      bench: ids('bench'),
      pressing: m['pressing'] as int,
      tempo: m['tempo'] as int,
      defensiveLine: m['line'] as int,
      captain: m['captain'] == null ? null : PlayerId(m['captain'] as int),
    );
  }

  /// Plain JSON for saving; [TeamSheet.fromJson] reads it back.
  Map<String, dynamic> toJson() => {
    'formation': formationId,
    'system': systemId,
    'xi': [for (final p in startingXi) p.value],
    'roles': slotRoles,
    'bench': [for (final p in bench) p.value],
    'pressing': pressing,
    'tempo': tempo,
    'line': defensiveLine,
    if (captain != null) 'captain': captain!.value,
  };

  final String formationId;
  final String systemId;

  /// Players in the slot order of the formation, goalkeeper first.
  final List<PlayerId> startingXi;

  /// Role id for each slot, null for no particular role.
  final List<String?> slotRoles;
  final List<PlayerId> bench;

  /// Slider levels 0 (low), 1 (normal), 2 (high).
  final int pressing;
  final int tempo;
  final int defensiveLine;

  /// The captain named by the manager, or null: then the player with the
  /// most leadership in the starting eleven wears the armband.
  final PlayerId? captain;

  TeamSheet copyWith({
    String? formationId,
    String? systemId,
    List<PlayerId>? startingXi,
    List<String?>? slotRoles,
    List<PlayerId>? bench,
    int? pressing,
    int? tempo,
    int? defensiveLine,
    PlayerId? captain,
    bool clearCaptain = false,
  }) {
    return TeamSheet(
      formationId: formationId ?? this.formationId,
      systemId: systemId ?? this.systemId,
      startingXi: startingXi ?? this.startingXi,
      slotRoles: slotRoles ?? this.slotRoles,
      bench: bench ?? this.bench,
      pressing: pressing ?? this.pressing,
      tempo: tempo ?? this.tempo,
      defensiveLine: defensiveLine ?? this.defensiveLine,
      captain: clearCaptain ? null : captain ?? this.captain,
    );
  }
}

/// One team ready for a match: squad, line-up and the state of the players.
class MatchTeam {
  MatchTeam({
    required this.clubId,
    required this.name,
    required List<Player> squad,
    required this.sheet,
    Map<PlayerId, double> form = const {},
    Map<PlayerId, double> fitness = const {},
    this.autoManage = true,
  }) : squad = List.unmodifiable(squad),
       form = Map.unmodifiable(form),
       fitness = Map.unmodifiable(fitness);

  final ClubId clubId;
  final String name;
  final List<Player> squad;
  final TeamSheet sheet;

  /// Form 0 to 100 per player, missing means the default of the rules.
  final Map<PlayerId, double> form;

  /// Fitness 0 to 100 per player, missing means fully fit.
  final Map<PlayerId, double> fitness;

  /// When true the assistant makes substitutions during the match.
  final bool autoManage;
}
