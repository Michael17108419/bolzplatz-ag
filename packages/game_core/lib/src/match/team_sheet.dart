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
  }) : startingXi = List.unmodifiable(startingXi),
       slotRoles = List.unmodifiable(
         slotRoles ?? List<String?>.filled(startingXi.length, null),
       ),
       bench = List.unmodifiable(bench);

  factory TeamSheet.fromJson(Map<String, dynamic> m) => TeamSheet(
    formationId: m['formation'] as String,
    systemId: m['system'] as String,
    startingXi: [for (final v in m['xi'] as List<dynamic>) PlayerId(v as int)],
    slotRoles: [for (final v in m['roles'] as List<dynamic>) v as String?],
    bench: [for (final v in m['bench'] as List<dynamic>) PlayerId(v as int)],
    pressing: m['pressing'] as int,
    tempo: m['tempo'] as int,
    defensiveLine: m['line'] as int,
  );

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

  TeamSheet copyWith({
    String? formationId,
    String? systemId,
    List<PlayerId>? startingXi,
    List<String?>? slotRoles,
    List<PlayerId>? bench,
    int? pressing,
    int? tempo,
    int? defensiveLine,
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
