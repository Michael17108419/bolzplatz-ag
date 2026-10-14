# Bolzplatz AG

Satirical football manager for Windows (Steam first), written in Flutter/Dart.
Mobile versions follow after the MVP. The design lives in the Claude Docs
project "Fussballsimulator" (Fahrplan and blocks 1 to 16).

## Layout

| Folder | Content |
|---|---|
| `app/` | Flutter Windows app, UI only |
| `packages/game_core/` | Pure Dart game logic, no UI, no database |
| `tools/` | Mass simulation, reports, data import |
| `rules/` | Versioned rule sets as JSON |

## Code rules

1. **Core without UI.** `game_core` imports neither Flutter, Drift nor `dart:io`.
   It is pure Dart so mass tests run without a window and a mobile port stays possible.
2. **No randomness outside the generator.** All random numbers come from the one
   seeded generator. `DateTime.now()` and `Random()` are forbidden in `game_core`.
   The same seed must always build the same world, byte for byte.
3. **Numbers live in the rules.** Factors, curves and limits are in
   `rules/rules_<season>.json`. No balancing number in code.
4. **Fixed IDs.** Clubs, players, contracts and so on get an ID that never changes.
   Names are for display only, never keys.
5. **Text only from language files.** No player-facing sentence in code.
   Texts use keys, placeholders and word variants.
6. **Immutable model.** Model classes are `final` and change by creating new
   objects. Each area changes state in exactly one place.
7. **Every rule has a test.** Each calculation from a block gets at least one test
   that recomputes a value from the design document. Lints are strict and the
   pipeline fails on any finding.

State management: Riverpod, only in `app/`, never in `game_core`.

Language: code, names and comments are English. Text shown in the game is German.

## Checks

```
cd packages/game_core
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

`test/architecture_test.dart` enforces rules 1 and 2 by scanning the sources.

CI: GitHub Actions on Windows machines (`.github/workflows/ci.yml`).
