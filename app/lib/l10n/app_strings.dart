import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

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
  String get careerLoading;
  String get careerLoadFailed;
  String get homeTitle;

  // --- career start (document 16) ---
  String get careerStepTrainer;
  String get careerStepBackstory;
  String get careerStepWish;
  String get careerStepLook;
  String get careerStepOffers;
  String get next;
  String get trainerHeading;
  String get lookHeading;
  String get trainerNameLabel;
  String get trainerRandomLook;
  String lookLabel(String key);
  String genderName(int index);
  String outfitName(int index);
  String hairStyleName(int index);
  String beardName(int index);
  String glassesName(int index);
  String secondColourLabel(int outfit);
  String get backstoryHeading;
  String get backstoryPick;
  String backstoryName(String id);
  String backstoryStrengths(String id);
  String backstoryHook(String hookId);
  String get hookLabel;
  String managerValueName(ManagerValue value);
  String managerValueInfo(ManagerValue value);
  String get hookInfo;
  String levelName(TraitLevel level);
  String get wishHeading;
  String get wishHint;
  String get wishNone;
  String wishChosen(String club);
  String wishMissing(String club, String level);
  String get offersHeading;
  String offersWishOffered(String club);
  String offersWishMissing(String club, String level);
  String get offerAccept;
  String get offerNoneChosen;
  String get offerBudget;
  String get offerGoal;
  String get offerLastSeason;
  String get offerSquad;
  String get offerPresident;
  String get offerQuirk;
  String situationName(Situation situation);
  String seasonGoalText(SeasonGoal goal);
  String quirkName(ClubQuirk quirk);
  String presidentTypeName(String id);
  String presidentTraitWord(PresidentTrait trait, bool high);
  String lastSeasonRank(int rank);
  String squadText(String strength, int rank, int total);
  String money(int euros);

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
  String get careerLoading => 'Die Welt wird aufgebaut ...';
  @override
  String get careerLoadFailed => 'Die Welt konnte nicht geladen werden.';
  @override
  String get homeTitle => 'Büro';

  @override
  String get careerStepTrainer => 'Trainer';
  @override
  String get careerStepBackstory => 'Vorgeschichte';
  @override
  String get careerStepWish => 'Wunschverein';
  @override
  String get careerStepLook => 'Kleidung';
  @override
  String get careerStepOffers => 'Angebote';
  @override
  String get next => 'Weiter';
  @override
  String get lookHeading => 'Brille und Kleidung';
  @override
  String get trainerHeading => 'Wer bist du?';
  @override
  String get trainerNameLabel => 'Dein Name';
  @override
  String get trainerRandomLook => 'Zufälliges Aussehen';
  @override
  String lookLabel(String key) => switch (key) {
    'skin' => 'Hautton',
    'hair_style' => 'Frisur',
    'hair_colour' => 'Haarfarbe',
    'beard' => 'Bart',
    'glasses' => 'Brille',
    'gender' => 'Geschlecht',
    'outfit' => 'Kleidung',
    'outfit_colour' => 'Farbe der Kleidung',
    'outfit_colour2' => 'Zweitfarbe',
    _ => key,
  };
  @override
  String genderName(int index) => const ['Mann', 'Frau', 'Divers'][index];
  @override
  String outfitName(int index) => const [
    'Trainingsjacke',
    'T-Shirt',
    'Hoodie',
    'Polo',
    'Anzug',
    'Holzfällerhemd',
    'Muskelshirt',
    'Kleid',
    'Bluse',
  ][index];
  @override
  String hairStyleName(int index) => const [
    'Glatze',
    'Kurzhaar',
    'Scheitel',
    'Locken',
    'Mähne',
    'Vokuhila',
  ][index];
  @override
  String beardName(int index) =>
      const ['Glatt', 'Dreitagebart', 'Vollbart', 'Schnauzer'][index];
  @override
  String secondColourLabel(int outfit) => switch (outfit) {
    4 => 'Farbe der Krawatte',
    5 => 'Farbe des Musters',
    7 => 'Farbe des Gürtels',
    8 => 'Farbe der Schleife',
    _ => 'Zweitfarbe',
  };
  @override
  String glassesName(int index) =>
      const ['Keine', 'Rund', 'Eckig', 'Sonnenbrille'][index];
  @override
  String get backstoryHeading => 'Wie bist du hierhergekommen?';
  @override
  String get backstoryPick => 'Wähle eine Vorgeschichte.';
  @override
  String backstoryName(String id) => switch (id) {
    'failed_pro' => 'Gescheiterter Ex-Profi',
    'outsider' => 'Quereinsteiger ohne Fußballerfahrung',
    'scandal_coach' => 'Skandalumwitterter Ex-Trainer',
    'club_fixture' => 'Vereinsurgestein',
    'business_student' => 'Wirtschaftsstudent',
    'youth_coach' => 'Jugendtrainer',
    'pub_landlord' => 'Kneipenwirt',
    'wandering_saviour' => 'Wandernder Retter',
    'pe_teacher' => 'Sportlehrer',
    'ex_referee' => 'Ex-Schiedsrichter',
    'tactics_streamer' => 'Taktik-Streamer',
    'motivation_guru' => 'Motivationsguru',
    _ => id,
  };
  @override
  String backstoryStrengths(String id) => switch (id) {
    'failed_pro' => 'Respekt in der Kabine, Spielerkontakte. Wenig Geld, die Presse erinnert an Skandale.',
    'outsider' => 'Wirtschaftsgeschick, gute Verhandlungen. Wenig Ansehen bei Spielern, taktisch schwach.',
    'scandal_coach' => 'Hohes Taktikwissen, Medienbekanntheit. Präsidentenvertrauen niedrig, Presse feindlich.',
    'club_fixture' => 'Volles Präsidentenvertrauen, kennt Verein und Umfeld. Wenig Charisma, kaum Verhandlungsgeschick.',
    'business_student' => 'Verhandlungsgeschick, Zahlenverständnis. Wenig Ansehen, wenig Kontakte, taktisch unerfahren.',
    'youth_coach' => 'Sehr guter Talentblick. Niedriges Ansehen, schwaches Verhandlungsgeschick.',
    'pub_landlord' =>
      'Gutes Charisma, viele Kontakte. Niedriges Ansehen, wenig Taktikwissen.',
    'wandering_saviour' => 'Viel Erfahrung, Kontakte, Verhandlungsgeschick. Hoher Stress, wenig Präsidentenvertrauen.',
    'pe_teacher' => 'Gutes Charisma. Niedriges Ansehen, wenige Kontakte.',
    'ex_referee' => 'Gutes Taktikwissen durch Regelkenntnis. Wenig Charisma.',
    'tactics_streamer' => 'Sehr hohes Taktikwissen, gutes Pressebild. Niedriges Ansehen in der Branche, wenige Kontakte.',
    'motivation_guru' => 'Sehr hohes Charisma, gutes Pressebild. Wenig Taktikwissen und Talentblick.',
    _ => id,
  };
  @override
  String backstoryHook(String hookId) => switch (hookId) {
    'hook_failed_pro' => 'Die Presse gräbt alte Skandale aus.',
    'hook_outsider' =>
      'Der Präsident hat dich selbst ausgesucht und erwartet Dankbarkeit.',
    'hook_scandal_coach' => 'Jede Niederlage wird zum Skandal.',
    'hook_club_fixture' =>
      'Jeder im Verein duzt dich und erwartet Gefälligkeiten.',
    'hook_business_student' => 'Die Spieler nennen dich „Praktikant“.',
    'hook_youth_coach' => 'Die Profis nehmen dich anfangs nicht ernst.',
    'hook_pub_landlord' => 'Die Fans lieben dich, die Medien lachen.',
    'hook_wandering_saviour' =>
      'Der Präsident rechnet von Anfang an mit deinem Abschied.',
    'hook_pe_teacher' =>
      'Die Spieler siezen dich und fragen nach Hausaufgaben.',
    'hook_ex_referee' => 'Die Schiedsrichter kennen dich persönlich, und alle erwarten, dass du ihnen nie widersprichst.',
    'hook_tactics_streamer' => 'Moon feiert dich, Earth News zweifelt.',
    'hook_motivation_guru' => 'Du hältst Reden, und die Presse zählt mit.',
    _ => hookId,
  };
  @override
  String get hookLabel => 'Der Haken';
  @override
  String managerValueInfo(ManagerValue value) => switch (value) {
    ManagerValue.standing =>
      'Dein Ruf in der Branche. Er entscheidet, welche Vereine überhaupt anrufen.',
    ManagerValue.charisma =>
      'Wie gut du Menschen führst. Wirkt auf Stimmung, Ansprachen und Beziehungen. Wächst mit der Zeit.',
    ManagerValue.stress =>
      'Wie sehr dich der Druck mitnimmt. Hier ist niedrig gut und hoch schlecht.',
    ManagerValue.presidentTrust =>
      'Wie sehr der Präsident dir vertraut. Davon hängen Budget und deine Zukunft im Verein ab.',
    ManagerValue.pressImage =>
      'Was die Zeitungen über dich schreiben. Gutes Bild bringt Rückenwind, schlechtes Gegenwind.',
    ManagerValue.contacts =>
      'Dein Netzwerk im Fußball. Hilft bei Transfers und bei der Suche nach Personal.',
    ManagerValue.tacticalKnowledge =>
      'Wie gut du Taktik verstehst. Bestimmt, wie viele und wie gute Aufstellungshinweise du bekommst. Wächst mit der Zeit.',
    ManagerValue.negotiation =>
      'Wie hart du verhandelst. Bessere Preise bei Transfers und Verträgen. Wächst mit der Zeit.',
    ManagerValue.talentEye =>
      'Wie gut du Talente erkennst. Macht dein Scouting genauer. Wächst mit der Zeit.',
  };
  @override
  String get hookInfo =>
      'Jede Vorgeschichte hat eine Schwäche, die dir im Spiel immer wieder Ärger macht.';
  @override
  String managerValueName(ManagerValue value) => switch (value) {
    ManagerValue.standing => 'Ansehen',
    ManagerValue.charisma => 'Charisma',
    ManagerValue.stress => 'Stress',
    ManagerValue.presidentTrust => 'Präsidentenvertrauen',
    ManagerValue.pressImage => 'Pressebild',
    ManagerValue.contacts => 'Kontakte',
    ManagerValue.tacticalKnowledge => 'Taktikkenntnis',
    ManagerValue.negotiation => 'Verhandlungsgeschick',
    ManagerValue.talentEye => 'Talentblick',
  };
  @override
  String levelName(TraitLevel level) => switch (level) {
    TraitLevel.low => 'niedrig',
    TraitLevel.middle => 'mittel',
    TraitLevel.high => 'hoch',
    TraitLevel.veryHigh => 'sehr hoch',
  };
  @override
  String get wishHeading => 'Hast du einen Wunschverein?';
  @override
  String get wishHint =>
      'Reicht dein Ansehen, steht er unter den Angeboten. Wenn nicht, sagen wir dir, was fehlt.';
  @override
  String get wishNone => 'Kein Wunschverein';
  @override
  String wishChosen(String club) => 'Wunschverein: $club';
  @override
  String wishMissing(String club, String level) =>
      'Für $club reicht dein Ansehen noch nicht. Nötig wäre mindestens „$level“.';
  @override
  String get offersHeading => 'Diese Vereine wollen dich';
  @override
  String offersWishOffered(String club) =>
      'Dein Wunschverein $club meldet sich tatsächlich.';
  @override
  String offersWishMissing(String club, String level) =>
      '$club hat sich nicht gemeldet. Dafür müsste dein Ansehen mindestens „$level“ sein.';
  @override
  String get offerAccept => 'Angebot annehmen';
  @override
  String get offerNoneChosen => 'Wähle ein Angebot.';
  @override
  String get offerBudget => 'Budget';
  @override
  String get offerGoal => 'Saisonziel';
  @override
  String get offerLastSeason => 'Vorsaison';
  @override
  String get offerSquad => 'Kader';
  @override
  String get offerPresident => 'Präsident';
  @override
  String get offerQuirk => 'Besonderheit';
  @override
  String situationName(Situation situation) => switch (situation) {
    Situation.favourite => 'Aufstiegsfavorit mit Druck',
    Situation.midTable => 'Mittelfeld ohne Ziel',
    Situation.relegation => 'Abstiegskampf',
    Situation.bankrupt => 'Pleite am Rand der Lizenz',
  };
  @override
  String seasonGoalText(SeasonGoal goal) => switch (goal) {
    SeasonGoal.title => 'Meisterschaft',
    SeasonGoal.promotion => 'Aufstieg',
    SeasonGoal.noTarget => 'Kein Ziel, nur nicht auffallen',
    SeasonGoal.survival => 'Klassenerhalt',
    SeasonGoal.licence => 'Klassenerhalt und Lizenz retten',
  };
  @override
  String quirkName(ClubQuirk quirk) => switch (quirk) {
    ClubQuirk.none => 'Keine',
    ClubQuirk.debtMountain => 'Schuldenberg',
    ClubQuirk.talentFactory => 'Talentschmiede',
    ClubQuirk.feudingSquad => 'Zerstrittene Kabine',
    ClubQuirk.loyalFans => 'Treue Fans',
    ClubQuirk.crumblingStadium => 'Bröckelndes Stadion',
  };
  @override
  String presidentTypeName(String id) => switch (id) {
    'construction_tycoon' => 'Größenwahnsinniger Bauunternehmer',
    'thrifty_butcher' => 'Sparsamer Metzgermeister',
    'car_dealer' => 'Geltungssüchtiger Autohändler',
    'savings_bank_director' => 'Sparkassendirektor',
    'ex_pro' => 'Ex-Profi',
    'rich_heir' => 'Reicher Erbe',
    'patron' => 'Mäzen',
    'club_fixture' => 'Vereinsurgestein',
    _ => id,
  };
  @override
  String presidentTraitWord(PresidentTrait trait, bool high) => switch (trait) {
    PresidentTrait.patience => high ? 'geduldig' : 'ungeduldig',
    PresidentTrait.meddling => high ? 'mischt sich ein' : 'lässt dich machen',
    PresidentTrait.thrift => high ? 'geizig' : 'großzügig',
    PresidentTrait.ambition => high ? 'ehrgeizig' : 'genügsam',
    PresidentTrait.vanity => high ? 'eitel' : 'bescheiden',
    PresidentTrait.loyalty => high ? 'treu' : 'wankelmütig',
    PresidentTrait.pressCraving => high ? 'pressegeil' : 'pressescheu',
  };
  @override
  String lastSeasonRank(int rank) => 'Platz $rank';
  @override
  String squadText(String strength, int rank, int total) =>
      'Stärke $strength, Platz $rank von $total';
  @override
  String money(int euros) {
    if (euros >= 1000000) {
      final m = (euros / 1000000).toStringAsFixed(1).replaceAll('.', ',');
      return '${m.endsWith(',0') ? m.substring(0, m.length - 2) : m} Mio. €';
    }
    final digits = euros.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
      out.write(digits[i]);
    }
    return '$out €';
  }

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
