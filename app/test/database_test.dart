import 'package:bolzplatz_app/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database stores and returns clubs', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.addClub('SV Dosenpfand Leipzig', 'Leipzig');
    await db.addClub('FC Monopol München', 'München');

    final clubs = await db.allClubs();
    expect(clubs.map((c) => c.name), [
      'SV Dosenpfand Leipzig',
      'FC Monopol München',
    ]);
  });
}
