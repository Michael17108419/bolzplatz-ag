import 'package:bolzplatz_app/game/saves.dart';
import 'package:flutter_test/flutter_test.dart';

// Engine 2 replays matches differently: saves from before (version 1, and
// version 2 before step 10e) are shown as unreadable instead of being
// continued with wrong results.

void main() {
  test('saves of engine 1 are refused', () {
    expect(SaveData.version, 3);
    expect(SaveData.tryParse('{"version": 1}'), isNull);
    expect(SaveData.tryParse('{"version": 2}'), isNull);
  });
}
