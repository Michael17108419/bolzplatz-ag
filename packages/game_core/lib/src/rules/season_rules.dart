import '../training/training.dart';
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
    required this.review,
    required this.court,
    required this.cabin,
    required this.condition,
    this.training = const TrainingRules(units: {}, templates: {}, values: {}),
  });

  factory SeasonRules.fromJson(Map<String, dynamic> m) => SeasonRules(
    injuryDaysPerMatchday: (m['injury_days_per_matchday'] as num).toDouble(),
    suspensionYellowCards: m['suspension_yellow_cards'] as int,
    formWin: (m['form_win'] as num).toDouble(),
    formLoss: (m['form_loss'] as num).toDouble(),
    formDrift: (m['form_drift'] as num).toDouble(),
    cups: CupRules.fromJson(m['cups'] as Map<String, dynamic>),
    review: ReviewRules.fromJson(m['review'] as Map<String, dynamic>),
    court: CourtRules.fromJson(m['court'] as Map<String, dynamic>),
    cabin: CabinRules.fromJson(m['cabin'] as Map<String, dynamic>),
    condition: ConditionRules.fromJson(m['condition'] as Map<String, dynamic>),
    training: TrainingRules.fromJson(m['training'] as Map<String, dynamic>?),
  );

  /// One matchday stands for this many days of recovery.
  final double injuryDaysPerMatchday;
  final int suspensionYellowCards;

  final double formWin;
  final double formLoss;
  final double formDrift;
  final CupRules cups;
  final ReviewRules review;

  /// The sports court after a straight red (engine 2, step 10e3).
  final CourtRules court;

  /// Types and the dressing room (engine 2, step 10f1).
  final CabinRules cabin;

  /// Form, confidence, load and match ratings (engine 2, step 10f2).
  final ConditionRules condition;

  /// Training units, templates and freshness (step 11a).
  final TrainingRules training;
}

/// How a player's condition moves from match to match (engine 2, step
/// 10f2): a rating per match from what he did (`rating_*`, 0 to 10 around
/// [ratingBase]), form as a running mean of the ratings, confidence that
/// jumps with the rating and settles back, and the load of the last weeks
/// that makes injuries likelier.
class ConditionRules {
  const ConditionRules(this._v);

  factory ConditionRules.fromJson(Map<String, dynamic> m) {
    final v = <String, double>{};
    for (final e in m.entries) {
      final raw = e.value;
      if (raw is! num) throw RulesError('season.condition.${e.key} invalid');
      v[e.key] = raw.toDouble();
    }
    for (final k in [
      'form_weight',
      'rating_to_form',
      'confidence_from_rating',
      'confidence_decay',
      'load_half_days',
      'load_reference',
      'load_injury',
      'min_minutes_rating',
      'rating_base',
    ]) {
      if (!v.containsKey(k)) throw RulesError('season.condition.$k missing');
    }
    return ConditionRules(Map.unmodifiable(v));
  }

  final Map<String, double> _v;

  /// A value by key (`rating_goal`, `load_injury` …), 0 if missing.
  double operator [](String key) => _v[key] ?? 0;
}

/// Thresholds of the types and numbers of the dressing room (engine 2,
/// step 10f1, Doc 06): "high", "low" and "extreme" of a trait; the weights
/// of the rank; the size of the council; how captain, council and
/// conflicts move the mood of the room.
class CabinRules {
  const CabinRules(this._v);

  factory CabinRules.fromJson(Map<String, dynamic> m) {
    const keys = [
      'high',
      'low',
      'extreme',
      'rank_leadership',
      'rank_age',
      'rank_years',
      'rank_strength',
      'council_size',
      'captain_fit',
      'captain_weak',
      'council_professionalism',
      'power_struggle',
      'party_council',
      'mercenary_council',
      'diva_outside',
    ];
    final v = <String, double>{};
    for (final k in keys) {
      final raw = m[k];
      if (raw is! num) throw RulesError('season.cabin.$k is missing');
      v[k] = raw.toDouble();
    }
    return CabinRules(Map.unmodifiable(v));
  }

  final Map<String, double> _v;

  double get high => _v['high']!;
  double get low => _v['low']!;
  double get extreme => _v['extreme']!;
  double get rankLeadership => _v['rank_leadership']!;
  double get rankAge => _v['rank_age']!;
  double get rankYears => _v['rank_years']!;
  double get rankStrength => _v['rank_strength']!;
  int get councilSize => _v['council_size']!.round();
  double get captainFit => _v['captain_fit']!;
  double get captainWeak => _v['captain_weak']!;
  double get councilProfessionalism => _v['council_professionalism']!;
  double get powerStruggle => _v['power_struggle']!;
  double get partyCouncil => _v['party_council']!;
  double get mercenaryCouncil => _v['mercenary_council']!;
  double get divaOutside => _v['diva_outside']!;
}

/// The range of a ban for one kind of red card: matches of the competition
/// or weeks on the calendar (DFB Rechts- und Verfahrensordnung).
class BanRange {
  const BanRange({required this.weeks, required this.min, required this.max});

  factory BanRange.fromJson(Map<String, dynamic> m) {
    final unit = m['unit'] as String;
    if (unit != 'matches' && unit != 'weeks') {
      throw RulesError('court unit must be matches or weeks, not $unit');
    }
    final range = BanRange(
      weeks: unit == 'weeks',
      min: m['min'] as int,
      max: m['max'] as int,
    );
    if (range.min < 1 || range.max < range.min) {
      throw const RulesError('court ban range invalid');
    }
    return range;
  }

  /// True for a ban in weeks, false for one in matches.
  final bool weeks;
  final int min;
  final int max;
}

/// The sports court after a straight red card (engine 2, step 10e3): the
/// ban by kind of the red card, how often a red card is of which kind when
/// the match does not tell, and how an appeal goes. A red the referee gave
/// too hard has better chances; the court is not bound to the motion, so an
/// appeal can also make it worse.
class CourtRules {
  const CourtRules({
    required this.bans,
    required this.kindWeights,
    required this.appealLower,
    required this.appealHigher,
    required this.harshLower,
    required this.harshHigher,
  });

  factory CourtRules.fromJson(Map<String, dynamic> m) {
    const kinds = ['dogso', 'rough', 'violent', 'insult', 'other'];
    final weights = m['kind_weights'] as Map<String, dynamic>;
    return CourtRules(
      bans: Map.unmodifiable({
        for (final k in kinds)
          k: BanRange.fromJson(m[k] as Map<String, dynamic>),
      }),
      kindWeights: Map.unmodifiable({
        for (final e in weights.entries) e.key: (e.value as num).toDouble(),
      }),
      appealLower: (m['appeal_lower'] as num).toDouble(),
      appealHigher: (m['appeal_higher'] as num).toDouble(),
      harshLower: (m['harsh_lower'] as num).toDouble(),
      harshHigher: (m['harsh_higher'] as num).toDouble(),
    );
  }

  /// Ban range by kind: dogso (Notbremse), rough, violent, insult, other.
  final Map<String, BanRange> bans;

  /// Kinds of a straight red without a told reason, by weight.
  final Map<String, double> kindWeights;
  final double appealLower;
  final double appealHigher;
  final double harshLower;
  final double harshHigher;

  BanRange banFor(String? kind) => bans[kind] ?? bans['other']!;
}

/// Numbers for the verdict on a season (document 13, drafts for mass tests).
class ReviewRules {
  const ReviewRules({
    required this.titleMissedMaxGap,
    required this.promotionMissedMaxGap,
    required this.survivalMissedMaxGap,
    required this.missedBase,
    required this.missedPerPlace,
    required this.failedBase,
    required this.failedPerPlace,
    required this.trustWeight,
    required this.moodWeight,
    required this.maxRisk,
  });

  factory ReviewRules.fromJson(Map<String, dynamic> m) => ReviewRules(
    titleMissedMaxGap: m['title_missed_max_gap'] as int,
    promotionMissedMaxGap: m['promotion_missed_max_gap'] as int,
    survivalMissedMaxGap: m['survival_missed_max_gap'] as int,
    missedBase: (m['missed_base'] as num).toDouble(),
    missedPerPlace: (m['missed_per_place'] as num).toDouble(),
    failedBase: (m['failed_base'] as num).toDouble(),
    failedPerPlace: (m['failed_per_place'] as num).toDouble(),
    trustWeight: (m['trust_weight'] as num).toDouble(),
    moodWeight: (m['mood_weight'] as num).toDouble(),
    maxRisk: (m['max_risk'] as num).toDouble(),
  );

  /// Places by which a goal may be missed and still count as "missed"
  /// (further off is "failed").
  final int titleMissedMaxGap;
  final int promotionMissedMaxGap;
  final int survivalMissedMaxGap;

  /// Dismissal risk: base plus a part per place missed.
  final double missedBase;
  final double missedPerPlace;
  final double failedBase;
  final double failedPerPlace;

  /// How strongly a distrustful president and a sour squad raise the risk.
  final double trustWeight;
  final double moodWeight;
  final double maxRisk;
}
