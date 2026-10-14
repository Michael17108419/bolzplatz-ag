import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

String _file() => File('../../rules/rules_2026_27.json').readAsStringSync();

Map<String, dynamic> _json() => jsonDecode(_file()) as Map<String, dynamic>;

Result<Rules, RulesError> _parse(Map<String, dynamic> m) =>
    Rules.parse(jsonEncode(m));

void main() {
  test('the shipped rules file for 2026/27 is valid', () {
    final result = Rules.parse(_file());
    expect(result.errorOrNull, isNull);
    final rules = result.valueOrNull!;
    expect(rules.seasonStartYear, 2026);
    expect(rules.ageCurves.length, Attribute.count);
    expect(rules.maxAbilitiesPerPlayer, 4);
    expect(rules.maxGoldAbilitiesPerPlayer, 1);
    expect(rules.tierMultiplier[AbilityTier.gold], 2.2);
  });

  test('league structure matches the world: 206 clubs', () {
    final rules = Rules.parse(_file()).valueOrNull!;
    final clubs = rules.leagues.fold<int>(0, (sum, l) => sum + l.teamCount);
    // 18 + 18 + 20 + 5 * 18 = 146 league places; pool clubs make up 206.
    expect(clubs, 146);
    expect(rules.leagues.where((l) => l.level == 4).length, 5);
    expect(
      rules.leagues.where((l) => l.level == 4).map((l) => l.region).toSet(),
      Region.values.toSet(),
    );
  });

  test('age curves follow the design values', () {
    final rules = Rules.parse(_file()).valueOrNull!;
    final c = rules.ageCurves[Attribute.acceleration]!;
    expect(
      [c.risesUntil, c.plateauFrom, c.plateauTo, c.declinesFrom],
      [23, 24, 27, 28],
    );
    final gk = rules.ageCurves[Attribute.gkPositioning]!;
    expect(gk.declinesFrom, 37);
  });

  test('rejects invalid JSON', () {
    expect(Rules.parse('{nope').isErr, isTrue);
  });

  test('rejects an unsupported schema version', () {
    final m = _json()..['schema_version'] = 2;
    expect(_parse(m).errorOrNull?.message, contains('schema_version'));
  });

  test('rejects a missing age curve', () {
    final m = _json();
    (m['age_curves'] as Map<String, dynamic>).remove('finishing');
    expect(_parse(m).errorOrNull?.message, contains('finishing'));
  });

  test('rejects an unknown attribute in age curves', () {
    final m = _json();
    (m['age_curves'] as Map<String, dynamic>)['telepathy'] = {
      'rises_until': 20,
      'plateau_from': 21,
      'plateau_to': 25,
      'declines_from': 26,
    };
    expect(_parse(m).errorOrNull?.message, contains('telepathy'));
  });

  test('rejects an inconsistent age curve', () {
    final m = _json();
    (m['age_curves'] as Map<String, dynamic>)['finishing'] = {
      'rises_until': 30,
      'plateau_from': 20,
      'plateau_to': 25,
      'declines_from': 26,
    };
    expect(_parse(m).errorOrNull?.message, contains('Inconsistent'));
  });

  test('rejects tier multipliers that do not rise', () {
    final m = _json();
    ((m['abilities'] as Map<String, dynamic>)['tier_multiplier']
            as Map<String, dynamic>)['gold'] =
        1.0;
    expect(_parse(m).isErr, isTrue);
  });

  test('rejects an odd team count and an unknown region', () {
    final odd = _json();
    ((odd['leagues'] as List<dynamic>).first as Map<String, dynamic>)[
        'team_count'] = 17;
    expect(_parse(odd).isErr, isTrue);

    final region = _json();
    ((region['leagues'] as List<dynamic>).last as Map<String, dynamic>)[
        'region'] = 'mars';
    expect(_parse(region).errorOrNull?.message, contains('mars'));
  });

  test('wrong value types become errors, not crashes', () {
    final m = _json()..['season_start_year'] = 'abc';
    expect(_parse(m).isErr, isTrue);
  });
}
