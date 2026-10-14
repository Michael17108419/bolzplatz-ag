import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  test('Ok carries a value', () {
    const Result<int, String> r = Ok(3);
    expect(r.isOk, isTrue);
    expect(r.valueOrNull, 3);
    expect(r.errorOrNull, isNull);
  });

  test('Err carries an error', () {
    const Result<int, String> r = Err('too young');
    expect(r.isErr, isTrue);
    expect(r.valueOrNull, isNull);
    expect(r.errorOrNull, 'too young');
  });

  test('map changes only Ok', () {
    const Result<int, String> ok = Ok(2);
    const Result<int, String> err = Err('x');
    expect(ok.map((v) => v * 10).valueOrNull, 20);
    expect(err.map((v) => v * 10).errorOrNull, 'x');
  });

  test('fold chooses the matching branch', () {
    const Result<int, String> ok = Ok(2);
    const Result<int, String> err = Err('x');
    expect(ok.fold((v) => 'ok $v', (e) => 'err $e'), 'ok 2');
    expect(err.fold((v) => 'ok $v', (e) => 'err $e'), 'err x');
  });
}
