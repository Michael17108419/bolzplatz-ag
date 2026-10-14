import 'dart:io';

import 'package:game_core/game_core.dart';

/// Generates the shipped start world once and writes it to
/// `data/world_2026_27.json`. Run from the `tools` folder:
///
///     dart run bin/generate_world.dart [seed]
///
/// Without a seed the seed from the rules file is used.
void main(List<String> args) {
  const root = '..';
  final rulesResult = Rules.parse(
    File('$root/rules/rules_2026_27.json').readAsStringSync(),
  );
  final rules = rulesResult.valueOrNull;
  if (rules == null) {
    stderr.writeln('Rules: ${rulesResult.errorOrNull}');
    exit(1);
  }
  final catalogResult = ClubCatalog.parse(
    File('$root/tools/data/vereine_2026_27.csv').readAsStringSync(),
  );
  final catalog = catalogResult.valueOrNull;
  if (catalog == null) {
    stderr.writeln('Club list: ${catalogResult.errorOrNull}');
    exit(1);
  }
  final names = NameLists.fromJson(
    File('$root/data/names_de.json').readAsStringSync(),
  );
  final seed = args.isEmpty ? null : int.parse(args.first);

  final result = WorldGenerator.generate(
    rules: rules,
    catalog: catalog,
    names: names,
    seed: seed,
  );
  final world = result.valueOrNull;
  if (world == null) {
    stderr.writeln('World: ${result.errorOrNull}');
    exit(1);
  }

  final out = File('$root/data/world_2026_27.json');
  out.writeAsStringSync(WorldJson.encode(world));
  stdout.writeln(
    'Wrote ${out.path}: ${world.clubs.length} clubs, '
    '${world.players.length} players, ${world.coaches.length} coaches '
    '(seed ${world.seed}).',
  );
}
