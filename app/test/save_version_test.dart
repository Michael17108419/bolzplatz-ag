import 'package:bolzplatz_app/game/saves.dart';
import 'package:flutter_test/flutter_test.dart';

// Engine 2 replays matches differently: saves from before (version 1) are
// shown as unreadable instead of being continued with wrong results.

void main() {
  test('saves of engine 1 are refused', () {
    expect(SaveData.version, 2);
    expect(SaveData.tryParse('{"version": 1}'), isNull);
  });
}
