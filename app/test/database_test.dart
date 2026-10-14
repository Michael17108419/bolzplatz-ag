import 'dart:io';

import 'package:bolzplatz_app/database.dart';
import 'package:bolzplatz_app/repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

Player _player({Contract? contract}) => Player(
  id: const PlayerId(7),
  firstName: 'Kalle',
  lastName: 'Kopfball',
  birthDate: GameDate(2000, 3, 15),
  position: Position.st,
  attributes: AttributeSet.filled(50).withValue(Attribute.heading, 77.5),
  traits: {for (final t in CharacterTrait.values) t: 42.5},
  injuryProneness: 33,
  abilities: const [
    SpecialAbility(SpecialAbilityType.headerMonster, AbilityTier.gold),
    SpecialAbility(SpecialAbilityType.targetMan, AbilityTier.bronze),
  ],
  developmentType: DevelopmentType.lateBloomer,
  potentialCore: 61,
  potentialDynamic: 9.5,
  roles: const {'target_man': RoleFamiliarity.expert},
  clubId: const ClubId(1),
  contract: contract,
);

void main() {
  late AppDatabase db;
  late GameRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = GameRepository(db);
  });
  tearDown(() => db.close());

  Future<void> seedLeagueAndClub() async {
    await repo.saveLeague(
      League(id: const LeagueId(1), name: '1. Liga', level: 1, teamCount: 18),
    );
    await repo.saveClub(
      const Club(
        id: ClubId(1),
        name: 'SV Dosenpfand Leipzig',
        shortName: 'Dosenpfand',
        place: 'Leipzig',
        region: Region.nordost,
        leagueId: LeagueId(1),
      ),
    );
  }

  test('database stores and returns clubs', () async {
    await seedLeagueAndClub();
    await db.addClub('FC Monopol München', 'München');
    final clubs = await db.allClubs();
    expect(clubs.map((c) => c.name), [
      'SV Dosenpfand Leipzig',
      'FC Monopol München',
    ]);
  });

  test('club and league round trip', () async {
    await seedLeagueAndClub();
    final club = await repo.loadClub(const ClubId(1));
    expect(club?.name, 'SV Dosenpfand Leipzig');
    expect(club?.region, Region.nordost);
    final league = await repo.loadLeague(const LeagueId(1));
    expect(league?.teamCount, 18);
    expect(await repo.loadClub(const ClubId(99)), isNull);
  });

  test('player with contract round trips unchanged', () async {
    await seedLeagueAndClub();
    final contract = Contract(
      id: const ContractId(3),
      playerId: const PlayerId(7),
      clubId: const ClubId(1),
      start: GameDate(2026, 7, 1),
      end: GameDate(2029, 6, 30),
      baseSalaryPerYear: 60000,
      salaryStages: const [50000, 60000, 70000],
      goalBonus: 500,
      releaseClause: 2000000,
      rolePromise: 'target_man',
    );
    final original = _player(contract: contract);
    await repo.savePlayer(original);

    final loaded = await repo.loadPlayer(const PlayerId(7));
    expect(loaded, isNotNull);
    expect(loaded!.attributes, original.attributes);
    expect(loaded.attributes[Attribute.heading], 77.5);
    expect(loaded.traits, original.traits);
    expect(loaded.abilities, original.abilities);
    expect(loaded.roles, original.roles);
    expect(loaded.birthDate, original.birthDate);
    expect(loaded.developmentType, DevelopmentType.lateBloomer);
    expect(loaded.potentialDynamic, 9.5);
    expect(loaded.contract?.salaryStages, [50000, 60000, 70000]);
    expect(loaded.contract?.releaseClause, 2000000);
    expect(loaded.contract?.rolePromise, 'target_man');
    expect(loaded.contract?.end, GameDate(2029, 6, 30));
  });

  test('saving a player twice updates instead of duplicating', () async {
    await seedLeagueAndClub();
    await repo.savePlayer(_player());
    await repo.savePlayer(_player());
    expect(await db.select(db.players).get(), hasLength(1));
  });

  test('league season keeps its clubs', () async {
    await seedLeagueAndClub();
    final league = League(
      id: const LeagueId(1),
      name: '1. Liga',
      level: 1,
      teamCount: 2,
    );
    await repo.saveClub(
      const Club(
        id: ClubId(2),
        name: 'FC Monopol München',
        shortName: 'Monopol',
        place: 'München',
        region: Region.bayern,
        leagueId: LeagueId(1),
      ),
    );
    await repo.saveLeagueSeason(
      LeagueSeason(
        league: league,
        season: const Season(2026),
        clubIds: const [ClubId(2), ClubId(1)],
      ),
    );
    final ids = await repo.loadLeagueSeasonClubs(
      const LeagueId(1),
      const Season(2026),
    );
    expect(ids, const [ClubId(1), ClubId(2)]);
  });

  test('foreign keys are enforced', () async {
    await expectLater(
      db
          .into(db.clubs)
          .insert(
            ClubsCompanion(
              id: const Value(5),
              name: Value('X'),
              place: Value('Y'),
              leagueId: const Value(404),),
          ),
      throwsA(isA<Exception>()),
    );
  });

  group('schema and migration guard', () {
    const expectedTables = [
      'clubs',
      'coaches',
      'contracts',
      'league_season_clubs',
      'leagues',
      'players',
    ];

    test('fresh database has exactly the expected tables', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .get();
      expect(rows.map((r) => r.read<String>('name')), expectedTables);
    });

    test('user_version equals the schema version', () async {
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.read<int>('user_version'), AppDatabase.currentSchemaVersion);
    });

    test('data survives closing and reopening a file database', () async {
      final dir = await Directory.systemTemp.createTemp('bolzplatz_test');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/game.sqlite');

      final first = AppDatabase(NativeDatabase(file));
      await GameRepository(first).saveLeague(
        League(id: const LeagueId(1), name: '1. Liga', level: 1, teamCount: 18),
      );
      await first.close();

      final second = AppDatabase(NativeDatabase(file));
      addTearDown(second.close);
      final league = await GameRepository(second).loadLeague(const LeagueId(1));
      expect(league?.name, '1. Liga');
    });
  });
}
