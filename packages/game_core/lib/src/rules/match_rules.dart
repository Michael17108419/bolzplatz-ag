import '../model/attribute.dart';
import '../model/position.dart';
import '../model/special_ability.dart';
import 'rules.dart';

double _d(Object? v) => (v! as num).toDouble();

Map<String, double> _numbers(Object? raw) => Map.unmodifiable({
  for (final e in (raw! as Map<String, dynamic>).entries)
    if (e.value is num) e.key: _d(e.value),
});

List<Attribute> _attributes(Object? raw) => List.unmodifiable([
  for (final id in raw! as List<dynamic>)
    Attribute.values.firstWhere(
      (a) => a.id == id,
      orElse: () => throw RulesError('Unknown attribute $id'),
    ),
]);

List<SpecialAbilityType> _abilities(Object? raw) => List.unmodifiable([
  for (final id in raw! as List<dynamic>)
    SpecialAbilityType.values.firstWhere(
      (a) => a.id == id,
      orElse: () => throw RulesError('Unknown ability $id'),
    ),
]);

/// One kind of shot.
class ShotTypeRule {
  const ShotTypeRule({
    required this.id,
    required this.weight,
    required this.goalBase,
    required this.attributes,
    required this.abilities,
  });

  final String id;

  /// Relative frequency before the shooter's skill is taken into account.
  final double weight;

  /// Goal chance of an average chance with an even duel.
  final double goalBase;
  final List<Attribute> attributes;
  final List<SpecialAbilityType> abilities;
}

/// Effects of one level of a slider. Keys are effect names, `scaled` lists
/// the keys that grow with the fit of the squad.
class SliderLevelEffect {
  const SliderLevelEffect({required this.values, required this.scaled});

  final Map<String, double> values;
  final Set<String> scaled;
}

/// Numbers of the match simulation, read from the `match` section.
class MatchRules {
  const MatchRules({
    required this.minutes,
    required this.halfTimeMinute,
    required this.phasesPerMatch,
    required this.tempoPhaseFactor,
    required this.homeAdvantage,
    required this.possessionExponent,
    required this.breakthroughBase,
    required this.breakthroughExponent,
    required this.breakthroughMin,
    required this.breakthroughMax,
    required this.qualityWeights,
    required this.qualityGoalMult,
    required this.goalExponent,
    required this.goalMin,
    required this.goalMax,
    required this.shotTypes,
    required this.blockedShare,
    required this.offTargetShare,
    required this.shooterSlotWeight,
    required this.keeperAttributes,
    required this.freeKicksPerMatch,
    required this.cornersPerMatch,
    required this.penaltiesPerMatch,
    required this.freeKickDirectShare,
    required this.freeKickDirectGoal,
    required this.freeKickCrossGoal,
    required this.cornerGoal,
    required this.penaltyGoal,
    required this.takerAttributes,
    required this.cornerTakerAttributes,
    required this.penaltyAttributes,
    required this.standardAbilityBonus,
    required this.yellowPerMinutePerTeam,
    required this.straightRedPerMinute,
    required this.redCardStrength,
    required this.injuryPerPlayerMinute,
    required this.injuryFatigueFactor,
    required this.injurySeverityWeights,
    required this.injuryDays,
    required this.missingPlayerStrength,
    required this.fatigueStartMinute,
    required this.fatigueScale,
    required this.staminaReference,
    required this.staminaMinFactor,
    required this.staminaMaxFactor,
    required this.baseDrain,
    required this.energyLossPerMinute,
    required this.formMinFactor,
    required this.formMaxFactor,
    required this.defaultForm,
    required this.momentumGoalFor,
    required this.momentumGoalAgainst,
    required this.momentumDecay,
    required this.momentumEffect,
    required this.counterDominanceScale,
    required this.sliders,
    required this.sliderFitReference,
    required this.sliderFitDivisor,
    required this.sliderFitSlope,
    required this.sliderScaleMin,
    required this.sliderScaleMax,
    required this.aiSubTrailingMinute,
    required this.aiSubTiredMinute,
    required this.aiTiredEnergy,
    required this.aiCheckInterval,
    required this.aiAttackWhenTrailingMinute,
    required this.attackRateReference,
    required this.abilityShotBonus,
    required this.ratingAttributes,
    required this.ratingPositions,
  });

  factory MatchRules.fromJson(Map<String, dynamic> m) {
    final bt = m['breakthrough'] as Map<String, dynamic>;
    final quality = m['quality'] as Map<String, dynamic>;
    const qualityOrder = ['half', 'chance', 'big'];
    final goal = m['goal'] as Map<String, dynamic>;
    final shotTypes = [
      for (final raw in m['shot_types'] as List<dynamic>)
        _shotType(raw as Map<String, dynamic>),
    ];
    if (shotTypes.length != 6) {
      throw const RulesError('match.shot_types needs six shot types');
    }
    final outcome = m['shot_outcome'] as Map<String, dynamic>;
    final slotWeights = <Position, double>{};
    final slotRaw = m['shooter_slot_weight'] as Map<String, dynamic>;
    for (final p in Position.values) {
      final v = slotRaw[p.id];
      if (v == null) throw RulesError('shooter_slot_weight misses ${p.id}');
      slotWeights[p] = _d(v);
    }
    final st = m['standards'] as Map<String, dynamic>;
    final cards = m['cards'] as Map<String, dynamic>;
    final inj = m['injuries'] as Map<String, dynamic>;
    final fat = m['fatigue'] as Map<String, dynamic>;
    final form = m['form'] as Map<String, dynamic>;
    final mom = m['momentum'] as Map<String, dynamic>;
    final sliderFit = m['slider_fit'] as Map<String, dynamic>;
    final ai = m['ai'] as Map<String, dynamic>;
    final rating = m['team_rating'] as Map<String, dynamic>;
    final severity = [
      for (final w in inj['severity_weights'] as List<dynamic>) _d(w),
    ];
    if (severity.length != 3) {
      throw const RulesError('injuries.severity_weights needs three values');
    }
    List<int> days(String key) => List.unmodifiable([
      for (final v in inj[key] as List<dynamic>) v as int,
    ]);

    final sliders = <String, Map<String, SliderLevelEffect>>{};
    final slidersRaw = m['sliders'] as Map<String, dynamic>;
    for (final entry in slidersRaw.entries) {
      final levels = <String, SliderLevelEffect>{};
      for (final level in (entry.value as Map<String, dynamic>).entries) {
        final raw = level.value as Map<String, dynamic>;
        levels[level.key] = SliderLevelEffect(
          values: _numbers(raw),
          scaled: Set.unmodifiable(
            ((raw['scaled'] as List<dynamic>?) ?? const <dynamic>[])
                .cast<String>(),
          ),
        );
      }
      sliders[entry.key] = Map.unmodifiable(levels);
    }

    final result = MatchRules(
      minutes: m['minutes'] as int,
      halfTimeMinute: m['half_time_minute'] as int,
      phasesPerMatch: _d(m['phases_per_match']),
      tempoPhaseFactor: _numbers(m['tempo_phase_factor']),
      homeAdvantage: _d(m['home_advantage']),
      possessionExponent: _d(m['possession_exponent']),
      breakthroughBase: _d(bt['base']),
      breakthroughExponent: _d(bt['exponent']),
      breakthroughMin: _d(bt['min']),
      breakthroughMax: _d(bt['max']),
      qualityWeights: List.unmodifiable([
        for (final k in qualityOrder)
          _d((quality[k] as Map<String, dynamic>)['weight']),
      ]),
      qualityGoalMult: List.unmodifiable([
        for (final k in qualityOrder)
          _d((quality[k] as Map<String, dynamic>)['goal_mult']),
      ]),
      goalExponent: _d(goal['exponent']),
      goalMin: _d(goal['min']),
      goalMax: _d(goal['max']),
      shotTypes: List.unmodifiable(shotTypes),
      blockedShare: _d(outcome['blocked']),
      offTargetShare: _d(outcome['off_target']),
      shooterSlotWeight: Map.unmodifiable(slotWeights),
      keeperAttributes: _attributes(m['keeper_attributes']),
      freeKicksPerMatch: _d(st['free_kicks_per_match']),
      cornersPerMatch: _d(st['corners_per_match']),
      penaltiesPerMatch: _d(st['penalties_per_match']),
      freeKickDirectShare: _d(st['free_kick_direct_share']),
      freeKickDirectGoal: _d(st['free_kick_direct_goal']),
      freeKickCrossGoal: _d(st['free_kick_cross_goal']),
      cornerGoal: _d(st['corner_goal']),
      penaltyGoal: _d(st['penalty_goal']),
      takerAttributes: _attributes(st['taker_attributes']),
      cornerTakerAttributes: _attributes(st['corner_taker_attributes']),
      penaltyAttributes: _attributes(st['penalty_attributes']),
      standardAbilityBonus: _d(st['ability_bonus']),
      yellowPerMinutePerTeam: _d(cards['yellow_per_minute_per_team']),
      straightRedPerMinute: _d(cards['straight_red_per_minute']),
      redCardStrength: _d(cards['red_card_strength']),
      injuryPerPlayerMinute: _d(inj['per_player_per_minute']),
      injuryFatigueFactor: _d(inj['fatigue_factor']),
      injurySeverityWeights: List.unmodifiable(severity),
      injuryDays: List.unmodifiable([
        days('days_light'),
        days('days_medium'),
        days('days_heavy'),
      ]),
      missingPlayerStrength: _d(inj['missing_player_strength']),
      fatigueStartMinute: fat['start_minute'] as int,
      fatigueScale: _d(fat['scale']),
      staminaReference: _d(fat['stamina_reference']),
      staminaMinFactor: _d(fat['stamina_min_factor']),
      staminaMaxFactor: _d(fat['stamina_max_factor']),
      baseDrain: _d(fat['base_drain']),
      energyLossPerMinute: _d(fat['energy_loss_per_minute']),
      formMinFactor: _d(form['min_factor']),
      formMaxFactor: _d(form['max_factor']),
      defaultForm: _d(form['default_form']),
      momentumGoalFor: _d(mom['goal_for']),
      momentumGoalAgainst: _d(mom['goal_against']),
      momentumDecay: _d(mom['decay']),
      momentumEffect: _d(mom['effect']),
      counterDominanceScale: _d(
        (m['attack_matchup']
            as Map<String, dynamic>)['counter_dominance_scale'],
      ),
      sliders: Map.unmodifiable(sliders),
      sliderFitReference: _d(sliderFit['reference']),
      sliderFitDivisor: _d(sliderFit['divisor']),
      sliderFitSlope: _d(sliderFit['slope']),
      sliderScaleMin: _d(sliderFit['scale_min']),
      sliderScaleMax: _d(sliderFit['scale_max']),
      aiSubTrailingMinute: ai['sub_trailing_minute'] as int,
      aiSubTiredMinute: ai['sub_tired_minute'] as int,
      aiTiredEnergy: _d(ai['tired_energy']),
      aiCheckInterval: ai['check_interval'] as int,
      aiAttackWhenTrailingMinute: ai['attack_when_trailing_minute'] as int,
      attackRateReference: _d(m['attack_rate_reference']),
      abilityShotBonus: _d(m['ability_shot_bonus']),
      ratingAttributes: Map.unmodifiable({
        for (final e in rating.entries)
          e.key: _attributes((e.value as Map<String, dynamic>)['attributes']),
      }),
      ratingPositions: Map.unmodifiable({
        for (final e in rating.entries)
          e.key: List<Position>.unmodifiable([
            for (final id in (e.value as Map<String, dynamic>)['positions']
                as List<dynamic>)
              Position.values.firstWhere(
                (p) => p.id == id,
                orElse: () => throw RulesError('Unknown position $id'),
              ),
          ]),
      }),
    );
    result._validate();
    return result;
  }

  static ShotTypeRule _shotType(Map<String, dynamic> m) => ShotTypeRule(
    id: m['id'] as String,
    weight: _d(m['weight']),
    goalBase: _d(m['goal_base']),
    attributes: _attributes(m['attributes']),
    abilities: _abilities(m['abilities']),
  );

  void _validate() {
    if (minutes <= 0 || halfTimeMinute <= 0 || halfTimeMinute >= minutes) {
      throw const RulesError('match.minutes or half_time_minute invalid');
    }
    if (phasesPerMatch <= 0) {
      throw const RulesError('match.phases_per_match must be positive');
    }
    for (final key in ['patient', 'normal', 'fast']) {
      if (tempoPhaseFactor[key] == null) {
        throw RulesError('tempo_phase_factor misses $key');
      }
    }
    if (breakthroughMin >= breakthroughMax || goalMin >= goalMax) {
      throw const RulesError('min must be below max');
    }
    if (blockedShare + offTargetShare >= 1) {
      throw const RulesError('shot_outcome shares must stay below 1');
    }
    for (final name in ['pressing', 'tempo', 'defensive_line']) {
      final levels = sliders[name];
      if (levels == null || levels.length != 3) {
        throw RulesError('match.sliders.$name needs three levels');
      }
    }
    if (qualityWeights.any((w) => w <= 0)) {
      throw const RulesError('quality weights must be positive');
    }
  }

  final int minutes;
  final int halfTimeMinute;

  /// Open-play possession phases per match at normal tempo.
  final double phasesPerMatch;
  final Map<String, double> tempoPhaseFactor;
  final double homeAdvantage;
  final double possessionExponent;
  final double breakthroughBase;
  final double breakthroughExponent;
  final double breakthroughMin;
  final double breakthroughMax;

  /// Weights and goal multipliers for half chance, chance, big chance.
  final List<double> qualityWeights;
  final List<double> qualityGoalMult;
  final double goalExponent;
  final double goalMin;
  final double goalMax;
  final List<ShotTypeRule> shotTypes;
  final double blockedShare;
  final double offTargetShare;
  final Map<Position, double> shooterSlotWeight;
  final List<Attribute> keeperAttributes;
  final double freeKicksPerMatch;
  final double cornersPerMatch;
  final double penaltiesPerMatch;
  final double freeKickDirectShare;
  final double freeKickDirectGoal;
  final double freeKickCrossGoal;
  final double cornerGoal;
  final double penaltyGoal;
  final List<Attribute> takerAttributes;
  final List<Attribute> cornerTakerAttributes;
  final List<Attribute> penaltyAttributes;
  final double standardAbilityBonus;
  final double yellowPerMinutePerTeam;
  final double straightRedPerMinute;
  final double redCardStrength;
  final double injuryPerPlayerMinute;
  final double injuryFatigueFactor;
  final List<double> injurySeverityWeights;

  /// Day ranges [min, max] for light, medium and heavy injuries.
  final List<List<int>> injuryDays;
  final double missingPlayerStrength;
  final int fatigueStartMinute;
  final double fatigueScale;
  final double staminaReference;
  final double staminaMinFactor;
  final double staminaMaxFactor;
  final double baseDrain;
  final double energyLossPerMinute;
  final double formMinFactor;
  final double formMaxFactor;
  final double defaultForm;
  final double momentumGoalFor;
  final double momentumGoalAgainst;
  final double momentumDecay;
  final double momentumEffect;
  final double counterDominanceScale;

  /// Slider name to level name to effects.
  final Map<String, Map<String, SliderLevelEffect>> sliders;
  final double sliderFitReference;
  final double sliderFitDivisor;
  final double sliderFitSlope;
  final double sliderScaleMin;
  final double sliderScaleMax;
  final int aiSubTrailingMinute;
  final int aiSubTiredMinute;
  final double aiTiredEnergy;
  final int aiCheckInterval;
  final int aiAttackWhenTrailingMinute;

  /// Attack probability per minute that the system `rate` effects refer to.
  final double attackRateReference;

  /// Relative shot quality bonus per unit of the ability tier multiplier.
  final double abilityShotBonus;

  /// Attributes and positions of the groups `build`, `attack`, `defense`
  /// and `duel_header`.
  final Map<String, List<Attribute>> ratingAttributes;
  final Map<String, List<Position>> ratingPositions;
}
