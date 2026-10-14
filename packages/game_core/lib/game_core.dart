/// Pure Dart game logic for Bolzplatz AG.
///
/// Rules for this package (see the root README):
/// - no imports of Flutter, Drift or dart:io
/// - no wall clock and no platform random source outside the seeded generator
/// - no player-facing text; use language file keys
library;

export 'src/calendar/game_date.dart';
export 'src/calendar/season.dart';
export 'src/generation/player_generator.dart';
export 'src/model/model.dart';
export 'src/pyramid/pyramid.dart';
export 'src/result/result.dart';
export 'src/rng/seeded_random.dart';
export 'src/rules/generator_rules.dart';
export 'src/rules/rules.dart';
export 'src/world/club_catalog.dart';
export 'src/world/world.dart';
export 'src/world/world_generator.dart';
export 'src/world/world_json.dart';
export 'src/world/world_report.dart';
