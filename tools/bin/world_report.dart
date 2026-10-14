import 'dart:io';

import 'package:game_core/game_core.dart';

/// Writes the distribution report of the shipped world to
/// `data/world_report_2026_27.md`. Run from the `tools` folder:
///
///     dart run bin/world_report.dart
void main() {
  const root = '..';
  final rulesResult = Rules.parse(
    File('$root/rules/rules_2026_27.json').readAsStringSync(),
  );
  final rules = rulesResult.valueOrNull;
  if (rules == null) {
    stderr.writeln('Rules: ${rulesResult.errorOrNull}');
    exit(1);
  }
  final world = WorldJson.decode(
    File('$root/data/world_2026_27.json').readAsStringSync(),
  );
  final out = File('$root/data/world_report_2026_27.md');
  out.writeAsStringSync(WorldReport.build(world, rules));
  stdout.writeln('Wrote ${out.path}');
}
