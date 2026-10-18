import '../model/coach.dart';
import '../model/ids.dart';
import '../model/player.dart';

/// What the coach tells one player (engine 2, step 10g1).
enum PlayerInstruction {
  /// Follows the most dangerous opponent; missing elsewhere.
  manMark,

  /// Shoots from distance more often.
  shootMore,

  /// Short and safe passes, fewer risky balls.
  safe,

  /// Goes in hard: wins more balls, fouls more.
  hard,

  /// Pushes up: more in attack, less at the back.
  forward,

  /// Stays back: more at the back, less in attack.
  stayBack,

  /// Looks for the through ball.
  through,
}

/// The wing a team overloads (engine 2, step 10g1), seen from the team.
enum Wing { left, right }

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
    Map<PlayerId, PlayerInstruction> instructions = const {},
    this.wing,
    this.wasteTime = false,
  }) : startingXi = List.unmodifiable(startingXi),
       instructions = Map.unmodifiable(instructions),
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
      instructions: {
        for (final e
            in ((m['instr'] as Map<String, dynamic>?) ?? const {}).entries)
          PlayerId(int.parse(e.key)): PlayerInstruction.values.byName(
            e.value as String,
          ),
      },
      wing: m['wing'] == null ? null : Wing.values.byName(m['wing'] as String),
      wasteTime: m['waste'] == true,
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
    if (instructions.isNotEmpty)
      'instr': {
        for (final e in instructions.entries) '${e.key.value}': e.value.name,
      },
    if (wing != null) 'wing': wing!.name,
    if (wasteTime) 'waste': true,
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

  /// One instruction per player at most (step 10g1); it follows the player,
  /// not the place.
  final Map<PlayerId, PlayerInstruction> instructions;

  /// The wing the team overloads, null for none (step 10g1).
  final Wing? wing;

  /// The team plays for time (step 10g1).
  final bool wasteTime;

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
    Map<PlayerId, PlayerInstruction>? instructions,
    Wing? wing,
    bool clearWing = false,
    bool? wasteTime,
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
      instructions: instructions ?? this.instructions,
      wing: clearWing ? null : wing ?? this.wing,
      wasteTime: wasteTime ?? this.wasteTime,
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
    Map<PlayerId, double> confidence = const {},
    Map<PlayerId, double> load = const {},
    Map<PlayerId, double> mood = const {},
    this.coach = const CoachProfile(),
    this.chemistry,
    this.autoManage = true,
  }) : squad = List.unmodifiable(squad),
       mood = Map.unmodifiable(mood),
       form = Map.unmodifiable(form),
       fitness = Map.unmodifiable(fitness),
       confidence = Map.unmodifiable(confidence),
       load = Map.unmodifiable(load);

  final ClubId clubId;
  final String name;
  final List<Player> squad;
  final TeamSheet sheet;

  /// Form 0 to 100 per player, missing means the default of the rules.
  final Map<PlayerId, double> form;

  /// Fitness 0 to 100 per player, missing means fully fit.
  final Map<PlayerId, double> fitness;

  /// Confidence 0 to 100 per player (step 10f2), missing means 50.
  final Map<PlayerId, double> confidence;

  /// Load of the last weeks per player (step 10f2): 1 is a full load,
  /// missing means none.
  final Map<PlayerId, double> load;

  /// Mood 0 to 100 per player (step 10f3), missing means the neutral mood
  /// of the rules.
  final Map<PlayerId, double> mood;

  /// The coach on the bench (step 10f3).
  final CoachProfile coach;

  /// Chemistry of a pair of players, 0 to 1 (step 10f4); null means every
  /// pair is average.
  final double Function(PlayerId a, PlayerId b)? chemistry;

  /// When true the assistant makes substitutions during the match.
  final bool autoManage;
}
