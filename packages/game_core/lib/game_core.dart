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
export 'src/match/auto_manager.dart';
export 'src/match/fit.dart';
export 'src/match/match_session.dart';
export 'src/match/match_types.dart';
export 'src/match/system_fit.dart';
export 'src/match/team_sheet.dart';
export 'src/model/model.dart';
export 'src/pyramid/pyramid.dart';
export 'src/result/result.dart';
export 'src/rng/seeded_random.dart';
export 'src/rules/generator_rules.dart';
export 'src/rules/match_rules.dart';
export 'src/rules/rules.dart';
export 'src/rules/season_rules.dart';
export 'src/rules/tactics_rules.dart';
export 'src/season/cup.dart';
export 'src/season/league_table.dart';
export 'src/season/schedule.dart';
export 'src/season/season_runner.dart';
export 'src/season/season_state.dart';
export 'src/world/club_catalog.dart';
export 'src/world/world.dart';
export 'src/world/world_generator.dart';
export 'src/world/world_json.dart';
export 'src/world/world_report.dart';
