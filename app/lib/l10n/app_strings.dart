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
  String get infoBackstory;
  String officeSeason(int startYear);
  String get officeToMenu;
  String get officeGo;
  String get officeNextTitle;
  String officeMatchday(int day);
  String get officeHome;
  String get officeAway;
  String officeStrengthCompare(String mine, String theirs);
  String get officeTableTitle;
  String get officeTableEmpty;
  String officeTableForecast(int rank, int count);
  String get officeCashTitle;
  String officeSquad(int count);
  String get officeMailTitle;
  String get officeMailPick;
  String get officeSenderPresident;
  String get officeSenderAdvisor;
  String get officeSenderNews;
  String officeMailSubjectPresident(String club);
  String officeMailBodyPresident(String typeId, String name);
  String get officeMailSubjectAdvisor;
  String officeMailBodyAdvisor({
    required String goal,
    required String budget,
    required int squad,
    required String opponent,
    required bool home,
  });
  String officeMailSubjectNews(Situation situation);
  String officeMailBodyNews({
    required String name,
    required String club,
    required String backstory,
    required String hook,
  });
  String get infoOfficeNext;
  String get infoOfficeTable;
  String get infoOfficeMail;
  String get infoStrength;
  String backstoryPast(String id);
  String get helpSettingTitle;
  String get helpSettingText;
  String get infoWish;
  String get infoSituation;
  String get infoGoal;
  String get infoBudget;
  String get infoLastSeason;
  String get infoSquad;
  String get infoPresident;
  String get infoQuirk;
  String infoQuirkKind(ClubQuirk quirk);
  String get offerSituation;
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
    ManagerValue.standing => 'Dein Ruf in der Branche. Hoch: Vereine rufen dich an. Niedrig: Du rufst an, und die Sekretärin legt auf.',
    ManagerValue.charisma => 'Wie gut du Menschen um den Finger wickelst. Wirkt auf Stimmung, Ansprachen und Beziehungen. Wächst, wenn du es übst.',
    ManagerValue.stress => 'Wie sehr dich der Job auffrisst. Niedrig ist gut. Hoch heißt: Kaffee, Kopfschmerzen und kurze Nerven.',
    ManagerValue.presidentTrust => 'Wie fest der Präsident an dich glaubt. Davon hängen dein Budget und deine Zukunft ab. Vertrauen gewinnt man in Jahren und verliert es in einer Halbzeit.',
    ManagerValue.pressImage => 'Was die Zeitung über dich schreibt. Ein gutes Bild gibt Rückenwind, ein schlechtes Schlagzeilen, die man nicht rahmen will.',
    ManagerValue.contacts => 'Wen du anrufen kannst. Hilft bei Transfers und beim Personal. Fußball ist ein Dorf mit Telefonnummern.',
    ManagerValue.tacticalKnowledge => 'Wie gut du Taktik verstehst. Davon hängt ab, wie viele und wie schlaue Hinweise du zur Aufstellung bekommst. Wächst mit der Zeit.',
    ManagerValue.negotiation => 'Wie hart du feilschst. Bessere Preise bei Transfers und Verträgen. Wächst mit der Erfahrung.',
    ManagerValue.talentEye => 'Wie gut du Talente erkennst, bevor es alle anderen tun. Macht dein Scouting genauer. Wächst mit der Zeit.',
  };
  @override
  String get hookInfo =>
      'Jede Vorgeschichte hat eine Macke, die dir im Spiel immer wieder dazwischenfunkt. Rechne damit.';
  @override
  String get infoBackstory =>
      'Dein Leben vor dem ersten Tag. Es bestimmt, mit welchen Stärken und Schwächen du startest. Jeder hier hat etwas erlebt, auf das er nicht stolz ist. Du auch.';
  @override
  String backstoryPast(String id) => switch (id) {
    'failed_pro' => 'Du warst mal Profi, fast. Zwei Jahre Bank, ein Kreuzbandriss, ein Abend, den die Zeitung nicht vergessen hat. Seitdem erzählst du jedem, es sei Pech gewesen.',
    'outsider' => 'Du hast Staubsauger verkauft und warst dabei erstaunlich gut. Dann wollte ein Präsident „frischen Wind“. Dass der Ball rund ist, hast du dir kurz vorher erklären lassen.',
    'scandal_coach' => 'Du hast schon einmal einen Verein trainiert, und es endete mit einer Pressekonferenz, die als Lehrfilm verwendet wird. Deine Taktik war bestechend. Das Wort „bestechend“ hättest du lieber nicht gehört.',
    'club_fixture' => 'Du hast hier als Kind Bälle geholt, später Bier gezapft, dann den Platz gemäht und irgendwann den Verein gerettet, ohne dass es jemand bemerkt hat. Dich kennt jeder, und jeder will etwas.',
    'business_student' => 'Sieben Semester BWL, eine Bachelorarbeit über „Synergien im Amateurfußball“ und ein Praktikum, in dem du nie Kaffee kochen musstest. Du hast Tabellen. Die Spieler haben Spott.',
    'youth_coach' => 'Zehn Jahre Samstagmorgen bei Regen, 40 Kinder, ein Ball und eine Trillerpfeife. Du erkennst Talent schon beim Schuhebinden. Erwachsene, die dir zuhören, kennst du dagegen nicht.',
    'pub_landlord' => 'Du hast tausende Spiele gesehen, von der besten Barhocker-Perspektive der Stadt aus. Deine Menschenkenntnis ist geprüft, deine Taktikkenntnis wurde nach der dritten Runde improvisiert.',
    'wandering_saviour' => 'Du hast fünf Vereine vor dem Abstieg gerettet und bist immer dann gegangen, wenn es ruhig wurde. Dein Koffer steht noch gepackt im Flur. Das ist keine Absicht, aber auch kein Zufall.',
    'pe_teacher' => 'Dreißig Jahre Schulhof, Zwei-Mannschaften-Wählen und Elternabende. Du kannst Menschen begeistern, die nicht wollen. Zum Glück sind Profis ähnlich, nur mit Beratern.',
    'ex_referee' => 'Du hast tausend Spiele gepfiffen und dir dabei tausend Beleidigungen gemerkt. Du kennst jede Regel auswendig. Die Spieler kennen dich auch.',
    'tactics_streamer' => 'Nächte vor dem Bildschirm, 400 Zuschauer, die dich lieben, und eine Taktiktafel in jedem Zimmer. Du weißt alles über Fußball, außer wie es sich anfühlt, wenn man dabei friert.',
    'motivation_guru' => 'Du hast Bücher geschrieben, Seminare gegeben und Menschen über Glasscherben laufen lassen. Ein Fußballplatz ist ähnlich, nur mit mehr Rasen und weniger Räucherstäbchen.',
    _ => id,
  };
  @override
  String officeSeason(int startYear) =>
      'Saison $startYear/${((startYear + 1) % 100).toString().padLeft(2, '0')}';
  @override
  String get officeToMenu => 'Hauptmenü';
  @override
  String get officeGo => 'Zum Spieltag';
  @override
  String get officeNextTitle => 'Nächstes Spiel';
  @override
  String officeMatchday(int day) => 'Spieltag $day';
  @override
  String get officeHome => 'Heimspiel';
  @override
  String get officeAway => 'Auswärtsspiel';
  @override
  String officeStrengthCompare(String mine, String theirs) =>
      'Stärke $mine gegen $theirs';
  @override
  String get officeTableTitle => 'Tabelle';
  @override
  String get officeTableEmpty =>
      'Noch nichts gespielt. Alle sind Erster, und alle sind es gern.';
  @override
  String officeTableForecast(int rank, int count) =>
      'Nach Stärke: Platz $rank von $count';
  @override
  String get officeCashTitle => 'Kasse';
  @override
  String officeSquad(int count) => 'Kader: $count Spieler';
  @override
  String get officeMailTitle => 'Postfach';
  @override
  String get officeMailPick => 'Such dir eine Nachricht aus.';
  @override
  String get officeSenderPresident => 'Präsident';
  @override
  String get officeSenderAdvisor => 'Berater';
  @override
  String get officeSenderNews => 'Earth News';
  @override
  String officeMailSubjectPresident(String club) => 'Willkommen bei $club!';
  @override
  String officeMailBodyPresident(String typeId, String name) => switch (typeId) {
    'construction_tycoon' =>
      'Willkommen, $name! Ich baue gerade ein Stadion für 80.000 Zuschauer, auch wenn wir im Schnitt 212 haben. Man muss groß denken, der Rest kommt von selbst. Bitte nicht am Fundament rütteln.',
    'thrifty_butcher' =>
      'Hallo $name, schön, dass Sie da sind. Das Budget liegt im Kühlfach, bitte nur im Notfall öffnen. Das Mittagessen in der Kantine ist ein Wurstbrot, selbstverständlich auf eigene Rechnung.',
    'car_dealer' =>
      '$name, Sie sind der Richtige! Ich habe ein Auge für Talente wie für Gebrauchtwagen: viel Politur, wenig Kilometer. Falls Sie ein Auto brauchen, ich hätte da was. Sofort verfügbar, Vorbesitzer unbekannt.',
    'savings_bank_director' =>
      'Guten Tag, $name. Wir freuen uns auf eine solide, risikoarme Zusammenarbeit. Spektakuläre Transfers prüfen wir gern. Im Ausschuss. Im Frühjahr.',
    'ex_pro' =>
      'Moin $name! Früher, als ich noch gespielt habe, gab es so etwas nicht. Ich schaue mal in der Kabine vorbei, nur zum Zuhören, versprochen. Zur Aufstellung sage ich dann nur ein paar Sätze. Oder zehn.',
    'rich_heir' =>
      'Hi $name, mega, dass es geklappt hat! Papa meint, der Verein ist gut für die Steuer, ich finde ihn auch ganz nett. Mach einfach, ich muss gleich zum Segeln.',
    'patron' =>
      'Verehrte(r) $name, es ist mir eine Freude. Ich unterstütze den Verein aus reiner Güte und erwarte dafür nur Dankbarkeit, Respekt und einen Stehplatz mit meinem Namen darauf.',
    'club_fixture' =>
      'Servus $name, ich bin seit 41 Jahren hier und habe jeden Trainer kommen und gehen sehen. Nur der Platzwart ist geblieben. Frag ihn, wenn du etwas wissen willst, und frag mich, wenn du etwas willst.',
    _ => 'Willkommen, $name! Möge die Saison kurz und der Gewinn lang sein.',
  };
  @override
  String get officeMailSubjectAdvisor => 'Kurzer Lagebericht';
  @override
  String officeMailBodyAdvisor({
    required String goal,
    required String budget,
    required int squad,
    required String opponent,
    required bool home,
  }) =>
      'Saisonziel: $goal. Transferbudget: $budget. Kader: $squad Spieler. '
      '${home ? 'Das erste Spiel ist zu Hause' : 'Das erste Spiel ist auswärts'}, Gegner: $opponent. '
      'Alles Weitere in den nächsten Wochen.';
  @override
  String officeMailSubjectNews(Situation situation) => switch (situation) {
    Situation.favourite => 'Jetzt oder nie: Neuer Trainer unter Druck',
    Situation.midTable => 'Dienst nach Vorschrift: Neuer Trainer im Mittelfeld',
    Situation.relegation => 'Feuerwehr gerufen, Streichhölzer geliefert',
    Situation.bankrupt => 'Kapitän der Titanic: Neuer Trainer an Bord',
  };
  @override
  String officeMailBodyNews({
    required String name,
    required String club,
    required String backstory,
    required String hook,
  }) =>
      '$name übernimmt $club. Der neue Mann ist, so heißt es: $backstory. $hook '
      'Wir beobachten das mit Interesse und einem Notizblock.';
  @override
  String get infoOfficeNext =>
      'Dein nächster Gegner und wo gespielt wird. Heimspiel heißt: Die eigenen Fans pöbeln mit dir. Auswärts pöbeln die anderen.';
  @override
  String get infoOfficeTable =>
      'Die Tabelle deiner Liga. Vor dem ersten Spiel steht noch nichts darin, deshalb zeigen wir, wo dich dein Kader der Stärke nach einordnet. Das ist eine Schätzung, kein Versprechen.';
  @override
  String get infoOfficeMail =>
      'Dein Posteingang. Hier melden sich Präsident, Berater und Presse, manchmal hilfreich, meist nicht. Ungelesenes bleibt gelb markiert.';
  @override
  String get infoStrength =>
      'Der Durchschnitt der 14 besten Spieler eines Vereins, grob gesagt: wie gut die Mannschaft auf dem Papier ist. Aufs Papier schießt aber keiner Tore.';
  @override
  String get helpSettingTitle => 'Hilfen';
  @override
  String get helpSettingText =>
      'Zeigt die kleinen gelben „i“ mit Erklärungen. Für alte Hasen abschaltbar.';
  @override
  String get infoWish =>
      'Dein Ansehen entscheidet, welche Ligen sich melden. Dein Traumverein ruft nur an, wenn du es dir verdient hast. Sonst sagen wir dir ehrlich, was fehlt.';
  @override
  String get infoSituation =>
      'Wie es dem Verein gerade geht. Das entscheidet über Ziel und Budget. „Pleite“ ist die Königsklasse der Probleme.';
  @override
  String get infoGoal =>
      'Was der Präsident von dir erwartet. Wer es verfehlt, lernt den Präsidenten besser kennen.';
  @override
  String get infoBudget =>
      'Dein Geld für Transfers. Der Rest des Vereins ist meist schon ausgegeben.';
  @override
  String get infoLastSeason =>
      'Platz in der Abschlusstabelle der letzten Saison. Verrät, ob du ein Erbe oder eine Baustelle übernimmst.';
  @override
  String get infoSquad =>
      'Stärke ist der Schnitt der 14 besten Spieler, dazu der Platz in der Liga nach Stärke. Zahlen lügen nicht. Trainer schon.';
  @override
  String get infoPresident =>
      'Dein Chef. Typ und Eigenschaften verraten, wie er tickt: geduldig oder ungeduldig, großzügig oder geizig, einmischend oder gelassen.';
  @override
  String get infoQuirk =>
      'Jeder Verein hat seine Eigenheit. Manche sind ein Geschenk, die meisten eine Prüfung.';
  @override
  String infoQuirkKind(ClubQuirk quirk) => switch (quirk) {
    ClubQuirk.none => 'Keine Besonderheit. Fast schon verdächtig.',
    ClubQuirk.debtMountain => 'Der Verein hat mehr Schulden als Spieler Beine. Das Geld ist knapp, die Gläubiger sind geduldig. Noch.',
    ClubQuirk.talentFactory => 'Aus der Jugend kommen laufend Talente. Du musst sie nur spielen lassen und den Verkaufsdrang des Präsidenten bremsen.',
    ClubQuirk.feudingSquad => 'In der Kabine fliegen mehr als Sprüche. Die Stimmung ist von Anfang an im Keller, da hilft nur Charisma.',
    ClubQuirk.loyalFans => 'Die Fans stehen hinter dir, auch wenn du es nicht verdient hast. Wie lange, hängt von den Ergebnissen ab.',
    ClubQuirk.crumblingStadium => 'Beim Heimspiel fällt gelegentlich ein Stück Tribüne ab. Das drückt Stimmung und Einnahmen, und die Reparatur kostet.',
  };
  @override
  String get offerSituation => 'Lage';
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
