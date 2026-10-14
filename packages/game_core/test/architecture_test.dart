import 'dart:io';

import 'package:test/test.dart';

/// Guards the architecture rules of game_core by scanning its sources.
void main() {
  final libDir = Directory('lib');
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  // Files that are allowed to touch the platform random source.
  const randomAllowList = <String>['lib/src/rng/seeded_random.dart'];

  String content(File f) => f.readAsStringSync();
  String rel(File f) => f.path.replaceAll(r'\', '/');

  test('game_core does not import Flutter, Drift or dart:io', () {
    final banned = RegExp(
      r"import\s+'(package:flutter/|package:drift|dart:io|dart:ui)",
    );
    for (final f in files) {
      expect(banned.hasMatch(content(f)), isFalse, reason: rel(f));
    }
  });

  test('game_core does not use DateTime.now()', () {
    for (final f in files) {
      expect(content(f).contains('DateTime.now('), isFalse, reason: rel(f));
    }
  });

  test('game_core uses Random only in the seeded generator', () {
    final random = RegExp(r'\bRandom\(');
    for (final f in files) {
      if (randomAllowList.contains(rel(f))) continue;
      expect(random.hasMatch(content(f)), isFalse, reason: rel(f));
    }
  });

  test('game_core contains no print calls', () {
    final print = RegExp(r'\bprint\(');
    for (final f in files) {
      expect(print.hasMatch(content(f)), isFalse, reason: rel(f));
    }
  });
}
