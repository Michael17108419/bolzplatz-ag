import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:game_core/game_core.dart';

import 'database.dart';

/// Maps between the pure game_core model and database rows.
class GameRepository {
  GameRepository(this._db);

  final AppDatabase _db;

  // --- leagues and clubs ---

  Future<void> saveLeague(League league) {
    return _db
        .into(_db.leagues)
        .insertOnConflictUpdate(
          LeaguesCompanion(
            id: Value(league.id.value),
            name: Value(league.name),
            level: Value(league.level),
            teamCount: Value(league.teamCount),
            region: Value(league.region?.id),
          ),
        );
  }

  Future<League?> loadLeague(LeagueId id) async {
    final row = await (_db.select(
      _db.leagues,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    if (row == null) return null;
    return League(
      id: LeagueId(row.id),
      name: row.name,
      level: row.level,
      teamCount: row.teamCount,
      region: row.region == null ? null : _region(row.region!),
    );
  }

  Future<void> saveClub(Club club) {
    return _db
        .into(_db.clubs)
        .insertOnConflictUpdate(
          ClubsCompanion(
            id: Value(club.id.value),
            name: Value(club.name),
            shortName: Value(club.shortName),
            place: Value(club.place),
            region: Value(club.region.id),
            leagueId: Value(club.leagueId?.value),
          ),
        );
  }

  Future<Club?> loadClub(ClubId id) async {
    final row = await (_db.select(
      _db.clubs,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    if (row == null) return null;
    return Club(
      id: ClubId(row.id),
      name: row.name,
      shortName: row.shortName,
      place: row.place,
      region: _region(row.region),
      leagueId: row.leagueId == null ? null : LeagueId(row.leagueId!),
    );
  }

  Future<void> saveLeagueSeason(LeagueSeason entry) async {
    final leagueId = entry.league.id.value;
    final year = entry.season.startYear;
    await _db.transaction(() async {
      await (_db.delete(_db.leagueSeasonClubs)..where(
            (t) => t.leagueId.equals(leagueId) & t.seasonStartYear.equals(year),
          ))
          .go();
      for (final clubId in entry.clubIds) {
        await _db
            .into(_db.leagueSeasonClubs)
            .insert(
              LeagueSeasonClubsCompanion(
                leagueId: Value(leagueId),
                seasonStartYear: Value(year),
                clubId: Value(clubId.value),
              ),
            );
      }
    });
  }

  Future<List<ClubId>> loadLeagueSeasonClubs(
    LeagueId league,
    Season season,
  ) async {
    final rows =
        await (_db.select(_db.leagueSeasonClubs)
              ..where(
                (t) =>
                    t.leagueId.equals(league.value) &
                    t.seasonStartYear.equals(season.startYear),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.clubId)]))
            .get();
    return [for (final r in rows) ClubId(r.clubId)];
  }

  // --- players and contracts ---

  Future<void> savePlayer(Player player) async {
    await _db.transaction(() async {
      await _db
          .into(_db.players)
          .insertOnConflictUpdate(
            PlayersCompanion(
              id: Value(player.id.value),
              firstName: Value(player.firstName),
              lastName: Value(player.lastName),
              birthEpochDay: Value(player.birthDate.epochDay),
              position: Value(player.position.id),
              attributesJson: Value(jsonEncode(player.attributes.toList())),
              traitsJson: Value(
                jsonEncode({
                  for (final e in player.traits.entries) e.key.id: e.value,
                }),
              ),
              injuryProneness: Value(player.injuryProneness),
              abilitiesJson: Value(
                jsonEncode([
                  for (final a in player.abilities)
                    {'type': a.type.id, 'tier': a.tier.name},
                ]),
              ),
              developmentType: Value(player.developmentType.id),
              potentialCore: Value(player.potentialCore),
              potentialDynamic: Value(player.potentialDynamic),
              rolesJson: Value(
                jsonEncode({
                  for (final e in player.roles.entries) e.key: e.value.name,
                }),
              ),
              clubId: Value(player.clubId?.value),
            ),
          );
      final contract = player.contract;
      if (contract != null) await _saveContract(contract);
    });
  }

  Future<void> _saveContract(Contract c) {
    return _db
        .into(_db.contracts)
        .insertOnConflictUpdate(
          ContractsCompanion(
            id: Value(c.id.value),
            playerId: Value(c.playerId.value),
            clubId: Value(c.clubId.value),
            startEpochDay: Value(c.start.epochDay),
            endEpochDay: Value(c.end.epochDay),
            baseSalaryPerYear: Value(c.baseSalaryPerYear),
            salaryStagesJson: Value(jsonEncode(c.salaryStages)),
            appearanceBonus: Value(c.appearanceBonus),
            goalBonus: Value(c.goalBonus),
            titleBonus: Value(c.titleBonus),
            signingBonus: Value(c.signingBonus),
            releaseClause: Value(c.releaseClause),
            rolePromise: Value(c.rolePromise),
            loanFromClubId: Value(c.loanFromClubId?.value),
          ),
        );
  }

  Future<Player?> loadPlayer(PlayerId id) async {
    final row = await (_db.select(
      _db.players,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    if (row == null) return null;
    final contractRow = await (_db.select(
      _db.contracts,
    )..where((t) => t.playerId.equals(id.value))).getSingleOrNull();
    return _playerFrom(row, contractRow);
  }

  Player _playerFrom(PlayerRow row, ContractRow? contractRow) {
    final values = (jsonDecode(row.attributesJson) as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
    final attributes = AttributeSet.fromMap({
      for (final a in Attribute.values) a: values[a.index],
    });
    final traitsRaw = jsonDecode(row.traitsJson) as Map<String, dynamic>;
    final traits = {
      for (final t in CharacterTrait.values)
        t: (traitsRaw[t.id] as num).toDouble(),
    };
    final abilitiesRaw = jsonDecode(row.abilitiesJson) as List<dynamic>;
    final abilities = [
      for (final a in abilitiesRaw)
        SpecialAbility(
          SpecialAbilityType.values.firstWhere(
            (t) => t.id == (a as Map<String, dynamic>)['type'],
          ),
          AbilityTier.values.byName(a['tier'] as String),
        ),
    ];
    final rolesRaw = jsonDecode(row.rolesJson) as Map<String, dynamic>;
    final roles = {
      for (final e in rolesRaw.entries)
        e.key: RoleFamiliarity.values.byName(e.value as String),
    };

    return Player(
      id: PlayerId(row.id),
      firstName: row.firstName,
      lastName: row.lastName,
      birthDate: GameDate.fromEpochDay(row.birthEpochDay),
      position: Position.values.firstWhere((p) => p.id == row.position),
      attributes: attributes,
      traits: traits,
      injuryProneness: row.injuryProneness,
      abilities: abilities,
      developmentType: DevelopmentType.values.firstWhere(
        (d) => d.id == row.developmentType,
      ),
      potentialCore: row.potentialCore,
      potentialDynamic: row.potentialDynamic,
      roles: roles,
      clubId: row.clubId == null ? null : ClubId(row.clubId!),
      contract: contractRow == null ? null : _contract(contractRow),
    );
  }

  Contract _contract(ContractRow r) {
    return Contract(
      id: ContractId(r.id),
      playerId: PlayerId(r.playerId),
      clubId: ClubId(r.clubId),
      start: GameDate.fromEpochDay(r.startEpochDay),
      end: GameDate.fromEpochDay(r.endEpochDay),
      baseSalaryPerYear: r.baseSalaryPerYear,
      salaryStages: [
        for (final v in jsonDecode(r.salaryStagesJson) as List<dynamic>)
          (v as num).toInt(),
      ],
      appearanceBonus: r.appearanceBonus,
      goalBonus: r.goalBonus,
      titleBonus: r.titleBonus,
      signingBonus: r.signingBonus,
      releaseClause: r.releaseClause,
      rolePromise: r.rolePromise,
      loanFromClubId: r.loanFromClubId == null
          ? null
          : ClubId(r.loanFromClubId!),
    );
  }

  static Region _region(String id) =>
      Region.values.firstWhere((r) => r.id == id);

  // --- the whole world ---

  /// Writes the complete start world in one transaction.
  Future<void> saveWorld(World w) async {
    await _db.transaction(() async {
      await _db.batch((b) {
        b.insertAllOnConflictUpdate(_db.gameMeta, [
          GameMetaCompanion(
            metaKey: const Value('seed'),
            metaValue: Value('${w.seed}'),
          ),
          GameMetaCompanion(
            metaKey: const Value('season_start_year'),
            metaValue: Value('${w.season.startYear}'),
          ),
        ]);
        b.insertAllOnConflictUpdate(_db.leagues, [
          for (final l in w.leagues)
            LeaguesCompanion(
              id: Value(l.id.value),
              name: Value(l.name),
              level: Value(l.level),
              teamCount: Value(l.teamCount),
              region: Value(l.region?.id),
            ),
        ]);
        b.insertAllOnConflictUpdate(_db.clubs, [
          for (final c in w.clubs)
            ClubsCompanion(
              id: Value(c.id.value),
              name: Value(c.name),
              shortName: Value(c.shortName),
              place: Value(c.place),
              region: Value(c.region.id),
              leagueId: Value(c.leagueId?.value),
            ),
        ]);
        b.insertAllOnConflictUpdate(_db.players, [
          for (final p in w.players) _playerCompanion(p),
        ]);
        b.insertAllOnConflictUpdate(_db.contracts, [
          for (final p in w.players)
            if (p.contract != null) _contractCompanion(p.contract!),
        ]);
        b.insertAllOnConflictUpdate(_db.coaches, [
          for (final c in w.coaches)
            CoachesCompanion(
              id: Value(c.id.value),
              firstName: Value(c.firstName),
              lastName: Value(c.lastName),
              birthEpochDay: Value(c.birthDate.epochDay),
              skillsJson: Value(jsonEncode(c.skills)),
              clubId: Value(c.clubId?.value),
            ),
        ]);
        b.insertAllOnConflictUpdate(_db.leagueSeasonClubs, [
          for (final ls in w.leagueSeasons)
            for (final clubId in ls.clubIds)
              LeagueSeasonClubsCompanion(
                leagueId: Value(ls.league.id.value),
                seasonStartYear: Value(ls.season.startYear),
                clubId: Value(clubId.value),
              ),
        ]);
      });
    });
  }

  /// Reads the complete world back. Returns null when no world is stored.
  Future<World?> loadWorld() async {
    final metaRows = await _db.select(_db.gameMeta).get();
    final meta = {for (final r in metaRows) r.metaKey: r.metaValue};
    if (!meta.containsKey('seed') || !meta.containsKey('season_start_year')) {
      return null;
    }
    final season = Season(int.parse(meta['season_start_year']!));

    final leagueRows = await (_db.select(
      _db.leagues,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final leagues = [
      for (final r in leagueRows)
        League(
          id: LeagueId(r.id),
          name: r.name,
          level: r.level,
          teamCount: r.teamCount,
          region: r.region == null ? null : _region(r.region!),
        ),
    ];
    final leagueById = {for (final l in leagues) l.id: l};

    final clubRows = await (_db.select(
      _db.clubs,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final clubs = [
      for (final r in clubRows)
        Club(
          id: ClubId(r.id),
          name: r.name,
          shortName: r.shortName,
          place: r.place,
          region: _region(r.region),
          leagueId: r.leagueId == null ? null : LeagueId(r.leagueId!),
        ),
    ];

    final pools = {
      for (final region in Region.values)
        region: [
          for (final c in clubs)
            if (c.leagueId == null && c.region == region) c.id,
        ],
    };

    final seasonRows =
        await (_db.select(_db.leagueSeasonClubs)..orderBy([
              (t) => OrderingTerm.asc(t.leagueId),
              (t) => OrderingTerm.asc(t.seasonStartYear),
              (t) => OrderingTerm.asc(t.clubId),
            ]))
            .get();
    final membersByLeague = <int, List<ClubId>>{};
    for (final r in seasonRows) {
      if (r.seasonStartYear != season.startYear) continue;
      (membersByLeague[r.leagueId] ??= []).add(ClubId(r.clubId));
    }
    final leagueSeasons = [
      for (final l in leagues)
        LeagueSeason(
          league: leagueById[l.id]!,
          season: season,
          clubIds: membersByLeague[l.id.value] ?? const [],
        ),
    ];

    final contractRows = await _db.select(_db.contracts).get();
    final contractByPlayer = {for (final r in contractRows) r.playerId: r};
    final playerRows = await (_db.select(
      _db.players,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final players = [
      for (final r in playerRows) _playerFrom(r, contractByPlayer[r.id]),
    ];

    final coachRows = await (_db.select(
      _db.coaches,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final coaches = [
      for (final r in coachRows)
        Coach(
          id: CoachId(r.id),
          firstName: r.firstName,
          lastName: r.lastName,
          birthDate: GameDate.fromEpochDay(r.birthEpochDay),
          skills: {
            for (final e
                in (jsonDecode(r.skillsJson) as Map<String, dynamic>).entries)
              e.key: (e.value as num).toDouble(),
          },
          clubId: r.clubId == null ? null : ClubId(r.clubId!),
        ),
    ];

    return World(
      seed: int.parse(meta['seed']!),
      season: season,
      leagues: leagues,
      clubs: clubs,
      leagueSeasons: leagueSeasons,
      pools: pools,
      players: players,
      coaches: coaches,
    );
  }

  PlayersCompanion _playerCompanion(Player player) {
    return PlayersCompanion(
      id: Value(player.id.value),
      firstName: Value(player.firstName),
      lastName: Value(player.lastName),
      birthEpochDay: Value(player.birthDate.epochDay),
      position: Value(player.position.id),
      attributesJson: Value(jsonEncode(player.attributes.toList())),
      traitsJson: Value(
        jsonEncode({for (final e in player.traits.entries) e.key.id: e.value}),
      ),
      injuryProneness: Value(player.injuryProneness),
      abilitiesJson: Value(
        jsonEncode([
          for (final a in player.abilities)
            {'type': a.type.id, 'tier': a.tier.name},
        ]),
      ),
      developmentType: Value(player.developmentType.id),
      potentialCore: Value(player.potentialCore),
      potentialDynamic: Value(player.potentialDynamic),
      rolesJson: Value(
        jsonEncode({for (final e in player.roles.entries) e.key: e.value.name}),
      ),
      clubId: Value(player.clubId?.value),
    );
  }

  ContractsCompanion _contractCompanion(Contract c) {
    return ContractsCompanion(
      id: Value(c.id.value),
      playerId: Value(c.playerId.value),
      clubId: Value(c.clubId.value),
      startEpochDay: Value(c.start.epochDay),
      endEpochDay: Value(c.end.epochDay),
      baseSalaryPerYear: Value(c.baseSalaryPerYear),
      salaryStagesJson: Value(jsonEncode(c.salaryStages)),
      appearanceBonus: Value(c.appearanceBonus),
      goalBonus: Value(c.goalBonus),
      titleBonus: Value(c.titleBonus),
      signingBonus: Value(c.signingBonus),
      releaseClause: Value(c.releaseClause),
      rolePromise: Value(c.rolePromise),
      loanFromClubId: Value(c.loanFromClubId?.value),
    );
  }
}
