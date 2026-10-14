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
  String get careerTitle;
  String get careerChooseClub;
  String get careerLoading;
  String get careerLoadFailed;
  String get careerManagerName;
  String get careerStart;
  String get careerNoClubChosen;
  String careerStrength(String value);
  String careerRank(int rank, int total);
  String get homeTitle;

  /// Display name of a league from its key in the world data.
  String leagueName(String key);
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
  @override
  String get careerTitle => 'Karrierestart';
  @override
  String get careerChooseClub => 'Wähle deinen Verein';
  @override
  String get careerLoading => 'Die Welt wird aufgebaut ...';
  @override
  String get careerLoadFailed => 'Die Welt konnte nicht geladen werden.';
  @override
  String get careerManagerName => 'Dein Name als Manager';
  @override
  String get careerStart => 'Karriere starten';
  @override
  String get careerNoClubChosen => 'Noch kein Verein gewählt.';
  @override
  String careerStrength(String value) => 'Stärke $value';
  @override
  String careerRank(int rank, int total) =>
      'Platz $rank von $total nach Stärke';
  @override
  String get homeTitle => 'Büro';
  @override
  String leagueName(String key) => switch (key) {
    'liga_1' => '1. Liga',
    'liga_2' => '2. Liga',
    'liga_3' => '3. Liga',
    'liga_4_nord' => '4. Liga Nord',
    'liga_4_nordost' => '4. Liga Nordost',
    'liga_4_west' => '4. Liga West',
    'liga_4_suedwest' => '4. Liga Südwest',
    'liga_4_bayern' => '4. Liga Bayern',
    _ => key,
  };
}

/// The strings in use. Later this follows a setting in the settings screen.
final stringsProvider = Provider<AppStrings>((ref) => const AppStringsDe());
