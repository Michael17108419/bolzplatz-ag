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

/// The pitch as a grid of zones (engine 2): [columns] from the own goal to
/// the goal of the opponent, [lanes] left, centre and right, always seen
/// from the team that has the ball.
class ZoneRules {
  const ZoneRules({
    required this.startColumnWeights,
    required this.stepShare,
    required this.stepMin,
    required this.stepMax,
    required this.duelExponent,
    required this.duelRatioMin,
    required this.duelRatioMax,
    required this.laneChange,
    required this.laneWeights,
    required this.laneSame,
    required this.laneAdjacent,
    required this.laneFar,
    required this.centreOnWing,
    required this.shooterLaneExponent,
    required this.ballWonEventFromColumn,
    required this.columnWeights,
  });

  factory ZoneRules.fromJson(Map<String, dynamic> m) {
    List<double> numbers(Object? raw, int length, String name) {
      final list = [for (final v in raw! as List<dynamic>) _d(v)];
      if (list.length != length) {
        throw RulesError('match.zones.$name needs $length values');
      }
      if (list.any((v) => v < 0)) {
        throw RulesError('match.zones.$name must not be negative');
      }
      return List.unmodifiable(list);
    }

    final lanes = m['lane_weights'] as Map<String, dynamic>;
    if (!lanes.containsKey('default')) {
      throw const RulesError('match.zones.lane_weights needs "default"');
    }
    final factor = m['lane_factor'] as Map<String, dynamic>;
    final columnsRaw = m['column_weights'] as Map<String, dynamic>;
    final columnWeights = <Position, List<double>>{};
    for (final p in Position.values) {
      final raw = columnsRaw[p.id];
      if (raw == null) throw RulesError('match.zones misses ${p.id}');
      columnWeights[p] = numbers(raw, columns, 'column_weights.${p.id}');
    }
    final result = ZoneRules(
      startColumnWeights: numbers(
        m['start_column_weights'],
        columns,
        'start_column_weights',
      ),
      stepShare: numbers(m['step_share'], columns - 1, 'step_share'),
      stepMin: _d(m['step_min']),
      stepMax: _d(m['step_max']),
      duelExponent: _d(m['duel_exponent']),
      duelRatioMin: _d(m['duel_ratio_min']),
      duelRatioMax: _d(m['duel_ratio_max']),
      laneChange: _d(m['lane_change']),
      laneWeights: Map.unmodifiable({
        for (final e in lanes.entries)
          e.key: numbers(e.value, ZoneRules.lanes, 'lane_weights.${e.key}'),
      }),
      laneSame: _d(factor['same']),
      laneAdjacent: _d(factor['adjacent']),
      laneFar: _d(factor['far']),
      centreOnWing: _d(factor['centre_on_wing']),
      shooterLaneExponent: _d(m['shooter_lane_exponent']),
      ballWonEventFromColumn: (m['ball_won_event_from_column'] as num).toInt(),
      columnWeights: Map.unmodifiable(columnWeights),
    );
    if (result.startColumnWeights.last != 0) {
      throw const RulesError('match.zones: no attack starts in the last zone');
    }
    if (result.stepShare.any((s) => s <= 0)) {
      throw const RulesError('match.zones.step_share must be positive');
    }
    if (result.stepMin <= 0 || result.stepMin >= result.stepMax) {
      throw const RulesError('match.zones.step_min must be below step_max');
    }
    if (result.duelRatioMin <= 0 || result.duelRatioMin > result.duelRatioMax) {
      throw const RulesError('match.zones.duel_ratio_min/max invalid');
    }
    return result;
  }

  /// Number of columns from the own goal (0) to the goal of the opponent.
  static const int columns = 5;

  /// Number of lanes: left (0), centre (1), right (2).
  static const int lanes = 3;

  /// Where attacks start (the last column must be zero).
  final List<double> startColumnWeights;

  /// Share of the breakthrough chance that each step from column c to c + 1
  /// carries (as an exponent): the steps of one attack multiply to the
  /// breakthrough chance of the team.
  final List<double> stepShare;
  final double stepMin;
  final double stepMax;

  /// How strongly the duel of the two players bends one step.
  final double duelExponent;
  final double duelRatioMin;
  final double duelRatioMax;

  /// Chance that the ball changes the lane in one step.
  final double laneChange;

  /// Lane weights at the start of an attack by system id (`default` for
  /// systems without an own entry).
  final Map<String, List<double>> laneWeights;
  final double laneSame;
  final double laneAdjacent;
  final double laneFar;

  /// Weight of a central position on a wing lane.
  final double centreOnWing;
  final double shooterLaneExponent;

  /// Lost balls from this column on are written as events.
  final int ballWonEventFromColumn;

  /// How much each position is involved in each column (own view).
  final Map<Position, List<double>> columnWeights;

  /// Sum of the step shares from [column] to the last column.
  double shareFrom(int column) {
    var sum = 0.0;
    for (var c = column; c < columns - 1; c++) {
      sum += stepShare[c];
    }
    return sum;
  }

  /// Mean share of a normal attack over its start columns. An attack that
  /// starts further up (a counter) needs fewer steps and has a better chance
  /// than the team's breakthrough chance.
  double get referenceShare {
    var sum = 0.0;
    var total = 0.0;
    for (var c = 0; c < columns; c++) {
      sum += startColumnWeights[c] * shareFrom(c);
      total += startColumnWeights[c];
    }
    return sum / total;
  }

  /// Lane weights at the start of an attack for the system [systemId].
  List<double> lanesFor(String systemId) =>
      laneWeights[systemId] ?? laneWeights['default']!;

  /// How much a player on [position] is involved in [lane] (own view).
  double laneFactor(Position position, int lane) {
    final side = position.wideSide;
    if (side == null) return lane == 1 ? laneSame : centreOnWing;
    final home = side == Foot.left ? 0 : 2;
    final distance = (home - lane).abs();
    return distance == 0
        ? laneSame
        : distance == 1
        ? laneAdjacent
        : laneFar;
  }
}

/// One thing the player on the ball can do in a zone (engine 2).
class ActionRule {
  const ActionRule({
    required this.id,
    required this.advance,
    required this.risk,
    required this.weights,
    required this.lanes,
    required this.attack,
    required this.defend,
    required this.abilities,
    required this.defendAbilities,
    required this.selfShot,
    required this.shotBias,
  });

  factory ActionRule.fromJson(Map<String, dynamic> m) {
    final id = m['id'] as String;
    List<double> numbers(String key, int length) {
      final list = [for (final v in m[key] as List<dynamic>) _d(v)];
      if (list.length != length || list.any((v) => v < 0)) {
        throw RulesError('match.actions.$id.$key needs $length values >= 0');
      }
      return List.unmodifiable(list);
    }

    final rule = ActionRule(
      id: id,
      advance: (m['advance'] as num).toInt(),
      risk: _d(m['risk']),
      weights: numbers('weights', ZoneRules.columns),
      lanes: numbers('lanes', ZoneRules.lanes),
      attack: _attributes(m['attack']),
      defend: _attributes(m['defend']),
      abilities: _abilities(m['abilities']),
      defendAbilities: _abilities(m['defend_abilities']),
      selfShot: _d(m['self_shot']),
      shotBias: _numbers(m['shot_bias']),
    );
    if (rule.advance < 0 || rule.advance > 2) {
      throw RulesError('match.actions.$id.advance must be 0, 1 or 2');
    }
    if (rule.risk <= 0 || rule.risk > 1) {
      throw RulesError('match.actions.$id.risk must be in (0, 1]');
    }
    if (rule.attack.isEmpty || rule.defend.isEmpty) {
      throw RulesError('match.actions.$id needs attack and defend attributes');
    }
    return rule;
  }

  final String id;

  /// Columns the ball moves on success; 0 is a shot from where it is.
  final int advance;

  /// Factor on the success of the step (risky passes skip a column).
  final double risk;

  /// Base weight of the action in each column (own view).
  final List<double> weights;

  /// Factor of the action on the left, centre and right lane.
  final List<double> lanes;
  final List<Attribute> attack;
  final List<Attribute> defend;

  /// Abilities that help the player on the ball, and the defender.
  final List<SpecialAbilityType> abilities;
  final List<SpecialAbilityType> defendAbilities;

  /// Weight of the player on the ball to take the shot himself after this
  /// action reached the last column (1 is like everyone else).
  final double selfShot;

  /// Factors on the weights of shot types after this action.
  final Map<String, double> shotBias;

  bool get isShot => advance == 0;
}

/// The actions of the player on the ball and how teams choose them.
class ActionRules {
  const ActionRules({
    required this.skillExponent,
    required this.abilityBonus,
    required this.list,
    required this.systemWeights,
  });

  factory ActionRules.fromJson(Map<String, dynamic> m) {
    final list = [
      for (final raw in m['list'] as List<dynamic>)
        ActionRule.fromJson(raw as Map<String, dynamic>),
    ];
    final ids = {for (final a in list) a.id};
    if (ids.length != list.length) {
      throw const RulesError('match.actions has an id twice');
    }
    if (!list.any((a) => !a.isShot)) {
      throw const RulesError('match.actions needs an action that moves on');
    }
    final systems = <String, Map<String, double>>{};
    for (final e in (m['system_weights'] as Map<String, dynamic>).entries) {
      final w = _numbers(e.value);
      for (final key in w.keys) {
        if (!ids.contains(key)) {
          throw RulesError('match.actions.system_weights: unknown $key');
        }
      }
      systems[e.key] = w;
    }
    return ActionRules(
      skillExponent: _d(m['skill_exponent']),
      abilityBonus: _d(m['ability_bonus']),
      list: List.unmodifiable(list),
      systemWeights: Map.unmodifiable(systems),
    );
  }

  /// How strongly a player's skill for an action makes him choose it.
  final double skillExponent;

  /// Bonus per tier multiplier of a fitting ability in a duel.
  final double abilityBonus;
  final List<ActionRule> list;

  /// System id to action id to factor on the action's weight.
  final Map<String, Map<String, double>> systemWeights;

  double systemWeight(String systemId, String actionId) =>
      systemWeights[systemId]?[actionId] ?? 1.0;
}

/// Counter attacks after a ball won in midfield (engine 2).
class CounterRules {
  const CounterRules({
    required this.fromColumns,
    required this.chance,
    required this.systemChance,
    required this.disorder,
    required this.disorderSteps,
    required this.abilityBonus,
  });

  factory CounterRules.fromJson(Map<String, dynamic> m) {
    final from = [for (final v in m['from_columns'] as List<dynamic>) v as int];
    if (from.any((c) => c < 1 || c >= ZoneRules.columns - 1)) {
      throw const RulesError('match.counter.from_columns must be 1 to 3');
    }
    final rule = CounterRules(
      fromColumns: Set.unmodifiable(from),
      chance: _d(m['chance']),
      systemChance: _numbers(m['system_chance']),
      disorder: _d(m['disorder']),
      disorderSteps: (m['disorder_steps'] as num).toInt(),
      abilityBonus: _d(m['ability_bonus']),
    );
    if (rule.disorder <= 0 || rule.disorder > 1) {
      throw const RulesError('match.counter.disorder must be in (0, 1]');
    }
    return rule;
  }

  /// Columns (seen from the team that lost the ball) where a lost ball can
  /// start a counter attack of the other team.
  final Set<int> fromColumns;
  final double chance;

  /// Chance by system of the team that won the ball (default [chance]).
  final Map<String, double> systemChance;

  /// Factor on the defending values of a team caught on the counter.
  final double disorder;

  /// For how many steps of the counter the defence is out of order.
  final int disorderSteps;

  /// Bonus per tier multiplier of a counter player on the ball.
  final double abilityBonus;

  double chanceFor(String systemId) => systemChance[systemId] ?? chance;
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
    required this.gameStateEffect,
    required this.gameStateFromMinute,
    required this.gameStateMaxDiff,
    required this.keeperQualityReference,
    required this.keeperQualityExponent,
    required this.goalMin,
    required this.goalMax,
    required this.shotTypes,
    required this.blockedShare,
    required this.offTargetShare,
    required this.shooterSlotWeight,
    required this.assistOpenPlayChance,
    required this.assistSetPieceChance,
    required this.assistPositionWeight,
    required this.assistAttributes,
    required this.assistSetPieceAttributes,
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
    required this.repeatYellowWeight,
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
    required this.zones,
    required this.actions,
    required this.counter,
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
    final assistRaw = m['assist'] as Map<String, dynamic>;
    final assistWeights = <Position, double>{};
    final assistPos = assistRaw['position_weight'] as Map<String, dynamic>;
    for (final p in Position.values) {
      final v = assistPos[p.id];
      if (v == null) throw RulesError('assist.position_weight misses ${p.id}');
      assistWeights[p] = _d(v);
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
      gameStateEffect: _d(m['game_state']['effect']),
      gameStateFromMinute: (m['game_state']['from_minute'] as num).toInt(),
      gameStateMaxDiff: (m['game_state']['max_diff'] as num).toInt(),
      keeperQualityReference: _d(goal['keeper_quality_reference']),
      keeperQualityExponent: _d(goal['keeper_quality_exponent']),
      goalMin: _d(goal['min']),
      goalMax: _d(goal['max']),
      shotTypes: List.unmodifiable(shotTypes),
      blockedShare: _d(outcome['blocked']),
      offTargetShare: _d(outcome['off_target']),
      shooterSlotWeight: Map.unmodifiable(slotWeights),
      assistOpenPlayChance: _d(assistRaw['open_play_chance']),
      assistSetPieceChance: _d(assistRaw['set_piece_chance']),
      assistPositionWeight: Map.unmodifiable(assistWeights),
      assistAttributes: _attributes(assistRaw['attributes']),
      assistSetPieceAttributes: _attributes(assistRaw['set_piece_attributes']),
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
      repeatYellowWeight: _d(cards['repeat_yellow_weight']),
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
            for (final id
                in (e.value as Map<String, dynamic>)['positions']
                    as List<dynamic>)
              Position.values.firstWhere(
                (p) => p.id == id,
                orElse: () => throw RulesError('Unknown position $id'),
              ),
          ]),
      }),
      zones: ZoneRules.fromJson(m['zones'] as Map<String, dynamic>),
      actions: ActionRules.fromJson(m['actions'] as Map<String, dynamic>),
      counter: CounterRules.fromJson(m['counter'] as Map<String, dynamic>),
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

  /// Teams that lead attack a little less and teams that trail a little
  /// more: per goal of difference (up to [gameStateMaxDiff]) the
  /// breakthrough chance changes by this share, from [gameStateFromMinute].
  final double gameStateEffect;
  final int gameStateFromMinute;
  final int gameStateMaxDiff;

  /// Weaker goalkeepers concede more than the ratio of shooter to keeper
  /// alone says: the goal chance is also multiplied by
  /// (reference / keeper) ^ exponent.
  final double keeperQualityReference;
  final double keeperQualityExponent;
  final double goalMin;
  final double goalMax;
  final List<ShotTypeRule> shotTypes;
  final double blockedShare;
  final double offTargetShare;
  final Map<Position, double> shooterSlotWeight;

  /// Chance that a goal from open play has an assist.
  final double assistOpenPlayChance;

  /// Chance that a header goal from a corner or free-kick cross has an assist.
  final double assistSetPieceChance;
  final Map<Position, double> assistPositionWeight;
  final List<Attribute> assistAttributes;
  final List<Attribute> assistSetPieceAttributes;
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

  /// Weight of a player who already has a yellow card when the next
  /// player to be booked is drawn (1 means no difference).
  final double repeatYellowWeight;
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

  /// The zones of the pitch (engine 2).
  final ZoneRules zones;

  /// What the player on the ball does (engine 2).
  final ActionRules actions;

  /// Counter attacks (engine 2).
  final CounterRules counter;
}
