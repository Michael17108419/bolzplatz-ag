import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

String _file() => File('../../rules/rules_2026_27.json').readAsStringSync();

TacticsRules _tactics() => Rules.parse(_file()).valueOrNull!.tactics;

Result<Rules, RulesError> _parseChanged(void Function(Map<String, dynamic>) f) {
  final m = jsonDecode(_file()) as Map<String, dynamic>;
  f(m['tactics'] as Map<String, dynamic>);
  return Rules.parse(jsonEncode(m));
}

void main() {
  test('the shipped file has 30 roles, 9 formations, 5 systems, 3 sliders', () {
    final t = _tactics();
    expect(t.roles.length, 30);
    expect(t.formations.length, 9);
    expect(t.systems.length, 5);
    expect(t.sliders.length, 3);
    expect(t.talks.length, 5);
  });

  test('every formation has 11 slots with one goalkeeper', () {
    for (final f in _tactics().formations) {
      expect(f.slots.length, 11, reason: f.id);
      expect(f.slots.where((p) => p.isGoalkeeper).length, 1, reason: f.id);
    }
  });

  test('back line size matches the formation name', () {
    for (final f in _tactics().formations) {
      expect(f.backLine, int.parse(f.id.substring(0, 1)), reason: f.id);
      final defenders = f.slots
          .where((p) => p == Position.iv)
          .length;
      expect(defenders, f.backLine == 4 ? 2 : 3, reason: f.id);
      expect(f.wingBackSlots, f.backLine == 3, reason: f.id);
    }
  });

  test('every outfield formation slot position has a role offered', () {
    final t = _tactics();
    for (final f in t.formations) {
      for (final p in f.slots) {
        expect(
          t.roles.any((r) => r.positions.contains(p)),
          isTrue,
          reason: '${f.id} ${p.id}',
        );
      }
    }
  });

  test('every position offers at least one role and every role fits a system', () {
    final t = _tactics();
    for (final p in Position.values) {
      expect(t.roles.any((r) => r.positions.contains(p)), isTrue, reason: p.id);
    }
    for (final r in t.roles) {
      expect(r.fitsSystems, isNotEmpty, reason: r.id);
    }
  });

  test('goalkeeper roles use goalkeeper attributes, field roles do not', () {
    for (final r in _tactics().roles) {
      final keeper = r.positions.contains(Position.tw);
      expect(r.positions.every((p) => p.isGoalkeeper == keeper), isTrue);
      if (keeper) {
        expect(r.keyAttributes.any((a) => a.isGoalkeeping), isTrue);
      } else {
        expect(r.keyAttributes.any((a) => a.isGoalkeeping), isFalse);
      }
    }
  });

  test('only the wide centre back is bound to back three or five', () {
    final bound = _tactics().roles.where((r) => r.onlyWithBackThreeOrFive);
    expect(bound.map((r) => r.id), ['wide_centre_back']);
  });

  test('position distance: zero diagonal, symmetric except for wings', () {
    final t = _tactics();
    expect(t.positionDistance[Position.iv]![Position.st], 28);
    expect(t.positionDistance[Position.zm]![Position.zdm], 4);
    for (final p in Position.values) {
      expect(t.positionDistance[p]![p], 0);
    }
  });

  test('weak foot penalty falls with stars; five stars cost nothing', () {
    final t = _tactics();
    expect(t.weakFootPenalty[1], 0.20);
    expect(t.weakFootPenalty[5], 0);
  });

  test('role familiarity rises from minus to plus plus', () {
    final f = _tactics().roleFamiliarityFactor;
    expect(f['minus']! < f['zero']!, isTrue);
    expect(f['zero']! < f['plus']!, isTrue);
    expect(f['plus']! < f['plus_plus']!, isTrue);
  });

  test('a formation with a missing slot is rejected', () {
    final result = _parseChanged((t) {
      final f = (t['formations'] as List<dynamic>).first as Map<String, dynamic>;
      (f['slots'] as List<dynamic>).removeLast();
    });
    expect(result.errorOrNull, isNotNull);
  });

  test('a role that fits an unknown system is rejected', () {
    final result = _parseChanged((t) {
      final r = (t['roles'] as List<dynamic>).first as Map<String, dynamic>;
      (r['fits_systems'] as List<dynamic>).add('nonsense');
    });
    expect(result.errorOrNull, isNotNull);
  });

  test('an unknown attribute in a role is rejected', () {
    final result = _parseChanged((t) {
      final r = (t['roles'] as List<dynamic>).first as Map<String, dynamic>;
      (r['key_attributes'] as List<dynamic>).add('charm');
    });
    expect(result.errorOrNull, isNotNull);
  });
}
