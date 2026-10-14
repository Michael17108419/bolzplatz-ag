import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Minimal table for the Phase 0 platform check.
class Clubs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get place => text()();
}

@DriftDatabase(tables: [Clubs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'bolzplatz'));

  @override
  int get schemaVersion => 1;

  Future<List<Club>> allClubs() => select(clubs).get();

  Future<void> addClub(String name, String place) {
    return into(clubs).insert(ClubsCompanion.insert(name: name, place: place));
  }
}
