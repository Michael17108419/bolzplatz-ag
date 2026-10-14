import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Loads all clubs; seeds a few on first start so the table is not empty.
final clubsProvider = FutureProvider<List<ClubRow>>((ref) async {
  final db = ref.watch(databaseProvider);
  var clubs = await db.allClubs();
  if (clubs.isEmpty) {
    await db.addClub('SV Dosenpfand Leipzig', 'Leipzig');
    await db.addClub('FC Monopol München', 'München');
    await db.addClub('SC Elbphilharmonie Hamburg', 'Hamburg');
    clubs = await db.allClubs();
  }
  return clubs;
});
