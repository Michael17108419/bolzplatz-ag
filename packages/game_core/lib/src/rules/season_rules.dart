import 'rules.dart';

/// Numbers for the cups.
class CupRules {
  const CupRules({
    required this.bolzplatzAfterMatchday,
    required this.pottAfterMatchday,
    required this.bolzplatzFieldSize,
    required this.bolzplatzLowerGroupSize,
    required this.yearOneFourthLeaguePlaces,
    required this.thirdLeaguePlaces,
    required this.pottPlacesPerRegion,
    required this.pottExtraPlaces,
    required this.pottBracketSize,
    required this.extraTimeHalfMinutes,
  });

  factory CupRules.fromJson(Map<String, dynamic> m) {
    List<int> days(String key) =>
        List.unmodifiable([for (final v in m[key] as List<dynamic>) v as int]);
    final rules = CupRules(
      bolzplatzAfterMatchday: days('bolzplatz_after_matchday'),
      pottAfterMatchday: days('pott_after_matchday'),
      bolzplatzFieldSize: m['bolzplatz_field_size'] as int,
      bolzplatzLowerGroupSize: m['bolzplatz_lower_group_size'] as int,
      yearOneFourthLeaguePlaces:
          m['bolzplatz_year_one_fourth_league_places'] as int,
      thirdLeaguePlaces: m['bolzplatz_third_league_places'] as int,
      pottPlacesPerRegion: m['pott_places_per_region'] as int,
      pottExtraPlaces: m['pott_extra_places'] as int,
      pottBracketSize: m['pott_bracket_size'] as int,
      extraTimeHalfMinutes: m['extra_time_half_minutes'] as int,
    );
    if (rules.bolzplatzFieldSize != 64 ||
        rules.bolzplatzAfterMatchday.length != 6) {
      throw const RulesError('Bolzplatzpokal needs 64 teams and 6 rounds');
    }
    if (rules.pottAfterMatchday.length != 5 || rules.pottBracketSize != 32) {
      throw const RulesError('Pott der Provinz needs a 32 bracket, 5 rounds');
    }
    return rules;
  }

  /// League matchday after which each cup round is played.
  final List<int> bolzplatzAfterMatchday;
  final List<int> pottAfterMatchday;
  final int bolzplatzFieldSize;

  /// Clubs of the lower group in round 1 of the Bolzplatzpokal.
  final int bolzplatzLowerGroupSize;

  /// Places for fourth-league clubs in the first season (drawn).
  final int yearOneFourthLeaguePlaces;

  /// Places for the best clubs of the third league from the second season.
  final int thirdLeaguePlaces;
  final int pottPlacesPerRegion;
  final int pottExtraPlaces;
  final int pottBracketSize;
  final int extraTimeHalfMinutes;
}

/// Numbers for the course of a season.
class SeasonRules {
  const SeasonRules({
    required this.injuryDaysPerMatchday,
    required this.suspensionYellowCards,
    required this.formWin,
    required this.formLoss,
    required this.formDrift,
    required this.cups,
  });

  factory SeasonRules.fromJson(Map<String, dynamic> m) => SeasonRules(
    injuryDaysPerMatchday: (m['injury_days_per_matchday'] as num).toDouble(),
    suspensionYellowCards: m['suspension_yellow_cards'] as int,
    formWin: (m['form_win'] as num).toDouble(),
    formLoss: (m['form_loss'] as num).toDouble(),
    formDrift: (m['form_drift'] as num).toDouble(),
    cups: CupRules.fromJson(m['cups'] as Map<String, dynamic>),
  );

  /// One matchday stands for this many days of recovery.
  final double injuryDaysPerMatchday;
  final int suspensionYellowCards;
  final double formWin;
  final double formLoss;
  final double formDrift;
  final CupRules cups;
}
