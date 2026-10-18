import 'package:bolzplatz_app/game/saves.dart';
import 'package:flutter_test/flutter_test.dart';

// Engine 2 replays matches differently: saves from before (version 1,
// version 2 before step 10e, version 3 before steps 10f to 10h, version 4
// before step 11) are shown as unreadable instead of being continued with
// wrong results.

void main() {
  test('saves of engine 1 are refused', () {
    expect(SaveData.version, 5);
    expect(SaveData.tryParse('{"version": 1}'), isNull);
    expect(SaveData.tryParse('{"version": 2}'), isNull);
    expect(SaveData.tryParse('{"version": 3}'), isNull);
    expect(SaveData.tryParse('{"version": 4}'), isNull);
  });
}
