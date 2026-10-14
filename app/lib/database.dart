import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// Ids are fixed by the game (rule 4), so no table uses autoIncrement.
// Structured values (attributes, traits, abilities, roles, skills) are stored
// as JSON text; the mapping lives in repository.dart.

@DataClassName('LeagueRow')
class Leagues extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get level => integer()();
  IntColumn get teamCount => integer()();
  TextColumn get region => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ClubRow')
class Clubs extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get shortName => text().withDefault(const Constant(''))();
  TextColumn get place => text()();
  TextColumn get region => text().withDefault(const Constant('nord'))();
  IntColumn get leagueId => integer().nullable().references(Leagues, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlayerRow')
class Players extends Table {
  IntColumn get id => integer()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  IntColumn get birthEpochDay => integer()();
  TextColumn get position => text()();
  TextColumn get attributesJson => text()();
  TextColumn get traitsJson => text()();
  RealColumn get injuryProneness => real()();
  TextColumn get abilitiesJson => text()();
  TextColumn get developmentType => text()();
  RealColumn get potentialCore => real()();
  RealColumn get potentialDynamic => real()();
  TextColumn get rolesJson => text()();
  IntColumn get clubId => integer().nullable().references(Clubs, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CoachRow')
class Coaches extends Table {
  IntColumn get id => integer()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  IntColumn get birthEpochDay => integer()();
  TextColumn get skillsJson => text()();
  IntColumn get clubId => integer().nullable().references(Clubs, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ContractRow')
class Contracts extends Table {
  IntColumn get id => integer()();
  IntColumn get playerId => integer().references(Players, #id)();
  IntColumn get clubId => integer().references(Clubs, #id)();
  IntColumn get startEpochDay => integer()();
  IntColumn get endEpochDay => integer()();
  IntColumn get baseSalaryPerYear => integer()();
  TextColumn get salaryStagesJson => text()();
  IntColumn get appearanceBonus => integer()();
  IntColumn get goalBonus => integer()();
  IntColumn get titleBonus => integer()();
  IntColumn get signingBonus => integer()();
  IntColumn get releaseClause => integer().nullable()();
  TextColumn get rolePromise => text().nullable()();
  IntColumn get loanFromClubId => integer().nullable().references(Clubs, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LeagueSeasonClubRow')
class LeagueSeasonClubs extends Table {
  IntColumn get leagueId => integer().references(Leagues, #id)();
  IntColumn get seasonStartYear => integer()();
  IntColumn get clubId => integer().references(Clubs, #id)();

  @override
  Set<Column> get primaryKey => {leagueId, seasonStartYear, clubId};
}

/// Small key/value table for facts about the whole save (seed, season).
@DataClassName('MetaRow')
class GameMeta extends Table {
  TextColumn get metaKey => text()();
  TextColumn get metaValue => text()();

  @override
  Set<Column> get primaryKey => {metaKey};
}

@DriftDatabase(
  tables: [
    Leagues,
    Clubs,
    Players,
    Coaches,
    Contracts,
    LeagueSeasonClubs,
    GameMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'bolzplatz'));

  /// Bump on every schema change and add a step to [migration].
  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Add one step per version here, for example:
      // if (from < 2) await m.addColumn(players, players.newColumn);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<List<ClubRow>> allClubs() => select(clubs).get();

  Future<void> addClub(String name, String place) async {
    final next = (await allClubs()).length + 1;
    await into(clubs).insert(
      ClubsCompanion(id: Value(next), name: Value(name), place: Value(place)),
    );
  }
}
