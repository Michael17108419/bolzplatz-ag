import 'dart:convert';

import '../calendar/game_date.dart';
import '../calendar/season.dart';
import '../model/attribute.dart';
import '../model/attribute_set.dart';
import '../model/character.dart';
import '../model/club.dart';
import '../model/coach.dart';
import '../model/contract.dart';
import '../model/development.dart';
import '../model/ids.dart';
import '../model/league.dart';
import '../model/player.dart';
import '../model/position.dart';
import '../model/region.dart';
import '../model/special_ability.dart';
import 'world.dart';

/// Reads and writes the world data file. The text is stable: the same world
/// always gives the same text, with one player per line.
class WorldJson {
  const WorldJson._();

  static const int formatVersion = 1;

  static String encode(World w) {
    final head = {
      'format_version': formatVersion,
      'seed': w.seed,
      'season_start_year': w.season.startYear,
      'leagues': [
        for (final l in w.leagues)
          {
            'id': l.id.value,
            'name': l.name,
            'level': l.level,
            'team_count': l.teamCount,
            'region': l.region?.id,
          },
      ],
      'clubs': [
        for (final c in w.clubs)
          {
            'id': c.id.value,
            'name': c.name,
            'short_name': c.shortName,
            'place': c.place,
            'region': c.region.id,
            'league_id': c.leagueId?.value,
          },
      ],
      'league_seasons': [
        for (final ls in w.leagueSeasons)
          {
            'league_id': ls.league.id.value,
            'clubs': [for (final c in ls.clubIds) c.value],
          },
      ],
      'pools': {
        for (final e in w.pools.entries)
          e.key.id: [for (final c in e.value) c.value],
      },
      'coaches': [
        for (final c in w.coaches)
          {
            'id': c.id.value,
            'first_name': c.firstName,
            'last_name': c.lastName,
            'birth': c.birthDate.epochDay,
            'club_id': c.clubId?.value,
            'skills': c.skills,
          },
      ],
    };
    final headText = jsonEncode(head);
    final players = w.players.map((p) => jsonEncode(_player(p))).join(',\n');
    // Insert the players as the last key of the object.
    return '${headText.substring(0, headText.length - 1)},"players":[\n'
        '$players\n]}\n';
  }

  static Map<String, dynamic> _player(Player p) => {
    'id': p.id.value,
    'first_name': p.firstName,
    'last_name': p.lastName,
    'birth': p.birthDate.epochDay,
    'position': p.position.id,
    'attributes': p.attributes.toList(),
    'traits': [for (final t in CharacterTrait.values) p.traits[t]],
    'injury_proneness': p.injuryProneness,
    'abilities': [
      for (final a in p.abilities) [a.type.id, a.tier.name],
    ],
    'development': p.developmentType.id,
    'potential_core': p.potentialCore,
    'potential_dynamic': p.potentialDynamic,
    'roles': {for (final e in p.roles.entries) e.key: e.value.name},
    'club_id': p.clubId?.value,
    'contract': p.contract == null ? null : _contract(p.contract!),
  };

  static Map<String, dynamic> _contract(Contract c) => {
    'id': c.id.value,
    'club_id': c.clubId.value,
    'start': c.start.epochDay,
    'end': c.end.epochDay,
    'salary': c.baseSalaryPerYear,
    'salary_stages': c.salaryStages,
    'appearance_bonus': c.appearanceBonus,
    'goal_bonus': c.goalBonus,
    'title_bonus': c.titleBonus,
    'signing_bonus': c.signingBonus,
    'release_clause': c.releaseClause,
    'role_promise': c.rolePromise,
    'loan_from': c.loanFromClubId?.value,
  };

  /// Reads a world file. Throws [FormatException] when it is not valid.
  static World decode(String text) {
    final Map<String, dynamic> root;
    try {
      root = jsonDecode(text) as Map<String, dynamic>;
    } on TypeError catch (e) {
      throw FormatException('World file has the wrong shape: $e');
    }
    if (root['format_version'] != formatVersion) {
      throw FormatException(
        'Unsupported world format ${root['format_version']}',
      );
    }
    try {
      return _decode(root);
    } on TypeError catch (e) {
      throw FormatException('World file has the wrong value type: $e');
    } on ArgumentError catch (e) {
      throw FormatException('World file has invalid data: ${e.message}');
    }
  }

  static Region _region(String id) =>
      Region.values.firstWhere((r) => r.id == id);

  static World _decode(Map<String, dynamic> root) {
    final season = Season(root['season_start_year'] as int);

    final leagues = [
      for (final raw in root['leagues'] as List<dynamic>)
        _league(raw as Map<String, dynamic>),
    ];
    final leagueById = {for (final l in leagues) l.id: l};

    final clubs = [
      for (final raw in root['clubs'] as List<dynamic>)
        _club(raw as Map<String, dynamic>),
    ];

    final leagueSeasons = [
      for (final raw in root['league_seasons'] as List<dynamic>)
        _leagueSeason(raw as Map<String, dynamic>, leagueById, season),
    ];

    final pools = {
      for (final e in (root['pools'] as Map<String, dynamic>).entries)
        _region(e.key): [
          for (final c in e.value as List<dynamic>) ClubId(c as int),
        ],
    };

    final coaches = [
      for (final raw in root['coaches'] as List<dynamic>)
        _coach(raw as Map<String, dynamic>),
    ];

    final players = [
      for (final raw in root['players'] as List<dynamic>)
        _playerFrom(raw as Map<String, dynamic>),
    ];

    return World(
      seed: root['seed'] as int,
      season: season,
      leagues: List.unmodifiable(leagues),
      clubs: List.unmodifiable(clubs),
      leagueSeasons: List.unmodifiable(leagueSeasons),
      pools: pools,
      players: List.unmodifiable(players),
      coaches: List.unmodifiable(coaches),
    );
  }

  static League _league(Map<String, dynamic> m) => League(
    id: LeagueId(m['id'] as int),
    name: m['name'] as String,
    level: m['level'] as int,
    teamCount: m['team_count'] as int,
    region: m['region'] == null ? null : _region(m['region'] as String),
  );

  static Club _club(Map<String, dynamic> m) => Club(
    id: ClubId(m['id'] as int),
    name: m['name'] as String,
    shortName: m['short_name'] as String,
    place: m['place'] as String,
    region: _region(m['region'] as String),
    leagueId: m['league_id'] == null ? null : LeagueId(m['league_id'] as int),
  );

  static LeagueSeason _leagueSeason(
    Map<String, dynamic> m,
    Map<LeagueId, League> leagues,
    Season season,
  ) {
    final league = leagues[LeagueId(m['league_id'] as int)];
    if (league == null) throw ArgumentError('Unknown league in league_seasons');
    return LeagueSeason(
      league: league,
      season: season,
      clubIds: [for (final c in m['clubs'] as List<dynamic>) ClubId(c as int)],
    );
  }

  static Coach _coach(Map<String, dynamic> m) => Coach(
    id: CoachId(m['id'] as int),
    firstName: m['first_name'] as String,
    lastName: m['last_name'] as String,
    birthDate: GameDate.fromEpochDay(m['birth'] as int),
    skills: {
      for (final e in (m['skills'] as Map<String, dynamic>).entries)
        e.key: (e.value as num).toDouble(),
    },
    clubId: m['club_id'] == null ? null : ClubId(m['club_id'] as int),
  );

  static Player _playerFrom(Map<String, dynamic> m) {
    final values = [
      for (final v in m['attributes'] as List<dynamic>) (v as num).toDouble(),
    ];
    if (values.length != Attribute.count) {
      throw ArgumentError('Player ${m['id']} has ${values.length} attributes');
    }
    final traitValues = m['traits'] as List<dynamic>;
    if (traitValues.length != CharacterTrait.values.length) {
      throw ArgumentError('Player ${m['id']} has wrong trait count');
    }
    final playerId = PlayerId(m['id'] as int);
    final contractRaw = m['contract'] as Map<String, dynamic>?;
    return Player(
      id: playerId,
      firstName: m['first_name'] as String,
      lastName: m['last_name'] as String,
      birthDate: GameDate.fromEpochDay(m['birth'] as int),
      position: Position.values.firstWhere((p) => p.id == m['position']),
      attributes: AttributeSet.fromMap({
        for (final a in Attribute.values) a: values[a.index],
      }),
      traits: {
        for (final t in CharacterTrait.values)
          t: (traitValues[t.index] as num).toDouble(),
      },
      injuryProneness: (m['injury_proneness'] as num).toDouble(),
      abilities: [
        for (final raw in m['abilities'] as List<dynamic>)
          SpecialAbility(
            SpecialAbilityType.values.firstWhere(
              (t) => t.id == (raw as List<dynamic>)[0],
            ),
            AbilityTier.values.byName(raw[1] as String),
          ),
      ],
      developmentType: DevelopmentType.values.firstWhere(
        (d) => d.id == m['development'],
      ),
      potentialCore: (m['potential_core'] as num).toDouble(),
      potentialDynamic: (m['potential_dynamic'] as num).toDouble(),
      roles: {
        for (final e in (m['roles'] as Map<String, dynamic>).entries)
          e.key: RoleFamiliarity.values.byName(e.value as String),
      },
      clubId: m['club_id'] == null ? null : ClubId(m['club_id'] as int),
      contract: contractRaw == null
          ? null
          : _contractFrom(contractRaw, playerId),
    );
  }

  static Contract _contractFrom(Map<String, dynamic> m, PlayerId playerId) =>
      Contract(
        id: ContractId(m['id'] as int),
        playerId: playerId,
        clubId: ClubId(m['club_id'] as int),
        start: GameDate.fromEpochDay(m['start'] as int),
        end: GameDate.fromEpochDay(m['end'] as int),
        baseSalaryPerYear: m['salary'] as int,
        salaryStages: [
          for (final v in m['salary_stages'] as List<dynamic>) v as int,
        ],
        appearanceBonus: m['appearance_bonus'] as int,
        goalBonus: m['goal_bonus'] as int,
        titleBonus: m['title_bonus'] as int,
        signingBonus: m['signing_bonus'] as int,
        releaseClause: m['release_clause'] as int?,
        rolePromise: m['role_promise'] as String?,
        loanFromClubId: m['loan_from'] == null
            ? null
            : ClubId(m['loan_from'] as int),
      );
}
