import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/desk.dart';
import '../game/lineup.dart';
import '../game/squad.dart';
import '../game/stats.dart';
import '../game/ticker.dart';
import 'reporter_strings.dart';

/// All texts of the user interface. A screen asks this interface and never
/// holds a literal; another language is one more implementation.
abstract interface class AppStrings {
  String get languageName;
  String get appTitle;
  String get tagline;
  String get menuNewGame;
  String get menuLoadGame;
  String get menuContinue;
  String get menuSettings;
  String get menuQuit;
  String get back;
  String get settingsTitle;
  String get settingsLanguage;
  String get settingsShortcuts;
  String get settingsTicker;
  String get settingsTickerText;
  String get settingsVibration;
  String get settingsVibrationText;
  String get settingsSound;
  String get settingsSoundText;
  String get settingsAbout;
  String get settingsAboutText;
  String get settingsGeneral;
  String get settingsMatch;
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
  String get officeMenuLabel;
  String get officeGo;
  String get officeNextTitle;
  String officeMatchday(int day);

  // Match day: preview, live ticker, report.
  String get matchKickOff;
  String get matchPreviewStrength;

  // Ground, crowd and weather (steps 10e4 and 10e5).
  String get matchPreviewConditions;
  String weatherName(String kind);
  String groundName(String state);
  String matchPreviewVenue(String? stadium, int capacity);
  String matchPreviewWeather(String weather, String ground);
  String jourFixForecast(String weather);
  String matchPreviewLineup(String formation, String system);
  String get matchPreviewAbsent;
  String matchAbsence(Absence reason);
  String get matchSheetReplaced;
  String get matchNoAbsent;
  String get infoMatchPreview;
  String get matchSpeedSlow;
  String get matchSpeedNormal;
  String get matchSpeedFast;
  String get matchPause;
  String get matchResume;
  String get matchSkip;
  String get matchSubs;
  String get matchTactics;
  String get matchToReport;
  String get matchLeaveBlocked;
  String get matchFinal;
  String get matchPaused;
  String matchSubsLeft(int n);
  String get matchSubNoWindow;
  String matchSubsAndWindows(int subs, int windows, {required bool breakNow});
  String get matchSubPickOff;
  String get matchSubPickOn;
  String matchSubStats(int energy, int form);
  String get matchSubFits;
  String get matchSubNone;
  String get matchSubBenchEmpty;
  String get matchSubKeeperOnly;
  String get infoMatchSpeed;
  String get matchViewOwn;
  String get matchViewConference;
  String get confNotStarted;
  String confRunning(String minute);
  String get confFinished;
  String get confTable;
  String get confPlayedShort;
  String get confPointsShort;
  String get confNoLeagues;
  String weekdayShort(int weekday);
  String get infoConference;
  String get infoNextDay;
  String monthName(int month);
  String get calLegendMatch;
  String get calModeMonth;
  String get calModeWeek;
  String get calLegendTitle;
  String get calDayEmpty;
  String get calLegendLeague;
  String get calLegendCup;
  String get calLegendHoliday;
  String get calLegendBreak;
  String get calLegendRest;
  String get calToday;
  String get infoCalendarMonth;
  String get infoMatchSubs;
  String get infoMatchTactics;
  String get matchClose;
  String get matchReportTitle;
  String get matchReportGoals;
  String get matchReportNoGoals;
  String get matchReportCards;
  String get matchReportInjuries;
  String get matchReportStats;
  String get matchReportToTable;
  String get matchReportToOffice;
  String matchReportVerdict(int mine, int theirs);
  String matchStatName(String id);
  String matchCardLine(TickerKind kind);
  String matchInjuryLine(int days);
  String get infoMatchReport;
  List<String> tickerTemplates(TickerKind kind);

  /// The texts of the radio reporter (step 10d2).
  ReporterStrings get reporter;

  /// Short sentence before a shot that tells the build-up ({q} is the last
  /// player on the ball), by action id of the rules; empty for none.
  String tickerLead(String action);
  String get officeHome;
  String get officeAway;
  String officeStrengthCompare(String mine, String theirs);
  String get officeCashTitle;
  String officeSquad(int count);
  String get officeMailTitle;
  String get officeMailPick;
  String get postFilterCurrent;
  String get postFilterUnread;
  String get postFilterArchive;
  String get postMarkAllRead;
  String get postEmpty;
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

  // --- desk scene (document "Büro als Schreibtisch-Szene") ---
  String deskName(DeskItem item);
  String deskShort(DeskItem item);
  String deskHint(DeskItem item);
  String deskKey(int digit);
  String get deskKeyDoor;
  String deskNext(int matchday);
  String deskNextCup(String cup);
  String get deskBadgeTactics;
  String deskBadgePost(int unread);
  String get infoDesk;
  String get comingLater;
  String jourFixSubject(int matchday);
  String jourFixBody({
    required int unread,
    required int matchday,
    required String opponent,
    required bool home,
  });
  String get jourFixToPost;
  String get jourFixToTactics;
  String get jourFixToCalendar;

  // --- squad and player profile (document 08) ---
  String get squadCount0;
  String squadCount(int n);
  String squadFilterName(SquadFilter filter);
  String squadFilterButton(String name);
  String get squadFilterTitle;
  String squadAgeShort(int age);
  String squadContractUntil(int year);
  String get squadNoContract;
  String squadSortName(SquadSort sort);
  String get squadEmpty;
  String get squadColName;
  String get squadColPos;
  String get squadColStrength;
  String get squadColAge;
  String get squadColContract;
  String get infoSquadList;
  String get infoSquadStrength;
  String get infoSquadPos;
  String get infoSquadContract;
  String get infoSquadSort;
  String profileTab(int index);
  String get profileBack;
  String profileAgeNation(int age, String nation);
  String get profileOverall;
  String get profileMainRole;
  String get profileNoRole;
  String get profileAbilities;
  String get profileNoAbilities;
  String get profileContract;
  String profileContractUntil(String date);
  String profileSalary(String perYear);
  String get profileNoContract;
  String get profileForm;
  String get profileFormNone;
  String get infoProfileOverall;
  String get infoProfileRole;
  String get infoProfileAbilities;
  String get infoProfileForm;
  String get valuesHint;
  String get infoValues;
  String get infoValuesBar;
  String attributeGroupName(AttributeGroup group);
  String attributeName(Attribute attribute);
  String get rolesPositions;
  String get rolesMainPosition;
  String get rolesSecondaryNone;
  String positionFamiliarityName(PositionFamiliarity f);
  String get rolesFoot;
  String get rolesWeakFoot;
  String footName(Foot foot);
  String get rolesList;
  String get rolesBackThree;
  String roleSideHint(bool fits);
  String get infoRoles;
  String get infoRolesSymbols;
  String get infoPositions;
  String get headTraits;
  String get headInjury;
  String get headPotential;
  String get headDevelopment;
  String get headCircumstances;
  String get headCircumstancesText;
  String get infoTraits;
  String get infoPotential;
  String get infoDevelopment;
  String get infoCircumstances;
  String traitName(CharacterTrait trait);
  String traitLevelName(int level);
  String developmentTypeName(DevelopmentType type);
  String get careerNoSeason;
  String careerSince(String date);
  String get infoCareer;
  String positionName(Position position);
  String abilityName(SpecialAbilityType type);
  String abilityInfo(SpecialAbilityType type);
  String abilityTierName(AbilityTier tier);
  String roleName(String id);
  String roleFamiliaritySymbol(RoleFamiliarity f);
  String roleFamiliarityName(RoleFamiliarity f);
  String nationName(String code);

  // --- line-up (Bauabschnitt 5) ---
  String get lineupTabTactics;
  String get lineupTabSquad;
  String get lineupFormation;
  String get infoLineupFormation;
  String get lineupSystem;
  String get infoLineupSystem;
  String systemName(String id);
  String systemHint(String id);
  String get lineupSliders;
  String get infoLineupSliders;
  String get lineupCaptain;
  String get infoLineupCaptain;
  String get lineupCaptainAuto;
  String lineupCaptainAutoIs(String name);
  String sliderName(String id);
  String sliderLevelName(String id, int level);
  String get lineupPreview;
  String get infoLineupPreview;
  String get lineupStrength;
  String get lineupRoleFit;
  String get lineupSystemFit;
  String lineupSystemFitName(double fit);
  String lineupOutOfPosition(int n);
  String get lineupAuto;
  String get lineupConfirm;
  String get lineupConfirmed;
  String get lineupHint;
  String get infoLineupPitch;
  String get lineupStartXi;
  String get lineupBench;
  String get lineupStand;
  String lineupBenchFull(int places);
  String lineupAbsentBlocked(String reason);
  String get lineupSwapKeeper;
  String get lineupPickerFit;
  String get lineupPickerAll;
  String get lineupPickerHere;
  String get lineupBenchDone;
  String lineupPickerPlaysOn(String position);
  String get settingsAutoLineup;
  String get settingsAutoLineupText;
  String get lineupBenchTitle;
  String get lineupBenchEmpty;
  String get lineupBenchRemove;
  String lineupAbsentWarning(int n);
  String get lineupGoToLineup;
  String lineupAbsentInSheet(String names);
  String lineupAutoChanged(String names);
  String lineupBenchCount(int n, int places);
  String get lineupNoBenchKeeper;
  String get lineupSlotRole;
  String get infoLineupSlot;
  String get lineupNoRole;
  String lineupRolePercent(int percent);
  String lineupOutOfPositionHint(String own, String slot, int percent);
  String get lineupNoSheet;
  String lineupProblemText(LineupProblem problem);
  String get lineupPickSlotFirst;

  // --- statistics ---
  String get statsTabTables;
  String get statsTabCups;
  String get statsTabScorers;
  String get infoStatsPage;
  String get statsColPlace;
  String get statsColClub;
  String get statsColPlayed;
  String get statsColWon;
  String get statsColDrawn;
  String get statsColLost;
  String get statsColGoals;
  String get statsColDiff;
  String get statsColPoints;
  String get infoStatsColumns;
  String get statsForecastNote;
  String get statsOwnLeague;
  String statsZoneName(TableZone zone);
  String get infoStatsZones;
  String get statsCupBolzplatz;
  String get statsCupPott;
  String get infoStatsCupBolzplatz;
  String get infoStatsCupPott;
  String statsCupRoundName(int clubs);
  String statsCupAfterMatchday(int day);
  String get statsCupNotDrawn;
  String statsCupWinner(String club);
  String get statsCupNoWinner;
  String regionName(Region region);
  String get statsGoals;
  String get statsAssists;
  String get infoStatsScorers;
  String get statsScorersEmpty;
  String get statsAssistsEmpty;
  String seasonLabel(int startYear);
  String seasonEndSubject(int startYear, bool dismissed);
  String seasonEndBody({
    required int startYear,
    required String league,
    required int rank,
    required int teams,
    required String champion,
    required String? cupWinner,
    required int levelChange,
    required String? nextLeague,
    required GoalVerdict verdict,
    required int gap,
    required SeasonGoal goal,
    required bool dismissed,
  });
  String get deskNextSeason;
  String seasonStarted(int startYear, String league, String goal);
  String get dismissTitle;
  String dismissBody(String club, int startYear, int rank, int teams);
  String get dismissSearch;
  String get dismissMenu;
  String get infoDismiss;
  String get calLegendVacation;
  String get calLegendAppointment;
  String get vacTitle;
  String vacCounter(int total, int minTotal, int block, int minBlock);
  String vacStatus(VacationLevel level, bool blockKept, int minBlock);
  String get vacEdit;
  String get vacModeDays;
  String get vacModeRange;
  String get vacRangeHint;
  String get vacSuggest;
  String get vacClear;
  String get infoVacation;
  String get apptTitle;
  String get apptNone;
  String apptName(AppointmentKind kind, int variant);
  String get infoAppointments;
  String apptMailSubject(AppointmentKind kind, int variant, int number);
  String apptMailBody(
    AppointmentKind kind,
    int variant, {
    required String manager,
    required String goal,
    required String club,
  });
  String jourFixReview({
    required String opponent,
    required bool home,
    required int goalsFor,
    required int goalsAgainst,
    required int seed,
    String? cup,
    bool? wentThrough,
  });
  String get jourFixNoMatch;
  String jourFixTable(int place, int teams);
  String jourFixAbsent(int count);
  String jourFixNext(int matchday, String opponent, bool home);
  String jourFixAppointments(String list);
  String jourFixVacation(int total, int minTotal);
  String vacVerdictSubject(bool kept);
  String vacVerdictBody(int total, int minTotal, int block, int minBlock);
  String get jourFixGreeting;
  String get jourFixSign;
  String cupName(Competition competition);

  // Sports court after a red card (step 10e3).
  String get courtSender;
  String get courtAccept;
  String get courtAppeal;
  String courtSubject(String player, CourtStatus status);
  String courtBody({
    required String player,
    required String kind,
    required String? competition,
    required int motion,
    required bool weeks,
    required CourtStatus status,
    int? verdict,
  });
  String cupRoundName(bool isFinal, int round);
  String matchShootoutLine(String winner, int home, int away);
  String get confCupTab;
  String get confTabLive;
  String get confTabResults;
  String get confTabTable;
  String get confNoLive;
  String get confNoResults;
  String get confGoalsShort;
  String get confDiffShort;
  String confKickoffAt(String time);
  String get matchReportExtraTime;
  String matchReportShootout(int home, int away);
  String get matchReportThrough;
  String get matchReportOut;
  String get savesTitle;
  String get savesAuto;
  String savesSlot(String slot);
  String get savesEmpty;
  String get savesUnreadable;
  String savesLine1(String trainer, String club);
  String savesLiveHint(int minute);
  String savesLine2(String league, String date, int matchday, int matchdays);
  String savesSavedAt(String stamp);
  String get savesSave;
  String get savesLoad;
  String get savesDelete;
  String get savesCancel;
  String get savesOverwriteTitle;
  String get savesOverwriteText;
  String get savesDeleteTitle;
  String get savesDeleteText;
  String get savesDone;
  String get savesLoadFailed;
  String get savesLoading;
  String get savesSettings;
  String get savesNothingToLoad;
  String get infoSaves;
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
  String get menuContinue => 'Weiterspielen';
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
  String get settingsTicker => 'Ticker-Tempo';
  @override
  String get settingsTickerText =>
      'So schnell läuft der Ticker beim Anpfiff los. Im Spiel kannst du es jederzeit ändern.';
  @override
  String get settingsVibration => 'Vibration bei Toren';
  @override
  String get settingsVibrationText =>
      'Dein Handy brummt, wenn deine Mannschaft trifft. Im iPhone-Browser geht das leider nicht, erst in der richtigen App.';
  @override
  String get settingsSound => 'Ton';
  @override
  String get settingsSoundText =>
      'Pfiffe und Jubel. Gibt es noch nicht, der Schalter hält die Stelle warm.';
  @override
  String get settingsAbout => 'Über das Spiel';
  @override
  String get settingsAboutText =>
      'Bolzplatz AG. Tipp: In Safari auf „Teilen“ und dann „Zum Home-Bildschirm“, dann startet das Spiel wie eine App.';
  @override
  String get settingsGeneral => 'Allgemein';
  @override
  String get settingsMatch => 'Spiel';
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
  String get officeMenuLabel => 'Menü';
  @override
  String get officeGo => 'Zum Spieltag';
  @override
  String get officeNextTitle => 'Nächstes Spiel';
  @override
  String officeMatchday(int day) => 'Spieltag $day';
  @override
  String get matchKickOff => 'Anpfiff';
  @override
  String get matchPreviewStrength => 'Mannschaftsstärke';
  @override
  String get matchPreviewConditions => 'Stadion und Wetter';
  @override
  String weatherName(String kind) => switch (kind) {
    'sunny' => 'sonnig',
    'cloudy' => 'bewölkt',
    'rain' => 'Regen',
    'heavy_rain' => 'Starkregen',
    'snow' => 'Schnee',
    'heat' => 'Hitze',
    'wind' => 'stürmisch',
    _ => kind,
  };
  @override
  String groundName(String state) => switch (state) {
    'good' => 'gut',
    'wet' => 'nass',
    'heavy' => 'tief (Acker)',
    'frozen' => 'gefroren',
    _ => state,
  };
  @override
  String matchPreviewVenue(String? stadium, int capacity) => stadium == null
      ? 'Neutraler Platz, $capacity Plätze'
      : '$stadium, $capacity Plätze';
  @override
  String matchPreviewWeather(String weather, String ground) =>
      'Wetter: ${weatherName(weather)} · Platz: ${groundName(ground)}';
  @override
  String jourFixForecast(String weather) =>
      'Der Wetterbericht für das Spiel sagt: ${weatherName(weather)}. '
      'Meteorologen haben übrigens eine ähnliche Trefferquote wie unser Sturm.';
  @override
  String matchPreviewLineup(String formation, String system) =>
      'Deine Elf: $formation · $system';
  @override
  String get matchPreviewAbsent => 'Fehlen bei dir';
  @override
  String matchAbsence(Absence reason) => switch (reason) {
    Absence.injured => 'verletzt',
    Absence.suspended => 'gesperrt',
  };
  @override
  String get matchSheetReplaced =>
      'In deiner Aufstellung stand jemand, der heute ausfällt. Dein '
      'Assistent hat für dieses Spiel neu aufgestellt – er war ohnehin '
      'schon beleidigt, dass du ihn nicht gefragt hast.';
  @override
  String get matchNoAbsent => 'Alle fit und nur leicht mürrisch.';
  @override
  String get infoMatchPreview =>
      'Vor dem Anpfiff siehst du, gegen wen es geht, wie stark beide '
      'Mannschaften im Schnitt sind und wer bei dir fehlt. Die Stärke ist '
      'der Mittelwert der 14 besten Spieler. Sie sagt nicht, wer gewinnt – '
      'sonst müsste man ja nicht spielen.';
  @override
  String get matchSpeedSlow => 'Langsam';
  @override
  String get matchSpeedNormal => 'Mittel';
  @override
  String get matchSpeedFast => 'Schnell';
  @override
  String get matchPause => 'Pause';
  @override
  String get matchResume => 'Weiter';
  @override
  String get matchSkip => 'Bis zum Ende';
  @override
  String get matchSubs => 'Wechsel';
  @override
  String get matchTactics => 'Taktik';
  @override
  String get matchToReport => 'Zum Spielbericht';
  @override
  String get matchLeaveBlocked =>
      'Mitten im Spiel gehst du nicht. Das haben schon andere Trainer '
      'versucht, es endete in einer Geldstrafe.';
  @override
  String get matchFinal => 'Endstand';
  @override
  String get matchPaused => 'Unterbrechung';
  @override
  String matchSubsLeft(int n) => n == 1 ? 'Noch 1 Wechsel' : 'Noch $n Wechsel';
  @override
  String get matchSubNoWindow =>
      'Alle drei Wechselfenster sind verbraucht. Regel ist Regel, auch für '
      'dich. Erst in der Pause oder vor der Verlängerung geht wieder was.';
  @override
  String matchSubsAndWindows(int subs, int windows, {required bool breakNow}) {
    final changes = matchSubsLeft(subs);
    if (breakNow) return '$changes · Pause, kostet kein Fenster';
    return windows == 1
        ? '$changes · 1 Fenster'
        : '$changes · $windows Fenster';
  }
  @override
  String get matchSubPickOff => 'Wer geht raus?';
  @override
  String get matchSubPickOn => 'Wer kommt rein?';

  @override
  String matchSubStats(int energy, int form) => 'Kraft $energy % · Form $form';

  @override
  String get matchSubFits => 'passt';
  @override
  String get matchSubNone => 'Du hast alle Wechsel verbraucht.';
  @override
  String get matchSubBenchEmpty => 'Die Bank ist leer. Das nennt man Mut.';
  @override
  String get matchSubKeeperOnly =>
      'Ein Torwart darf nur für einen Torwart, ein Feldspieler nur für '
      'einen Feldspieler. So steht es geschrieben.';
  @override
  String get matchViewOwn => 'Mein Spiel';
  @override
  String get matchViewConference => 'Konferenz';
  @override
  String get confNotStarted => 'noch nicht angepfiffen';
  @override
  String confRunning(String minute) => 'läuft · $minute\'';
  @override
  String get confFinished => 'abgepfiffen';
  @override
  String get confTable => 'Live-Tabelle';
  @override
  String get confPlayedShort => 'Sp';
  @override
  String get confPointsShort => 'Pkt';
  @override
  String get confNoLeagues => 'Heute spielt keine Liga. Ungewohnte Ruhe.';
  @override
  String weekdayShort(int weekday) =>
      const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][weekday - 1];
  @override
  String get infoConference =>
      'Alle Spiele, die zur gleichen Zeit angepfiffen werden, laufen '
      'gemeinsam. Hier siehst du ihren Stand, wie in der Radio-Konferenz. '
      'Die Tabelle rechnet jeden Zwischenstand sofort mit. Reiter gibt es '
      'nur für Ligen, die heute spielen, deine zuerst.';
  @override
  String get infoNextDay =>
      'Lässt die Uhr laufen, bis etwas passiert: dein nächstes Spiel '
      '(Liga oder Pokal) oder eine Entscheidung, die du treffen musst. Freie '
      'Tage und die Spiele der anderen Ligen laufen dabei im Hintergrund '
      'mit. Das Datum auf dem Tischkalender läuft mit.';
  @override
  String monthName(int month) => const [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ][month - 1];
  @override
  String get calLegendMatch => 'Dein Spiel';

  @override
  String get calModeMonth => 'Monat';

  @override
  String get calModeWeek => 'Woche';

  @override
  String get calLegendTitle => 'Legende';

  @override
  String get calDayEmpty => 'Nichts los. Ungewohnt ruhig.';

  @override
  String get calLegendLeague => 'Liga-Spieltag';
  @override
  String get calLegendCup => 'Pokal';
  @override
  String get calLegendHoliday => 'Feiertag';
  @override
  String get calLegendBreak => 'Länderspielpause';
  @override
  String get calLegendRest => 'Sommer- und Winterpause';
  @override
  String get calToday => 'Heute';
  @override
  String get infoCalendarMonth =>
      'Der Monat auf einen Blick: Dein Spiel, die Spieltage der Ligen, '
      'Pokalrunden, Feiertage, Länderspielpausen und die Zeiten, in denen '
      'die Spieler Urlaub haben müssen (30 Werktage pro Spieljahr, einmal '
      '12 am Stück). An Feiertagen wird bis auf wenige Ausnahmen trotzdem '
      'gespielt. Karfreitag, Totensonntag, Volkstrauertag, der 24. und '
      '25.12. sind spielfrei.';
  @override
  String get infoMatchSpeed =>
      'Wie schnell die Minuten vergehen. Bei Verletzung, Rot und zur '
      'Halbzeit hält das Spiel von selbst an, damit du reagieren kannst. '
      '"Bis zum Ende" spielt den Rest sofort, ohne dass du noch eingreifst.';
  @override
  String get infoMatchSubs =>
      'Fünf Wechsel pro Spiel, aber nur in drei Unterbrechungen. Mehrere '
      'Wechsel auf einmal kosten ein Fenster, die Halbzeit kostet keins. In '
      'der Verlängerung gibt es einen Wechsel und ein Fenster obendrauf. Wer '
      'rausgeht, kommt nicht wieder. Wer verletzt rausmuss, wird vom '
      'Assistenten ersetzt und zählt als Wechsel mit, sofern noch ein '
      'Fenster frei ist.';
  @override
  String get infoMatchTactics =>
      'System und Regler kannst du im Spiel ändern. In den ersten Minuten '
      'und in der Halbzeit kostet das nichts. Zu anderer Zeit wird die '
      'Mannschaft unruhig, weil sie nicht weiß, wem sie glauben soll.';
  @override
  String get matchClose => 'Schließen';
  @override
  String get matchReportTitle => 'Spielbericht';
  @override
  String get matchReportGoals => 'Tore';
  @override
  String get matchReportNoGoals =>
      'Keine Tore. Das Publikum fordert sein Eintrittsgeld zurück.';
  @override
  String get matchReportCards => 'Karten';
  @override
  String get matchReportInjuries => 'Verletzungen';
  @override
  String get matchReportStats => 'Zahlen zum Spiel';
  @override
  String get matchReportToTable => 'Zur Tabelle';
  @override
  String get matchReportToOffice => 'Zurück ins Büro';
  @override
  String matchReportVerdict(int mine, int theirs) {
    if (mine > theirs) {
      return mine - theirs >= 3
          ? 'Ein Fest. Der Präsident lächelt, und das ist selten.'
          : 'Gewonnen. Wir tun so, als wäre das geplant gewesen.';
    }
    if (mine < theirs) {
      return theirs - mine >= 3
          ? 'Das war keine Niederlage, das war ein Naturereignis.'
          : 'Verloren. Wir nennen es "Lehrgeld" und schicken die Rechnung '
                'an den Schiedsrichter.';
    }
    return mine == 0
        ? 'Nullnull. Wenigstens hat sich niemand verletzt, außer dem Spiel.'
        : 'Unentschieden. Die Diplomatie hat gesiegt.';
  }

  @override
  String matchStatName(String id) => switch (id) {
    'shots' => 'Schüsse',
    'shotsOnTarget' => 'Aufs Tor',
    'corners' => 'Ecken',
    'freeKicks' => 'Freistöße',
    'yellow' => 'Gelbe Karten',
    'red' => 'Rote Karten',
    'subs' => 'Wechsel',
    _ => id,
  };
  @override
  String matchCardLine(TickerKind kind) => switch (kind) {
    TickerKind.yellow => 'Gelb',
    TickerKind.secondYellow => 'Gelb-Rot',
    _ => 'Rot',
  };
  @override
  String matchInjuryLine(int days) =>
      days == 1 ? 'fällt 1 Tag aus' : 'fällt $days Tage aus';
  @override
  String get infoMatchReport =>
      'Hier steht, was passiert ist, auch wenn du es live gesehen hast. '
      'Verletzte und Gesperrte fehlen im nächsten Spiel und stehen im '
      'Kader und in der Aufstellung markiert.';
  @override
  ReporterStrings get reporter => const ReporterStringsDe();
  @override
  List<String> tickerTemplates(TickerKind kind) => switch (kind) {
    TickerKind.kickOff => const [
      'Anpfiff! {home} gegen {away}. Möge der Bessere gewinnen – oder '
          'wenigstens der Lautere.',
      'Der Ball rollt: {home} gegen {away}. Alle tun so, als hätten sie '
          'einen Plan.',
      'Los geht\'s zwischen {home} und {away}. Die Nervosität auf der Bank '
          'ist kostenlos.',
      'Der Schiedsrichter pfeift an. {home} gegen {away}, Hoffnung gegen '
          'Wirklichkeit.',
    ],
    TickerKind.goal => const [
      'TOR für {team}! Es steht {score}.',
      'Drin! {team} jubelt, {score}.',
      'Einschlag! Das Netz zappelt, {team} trifft zum {score}.',
      'TOOOR! {team} macht das Ding, {score}.',
      'Und der ist drin! {team} lässt das Stadion beben, {score}.',
      'Tor für {team}. Der Torwart guckt dem Ball hinterher wie einem '
          'abfahrenden Zug. {score}.',
    ],
    TickerKind.goalAssist => const [
      'TOR für {team}! Es steht {score}.',
      'Drin! Schön herausgespielt von {team}, {score}.',
      'TOOOR! {team} kombiniert sich durch, {score}.',
      'Einschlag! Das war Teamwork bei {team}, {score}.',
      'Tor für {team}, und zwar eins zum Einrahmen. {score}.',
      'Der sitzt! {team} jubelt, {score}.',
    ],
    TickerKind.scorer => const [
      'Torschütze: {p}.',
      'Torschütze: {p}. Er wird es heute Abend noch dreimal erzählen.',
      'Torschütze: {p}. Kurzer Jubel, langer Instagram-Post.',
      'Torschütze: {p}. Hat er so trainiert, behauptet er hinterher.',
      'Torschütze: {p}. Das Trikot fliegt fast, die Gelbe gerade noch nicht.',
    ],
    TickerKind.assist => const [
      'Vorlage: {q}.',
      'Vorlage: {q}. Der eigentliche Künstler, wie immer unterbezahlt.',
      'Vorlage: {q}. Ohne ihn wäre das nur ein Gerücht gewesen.',
      'Vorlage: {q}. Bekommt einen Klaps und keine Schlagzeile.',
    ],
    TickerKind.penalty => const [
      'Elfmeter für {team}! Der Schiedsrichter zeigt auf den Punkt.',
      'Strafstoß für {team}. Jetzt wird es still im Stadion.',
      'Der Unparteiische entscheidet auf Elfmeter für {team}. Proteste '
          'zwecklos.',
      'Elfmeter! Wer traut sich bei {team}?',
    ],
    TickerKind.parade => const [
      'Parade! Der Torwart rettet gegen {p}.',
      '{p} schießt, aber der Keeper ist da. Ärgerlich für {team}.',
      'Glanztat des Torwarts gegen {p}. Der Ball bleibt draußen.',
      'Der Torwart lenkt den Schuss von {p} zur Seite. {team} hadert.',
    ],
    TickerKind.miss => const [
      '{p} hat die Chance, aber der Ball findet das Tor nicht.',
      'Vorbei! {p} zielt, trifft aber nur die Landschaft.',
      '{p} vergibt für {team}. Die Bank hält sich den Kopf.',
      'Das war eine Chance für {team}: {p} schießt knapp daneben.',
      '{p} jagt den Ball über die Latte. Reihe 27 sagt danke.',
      'Riesenchance für {p}! Und daneben. Der Rasen war schuld, sagt er.',
    ],
    TickerKind.blocked => const [
      '{p} zieht ab, aber ein Bein von {opp} ist im Weg.',
      'Schuss von {p}, geblockt. Da hat sich einer todesmutig reingeworfen.',
      '{p} probiert es, die Abwehr von {opp} stellt sich in den Weg.',
      'Abgefälscht! Der Versuch von {p} landet im Nirgendwo.',
    ],
    TickerKind.halfChance => const [
      '{p} versucht es mal. Harmlos.',
      'Halbe Chance für {team}: {p} schießt, der Torwart gähnt.',
      '{p} mit einem Versuch, der eher eine Frage war als eine Antwort.',
      'Abschluss {p}. Gut gemeint, schlecht getroffen.',
      '{p} probiert es aus der zweiten Reihe. Die zweite Reihe bleibt '
          'ungefährlich.',
    ],
    TickerKind.corner => const [
      'Ecke für {team}. {p} läuft an.',
      '{p} bringt die Ecke für {team} rein.',
      'Eckball {team}. Im Strafraum wird geschubst wie beim Schlussverkauf.',
      'Ecke von {p}. Die Großen gehen mit nach vorn.',
    ],
    TickerKind.lostCross => const [
      'Flanke von {q}, {p} köpft sie raus.',
      '{q} flankt, {p} ist zuerst dran und klärt für {team}.',
      'Die Hereingabe von {q} landet bei {p}. Kein Problem für {team}.',
      '{q} schlägt die Flanke, aber {p} steht goldrichtig.',
    ],
    TickerKind.lostThroughBall => const [
      '{q} will steil schicken, {p} liest das und fängt ab.',
      'Steilpass von {q}, eine Spur zu steil. {p} sagt danke.',
      '{q} sucht die Lücke, {p} macht sie zu.',
      'Der tödliche Pass von {q} stirbt bei {p}.',
    ],
    TickerKind.lostDribble => const [
      '{q} versucht es im Dribbling, {p} grätscht sauber dazwischen.',
      '{q} will an {p} vorbei. Will.',
      'Übersteiger von {q}, Ballgewinn {p}. Schön anzusehen war nur der '
          'Übersteiger.',
      '{q} verstolpert sich, {p} nimmt dankend an.',
    ],
    TickerKind.lostLongBall => const [
      '{q} schlägt ihn lang, {p} ist zuerst dran.',
      'Langer Ball von {q}, {p} köpft ihn zurück.',
      '{q} mit dem Befreiungsschlag, {p} bleibt Herr der Lage.',
    ],
    TickerKind.counter => const [
      'Ballgewinn {p}! {team} schaltet blitzschnell um.',
      '{p} erobert den Ball, und ab geht die Post: Konter {team}!',
      '{q} verliert die Kugel an {p}. Jetzt wird es schnell.',
      'Konter! {p} klaut den Ball, {team} rennt los, {opp} rennt hinterher.',
    ],
    TickerKind.addedTime => const [
      'Der vierte Offizielle zeigt {n} Minuten Nachspielzeit.',
      '{n} Minuten gibt es obendrauf.',
      'Nachspielzeit: {n} Minuten. Die Tafel leuchtet, die Nerven auch.',
      'Es gibt {n} Minuten Nachschlag.',
    ],
    TickerKind.keeperEightSeconds => const [
      '{p} hält den Ball zu lange fest. Acht Sekunden sind um: Ecke für '
          '{opp}.',
      '{p} kuschelt mit dem Ball, der Schiri zählt bis acht. Ecke für {opp}.',
      'Zeitspiel von {p}! Ab acht Sekunden gibt es eine Ecke, und die '
          'bekommt {opp}.',
    ],
    TickerKind.goalKickCountdown => const [
      '{p} lässt sich beim Abstoß Zeit, der Schiri zählt runter: Ecke für '
          '{opp}.',
      'Countdown beim Abstoß abgelaufen. {p} schaut entgeistert, {opp} hat '
          'eine Ecke.',
      '{p} legt sich den Ball zurecht. Und nochmal. Und nochmal. Ecke für '
          '{opp}.',
    ],
    TickerKind.throwInCountdown => const [
      '{p} trödelt beim Einwurf. Fünf Sekunden sind rum, Einwurf für {opp}.',
      'Einwurf {team}, aber {p} sucht noch die Brille. Jetzt wirft {opp}.',
      'Der Schiri zählt beim Einwurf runter, {p} zählt nicht mit. Ballbesitz '
          '{opp}.',
    ],
    // The radio reporter has its own texts (reporter_strings.dart).
    TickerKind.play ||
    TickerKind.shotUp ||
    TickerKind.freeKick ||
    TickerKind.colour ||
    TickerKind.calm ||
    TickerKind.varCheck ||
    TickerKind.varDecision => const [],
    TickerKind.captainOff => const [
      '{p} verlässt den Platz, die Kapitänsbinde wandert weiter.',
      'Ohne {p} fehlt {team} die Stimme auf dem Platz. Wer redet jetzt mit '
          'dem Schiri?',
      'Der Kapitän geht. {team} muss sich neu sortieren.',
    ],
    TickerKind.yellow => const [
      'Gelbe Karte für {p}. Der Schiedsrichter notiert eifrig.',
      '{p} sieht Gelb. Das Foul war eher Kunst als Sport.',
      'Verwarnung für {p} ({team}). Der Block des Schiedsrichters füllt sich.',
      'Gelb für {p}. Hoffentlich lernt er daraus. Hat er bisher nie.',
    ],
    TickerKind.secondYellow => const [
      'Gelb-Rot für {p}! {team} ist nur noch zu zehnt.',
      '{p} sieht zum zweiten Mal Gelb und muss duschen gehen.',
      'Zweite Gelbe für {p}: Platzverweis. {team} spielt in Unterzahl.',
      'Das war\'s für {p}. Gelb-Rot, und die Kabine ruft.',
    ],
    TickerKind.red => const [
      'Rote Karte für {p}! {team} ist nur noch zu zehnt.',
      'Platzverweis für {p}. Direkt Rot, keine Diskussion.',
      '{p} fliegt vom Platz. {team} spielt jetzt in Unterzahl.',
      'Rot! {p} muss sofort runter. Das wird teuer.',
    ],
    TickerKind.injury => const [
      '{p} bleibt liegen und kann nicht weiter. Verletzung, {days} Tage.',
      'Schlechte Nachrichten: {p} ({team}) hat sich verletzt. Ausfall {days} '
          'Tage.',
      '{p} humpelt vom Platz. Der Arzt sagt: {days} Tage Pause.',
      'Es hat {p} erwischt. {team} muss reagieren, er fällt {days} Tage aus.',
    ],
    TickerKind.substitution => const [
      'Wechsel bei {team}: {p} kommt für {q}.',
      '{q} geht, {p} kommt. Frische Beine für {team}.',
      'Die Bank von {team} schickt {p} aufs Feld. {q} darf sich setzen.',
      'Auswechslung: {p} ersetzt {q}. Der Trainer wird schon wissen, warum.',
    ],
    TickerKind.tactic => const [
      'An der Seitenlinie von {team} wird gestikuliert: neue Taktik.',
      '{team} stellt um. Ob das ein Plan ist, sehen wir gleich.',
      'Taktikwechsel bei {team}. Die Spieler nicken, als hätten sie es '
          'verstanden.',
      'Neue Ansage von der Bank ({team}): Es wird umgestellt.',
    ],
    TickerKind.halfTime => const [
      'Halbzeit. Es steht {score}. Zeit für Tee und große Worte.',
      'Pause beim Stand von {score}. In der Kabine wird gleich laut '
          'geflüstert.',
      'Der Schiedsrichter pfeift zur Pause: {score}. Jetzt ist der Trainer '
          'dran.',
      'Halbzeitpfiff, {score}. Die Würstchen sind der eigentliche Gewinner.',
    ],
    TickerKind.extraTime => const [
      'Verlängerung! Es steht {score}, und die Beine sind schon müde.',
      'Kein Sieger nach 90 Minuten ({score}). Es gibt Nachschlag: zweimal 15 '
          'Minuten.',
      'Unentschieden, {score}. Die Verlängerung beginnt, die Kabinen bleiben '
          'leer.',
    ],
    TickerKind.shootout => const ['Elfmeterschießen!'],
    TickerKind.fullTime => const [
      'Abpfiff! Endstand {score}.',
      'Das Spiel ist aus. {home} gegen {away} endet {score}.',
      'Schluss! {score}. Der Rest ist Pressekonferenz.',
      'Abpfiff beim Stand von {score}. Alle dürfen jetzt so tun, als hätten '
          'sie es kommen sehen.',
    ],
  };
  @override
  String tickerLead(String action) => switch (action) {
    'short_pass' => '{q} spielt kurz.',
    'through_ball' => '{q} steckt durch.',
    'long_ball' => '{q} mit dem langen Ball.',
    'cross' => 'Flanke von {q}.',
    'dribble' => '{q} tankt sich durch.',
    _ => '',
  };
  @override
  String get officeHome => 'Heimspiel';
  @override
  String get officeAway => 'Auswärtsspiel';
  @override
  String officeStrengthCompare(String mine, String theirs) =>
      'Stärke $mine gegen $theirs';
  @override
  String get officeCashTitle => 'Kasse';
  @override
  String officeSquad(int count) => 'Kader: $count Spieler';
  @override
  String get postFilterCurrent => 'Aktuell';

  @override
  String get postFilterUnread => 'Ungelesen';

  @override
  String get postFilterArchive => 'Archiv';

  @override
  String get postMarkAllRead => 'Alle gelesen';

  @override
  String get postEmpty => 'Hier liegt nichts. Auch das ist Post.';

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
  String officeMailBodyPresident(
    String typeId,
    String name,
  ) => switch (typeId) {
    'construction_tycoon' =>
      'Willkommen, $name! Ich baue gerade ein Stadion für 80.000 Zuschauer, auch wenn wir im Schnitt 212 haben. Man muss groß denken, der Rest kommt von selbst. Bitte nicht am Fundament rütteln.',
    'thrifty_butcher' =>
      'Hallo $name, schön, dass du da bist. Das Budget liegt im Kühlfach, bitte nur im Notfall öffnen. Das Mittagessen in der Kantine ist ein Wurstbrot, selbstverständlich auf eigene Rechnung.',
    'car_dealer' =>
      '$name, du bist der Richtige! Ich habe ein Auge für Talente wie für Gebrauchtwagen: viel Politur, wenig Kilometer. Falls du ein Auto brauchst, ich hätte da was. Sofort verfügbar, Vorbesitzer unbekannt.',
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

  // --- desk scene ---
  @override
  String deskName(DeskItem item) => switch (item) {
    DeskItem.post => 'Post',
    DeskItem.press => 'Presse',
    DeskItem.tactics => 'Taktiktafel',
    DeskItem.files => 'Spielerakten',
    DeskItem.calendar => 'Kalender',
    DeskItem.stats => 'Statistik und Rückblick',
    DeskItem.transfers => 'Transfers und Scouting',
    DeskItem.finance => 'Finanzen',
    DeskItem.grounds => 'Verein und Gelände',
    DeskItem.saves => 'Spielstände und Einstellungen',
    DeskItem.door => 'Weiter',
  };
  @override
  String deskShort(DeskItem item) => switch (item) {
    DeskItem.post => 'Post',
    DeskItem.press => 'Presse',
    DeskItem.tactics => 'Taktik',
    DeskItem.files => 'Akten',
    DeskItem.calendar => 'Kalender',
    DeskItem.stats => 'Statistik',
    DeskItem.transfers => 'Transfers',
    DeskItem.finance => 'Finanzen',
    DeskItem.grounds => 'Gelände',
    DeskItem.saves => 'Spielstand',
    DeskItem.door => 'Weiter',
  };
  @override
  String deskHint(DeskItem item) => switch (item) {
    DeskItem.post =>
      'Nachrichten vom Präsidenten, Berater und Presse. Die Ablage '
          'quillt über, das Postfach nicht.',
    DeskItem.press =>
      'Was die Zeitungen über dich schreiben. Die Zeitung ist von heute, '
          'der Kaffeefleck auch.',
    DeskItem.tactics =>
      'Hier wird mit Kreide Geschichte geschrieben. Oder zumindest ein '
          'Kreuz gemalt.',
    DeskItem.files =>
      'Dein Kader in Pappkartons. Wer fehlt, steckt vermutlich im '
          'falschen Karton.',
    DeskItem.calendar =>
      'Spielplan und Termine. Der Block ist abgerissen, die Fristen nicht.',
    DeskItem.stats =>
      'Tabellen, Torschützen und Pokale. Der Pokalschrank ist noch ein Brett.',
    DeskItem.transfers =>
      'Spieler suchen und kaufen. Die Stecknadeln sind dein Scoutingteam.',
    DeskItem.finance =>
      'Kasse und Lizenz. Der Taschenrechner kennt noch bessere Zeiten.',
    DeskItem.grounds =>
      'Verein und Gelände. Ausblick: Hinterhof. Ausbaustufe: Hinterhof, '
          'aber mit Tor.',
    DeskItem.saves =>
      'Spielstände und Einstellungen. Die Schublade klemmt, hält aber.',
    DeskItem.door =>
      'Weiter zum nächsten Spieltag. Hinter der Tür wartet der Platz.',
  };
  @override
  String deskKey(int digit) => 'Taste $digit';
  @override
  String get deskKeyDoor => 'Leertaste';
  @override
  String deskNext(int matchday) => 'Weiter zu Spieltag $matchday';
  @override
  String deskNextCup(String cup) => 'Weiter zum $cup';
  @override
  String get deskBadgeTactics => 'Aufstellung noch offen';
  @override
  String deskBadgePost(int unread) =>
      unread == 1 ? '1 ungelesene Nachricht' : '$unread ungelesene Nachrichten';
  @override
  String get infoDesk =>
      'Das ist dein Büro, und von hier läuft alles. Tipp auf ein Ding, '
      'und es öffnet sich (am Computer geht auch die Zahl daneben). Auf dem '
      'Handy wischst du durch den Raum, drei Ansichten. Der runde Knopf '
      'unten rechts lässt die Zeit weiterlaufen, die Tür tut dasselbe. Das '
      'Büro wird besser, wenn der Verein es tut. Versprochen, irgendwann.';
  @override
  String get comingLater => 'Kommt später.';
  @override
  String jourFixSubject(int matchday) =>
      'Jour Fix vor Spieltag $matchday: Deine Hausaufgaben';
  @override
  String jourFixBody({
    required int unread,
    required int matchday,
    required String opponent,
    required bool home,
  }) {
    final lines = <String>[
      'Guten Morgen! Damit du vor dem Spieltag nichts vergisst, hier die '
          'Liste, die du nicht bestellt hast:',
      '',
      if (unread > 0)
        '• Post: $unread ungelesen. Ja, die Leute schreiben wirklich an '
            'dich.',
      '• Aufstellung: Bisher hat sich noch niemand dafür interessiert. Du '
          'auch nicht.',
      '• Termin: Spieltag $matchday gegen $opponent '
          '(${home ? 'zu Hause' : 'auswärts'}). Der Gegner hat sich den '
          'Termin schon notiert.',
      '',
      'Mit freundlichen Grüßen, dein Vorzimmer',
    ];
    return lines.join('\n');
  }

  @override
  String get jourFixToPost => 'Zur Post';
  @override
  String get jourFixToTactics => 'Zur Taktiktafel';
  @override
  String get jourFixToCalendar => 'Zum Kalender';

  // --- squad and player profile ---
  @override
  String get squadCount0 => 'Keine Spieler';
  @override
  String squadCount(int n) => n == 1 ? '1 Spieler' : '$n Spieler';
  @override
  String squadFilterButton(String name) => 'Filter: $name';
  @override
  String get squadFilterTitle => 'Wen willst du sehen?';
  @override
  String squadAgeShort(int age) => '$age J.';
  @override
  String squadContractUntil(int year) => 'bis $year';
  @override
  String get squadNoContract => 'ohne Vertrag';
  @override
  String squadFilterName(SquadFilter filter) => switch (filter) {
    SquadFilter.all => 'Alle',
    SquadFilter.goalkeepers => 'Tor',
    SquadFilter.defenders => 'Abwehr',
    SquadFilter.midfielders => 'Mittelfeld',
    SquadFilter.attackers => 'Angriff',
  };
  @override
  String squadSortName(SquadSort sort) => switch (sort) {
    SquadSort.position => 'Position',
    SquadSort.strength => 'Stärke',
    SquadSort.age => 'Alter',
    SquadSort.name => 'Name',
    SquadSort.contract => 'Vertrag',
  };
  @override
  String get squadEmpty => 'Auf dieser Position hat dein Verein niemanden.';
  @override
  String get squadColName => 'Spieler';
  @override
  String get squadColPos => 'Pos.';
  @override
  String get squadColStrength => 'Stärke';
  @override
  String get squadColAge => 'Alter';
  @override
  String get squadColContract => 'Vertrag';
  @override
  String get infoSquadList =>
      'Dein Kader in der Reihenfolge, die du wählst. Klick auf eine '
      'Überschrift, um zu sortieren (nochmal klicken dreht um), oder auf '
      'einen Spieler, um alles über ihn zu erfahren. Auch das, was er '
      'lieber nicht verraten hätte.';
  @override
  String get infoSquadStrength =>
      'Die Gesamtstärke auf der Stammposition: der Durchschnitt aller Werte, '
      'die dort zählen. 100 wäre Weltklasse, in den unteren Ligen liegen die '
      'meisten zwischen 40 und 60.';
  @override
  String get infoSquadPos =>
      'Die Stammposition: TW Torwart, IV Innenverteidiger, LV und RV '
      'Außenverteidiger, ZDM defensives, ZM zentrales und ZOM offensives '
      'Mittelfeld, LA und RA Außen, ST Stürmer.';
  @override
  String get infoSquadContract =>
      'Das Jahr, in dem der Vertrag ausläuft. Danach kostet er dich keinen '
      'Cent mehr, den Spieler aber vielleicht den Verein.';
  @override
  String get infoSquadSort =>
      'Sortierung: Position, Stärke (stärkste zuerst), Alter (jüngste '
      'zuerst), Name (A bis Z) oder Vertrag (läuft zuerst aus).';
  @override
  String profileTab(int index) => const [
    'Übersicht',
    'Werte',
    'Rollen',
    'Kopf',
    'Karriere',
    'Vertrag',
  ][index];
  @override
  String get profileBack => 'Zum Kader';
  @override
  String profileAgeNation(int age, String nation) => '$age Jahre · $nation';
  @override
  String get profileOverall => 'Gesamtstärke';
  @override
  String get profileMainRole => 'Hauptrolle';
  @override
  String get profileNoRole => 'keine';
  @override
  String get profileAbilities => 'Spezialfähigkeiten';
  @override
  String get profileNoAbilities => 'Keine. Er ist ein ehrlicher Arbeiter.';
  @override
  String get profileContract => 'Vertrag';
  @override
  String profileContractUntil(String date) => 'bis $date';
  @override
  String profileSalary(String perYear) => '$perYear pro Jahr';
  @override
  String get profileNoContract => 'vereinslos';
  @override
  String get profileForm => 'Form und Stimmung';
  @override
  String get profileFormNone =>
      'Noch kein Spiel gespielt. Gute Laune ist also reine Theorie.';
  @override
  String get infoProfileOverall =>
      'Der Durchschnitt aller Werte, die auf der Stammposition des Spielers '
      'zählen. Mehr als 60 ist für diese Ligen schon richtig gut.';
  @override
  String get infoProfileRole =>
      'Was der Spieler auf seiner Position tut. Die Hauptrolle ist die, in '
      'der er sich am wohlsten fühlt. Die Zeichen zeigen, wie gut er sie '
      'kennt: Minus fremd, Null normal, Plus gut, Doppelplus Experte.';
  @override
  String get infoProfileAbilities =>
      'Besondere Stärken. Bronze, Silber und Gold zeigen, wie ausgeprägt '
      'sie sind. Mehr als vier hat niemand, und höchstens eine ist Gold.';
  @override
  String get infoProfileForm =>
      'Wie gut es ihm gerade läuft und wie er drauf ist. Kommt, sobald du '
      'das erste Spiel hinter sich haben.';
  @override
  String get valuesHint => 'Alle Werte von 1 bis 100';
  @override
  String get infoValues =>
      'Alle 34 Werte eines Feldspielers in sieben Blöcken, bei Torhütern '
      'dazu der Torwartblock. Klick auf einen Block, um ihn ein- oder '
      'auszuklappen.';
  @override
  String get infoValuesBar =>
      'Die Farbe zeigt die Klasse: Orange schwach (unter 40), Beige '
      'durchschnittlich, Grün gut (ab 60), Gelb Spitze (ab 80).';
  @override
  String attributeGroupName(AttributeGroup group) => switch (group) {
    AttributeGroup.physique => 'Physis',
    AttributeGroup.shooting => 'Schuss',
    AttributeGroup.setPieces => 'Standards',
    AttributeGroup.passing => 'Pass',
    AttributeGroup.intelligence => 'Spielintelligenz',
    AttributeGroup.dribbling => 'Dribbling',
    AttributeGroup.defending => 'Defensive',
    AttributeGroup.goalkeeping => 'Torwart',
  };
  @override
  String attributeName(Attribute attribute) => switch (attribute) {
    Attribute.acceleration => 'Antritt',
    Attribute.sprintSpeed => 'Endgeschwindigkeit',
    Attribute.stamina => 'Ausdauer',
    Attribute.strength => 'Kraft',
    Attribute.jumping => 'Sprungkraft',
    Attribute.recovery => 'Erholung',
    Attribute.goalInstinct => 'Torinstinkt',
    Attribute.finishing => 'Abschluss',
    Attribute.shotPower => 'Schusskraft',
    Attribute.longShots => 'Fernschuss',
    Attribute.volleys => 'Volleyschuss',
    Attribute.penalties => 'Elfmeter',
    Attribute.freeKicks => 'Freistöße',
    Attribute.corners => 'Eckbälle',
    Attribute.shortPassing => 'Kurzpass',
    Attribute.longPassing => 'Langpass',
    Attribute.crossing => 'Flanken',
    Attribute.curve => 'Effet',
    Attribute.vision => 'Spielübersicht',
    Attribute.composure => 'Ruhe am Ball',
    Attribute.reactions => 'Reaktion',
    Attribute.anticipation => 'Vorausahnen',
    Attribute.decisionMaking => 'Entscheidungen',
    Attribute.tacticalSense => 'Taktikverständnis',
    Attribute.concentration => 'Konzentration',
    Attribute.agility => 'Wendigkeit',
    Attribute.balance => 'Balance',
    Attribute.ballControl => 'Ballkontrolle',
    Attribute.dribbling => 'Dribbling',
    Attribute.interceptions => 'Abfangen',
    Attribute.heading => 'Kopfball',
    Attribute.defensiveAwareness => 'Defensivverhalten',
    Attribute.standingTackle => 'Zweikampf',
    Attribute.slidingTackle => 'Grätsche',
    Attribute.gkReflexes => 'Reflexe',
    Attribute.gkDiving => 'Hechten',
    Attribute.gkHandling => 'Fangsicherheit',
    Attribute.gkPositioning => 'Stellungsspiel',
    Attribute.gkKicking => 'Abschlag',
    Attribute.gkCommandOfArea => 'Strafraumbeherrschung',
    Attribute.gkDistribution => 'Spieleröffnung',
    Attribute.gkOneOnOne => 'Eins gegen eins',
  };
  @override
  String get rolesPositions => 'Positionen';
  @override
  String get rolesMainPosition => 'Stammposition';
  @override
  String get rolesSecondaryNone => 'Keine Nebenposition';
  @override
  String positionFamiliarityName(PositionFamiliarity f) => switch (f) {
    PositionFamiliarity.trained => 'eingespielt',
    PositionFamiliarity.practised => 'geübt',
  };
  @override
  String get rolesFoot => 'Fuß';
  @override
  String get rolesWeakFoot => 'Schwacher Fuß';
  @override
  String footName(Foot foot) => foot == Foot.left ? 'links' : 'rechts';
  @override
  String get rolesList => 'Rollen auf seinen Positionen';
  @override
  String get rolesBackThree => 'nur bei Dreier- oder Fünferkette';
  @override
  String roleSideHint(bool fits) =>
      fits ? 'Fuß passt zur Seite' : 'Falscher Fuß für diese Seite';
  @override
  String get infoRoles =>
      'Jede Rolle hat Schlüsselwerte. Das Zeichen daneben zeigt, wie gut der '
      'Spieler die Rolle kennt. Auf der falschen Seite für seinen Fuß gibt '
      'es Abzüge.';
  @override
  String get infoRolesSymbols =>
      'Minus: fremd (Abzug). Null: normal. Plus: gut (kleiner Bonus). '
      'Doppelplus: Experte (großer Bonus). Mehr als drei Plus und ein '
      'Doppelplus hat keiner.';
  @override
  String get infoPositions =>
      'Auf der Stammposition spielt er am besten. Auf Nebenpositionen ist er '
      'eingespielt (kaum Abzug) oder geübt (halber Abzug). Überall sonst '
      'zahlt er voll drauf.';
  @override
  String get headTraits => 'Charakter';
  @override
  String get headInjury => 'Verletzungsanfälligkeit';
  @override
  String get headPotential => 'Potenzial';
  @override
  String get headDevelopment => 'Entwicklung';
  @override
  String get headCircumstances => 'Umstände';
  @override
  String get headCircumstancesText =>
      'Rolle im Verein, Kabine, Medien, Berater und Finanzen erscheinen hier, '
      'sobald das Spiel läuft.';
  @override
  String get infoTraits =>
      'Wie er tickt. Die Werte sind in vier Stufen sichtbar (niedrig, mittel, '
      'hoch, extrem). Die genauen Zahlen bleiben geheim, wie im richtigen '
      'Leben.';
  @override
  String get infoPotential =>
      'Wie gut er höchstens werden kann, grob in fünf Punkten. Ob er es '
      'schafft, hängt von Alter, Training und Spielzeit ab.';
  @override
  String get infoDevelopment =>
      'Frühentwickler sind früh gut und lassen früher nach. Spätzünder '
      'brauchen länger, halten dafür länger durch.';
  @override
  String get infoCircumstances =>
      'Alles, was um einen Spieler herum passiert und seine Laune, Leistung '
      'und Wechselwünsche verändert.';
  @override
  String traitName(CharacterTrait trait) => switch (trait) {
    CharacterTrait.professionalism => 'Professionalität',
    CharacterTrait.temper => 'Hitzköpfigkeit',
    CharacterTrait.aggression => 'Aggressivität',
    CharacterTrait.egoism => 'Egoismus',
    CharacterTrait.leadership => 'Führungsstärke',
    CharacterTrait.pressureResistance => 'Nervenstärke',
    CharacterTrait.creativity => 'Kreativität',
    CharacterTrait.mediaHunger => 'Medienhunger',
    CharacterTrait.partyFactor => 'Partyfaktor',
    CharacterTrait.greed => 'Geldgier',
    CharacterTrait.ambition => 'Ehrgeiz',
    CharacterTrait.loyalty => 'Treue',
    CharacterTrait.consistency => 'Konstanz',
  };
  @override
  String traitLevelName(int level) =>
      const ['niedrig', 'mittel', 'hoch', 'extrem'][level];
  @override
  String developmentTypeName(DevelopmentType type) => switch (type) {
    DevelopmentType.earlyBloomer => 'Frühentwickler',
    DevelopmentType.normal => 'Normal',
    DevelopmentType.lateBloomer => 'Spätzünder',
  };
  @override
  String get careerNoSeason =>
      'Noch keine Saison gespielt. Statistik, Entwicklungskurve, '
      'Verletzungen und Meldungen aus der Presse erscheinen hier später.';
  @override
  String careerSince(String date) => 'Beim Verein seit $date';
  @override
  String get infoCareer =>
      'Der Lebenslauf des Spielers: Spiele, Tore, Verletzungen und was die '
      'Zeitungen über ihn geschrieben haben.';
  @override
  String positionName(Position position) => switch (position) {
    Position.tw => 'Torwart',
    Position.iv => 'Innenverteidiger',
    Position.lv => 'Linker Verteidiger',
    Position.rv => 'Rechter Verteidiger',
    Position.zdm => 'Defensives Mittelfeld',
    Position.zm => 'Zentrales Mittelfeld',
    Position.zom => 'Offensives Mittelfeld',
    Position.la => 'Linksaußen',
    Position.ra => 'Rechtsaußen',
    Position.st => 'Stürmer',
  };
  @override
  String abilityName(SpecialAbilityType type) => switch (type) {
    SpecialAbilityType.dribbler => 'Dribbelkönig',
    SpecialAbilityType.longShooter => 'Fernschütze',
    SpecialAbilityType.volleySpecialist => 'Volleyspezialist',
    SpecialAbilityType.goalPoacher => 'Abstauber',
    SpecialAbilityType.headerMonster => 'Kopfballungeheuer',
    SpecialAbilityType.playmaker => 'Spielmacher',
    SpecialAbilityType.targetMan => 'Zielspieler',
    SpecialAbilityType.counterPlayer => 'Konterspieler',
    SpecialAbilityType.setPieceSpecialist => 'Standardspezialist',
    SpecialAbilityType.ballShield => 'Ballschirm',
    SpecialAbilityType.firstTouch => 'Erstberührung',
    SpecialAbilityType.vacuumCleaner => 'Staubsauger',
    SpecialAbilityType.pressingMachine => 'Pressingmaschine',
    SpecialAbilityType.passReader => 'Passleser',
    SpecialAbilityType.penaltyKiller => 'Elfmetertöter',
    SpecialAbilityType.allrounder => 'Allrounder',
  };
  @override
  String abilityInfo(SpecialAbilityType type) => switch (type) {
    SpecialAbilityType.dribbler =>
      'Lässt Gegner stehen und freut sich darüber.',
    SpecialAbilityType.longShooter =>
      'Schießt aus 30 Metern. Trifft manchmal sogar das Tor.',
    SpecialAbilityType.volleySpecialist =>
      'Mag den Ball lieber in der Luft als am Boden.',
    SpecialAbilityType.goalPoacher =>
      'Steht immer genau dort, wo der Ball hinfällt.',
    SpecialAbilityType.headerMonster =>
      'Köpft alles, was fliegt, und manches, was nicht fliegt.',
    SpecialAbilityType.playmaker =>
      'Sieht Pässe, bevor andere wissen, dass es einen Ball gibt.',
    SpecialAbilityType.targetMan =>
      'Ein Hüne, an dem sich Verteidiger die Zähne ausbeißen.',
    SpecialAbilityType.counterPlayer =>
      'Rennt los, bevor der Gegner den Ball verloren hat.',
    SpecialAbilityType.setPieceSpecialist =>
      'Freistöße und Ecken sind sein Wohnzimmer.',
    SpecialAbilityType.ballShield => 'Den Ball bekommt man nur mit Gewalt.',
    SpecialAbilityType.firstTouch => 'Der Ball klebt schon beim Annehmen.',
    SpecialAbilityType.vacuumCleaner => 'Saugt jeden Ball im Mittelfeld ein.',
    SpecialAbilityType.pressingMachine => 'Läuft Gegner an, bis sie weinen.',
    SpecialAbilityType.passReader =>
      'Weiß vorher, wohin der Gegner passen will.',
    SpecialAbilityType.penaltyKiller =>
      'Hält Elfmeter, weil er einfach besser rät.',
    SpecialAbilityType.allrounder =>
      'Kann alles ein bisschen. Zählt als Fähigkeit.',
  };
  @override
  String abilityTierName(AbilityTier tier) => switch (tier) {
    AbilityTier.bronze => 'Bronze',
    AbilityTier.silver => 'Silber',
    AbilityTier.gold => 'Gold',
  };
  @override
  String roleName(String id) => switch (id) {
    'line_keeper' => 'Linientorwart',
    'sweeper_keeper' => 'Mitspielender Torwart',
    'playmaking_keeper' => 'Spielmacher im Tor',
    'box_keeper' => 'Strafraumtorwart',
    'anchor_defender' => 'Ankerverteidiger',
    'stopper' => 'Vorstopper',
    'ball_playing_defender' => 'Spielaufbauender Verteidiger',
    'libero' => 'Libero',
    'wide_centre_back' => 'Breiter Innenverteidiger',
    'full_back' => 'Außenverteidiger',
    'inverted_full_back' => 'Einrückender Außenverteidiger',
    'wing_back' => 'Schienenspieler',
    'attacking_wing_back' => 'Offensiver Schienenspieler',
    'inside_wing_back' => 'Einrückender Schienenspieler',
    'ball_winner' => 'Balleroberer',
    'anchor_midfielder' => 'Sechser',
    'deep_playmaker' => 'Tiefer Spielmacher',
    'box_to_box' => 'Box-zu-Box-Spieler',
    'playmaker' => 'Spielmacher',
    'half_winger' => 'Halbaußen',
    'classic_ten' => 'Klassische Zehn',
    'shadow_striker' => 'Schattenstürmer',
    'winger' => 'Flügelspieler',
    'inside_forward' => 'Einrückender Flügel',
    'wide_playmaker' => 'Spielmachender Flügel',
    'wide_midfielder' => 'Äußerer Mittelfeldspieler',
    'advanced_forward' => 'Vorgeschobener Stürmer',
    'poacher' => 'Strafraumjäger',
    'false_nine' => 'Falsche Neun',
    'target_man' => 'Wandspieler',
    _ => id,
  };
  @override
  String roleFamiliaritySymbol(RoleFamiliarity f) => switch (f) {
    RoleFamiliarity.unfamiliar => '−',
    RoleFamiliarity.basic => '0',
    RoleFamiliarity.comfortable => '+',
    RoleFamiliarity.expert => '++',
  };
  @override
  String roleFamiliarityName(RoleFamiliarity f) => switch (f) {
    RoleFamiliarity.unfamiliar => 'fremd',
    RoleFamiliarity.basic => 'normal',
    RoleFamiliarity.comfortable => 'gut',
    RoleFamiliarity.expert => 'Experte',
  };
  @override
  String nationName(String code) => switch (code) {
    'DE' => 'Deutschland',
    'TR' => 'Türkei',
    'PL' => 'Polen',
    'GH' => 'Ghana',
    'NG' => 'Nigeria',
    'HR' => 'Kroatien',
    'IT' => 'Italien',
    'NL' => 'Niederlande',
    'FR' => 'Frankreich',
    'ES' => 'Spanien',
    'BR' => 'Brasilien',
    _ => code,
  };

  // --- line-up ---
  @override
  String get lineupTabTactics => 'Taktik';
  @override
  String get lineupTabSquad => 'Kader';
  @override
  String get lineupFormation => 'Formation';
  @override
  String get infoLineupFormation =>
      'Die Zahlen sind die Spieler pro Reihe, von hinten nach vorn. Der '
      'Torwart zählt nicht mit, er steht ja ohnehin im Weg. Wer die '
      'Formation wechselt, lässt den Assistenten neu aufstellen; danach '
      'darfst du wieder alles besser wissen.';
  @override
  String get lineupSystem => 'Spielsystem';
  @override
  String get infoLineupSystem =>
      'Das System ist die Spielidee der ganzen Mannschaft. Die Zahl dahinter '
      'zeigt, wie gut deine Elf dazu passt: plus ist gut, minus ist Mut. '
      'Ein System, das nicht zu den Spielern passt, wirkt kaum und kostet '
      'trotzdem Kraft.';
  @override
  String systemName(String id) => switch (id) {
    'possession' => 'Ballbesitz',
    'counter' => 'Konter',
    'gegenpressing' => 'Gegenpressing',
    'wings' => 'Flügelspiel',
    'wall' => 'Mauer',
    _ => id,
  };
  @override
  String systemHint(String id) => switch (id) {
    'possession' =>
      'Der Ball gehört uns. Die Gegner dürfen zuschauen, das ist sehr '
          'höflich.',
    'counter' =>
      'Hinten stehen, vorne zuschlagen. Geduld ist die Kunst der '
          'Bequemen.',
    'gegenpressing' =>
      'Ball verloren? Sofort zurückholen. Kostet Kraft und Nerven.',
    'wings' =>
      'Über außen bis zur Grundlinie, dann hoch hinein. Der Kopfball '
          'bedankt sich.',
    'wall' => 'Kompakt, tief, hässlich. Wer nie verliert, steigt selten ab.',
    _ => '',
  };
  @override
  String get lineupSliders => 'Regler';
  @override
  String get lineupCaptain => 'Kapitän';
  @override
  String get infoLineupCaptain =>
      'Der Kapitän trägt die Binde und hält den Laden zusammen. Ein echter '
      'Anführer fängt die Mannschaft nach einem Gegentor auf. Fliegt er vom '
      'Platz oder sitzt draußen, wackelt der Haufen sichtbar. Lässt du das '
      'Feld leer, nimmt der Assistent den mit der größten Klappe in der Kabine.';
  @override
  String get lineupCaptainAuto => 'Assistent';
  @override
  String lineupCaptainAutoIs(String name) =>
      'Ohne deine Wahl trägt $name die Binde.';
  @override
  String get infoLineupSliders =>
      'Drei Regler, drei Stufen. Hohes Pressing und hohes Tempo kosten '
      'Kraft, eine hohe Abwehrlinie kostet Nerven. Welche Spieler dazu '
      'taugen, steht in den Schlüsselwerten: Ausdauer, Antritt, '
      'Antizipation.';
  @override
  String sliderName(String id) => switch (id) {
    'pressing' => 'Pressing',
    'tempo' => 'Tempo',
    'defensive_line' => 'Abwehrlinie',
    _ => id,
  };
  @override
  String sliderLevelName(String id, int level) => switch (id) {
    'pressing' => const ['niedrig', 'normal', 'hoch'][level],
    'tempo' => const ['geduldig', 'normal', 'schnell'][level],
    _ => const ['tief', 'normal', 'hoch'][level],
  };
  @override
  String get lineupPreview => 'Mannschaftsvorschau';
  @override
  String get infoLineupPreview =>
      'Stärke: der Durchschnitt deiner Elf auf den Plätzen, auf denen sie '
      'steht (100 wäre Weltklasse). Rollenpassung: wie gut jeder in seiner '
      'Rolle ist, von 0 bis 100 Prozent. Systempassung: wie gut die Elf zur '
      'Spielidee passt. Alles nur Vorschau, gespielt wird auf dem Platz.';
  @override
  String get lineupStrength => 'Stärke';
  @override
  String get lineupRoleFit => 'Rollenpassung';
  @override
  String get lineupSystemFit => 'Systempassung';
  @override
  String lineupSystemFitName(double fit) {
    if (fit >= 0.3) return 'sehr gut';
    if (fit >= 0.05) return 'gut';
    if (fit > -0.05) return 'mittel';
    if (fit > -0.3) return 'dürftig';
    return 'Wagnis';
  }

  @override
  String lineupOutOfPosition(int n) => n == 0
      ? 'Alle auf ihrer Position.'
      : n == 1
      ? 'Ein Spieler steht nicht auf seiner Position.'
      : '$n Spieler stehen nicht auf ihrer Position.';
  @override
  String get lineupAuto => 'Assistent stellt auf';
  @override
  String get lineupConfirm => 'Passt so';
  @override
  String get lineupConfirmed => 'Aufstellung steht.';
  @override
  String get lineupHint =>
      'Tipp auf einen Platz auf dem Feld und dann auf den Spieler, '
      'der dort spielen soll. Ohne Platz setzt ein Tipp auf einen Spieler '
      'ihn auf die Bank oder wieder herunter.';
  @override
  String get infoLineupPitch =>
      'So steht deine Elf auf dem Feld, der Torwart unten. Die Farbe des '
      'Punktes zeigt, wie gut der Spieler in seiner Rolle ist: gelb top, '
      'grün gut, beige mittel, orange schwach.';
  @override
  String get lineupBenchTitle => 'Bank';
  @override
  String get lineupStartXi => 'Startelf';
  @override
  String get lineupBench => 'Bank';
  @override
  String get lineupStand => 'Tribüne';
  @override
  String lineupBenchCount(int n, int places) => 'Bank: $n von $places Plätzen.';
  @override
  String get lineupNoBenchKeeper =>
      'Kein Ersatztorwart auf der Bank. Fliegt der Torwart, geht ein '
      'Feldspieler ins Tor.';
  @override
  String get settingsAutoLineup => 'Assistent stellt um';
  @override
  String get settingsAutoLineupText =>
      'Fällt jemand aus deiner Aufstellung aus, baut der Assistent sie neu. Aus: Du musst selbst umstellen, vorher geht es nicht weiter.';
  @override
  String get lineupBenchEmpty =>
      'Frei. Tipp unten auf einen Spieler, um ihn auf die Bank zu setzen.';
  @override
  String get lineupBenchRemove => 'Von der Bank nehmen';
  @override
  String lineupAbsentWarning(int n) =>
      n == 1 ? '1 Spieler fällt aus' : '$n Spieler fallen aus';
  @override
  String get lineupGoToLineup => 'Aufstellung';
  @override
  String lineupAbsentInSheet(String names) =>
      '$names fällt aus. Stell die Aufstellung um oder schalte in den Einstellungen den Assistenten ein.';
  @override
  String lineupAutoChanged(String names) =>
      '$names fällt aus, der Assistent hat umgestellt.';
  @override
  String get lineupSwapKeeper => 'Torwart und Feldspieler tauschen geht nicht.';
  @override
  String get lineupPickerFit => 'Passend';
  @override
  String get lineupPickerAll => 'Alle';
  @override
  String get lineupPickerHere => 'Spielt hier';
  @override
  String get lineupBenchDone => 'Fertig';
  @override
  String lineupPickerPlaysOn(String position) => 'Spielt auf $position';
  @override
  String lineupAbsentBlocked(String reason) =>
      'Der Spieler ist $reason und kann nicht spielen. Auch nicht, wenn du '
      'ganz lieb fragst.';
  @override
  String lineupBenchFull(int places) =>
      'Die Bank ist voll. $places Plätze, kein weiterer.';
  @override
  String get lineupSlotRole => 'Rolle auf diesem Platz';
  @override
  String get infoLineupSlot =>
      'Die Rolle sagt, was der Spieler auf seiner Position tut. Die Prozent '
      'zeigen, wie gut er sie ausfüllt (Position, Fuß, Vertrautheit und '
      'Schlüsselwerte zusammen). Eine Rolle nur für Dreier- oder '
      'Fünferkette gibt es bei Viererkette nicht.';
  @override
  String get lineupNoRole => 'keine besondere Rolle';
  @override
  String lineupRolePercent(int percent) => '$percent %';
  @override
  String lineupOutOfPositionHint(String own, String slot, int percent) =>
      'Von Haus aus $own, hier als $slot: er spielt mit $percent % seiner '
      'Werte.';
  @override
  String get lineupNoSheet =>
      'Aus diesem Kader lässt sich keine Elf stellen. Es fehlen Spieler '
      'oder ein Torwart.';
  @override
  String lineupProblemText(LineupProblem problem) => switch (problem) {
    LineupProblem.none => '',
    LineupProblem.missing =>
      'Es gibt keine Aufstellung. Ohne Elf wird nicht gespielt.',
    LineupProblem.wrongCount => 'Die Aufstellung hat nicht elf Spieler.',
    LineupProblem.keeper => 'Auf dem Torwartplatz steht kein Torwart.',
    LineupProblem.duplicate => 'Ein Spieler steht doppelt in der Aufstellung.',
    LineupProblem.foreign => 'Ein Spieler gehört nicht zu deinem Verein.',
  };
  @override
  String get lineupPickSlotFirst => 'Wähl zuerst einen Platz.';

  // --- statistics ---
  @override
  String get statsTabTables => 'Tabellen';
  @override
  String get statsTabCups => 'Pokale';
  @override
  String get statsTabScorers => 'Torschützen';
  @override
  String get infoStatsPage =>
      'Hier steht, wer oben steht und wer unten. Tabellen aller acht Ligen, die beiden Pokale und die besten Torschützen. Wer nachschauen will, ob der Nachbarverein auch so schlecht ist wie man selbst: bitte sehr.';
  @override
  String get statsColPlace => '#';
  @override
  String get statsColClub => 'Verein';
  @override
  String get statsColPlayed => 'Sp';
  @override
  String get statsColWon => 'S';
  @override
  String get statsColDrawn => 'U';
  @override
  String get statsColLost => 'N';
  @override
  String get statsColGoals => 'Tore';
  @override
  String get statsColDiff => 'Diff';
  @override
  String get statsColPoints => 'Pkt';
  @override
  String get infoStatsColumns =>
      'Sp = Spiele, S = Siege, U = Unentschieden, N = Niederlagen, Tore = geschossen zu kassiert, Diff = Tordifferenz, Pkt = Punkte (Sieg drei, Remis einer). Bei Punktgleichheit zählt erst die Tordifferenz, dann die geschossenen Tore.';
  @override
  String get statsForecastNote =>
      'Noch nichts gespielt. Die Reihenfolge folgt der Mannschaftsstärke und ist nur eine Schätzung.';
  @override
  String get statsOwnLeague => 'Deine Liga';
  @override
  String statsZoneName(TableZone zone) => switch (zone) {
    TableZone.none => '',
    TableZone.promotion => 'Aufstieg',
    TableZone.chance => 'Meister: Aufstiegschance',
    TableZone.playoffUp => 'Aufstiegs-Relegation',
    TableZone.playoffDown => 'Abstiegs-Relegation',
    TableZone.relegation => 'Abstieg',
  };
  @override
  String get infoStatsZones =>
      'Die farbigen Streifen zeigen, was der Platz bedeutet. Relegation ist ein Extra-Duell gegen einen Klub aus der Liga darüber oder darunter, Ausgang ungewiss, Nerven garantiert. In der 4. Liga steigt der Meister nur auf, wenn seine Region in dem Jahr an der Reihe ist.';
  @override
  String get statsCupBolzplatz => 'Bolzplatzpokal';
  @override
  String get statsCupPott => 'Pott der Provinz';
  @override
  String get infoStatsCupBolzplatz =>
      'Der große Pokal: 64 Vereine, ein Spiel pro Runde, wer verliert, fliegt raus. Dabei sind alle Klubs der 1. und 2. Liga und 28 Klubs aus den unteren Ligen. Ein Außenseiter-Sieg gilt als Märchen, bis man ihn selbst erlebt.';
  @override
  String get infoStatsCupPott =>
      'Der Pokal für die Provinz: in jeder der fünf Regionen ein eigenes 32er-Feld. Wer weit kommt, spielt nächste Saison im Bolzplatzpokal mit (vier Plätze je Region, dazu vier Zusatzplätze).';
  @override
  String statsCupRoundName(int clubs) => switch (clubs) {
    2 => 'Finale',
    4 => 'Halbfinale',
    8 => 'Viertelfinale',
    16 => 'Achtelfinale',
    _ => 'Runde der $clubs',
  };
  @override
  String statsCupAfterMatchday(int day) => 'nach Spieltag $day';
  @override
  String get statsCupNotDrawn => 'Noch nicht ausgelost.';
  @override
  String statsCupWinner(String club) => 'Sieger: $club';
  @override
  String get statsCupNoWinner => 'Noch kein Sieger.';
  @override
  String regionName(Region region) => switch (region) {
    Region.nord => 'Nord',
    Region.nordost => 'Nordost',
    Region.west => 'West',
    Region.suedwest => 'Südwest',
    Region.bayern => 'Bayern',
  };
  @override
  String get statsGoals => 'Tore';
  @override
  String get statsAssists => 'Vorlagen';
  @override
  String get infoStatsScorers =>
      'Die besten Schützen und Vorbereiter aller Ligen. Eine Vorlage ist der letzte Pass vor dem Tor, also die Arbeit, für die niemand Sprechchöre bekommt.';
  @override
  String get statsScorersEmpty =>
      'Noch kein Tor gefallen. Die Stürmer üben noch das Zielen.';
  @override
  String get statsAssistsEmpty =>
      'Noch keine Vorlage. Alle haben den Ball behalten.';
  @override
  String seasonLabel(int startYear) =>
      '$startYear/${((startYear + 1) % 100).toString().padLeft(2, '0')}';
  @override
  String seasonEndSubject(int startYear, bool dismissed) => dismissed
      ? 'Saisonbilanz ${seasonLabel(startYear)}: Wir müssen reden'
      : 'Saisonbilanz ${seasonLabel(startYear)}';
  @override
  String seasonEndBody({
    required int startYear,
    required String league,
    required int rank,
    required int teams,
    required String champion,
    required String? cupWinner,
    required int levelChange,
    required String? nextLeague,
    required GoalVerdict verdict,
    required int gap,
    required SeasonGoal goal,
    required bool dismissed,
  }) {
    final lines = <String>[
      'Die Saison ${seasonLabel(startYear)} ist vorbei. Du bist in der '
          '${leagueName(league)} Platz $rank von $teams geworden. Meister '
          'ist $champion.',
    ];
    if (cupWinner != null) {
      lines.add('Den Bolzplatzpokal hat $cupWinner gewonnen.');
    }
    if (levelChange < 0 && nextLeague != null) {
      lines.add(
        'Dein Verein steigt auf in die ${leagueName(nextLeague)}. '
        'Die Sektkorken sind schon unterwegs.',
      );
    } else if (levelChange > 0 && nextLeague != null) {
      lines.add(
        'Dein Verein steigt ab in die ${leagueName(nextLeague)}. '
        'Das Gute daran: Es kann nur besser werden.',
      );
    } else if (nextLeague == null) {
      lines.add(
        'Dein Verein hat die Pyramide nach unten verlassen. '
        'Weiter runter geht es nicht, außer in den Keller.',
      );
    } else {
      lines.add('Ihr bleibt in der ${leagueName(league)}.');
    }
    lines.add('Das Saisonziel war: ${seasonGoalText(goal)}.');
    lines.add(switch (verdict) {
      GoalVerdict.exceeded =>
        'Das Ziel hast du übertroffen. Der Präsident redet schon von '
            'Europa. Es gibt keins.',
      GoalVerdict.reached =>
        'Das Ziel hast du erreicht. Das ist die Pflicht, '
            'aber auch die ist selten.',
      GoalVerdict.missed =>
        'Das Ziel hast du knapp verpasst'
            '${gap > 0 ? ' (um $gap ${gap == 1 ? 'Platz' : 'Plätze'})' : ''}.',
      GoalVerdict.failed =>
        'Das Ziel hast du klar verfehlt'
            '${gap > 0 ? ' (um $gap Plätze)' : ''}.',
    });
    if (dismissed) {
      lines.add(
        'Der Präsident hat entschieden: Dein Vertrag wird zum '
        '30. Juni nicht verlängert. Er hat dabei sehr ernst geschaut und '
        'nur einmal auf die Uhr.',
      );
    } else if (verdict == GoalVerdict.missed || verdict == GoalVerdict.failed) {
      lines.add(
        'Du bleibst. Der Präsident drückt noch einmal ein Auge zu, '
        'das andere beobachtet dich.',
      );
    } else {
      lines.add('Dein Vertrag läuft weiter.');
    }
    return lines.join('\n\n');
  }

  @override
  String get deskNextSeason => 'Weiter';
  @override
  String seasonStarted(int startYear, String league, String goal) =>
      'Saison ${seasonLabel(startYear)} beginnt: ${leagueName(league)}. '
      'Saisonziel: $goal.';
  @override
  String get dismissTitle => 'Entlassen';
  @override
  String dismissBody(String club, int startYear, int rank, int teams) =>
      'Die Saison ${seasonLabel(startYear)} endete mit Platz $rank von '
      '$teams. Das hat dem Präsidenten von $club nicht gereicht. Du räumst '
      'dein Büro, nimmst die Kaffeetasse mit und gehst. Der Fußball geht '
      'ohne dich weiter. Er merkt es kaum. Du kannst dich bei anderen '
      'Vereinen bewerben.';
  @override
  String get dismissSearch => 'Neue Stelle suchen';
  @override
  String get dismissMenu => 'Zum Hauptmenü';
  @override
  String get infoDismiss =>
      'Wer das Saisonziel verfehlt, kann entlassen werden. Es zählt, wie '
      'weit du daneben lagst. Später zählen auch das Verhältnis zum '
      'Präsidenten und zur Mannschaft. Du kannst dich dann bei neuen '
      'Vereinen bewerben, mit demselben Trainer.';
  @override
  String get calLegendVacation => 'Urlaub (dein Plan)';
  @override
  String get calLegendAppointment => 'Termin (Punkt)';
  @override
  String get vacTitle => 'Urlaubsplaner';
  @override
  String vacCounter(int total, int minTotal, int block, int minBlock) =>
      '$total von $minTotal Werktagen geplant · längster Block $block '
      '(mindestens $minBlock)';
  @override
  String vacStatus(VacationLevel level, bool blockKept, int minBlock) {
    if (!blockKept) {
      return 'Es fehlt ein Block von mindestens $minBlock Werktagen am '
          'Stück. So viel Erholung schreibt das Gesetz der Mannschaft vor.';
    }
    return switch (level) {
      VacationLevel.less =>
        'Zu wenig frei: Die Spieler werden unzufrieden und irgendwann '
            'ausgebrannt. Der Verband schaut auch hin.',
      VacationLevel.exact =>
        'Genau richtig: Die Stimmung bleibt neutral. Das ist bei Fußballern '
            'schon ein Kompliment.',
      VacationLevel.more =>
        'Mehr als genug: Die Mannschaft freut sich, ausgeruht ist sie '
            'auch. Der Präsident wird es dir vorhalten.',
    };
  }

  @override
  String get vacEdit => 'Urlaub eintragen';
  @override
  String get vacModeDays => 'Einzelne Tage';
  @override
  String get vacModeRange => 'Zeitraum';
  @override
  String get vacRangeHint =>
      'Tippe den ersten und den letzten Tag. Ist der erste schon Urlaub, '
      'wird der Zeitraum gestrichen.';
  @override
  String get vacSuggest => 'Vorschlag des Assistenten';
  @override
  String get vacClear => 'Alles löschen';
  @override
  String get infoVacation =>
      'Du bestimmst, wann die ganze Mannschaft frei hat. Vorgabe: 30 '
      'Werktage (Montag bis Samstag ohne Feiertage) pro Saison, davon '
      'mindestens ein Block von 12 am Stück. Frei geben kannst du nur an '
      'Tagen ohne Pflichtspiel deines Vereins und ohne Pokaltermin. Genau 30 '
      'Tage lassen die Stimmung neutral, weniger machen die Spieler '
      'unzufrieden, mehr machen sie glücklich. Wer die Vorgabe verfehlt, '
      'bekommt am Saisonende eine Verwarnung, später Geldstrafen. Hast du '
      'nichts geplant, übernimmt der Assistent einen Vorschlag.';
  @override
  String get apptTitle => 'Termine';
  @override
  String get apptNone => 'Keine Termine in Sicht. Genieß es.';
  @override
  String apptName(AppointmentKind kind, int variant) => switch (kind) {
    AppointmentKind.jourFix => 'Jour Fix mit dem Präsidenten',
    AppointmentKind.presidentTalk => 'Gespräch mit dem Präsidenten',
    AppointmentKind.pressTalk =>
      variant == 0
          ? 'Pressekonferenz zum Saisonstart'
          : 'Pressekonferenz zur Winterbilanz',
    AppointmentKind.sponsorTalk =>
      variant == 0 ? 'Sponsorentermin (Sommer)' : 'Sponsorentermin (Winter)',
  };
  @override
  String get infoAppointments =>
      'Deine Termine in den nächsten Tagen. Der Jour Fix ist jede Woche nach '
      'dem Spiel, der Präsident will dich einmal im Monat sehen, dazu kommen '
      'Presse und Sponsoren. Zu jedem Termin kommt am Tag selbst eine Mail '
      'in die Post. Die Tage sind im Kalender mit einem Punkt markiert.';
  @override
  String apptMailSubject(AppointmentKind kind, int variant, int number) =>
      switch (kind) {
        AppointmentKind.jourFix => 'Jour Fix: Die Woche nach dem Spiel',
        AppointmentKind.presidentTalk => 'Gespräch beim Präsidenten',
        AppointmentKind.pressTalk =>
          variant == 0
              ? 'Pressekonferenz: Die Saison geht los'
              : 'Pressekonferenz: Die Winterbilanz',
        AppointmentKind.sponsorTalk =>
          variant == 0
              ? 'Sponsorentermin: Der Sommer-Händedruck'
              : 'Sponsorentermin: Der Winter-Händedruck',
      };
  @override
  String apptMailBody(
    AppointmentKind kind,
    int variant, {
    required String manager,
    required String goal,
    required String club,
  }) => switch (kind) {
    AppointmentKind.jourFix => '',
    AppointmentKind.presidentTalk =>
      'Lieber $manager,\n\nwir haben uns heute im Büro des Präsidenten '
          'getroffen. Er hat dreimal gesagt, wie stolz er auf $club ist, '
          'einmal an das Saisonziel erinnert ($goal) und beim Gehen die '
          'Kaffeetasse mitgenommen. Entscheiden musstest du nichts. Das '
          'Gespräch hat trotzdem stattgefunden, das steht jetzt im Protokoll.',
    AppointmentKind.pressTalk =>
      variant == 0
          ? 'Die Presse wollte vor dem ersten Spiel alles wissen: Ziele, '
                'Neuzugänge, Wetter. Du hast geantwortet, ohne etwas zu '
                'sagen, das ist die halbe Kunst. Morgen steht trotzdem '
                'etwas Falsches in der Zeitung. Das ist die andere Hälfte.'
          : 'Zur Winterpause wollten die Reporter eine Bilanz. Du hast die '
                'Hinrunde in drei Sätzen erklärt, der vierte kam aus Versehen '
                'ehrlich. Es wird schon niemand lesen. Doch, alle.',
    AppointmentKind.sponsorTalk =>
      variant == 0
          ? 'Der Sponsor war da, hat dir die Hand geschüttelt und ein Foto '
                'mit dem Vereinsbus machen lassen. Du musstest lächeln. Die '
                'Entscheidungen trifft die Kasse, nicht du.'
          : 'Der Sponsor hat im Winter vorbeigeschaut, den Verein gelobt '
                'und das Trikot genau geprüft. Das Logo sitzt, die Laune '
                'auch. Mehr gab es nicht zu besprechen.',
  };
  @override
  String jourFixReview({
    required String opponent,
    required bool home,
    required int goalsFor,
    required int goalsAgainst,
    required int seed,
    String? cup,
    bool? wentThrough,
  }) {
    final where = home ? 'zu Hause' : 'auswärts';
    final label = cup == null ? '' : ' im $cup';
    final score = '$goalsFor:$goalsAgainst';
    final won = goalsFor > goalsAgainst;
    final draw = goalsFor == goalsAgainst;
    final verdicts = won
        ? const [
            'Das nehme ich gern mit. Mehr davon, aber bitte ohne Herzinfarkt.',
            'Die Mannschaft war gut, der Gegner noch besser darin, uns '
                'gewinnen zu lassen.',
            'Drei Punkte sind drei Punkte. Der Rest ist Geschmackssache.',
          ]
        : draw
        ? const [
            'Ein Punkt ist ein Punkt. Gelacht wird erst, wenn es ein zweiter '
                'wird.',
            'Weder Fisch noch Fleisch, aber immerhin keine Niederlage.',
            'Das Unentschieden riecht nach verschenktem Sieg, schmeckt aber '
                'nach Pflichterfüllung.',
          ]
        : const [
            'Das war nichts. Ich sage es nur einmal laut, danach nur noch '
                'leise.',
            'Die Niederlage war verdient. Die Ausreden bitte nicht auch noch.',
            'Wir tun jetzt so, als hätten wir daraus gelernt.',
          ];
    final verdict = verdicts[seed.abs() % verdicts.length];
    final through = wentThrough == null
        ? ''
        : (wentThrough ? ' Wir sind eine Runde weiter.' : ' Wir sind raus.');
    return 'Rückblick: $score gegen $opponent ($where)$label.$through '
        '$verdict';
  }

  @override
  String get jourFixNoMatch =>
      'Rückblick: Es gab noch kein Spiel. Das Wetter war aber hervorragend.';
  @override
  String jourFixTable(int place, int teams) =>
      'Tabelle: Platz $place von $teams.';
  @override
  String jourFixAbsent(int count) => count == 0
      ? 'Ausfälle: keine. Das ist verdächtig.'
      : count == 1
      ? 'Ausfälle: 1 Spieler fehlt im nächsten Spiel.'
      : 'Ausfälle: $count Spieler fehlen im nächsten Spiel.';
  @override
  String jourFixNext(int matchday, String opponent, bool home) =>
      'Ausblick: Spieltag $matchday gegen $opponent, '
      '${home ? 'Heimspiel' : 'Auswärtsspiel'}.';
  @override
  String jourFixAppointments(String list) => 'Termine dieser Woche: $list.';
  @override
  String jourFixVacation(int total, int minTotal) =>
      'Urlaub: Erst $total von $minTotal Werktagen sind eingetragen. Das '
      'regelt der Verband, nicht ich, aber ich muss es dir sagen.';
  @override
  String vacVerdictSubject(bool kept) => kept
      ? 'Urlaubsbilanz: Vorgabe erfüllt'
      : 'Urlaubsbilanz: Verwarnung vom Verband';
  @override
  String vacVerdictBody(int total, int minTotal, int block, int minBlock) {
    final head =
        'Die Saison ist vorbei. Die Mannschaft hatte $total von $minTotal '
        'Werktagen frei, der längste Block dauerte $block Werktage '
        '(Vorgabe: $minBlock).';
    final kept = total >= minTotal && block >= minBlock;
    return kept
        ? '$head\n\nDie Vorgabe ist erfüllt. Der Verband hat nichts zu '
              'meckern, die Spieler auch nicht. Genieß den Moment.'
        : '$head\n\nDie Vorgabe ist verfehlt. Das ist eine offizielle '
              'Verwarnung. Beim nächsten Mal wird es eine Geldstrafe, und '
              'die Spieler haben es auch gemerkt.';
  }

  @override
  String get jourFixGreeting =>
      'Guten Morgen! Hier ist der wöchentliche Jour Fix, kurz und mit '
      'Kaffee:';
  @override
  String get jourFixSign => 'Mit freundlichen Grüßen, dein Präsident';
  @override
  String get courtSender => 'Kontrollausschuss des Verbands';
  @override
  String get courtAccept => 'Annehmen';
  @override
  String get courtAppeal => 'Einspruch';
  @override
  String courtSubject(String player, CourtStatus status) => switch (status) {
    CourtStatus.open => 'Strafantrag gegen $player',
    CourtStatus.accepted => 'Sperre für $player rechtskräftig',
    CourtStatus.appealed => 'Urteil des Sportgerichts: $player',
    CourtStatus.stopped => 'Verfahren gegen $player eingestellt',
  };
  @override
  String courtBody({
    required String player,
    required String kind,
    required String? competition,
    required int motion,
    required bool weeks,
    required CourtStatus status,
    int? verdict,
  }) {
    String ban(int n) => weeks
        ? (n == 1 ? '1 Woche' : '$n Wochen')
        : (n == 1 ? '1 Spiel' : '$n Spiele');
    final why = switch (kind) {
      'dogso' => 'wegen einer Notbremse',
      'rough' => 'wegen rohen Spiels',
      'violent' => 'wegen einer Tätlichkeit',
      'insult' => 'wegen Schiedsrichterbeleidigung',
      _ => 'wegen eines groben Foulspiels',
    };
    final where = competition == null
        ? 'im Ligaspiel'
        : 'im Spiel im $competition';
    final scope = weeks
        ? 'Die Sperre gilt für alle Pflichtspiele.'
        : competition == null
        ? 'Die Sperre gilt für Ligaspiele.'
        : 'Die Sperre gilt für Spiele im $competition.';
    const sign = 'Mit sportlichen Grüßen\nDer Kontrollausschuss';
    final head =
        'Sehr geehrter Herr Trainer,\n\nIhr Spieler $player wurde $where $why '
        'des Feldes verwiesen.';
    final after = verdict ?? motion;
    final outcome = after < motion
        ? 'Gute Nachricht: Die Sperre sinkt von ${ban(motion)} auf '
              '${ban(after)}.'
        : after > motion
        ? 'Das ging nach hinten los: Das Gericht erhöht die Sperre von '
              '${ban(motion)} auf ${ban(after)}.'
        : 'Das Gericht bestätigt den Antrag: ${ban(motion)} Sperre.';
    return switch (status) {
      CourtStatus.open =>
        '$head Der Kontrollausschuss beantragt eine Sperre von '
            '${ban(motion)}. $scope\n\nStimmen Sie zu, entscheidet der '
            'Einzelrichter genau so. Legen Sie Einspruch ein, verhandelt das '
            'Sportgericht. Das kann milder ausgehen, gleich oder auch härter: '
            'Das Gericht ist an unseren Antrag nicht gebunden. Bis dahin ist '
            '$player gesperrt.\n\n$sign',
      CourtStatus.accepted =>
        '$head Sie haben dem Antrag zugestimmt. $player ist für '
            '${ban(motion)} gesperrt. $scope\n\n$sign',
      CourtStatus.appealed =>
        '$head Auf Ihren Einspruch hin hat das Sportgericht verhandelt. '
            '$outcome $scope\n\n$sign',
      CourtStatus.stopped =>
        '$head Die Auswertung der Bilder zeigt: Der Schiedsrichter hat den '
            'falschen Spieler vom Platz gestellt. Das Verfahren ist '
            'eingestellt, $player ist nicht gesperrt.\n\n$sign',
    };
  }

  @override
  String cupName(Competition competition) =>
      competition == Competition.pott ? 'Pott der Provinz' : 'Bolzplatzpokal';
  @override
  String cupRoundName(bool isFinal, int round) =>
      isFinal ? 'Finale' : 'Runde ${round + 1}';
  @override
  String matchShootoutLine(String winner, int home, int away) =>
      'Elfmeterschießen entschieden: $winner gewinnt mit $home:$away. '
      'Die Nerven waren heute nicht im Preis inbegriffen.';
  @override
  String get confCupTab => 'Pokal';

  @override
  String get confTabLive => 'Live';

  @override
  String get confTabResults => 'Ergebnisse';

  @override
  String get confTabTable => 'Tabelle';

  @override
  String get confNoLive => 'Alles abgepfiffen. Hier läuft nichts mehr.';

  @override
  String get confNoResults => 'Noch nichts abgepfiffen. Geduld.';

  @override
  String get confGoalsShort => 'Tore';

  @override
  String get confDiffShort => 'Diff.';

  @override
  String confKickoffAt(String time) => 'Anstoß $time';
  @override
  String get matchReportExtraTime => 'nach Verlängerung';
  @override
  String matchReportShootout(int home, int away) =>
      'im Elfmeterschießen $home:$away';
  @override
  String get matchReportThrough => 'Du bist eine Runde weiter!';
  @override
  String get matchReportOut =>
      'Ausgeschieden. Der Pokal bleibt ein schönes Wort.';
  @override
  String get savesTitle => 'Spielstände';
  @override
  String get savesAuto => 'Autospeicher';
  @override
  String savesSlot(String slot) => 'Platz $slot';
  @override
  String get savesEmpty => 'Leer. Hier passt noch eine Karriere rein.';
  @override
  String get savesUnreadable =>
      'Nicht lesbar: andere Version oder beschädigt. Die Datei bleibt liegen.';
  @override
  String savesLine1(String trainer, String club) => '$trainer bei $club';
  @override
  String savesLiveHint(int minute) => 'Ein Spiel läuft: Minute $minute.';
  @override
  String savesLine2(String league, String date, int matchday, int matchdays) =>
      '$league · $date · Spieltag $matchday von $matchdays gespielt';
  @override
  String savesSavedAt(String stamp) => 'Gespeichert am $stamp';
  @override
  String get savesSave => 'Speichern';
  @override
  String get savesLoad => 'Laden';
  @override
  String get savesDelete => 'Löschen';
  @override
  String get savesCancel => 'Abbrechen';
  @override
  String get savesOverwriteTitle => 'Spielstand überschreiben?';
  @override
  String get savesOverwriteText =>
      'Auf diesem Platz liegt schon eine Karriere. Die ist danach weg.';
  @override
  String get savesDeleteTitle => 'Spielstand löschen?';
  @override
  String get savesDeleteText => 'Weg ist weg. Das gibt es kein Zurück.';
  @override
  String get savesDone => 'Gespeichert.';
  @override
  String get savesLoadFailed =>
      'Der Spielstand passt nicht zu dieser Welt. Er bleibt unberührt.';
  @override
  String get savesLoading => 'Dein Spielstand wird nachgespielt …';
  @override
  String get savesSettings => 'Einstellungen';
  @override
  String get savesNothingToLoad =>
      'Noch kein Spielstand. Erst Karriere starten, dann gibt es etwas zu laden.';
  @override
  String get infoSaves =>
      'Der Autospeicher wird nach jedem Tag und jedem Spiel überschrieben, du musst nichts tun. Auf den Plätzen 1 bis 3 sicherst du Stände, die bleiben, bis du sie überschreibst. Gespeichert wird nur im Büro, nie mitten im Spiel: Erst abpfeifen, dann speichern. Beim Laden spielt das Spiel deine Karriere kurz im Hintergrund nach, das dauert einen Moment.';
}

/// The strings in use. Later this follows a setting in the settings screen.
final stringsProvider = Provider<AppStrings>((ref) => const AppStringsDe());
