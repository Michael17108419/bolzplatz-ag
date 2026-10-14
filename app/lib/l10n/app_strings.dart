import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All texts of the user interface. A screen asks this interface and never
/// holds a literal; another language is one more implementation.
abstract interface class AppStrings {
  String get languageName;
  String get appTitle;
  String get tagline;
  String get menuNewGame;
  String get menuLoadGame;
  String get menuSettings;
  String get menuQuit;
  String get back;
  String get settingsTitle;
  String get settingsLanguage;
  String get settingsShortcuts;
  String get shortcutBack;
  String get shortcutBackKey;
  String comingInStep(int step);
}

/// German, the only language for now.
class AppStringsDe implements AppStrings {
  const AppStringsDe();

  @override
  String get languageName => 'Deutsch';
  @override
  String get appTitle => 'Bolzplatz AG';
  @override
  String get tagline => 'Der Fußballmanager für Aktionäre';
  @override
  String get menuNewGame => 'Neues Spiel';
  @override
  String get menuLoadGame => 'Spiel laden';
  @override
  String get menuSettings => 'Einstellungen';
  @override
  String get menuQuit => 'Beenden';
  @override
  String get back => 'Zurück';
  @override
  String get settingsTitle => 'Einstellungen';
  @override
  String get settingsLanguage => 'Sprache';
  @override
  String get settingsShortcuts => 'Tastaturkürzel';
  @override
  String get shortcutBack => 'Zurück zum vorigen Bildschirm';
  @override
  String get shortcutBackKey => 'Esc';
  @override
  String comingInStep(int step) => 'Kommt in Bauabschnitt $step.';
}

/// The strings in use. Later this follows a setting in the settings screen.
final stringsProvider = Provider<AppStrings>((ref) => const AppStringsDe());
