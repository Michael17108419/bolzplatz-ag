import 'dart:math' as math;

import '../model/attribute.dart';
import '../model/ids.dart';
import '../model/player.dart';
import '../model/position.dart';
import '../model/special_ability.dart';
import '../rng/seeded_random.dart';
import '../rules/match_rules.dart';
import '../rules/rules.dart';
import 'fit.dart';
import 'limits.dart';
import 'match_types.dart';
import 'system_fit.dart';
import 'team_sheet.dart';

class _Slot {
  _Slot(this.player, this.position, this.role, this.energy, this.since);

  final Player player;
  Position position;
  String? role;
  double energy;
  int since;

  /// Player values for the duels of engine 2, one per action of the rules,
  /// set by [MatchSession] when the zones are built: with the ball and
  /// against it.
  List<double> act = const [];
  List<double> def = const [];
}

/// Who takes part in each zone, seen from one side (engine 2). Lists run
/// along the pitch of the side, indexed by zone (column * 3 + lane).
class _Zones {
  _Zones(this.slots, this.carry, this.actMean, this.defend, this.defMean);

  final List<_Slot> slots;

  /// Weights of the players to have the ball in a zone of the own view.
  final List<List<double>> carry;

  /// Weighted mean value of the ball carriers per zone and action.
  final List<List<double>> actMean;

  /// Weights of the players to defend a zone of the opponent's view.
  final List<List<double>> defend;

  /// Weighted mean defending value per zone (opponent's view) and action.
  final List<List<double>> defMean;
}

class _Ratings {
  double build = 0;
  double attack = 0;
  double defense = 0;
  double keeper = 0;
}

class _Side {
  _Side(this.team)
    : sheet = team.sheet,
      stats = TeamStats(),
      byId = {for (final p in team.squad) p.id: p};

  final MatchTeam team;
  final Map<PlayerId, Player> byId;
  TeamSheet sheet;
  final TeamStats stats;
  final List<_Slot> pitch = [];
  final List<Player> bench = [];
  final Map<PlayerId, int> yellows = {};
  final Map<PlayerId, int> entered = {};
  final Map<PlayerId, int> played = {};
  int subsUsed = 0;
  int countedChanges = 0;
  int missing = 0;
  double momentum = 0;
  double homeFactor = 1;
  double drainMult = 1;
  _Ratings ratings = _Ratings();
  Map<String, double> fx = {};
  double fitBonus = 0;

  /// Zone tables of engine 2; null when the players on the pitch changed
  /// since they were built.
  _Zones? zones;
}

/// One match in progress. Call [advanceTo] to play minutes; between calls the
/// caller may substitute players or change tactics. [finish] plays the rest
/// and returns the result.
///
/// Everything random comes from the seed, so a match can be repeated.
/// A change the manager made during a live match: a substitution or a
/// change of system and sliders. Saved games repeat them.
class SessionAction {
  const SessionAction._(
    this.minute,
    this.side,
    this.off,
    this.on,
    this.systemId,
    this.pressing,
    this.tempo,
    this.defensiveLine,
  );

  factory SessionAction.substitution(
    int minute,
    int side,
    PlayerId off,
    PlayerId on,
  ) => SessionAction._(minute, side, off, on, null, null, null, null);

  factory SessionAction.tactics(
    int minute,
    int side, {
    String? systemId,
    int? pressing,
    int? tempo,
    int? defensiveLine,
  }) => SessionAction._(
    minute,
    side,
    null,
    null,
    systemId,
    pressing,
    tempo,
    defensiveLine,
  );

  factory SessionAction.fromJson(Map<String, dynamic> m) {
    final off = m['off'] as int?;
    final on = m['on'] as int?;
    return SessionAction._(
      m['minute'] as int,
      m['side'] as int,
      off == null ? null : PlayerId(off),
      on == null ? null : PlayerId(on),
      m['system'] as String?,
      m['pressing'] as int?,
      m['tempo'] as int?,
      m['line'] as int?,
    );
  }

  final int minute;
  final int side;

  /// Set for a substitution.
  final PlayerId? off;
  final PlayerId? on;

  /// Set for a tactic change (only the parts that were changed).
  final String? systemId;
  final int? pressing;
  final int? tempo;
  final int? defensiveLine;

  bool get isSubstitution => off != null;

  Map<String, dynamic> toJson() => {
    'minute': minute,
    'side': side,
    if (off != null) 'off': off!.value,
    if (on != null) 'on': on!.value,
    if (systemId != null) 'system': systemId,
    if (pressing != null) 'pressing': pressing,
    if (tempo != null) 'tempo': tempo,
    if (defensiveLine != null) 'line': defensiveLine,
  };

  /// Does the change in [session].
  void applyTo(MatchSession session) {
    if (isSubstitution) {
      session.substitute(side, off!, on!);
    } else {
      session.changeTactics(
        side,
        systemId: systemId,
        pressing: pressing,
        tempo: tempo,
        defensiveLine: defensiveLine,
      );
    }
  }
}

class MatchSession {
  MatchSession({
    required this.rules,
    required MatchTeam home,
    required MatchTeam away,
    required int seed,
    bool neutral = false,
  }) : _rng = SeededRandom(seed),
       _fit = Fit(rules),
       _systemFit = SystemFit(rules),
       _sides = [_Side(home), _Side(away)] {
    _totalMinutes = rules.match.minutes;
    // A neutral venue (the cup final) gives nobody the home advantage.
    _sides[0].homeFactor = neutral ? 1 : rules.match.homeAdvantage;
    for (final side in _sides) {
      _setUp(side);
    }
    _events.add(
      const MatchEvent(
        minute: 0,
        type: MatchEventType.kickOff,
        side: -1,
        homeGoals: 0,
        awayGoals: 0,
      ),
    );
    for (final side in _sides) {
      _refresh(side);
    }
  }

  final Rules rules;
  final SeededRandom _rng;
  final Fit _fit;
  final SystemFit _systemFit;
  final List<_Side> _sides;
  final List<MatchEvent> _events = [];
  final List<MatchInjury> _injuries = [];
  int _minute = 0;
  int _goalsHome = 0;
  int _goalsAway = 0;
  bool _finished = false;
  int _totalMinutes = 0;
  final List<SessionAction> _actions = [];
  bool _extraTime = false;
  int? _shootoutWinner;

  MatchRules get _m => rules.match;

  /// Minutes played so far.
  int get minute => _minute;
  bool get isFinished => _finished;
  int get homeGoals => _goalsHome;
  int get awayGoals => _goalsAway;
  List<MatchEvent> get events => List.unmodifiable(_events);

  /// The substitutions and tactic changes made by hand, with their minute.
  /// [replay] repeats them in a fresh session of the same match.
  List<SessionAction> get actions => List.unmodifiable(_actions);

  /// Plays the match on, repeating [actions] at their minutes. For a cup
  /// tie ([knockout]) extra time starts when a change falls into it.
  void replay(List<SessionAction> actions, {bool knockout = false}) {
    for (final a in actions) {
      if (knockout && a.minute > rules.match.minutes) {
        advanceTo(rules.match.minutes);
        _startExtraTimeIfLevel();
      }
      advanceTo(a.minute);
      a.applyTo(this);
    }
  }

  /// True once extra time has begun.
  bool get inExtraTime => _extraTime;

  /// True after the shoot-out of a cup tie was played.
  bool get shootoutPlayed => _shootoutWinner != null;

  /// True if the score is level.
  bool get isLevel => _goalsHome == _goalsAway;

  /// A finished cup tie that is level goes into extra time. Returns true if
  /// extra time started.
  bool _startExtraTimeIfLevel() {
    if (_extraTime || !_finished || !isLevel) return false;
    startExtraTime(halfMinutes: rules.season.cups.extraTimeHalfMinutes);
    return _extraTime;
  }

  /// The ticker of a cup tie calls this after full time: starts extra time
  /// if the score is level. Returns true if it did.
  bool startExtraTimeIfLevel() => _startExtraTimeIfLevel();

  /// Ids of the players on the pitch for [side] (0 home, 1 away).
  List<PlayerId> onPitch(int side) => [
    for (final s in _sides[side].pitch) s.player.id,
  ];

  /// Ids of the unused substitutes of [side].
  List<PlayerId> benchOf(int side) => [
    for (final p in _sides[side].bench) p.id,
  ];

  /// The line-up and tactics of [side] as they are now: system and sliders
  /// follow every [changeTactics].
  TeamSheet sheetOf(int side) => _sides[side].sheet;

  /// Energy (0 to 100) of a player now: tired on the pitch, the fitness he
  /// came with on the bench.
  double energyOf(int side, PlayerId id) {
    for (final s in _sides[side].pitch) {
      if (s.player.id == id) return s.energy;
    }
    return _sides[side].team.fitness[id] ?? 100.0;
  }

  /// Form (0 to 100) of a player of [side].
  double formOf(int side, PlayerId id) =>
      _sides[side].team.form[id] ?? _m.defaultForm;

  /// The position of the place on the pitch where [id] plays now, or null
  /// for a substitute.
  Position? slotPositionOf(int side, PlayerId id) {
    for (final s in _sides[side].pitch) {
      if (s.player.id == id) return s.position;
    }
    return null;
  }

  /// The role of [id] on the pitch, or null (no role, or on the bench).
  String? roleOf(int side, PlayerId id) {
    for (final s in _sides[side].pitch) {
      if (s.player.id == id) return s.role;
    }
    return null;
  }

  int substitutionsLeft(int side) =>
      rules.tactics.maxSubstitutions - _sides[side].subsUsed;

  // ---------------------------------------------------------------- setup

  void _setUp(_Side side) {
    final sheet = side.sheet;
    final formation = rules.tactics.formation(sheet.formationId);
    if (sheet.startingXi.length != formation.slots.length) {
      throw ArgumentError('Starting eleven does not match the formation');
    }
    if (sheet.startingXi.toSet().length != sheet.startingXi.length) {
      throw ArgumentError('A player is in the starting eleven twice');
    }
    for (var i = 0; i < formation.slots.length; i++) {
      final player = side.byId[sheet.startingXi[i]];
      if (player == null) throw ArgumentError('Player not in the squad');
      final fitness = side.team.fitness[player.id] ?? 100.0;
      side.pitch.add(
        _Slot(player, formation.slots[i], sheet.slotRoles[i], fitness, 0),
      );
      side.entered[player.id] = 0;
    }
    for (final id in sheet.bench) {
      final player = side.byId[id];
      if (player == null || sheet.startingXi.contains(id)) {
        throw ArgumentError('Bad substitute');
      }
      side.bench.add(player);
    }
  }

  // -------------------------------------------------------------- ratings

  double _formFactor(_Side side, Player p) {
    final form = side.team.form[p.id] ?? _m.defaultForm;
    return _m.formMinFactor +
        (_m.formMaxFactor - _m.formMinFactor) * form / 100;
  }

  double _energyFactor(_Slot s) => 1 - _m.fatigueScale * (1 - s.energy / 100);

  double _slotMean(_Side side, _Slot s, Iterable<Attribute> attributes) {
    final tactics = rules.tactics;
    final role = s.role == null ? null : tactics.role(s.role!);
    final mult =
        _fit.positionMultiplier(s.player, s.position) *
        _formFactor(side, s.player) *
        _energyFactor(s);
    return _fit.meanAttributes(
      s.player,
      attributes,
      positionMult: mult,
      footMult: _fit.weakFootMultiplier(s.player, s.position),
      role: role,
      roleFactorValue:
          _fit.roleFactor(s.player, s.role) +
          _fit.sideFactor(s.player, s.position, role),
    );
  }

  double _groupMean(_Side side, String group) {
    final positions = _m.ratingPositions[group]!;
    final attributes = _m.ratingAttributes[group]!;
    var sum = 0.0;
    var n = 0;
    for (final s in side.pitch) {
      if (!positions.contains(s.position)) continue;
      sum += _slotMean(side, s, attributes);
      n++;
    }
    if (n > 0) return sum / n;
    // Group empty (for example after red cards): use all outfield players.
    for (final s in side.pitch) {
      if (s.position.isGoalkeeper) continue;
      sum += _slotMean(side, s, attributes);
      n++;
    }
    return n == 0 ? 20 : sum / n;
  }

  void _refresh(_Side side) {
    final ratings = _Ratings();
    final tactics = rules.tactics;
    var fitSum = 0.0;
    for (final s in side.pitch) {
      fitSum += _fit.playerFit(s.player, s.position, s.role);
    }
    final teamFit = side.pitch.isEmpty ? 0.0 : fitSum / side.pitch.length;
    final unsettled =
        math.max(0, side.countedChanges - tactics.freeChanges) *
        tactics.penaltyPerExtraChange;
    side.fitBonus = math.max(0.0, tactics.fitBonusMax * teamFit - unsettled);
    final strength =
        math.pow(_m.missingPlayerStrength, side.missing).toDouble() *
        (1 + side.fitBonus);
    ratings
      ..build = _groupMean(side, 'build') * strength
      ..attack = _groupMean(side, 'attack') * strength
      ..defense = _groupMean(side, 'defense') * strength;
    final keeper = side.pitch.where((s) => s.position.isGoalkeeper);
    ratings.keeper = keeper.isEmpty
        ? 20
        : _slotMean(side, keeper.first, _m.keeperAttributes) * strength;
    side.ratings = ratings;
    _effects(side);
    side.zones = _buildZones(side);
  }

  /// Builds the zone tables of [side] from the players on the pitch now.
  _Zones _buildZones(_Side side) {
    final z = _m.zones;
    final actions = _m.actions.list;
    final slots = List<_Slot>.of(side.pitch);
    for (final s in slots) {
      s
        ..act = [for (final a in actions) _slotMean(side, s, a.attack)]
        ..def = [for (final a in actions) _slotMean(side, s, a.defend)];
    }
    const lanes = ZoneRules.lanes;
    const count = ZoneRules.columns * lanes;
    final carry = <List<double>>[];
    final actMean = <List<double>>[];
    final defend = <List<double>>[];
    final defMean = <List<double>>[];
    for (var zone = 0; zone < count; zone++) {
      final column = zone ~/ lanes;
      final lane = zone % lanes;
      // As carrier the zone is seen from this side, as defender from the
      // other side: column and lane are mirrored.
      final c = [
        for (final s in slots)
          z.columnWeights[s.position]![column] * z.laneFactor(s.position, lane),
      ];
      final d = [
        for (final s in slots)
          s.position.isGoalkeeper
              ? 0.0
              : z.columnWeights[s.position]![ZoneRules.columns - 1 - column] *
                    z.laneFactor(s.position, lanes - 1 - lane),
      ];
      _fallback(c, slots);
      _fallback(d, slots);
      carry.add(c);
      defend.add(d);
      actMean.add([
        for (var a = 0; a < actions.length; a++)
          _weightedMean(c, [for (final s in slots) s.act[a]]),
      ]);
      defMean.add([
        for (var a = 0; a < actions.length; a++)
          _weightedMean(d, [for (final s in slots) s.def[a]]),
      ]);
    }
    return _Zones(slots, carry, actMean, defend, defMean);
  }

  /// A zone nobody covers (after red cards, for example) is shared by all
  /// outfield players, or by everyone if only the keeper is left.
  static void _fallback(List<double> weights, List<_Slot> slots) {
    if (weights.any((w) => w > 0)) return;
    for (var i = 0; i < slots.length; i++) {
      weights[i] = slots[i].position.isGoalkeeper ? 0 : 1;
    }
    if (weights.any((w) => w > 0)) return;
    for (var i = 0; i < weights.length; i++) {
      weights[i] = 1;
    }
  }

  static double _weightedMean(List<double> weights, List<double> values) {
    var sum = 0.0;
    var total = 0.0;
    for (var i = 0; i < weights.length; i++) {
      sum += weights[i] * values[i];
      total += weights[i];
    }
    return total <= 0 ? 1 : math.max(1.0, sum / total);
  }

  _Zones _zonesOf(_Side side) => side.zones ??= _buildZones(side);

  static const _noGain = {'drain', 'yellow'};

  void _effects(_Side side) {
    final tactics = rules.tactics;
    final fx = <String, double>{};
    void add(String k, double v) => fx[k] = (fx[k] ?? 0) + v;
    final eleven = [for (final s in side.pitch) s.player];
    final cfg = tactics.systemFit;
    final system = tactics.system(side.sheet.systemId);
    final sc = _systemFit.scale(_systemFit.fit(eleven, system.id));
    for (final e in system.bonus.entries) {
      add(e.key, e.value * sc * (_noGain.contains(e.key) ? 1 : cfg.effectGain));
    }
    for (final e in system.cost.entries) {
      add(
        e.key,
        e.value * (_noGain.contains(e.key) ? 1 : cfg.effectGain * cfg.costGain),
      );
    }
    fx['scale'] = sc;

    final levels = [
      side.sheet.pressing,
      side.sheet.tempo,
      side.sheet.defensiveLine,
    ];
    for (var i = 0; i < tactics.sliders.length; i++) {
      final slider = tactics.sliders[i];
      final levelName = slider.levels[levels[i].limit(0, 2)];
      final effect = _m.sliders[slider.id]![levelName]!;
      var keySum = 0.0;
      var n = 0;
      for (final s in side.pitch) {
        if (s.position.isGoalkeeper) continue;
        keySum += _fit.meanAttributes(s.player, slider.keyAttributes);
        n++;
      }
      final mean = n == 0 ? _m.sliderFitReference : keySum / n;
      final x = (mean - _m.sliderFitReference) / _m.sliderFitDivisor;
      final scale = (1 + _m.sliderFitSlope * x).limit(
        _m.sliderScaleMin,
        _m.sliderScaleMax,
      );
      for (final e in effect.values.entries) {
        add(e.key, effect.scaled.contains(e.key) ? e.value * scale : e.value);
      }
    }
    side.fx = fx;
    side.drainMult = (_m.baseDrain + (fx['drain'] ?? 0)) / (2 * _m.baseDrain);
  }

  double _fx(int side, String key) => _sides[side].fx[key] ?? 0;

  // ------------------------------------------------------------ main loop

  /// Plays all minutes up to and including [target] (at most the full time).
  void advanceTo(int target) {
    final end = math.min(target, _totalMinutes);
    while (_minute < end && !_finished) {
      _minute++;
      _playMinute(_minute);
      if (_minute == _m.halfTimeMinute) {
        _add(MatchEventType.halfTime, -1);
      }
      if (_minute == _totalMinutes) {
        _add(MatchEventType.fullTime, -1);
        _closeBooks();
        _finished = true;
      }
    }
  }

  /// Adds extra time to a finished match (two halves of [halfMinutes]).
  /// Sets the clock back so that [advanceTo] plays on.
  void startExtraTime({int halfMinutes = 15}) {
    if (!_finished) return;
    for (final side in _sides) {
      for (final s in side.pitch) {
        s.since = _minute;
      }
    }
    _totalMinutes = _minute + 2 * halfMinutes;
    _finished = false;
    _extraTime = true;
    _add(MatchEventType.extraTime, -1);
  }

  /// Plays a penalty shoot-out and returns the winning side (0 or 1).
  /// Kicks are events but do not count as goals of the match.
  int playShootout() => _shootoutWinner ??= _runShootout();

  int _runShootout() {
    final taken = [0, 0];
    final scored = [0, 0];
    final order = [
      for (final side in _sides)
        [
          for (final s in side.pitch)
            if (!s.position.isGoalkeeper) s,
        ]..sort(
          (a, b) => _fit
              .slotScore(b.player, b.position)
              .compareTo(_fit.slotScore(a.player, a.position)),
        ),
    ];
    bool kick(int t) {
      final takers = order[t];
      final slot = takers.isEmpty
          ? _sides[t].pitch.first
          : takers[taken[t] % takers.length];
      final side = _sides[t];
      final defender = _sides[1 - t];
      final score = _slotMean(side, slot, _m.penaltyAttributes);
      final keeper = math.max(20.0, defender.ratings.keeper);
      final p = (_m.penaltyGoal * math.pow(score / keeper, 0.5)).limit(
        0.2,
        0.95,
      );
      final goal = _rng.nextDouble() < p;
      taken[t]++;
      if (goal) scored[t]++;
      _events.add(
        MatchEvent(
          minute: _minute,
          type: MatchEventType.shootoutKick,
          side: t,
          homeGoals: _goalsHome,
          awayGoals: _goalsAway,
          player: slot.player.id,
          outcome: goal ? ShotOutcome.goal : ShotOutcome.saved,
        ),
      );
      return goal;
    }

    for (var round = 0; round < 5; round++) {
      kick(0);
      if (_decided(taken, scored)) return scored[0] > scored[1] ? 0 : 1;
      kick(1);
      if (_decided(taken, scored)) return scored[0] > scored[1] ? 0 : 1;
    }
    while (true) {
      final a = kick(0);
      final b = kick(1);
      if (a != b) return a ? 0 : 1;
    }
  }

  bool _decided(List<int> taken, List<int> scored) {
    final leftHome = 5 - taken[0];
    final leftAway = 5 - taken[1];
    if (leftHome < 0 || leftAway < 0) return false;
    return scored[0] > scored[1] + leftAway || scored[1] > scored[0] + leftHome;
  }

  /// Number of kicks each team scored is in the events; helper for callers.
  List<int> shootoutScore() {
    final score = [0, 0];
    for (final e in _events) {
      if (e.type == MatchEventType.shootoutKick && e.isGoal) score[e.side]++;
    }
    return score;
  }

  /// Plays a cup tie to its end: extra time if it is level after full time,
  /// then the shoot-out. Can be called at any point of the tie.
  KnockoutResult finishKnockout() {
    advanceTo(rules.match.minutes);
    _startExtraTimeIfLevel();
    advanceTo(_totalMinutes);
    if (_goalsHome != _goalsAway) {
      final result = finish();
      return KnockoutResult(
        match: result,
        winnerSide: result.homeGoals > result.awayGoals ? 0 : 1,
        extraTime: _extraTime,
      );
    }
    final winner = playShootout();
    final score = shootoutScore();
    final result = finish();
    return KnockoutResult(
      match: result,
      winnerSide: winner,
      extraTime: true,
      shootoutHome: score[0],
      shootoutAway: score[1],
    );
  }

  /// Plays the rest of the match and returns the result.
  MatchResult finish() {
    advanceTo(_totalMinutes);
    return MatchResult(
      homeGoals: _goalsHome,
      awayGoals: _goalsAway,
      events: List.unmodifiable(_events),
      homeStats: _sides[0].stats,
      awayStats: _sides[1].stats,
      injuries: List.unmodifiable(_injuries),
      minutesPlayed: {for (final side in _sides) ...side.played},
    );
  }

  void _closeBooks() {
    for (final side in _sides) {
      for (final s in side.pitch) {
        side.played[s.player.id] =
            (side.played[s.player.id] ?? 0) + _minute - s.since;
      }
    }
  }

  void _add(
    MatchEventType type,
    int side, {
    Player? player,
    Player? other,
    String? shotType,
    ChanceQuality? quality,
    ShotOutcome? outcome,
    int? days,
    int? column,
    int? lane,
    List<PlayerId> chain = const [],
    String? action,
  }) {
    _events.add(
      MatchEvent(
        minute: _minute,
        type: type,
        side: side,
        homeGoals: _goalsHome,
        awayGoals: _goalsAway,
        player: player?.id,
        otherPlayer: other?.id,
        shotType: shotType,
        quality: quality,
        outcome: outcome,
        injuryDays: days,
        column: column,
        lane: lane,
        chain: chain,
        action: action,
      ),
    );
  }

  void _playMinute(int minute) {
    for (final side in _sides) {
      side.momentum *= _m.momentumDecay;
    }
    _cardsAndInjuries(minute);
    _standards();
    final tempo = [
      for (final side in _sides)
        _m.tempoPhaseFactor[rules.tactics.sliders[1].levels[side.sheet.tempo
            .limit(0, 2)]]!,
    ];
    final phases = _m.phasesPerMatch / _m.minutes * (tempo[0] + tempo[1]) / 2;
    var n = phases.floor();
    if (_rng.nextDouble() < phases - n) n++;
    for (var i = 0; i < n; i++) {
      _phase();
    }
    _tire(minute);
    if (minute % _m.aiCheckInterval == 0 || _dirty) {
      for (final side in _sides) {
        if (side.team.autoManage) _assistant(side);
        _refresh(side);
      }
      _dirty = false;
    }
  }

  bool _dirty = false;

  void _tire(int minute) {
    for (final side in _sides) {
      final phase = minute < _m.fatigueStartMinute ? 0.5 : 1.5;
      for (final s in side.pitch) {
        final stamina = s.player.attributes[Attribute.stamina];
        final factor = (_m.staminaReference / stamina).limit(
          _m.staminaMinFactor,
          _m.staminaMaxFactor,
        );
        s.energy = math.max(
          0.0,
          s.energy - _m.energyLossPerMinute * phase * side.drainMult * factor,
        );
      }
    }
  }

  // --------------------------------------------------------------- phases

  double _build(int i) {
    final side = _sides[i];
    final other = _sides[1 - i];
    var press = other.fx['opp_build'] ?? 0;
    press -= other.fx['press'] ?? 0;
    if (side.sheet.systemId == 'possession') {
      final soften = 0.5 * math.min(1.0, (side.fx['scale'] ?? 1) / 1.5);
      press *= 1 - soften;
    }
    return side.ratings.build *
        (1 + (side.fx['build'] ?? 0)) *
        side.homeFactor *
        (1 + _m.momentumEffect * side.momentum) *
        (1 + press);
  }

  /// A counter attack waiting to be played as the next phase: the side,
  /// the column and the lane where it starts (own view).
  (int, int, int)? _counter;

  void _phase() {
    final counter = _counter;
    _counter = null;
    final int t;
    if (counter != null) {
      t = counter.$1;
    } else {
      final b0 = math.pow(_build(0), _m.possessionExponent).toDouble();
      final b1 = math.pow(_build(1), _m.possessionExponent).toDouble();
      t = _rng.nextDouble() < b0 / (b0 + b1) ? 0 : 1;
    }
    final o = 1 - t;
    final attacker = _sides[t];
    final defender = _sides[o];
    attacker.stats.possessionPhases++;

    final rateMult =
        1 + (_fx(t, 'rate') + _fx(o, 'opp_rate')) / _m.attackRateReference;
    var att =
        attacker.ratings.attack *
        (1 + _fx(t, 'att') + _fx(o, 'opp_att')) *
        attacker.homeFactor *
        (1 + _m.momentumEffect * attacker.momentum);
    final counter = _fx(t, 'counter');
    if (counter != 0) {
      final dom = ((_build(o) / _build(t) - 1) * _m.counterDominanceScale)
          .limit(0.0, 1.0);
      att *= 1 + counter * (1 + dom);
    }
    final dfn =
        defender.ratings.defense *
        (1 + _fx(o, 'dfn')) *
        defender.homeFactor *
        (1 + _m.momentumEffect * defender.momentum);
    var state = 1.0;
    if (_minute >= _m.gameStateFromMinute) {
      final diff =
          ((t == 0 ? _goalsHome - _goalsAway : _goalsAway - _goalsHome)).limit(
            -_m.gameStateMaxDiff,
            _m.gameStateMaxDiff,
          );
      state = 1 - _m.gameStateEffect * diff;
    }
    final q =
        (_m.breakthroughBase *
                math.pow(att / dfn, _m.breakthroughExponent) *
                rateMult *
                state)
            .limit(_m.breakthroughMin, _m.breakthroughMax);
    _attack(t, q, counter: counter);
  }

  /// Plays one attack of side [t] through the zones (engine 2). The ball
  /// moves from column to column. In every zone the player on the ball
  /// chooses an action (pass, through ball, long ball, cross, dribbling or a
  /// shot from distance) and meets a defender of the zone in a duel of the
  /// values that action needs. The steps of a normal attack multiply to the
  /// breakthrough chance [q] of the team; the duel bends each step by how
  /// good these two players are at it compared with those usually there.
  /// A [counter] starts further up against a defence out of order.
  void _attack(int t, double q, {(int, int, int)? counter}) {
    final o = 1 - t;
    final z = _m.zones;
    final acts = _m.actions;
    final attacker = _sides[t];
    final defender = _sides[o];
    final own = _zonesOf(attacker);
    final other = _zonesOf(defender);
    if (own.slots.isEmpty || other.slots.isEmpty) return;
    const lanes = ZoneRules.lanes;
    const last = ZoneRules.columns - 1;
    var column =
        counter?.$2 ?? _rng.weightedIndex(z.startColumnWeights);
    var lane =
        counter?.$3 ??
        _rng.weightedIndex(z.lanesFor(attacker.sheet.systemId));
    final reference = z.referenceShare;
    final chain = <Player>[];
    var step = 0;
    ActionRule? lastAction;
    _Slot? lastCarrier;
    while (column < last) {
      final zone = column * lanes + lane;
      final carrier = own.slots[_rng.weightedIndex(own.carry[zone])];
      final a = _chooseAction(attacker, own, carrier, zone, column, lane);
      final action = acts.list[a];
      if (action.isShot) {
        _chance(
          t,
          lane: lane,
          chain: chain,
          shooter: carrier.player,
          forceType: action.id == 'long_shot' ? 'long_shot' : null,
          column: column,
          action: action.id,
        );
        return;
      }
      if (chain.isEmpty || chain.last.id != carrier.player.id) {
        chain.add(carrier.player);
      }
      final tackler = other.slots[_rng.weightedIndex(other.defend[zone])];
      var ratio =
          (carrier.act[a] / own.actMean[zone][a]) *
          _abilityMult(carrier.player, action.abilities, acts.abilityBonus) /
          ((tackler.def[a] / other.defMean[zone][a]) *
              _abilityMult(
                tackler.player,
                action.defendAbilities,
                acts.abilityBonus,
              ));
      if (counter != null && step < _m.counter.disorderSteps) {
        ratio /= _m.counter.disorder;
        ratio *= _abilityMult(
          carrier.player,
          const [SpecialAbilityType.counterPlayer],
          _m.counter.abilityBonus,
        );
      }
      final duel = math
          .pow(ratio, z.duelExponent)
          .toDouble()
          .limit(z.duelRatioMin, z.duelRatioMax);
      final target = math.min(column + action.advance, last);
      final share = z.shareFrom(column) - z.shareFrom(target);
      final p = (math.pow(q, share / reference).toDouble() * action.risk * duel)
          .limit(z.stepMin, z.stepMax);
      if (_rng.nextDouble() >= p) {
        _lost(t, carrier, tackler, column, lane, action.id);
        return;
      }
      column = target;
      lastAction = action;
      lastCarrier = carrier;
      step++;
      if (_rng.nextDouble() < z.laneChange) {
        lane = lane == 1
            ? (_rng.nextDouble() < 0.5 ? 0 : 2)
            : (_rng.nextDouble() < 0.75 ? 1 : 2 - lane);
      }
    }
    _chance(
      t,
      lane: lane,
      chain: chain,
      carrier: lastCarrier?.player,
      selfShot: lastAction?.selfShot ?? 1,
      shotBias: lastAction?.shotBias ?? const {},
      action: lastAction?.id,
    );
  }

  /// The ball of side [t] is lost in [column]: a ball won for the other
  /// side, perhaps a counter attack.
  void _lost(
    int t,
    _Slot carrier,
    _Slot tackler,
    int column,
    int lane,
    String action,
  ) {
    final o = 1 - t;
    final z = _m.zones;
    final c = _m.counter;
    final winner = _sides[o];
    winner.stats.ballsWon++;
    const last = ZoneRules.columns - 1;
    if (c.fromColumns.contains(column) &&
        _rng.nextDouble() < c.chanceFor(winner.sheet.systemId)) {
      // Seen from the winner the place is mirrored.
      _counter = (o, last - column, ZoneRules.lanes - 1 - lane);
      _add(
        MatchEventType.counterAttack,
        o,
        player: tackler.player,
        other: carrier.player,
        column: last - column,
        lane: ZoneRules.lanes - 1 - lane,
        action: action,
      );
      return;
    }
    if (column >= z.ballWonEventFromColumn) {
      _add(
        MatchEventType.ballWon,
        o,
        player: tackler.player,
        other: carrier.player,
        column: column,
        lane: lane,
        action: action,
      );
    }
  }

  /// Picks what the player in [slot] does with the ball: the weight of an
  /// action comes from the column and lane, the system of the team and how
  /// good the player is at it compared with those usually in the zone.
  int _chooseAction(
    _Side side,
    _Zones zones,
    _Slot slot,
    int zone,
    int column,
    int lane,
  ) {
    final acts = _m.actions;
    final weights = <double>[];
    for (var i = 0; i < acts.list.length; i++) {
      final a = acts.list[i];
      final base =
          a.weights[column] *
          a.lanes[lane] *
          acts.systemWeight(side.sheet.systemId, a.id);
      if (base <= 0) {
        weights.add(0);
        continue;
      }
      final skill = slot.act[i] / zones.actMean[zone][i];
      weights.add(
        base *
            math.pow(skill, acts.skillExponent).toDouble() *
            _abilityMult(slot.player, a.abilities, acts.abilityBonus),
      );
    }
    if (weights.every((w) => w <= 0)) {
      return acts.list.indexWhere((a) => !a.isShot);
    }
    return _rng.weightedIndex(weights);
  }

  /// 1 plus [bonus] for every ability of [p] among [types], scaled by its
  /// tier (bronze, silver, gold).
  double _abilityMult(
    Player p,
    List<SpecialAbilityType> types,
    double bonus,
  ) {
    if (types.isEmpty) return 1;
    var factor = 1.0;
    for (final a in p.abilities) {
      if (types.contains(a.type)) {
        factor += bonus * (rules.tierMultiplier[a.tier] ?? 1);
      }
    }
    return factor;
  }

  Player? _pickShooter(
    _Side side,
    int lane, {
    Player? carrier,
    double selfShot = 1,
  }) {
    final z = _m.zones;
    final slots = [
      for (final s in side.pitch)
        if (!s.position.isGoalkeeper) s,
    ];
    if (slots.isEmpty) return null;
    final weights = [
      for (final s in slots)
        _m.shooterSlotWeight[s.position]! *
                s.player.attributes[Attribute.goalInstinct] *
                math
                    .pow(z.laneFactor(s.position, lane), z.shooterLaneExponent)
                    .toDouble() *
                (s.player.id == carrier?.id ? selfShot : 1.0) +
            0.001,
    ];
    return slots[_rng.weightedIndex(weights)].player;
  }

  /// The player who made the pass for a goal, or null without an assist.
  /// Open-play goals and header goals from crosses can have one; penalties
  /// and direct free kicks never do.
  Player? _pickAssister(
    _Side side,
    Player shooter,
    String typeId,
    ChanceQuality? quality, {
    Player? passer,
  }) {
    final bool setPiece = quality == null && typeId == 'header';
    if (quality == null && !setPiece) return null;
    final chance = setPiece ? _m.assistSetPieceChance : _m.assistOpenPlayChance;
    if (_rng.nextDouble() >= chance) return null;
    // In open play the last player of the attack made the pass.
    if (!setPiece && passer != null && passer.id != shooter.id) return passer;
    final attrs = setPiece ? _m.assistSetPieceAttributes : _m.assistAttributes;
    final slots = [
      for (final s in side.pitch)
        if (s.player.id != shooter.id &&
            (_m.assistPositionWeight[s.position] ?? 0) > 0)
          s,
    ];
    if (slots.isEmpty) return null;
    final weights = [
      for (final s in slots)
        _m.assistPositionWeight[s.position]! * _slotMean(side, s, attrs) +
            0.001,
    ];
    return slots[_rng.weightedIndex(weights)].player;
  }

  _Slot _slotOf(_Side side, Player p) =>
      side.pitch.firstWhere((s) => s.player.id == p.id);

  double _abilityFactor(Player p, ShotTypeRule type) {
    var factor = 1.0;
    for (final a in p.abilities) {
      if (type.abilities.contains(a.type)) {
        factor += _m.abilityShotBonus * (rules.tierMultiplier[a.tier] ?? 1);
      }
    }
    return factor;
  }

  /// A chance of side [t] after an attack on [lane]. [shooter] and
  /// [forceType] are set for a shot from distance that the player on the
  /// ball chose himself (always a half chance from [column]). Otherwise
  /// the shooter is drawn; the last [carrier] takes it himself with the
  /// weight [selfShot], and [shotBias] favours shot types (a cross ends in
  /// a header more often).
  void _chance(
    int t, {
    int lane = 1,
    List<Player> chain = const [],
    Player? shooter,
    String? forceType,
    int? column,
    Player? carrier,
    double selfShot = 1,
    Map<String, double> shotBias = const {},
    String? action,
  }) {
    final o = 1 - t;
    final attacker = _sides[t];
    final picked =
        shooter ??
        _pickShooter(attacker, lane, carrier: carrier, selfShot: selfShot);
    if (picked == null) return;
    final slot = _slotOf(attacker, picked);
    final forced = forceType == null
        ? -1
        : _m.shotTypes.indexWhere((type) => type.id == forceType);
    final qualityIndex = forced >= 0
        ? 0
        : _rng.weightedIndex(_m.qualityWeights);
    final quality = ChanceQuality.values[qualityIndex];

    final scores = [
      for (final type in _m.shotTypes)
        _slotMean(attacker, slot, type.attributes) *
            _abilityFactor(picked, type),
    ];
    final weights = [
      for (var i = 0; i < scores.length; i++)
        _m.shotTypes[i].weight *
                (shotBias[_m.shotTypes[i].id] ?? 1.0) *
                math.pow(scores[i] / 50, 2).toDouble() +
            0.0001,
    ];
    final typeIndex = forced >= 0 ? forced : _rng.weightedIndex(weights);
    final type = _m.shotTypes[typeIndex];
    final keeper = _sides[o].ratings.keeper;
    final goal =
        (type.goalBase *
                _m.qualityGoalMult[qualityIndex] *
                math.pow(scores[typeIndex] / keeper, _m.goalExponent) *
                math.pow(
                  _m.keeperQualityReference / keeper,
                  _m.keeperQualityExponent,
                ))
            .limit(_m.goalMin, _m.goalMax);
    final passers = [
      for (final p in chain)
        if (p.id != picked.id) p,
    ];
    _shot(
      t,
      picked,
      type.id,
      quality,
      goal,
      column:
          column ??
          (type.id == 'long_shot'
              ? ZoneRules.columns - 2
              : ZoneRules.columns - 1),
      lane: lane,
      chain: passers,
      action: action,
    );
  }

  void _shot(
    int t,
    Player shooter,
    String typeId,
    ChanceQuality? quality,
    double goalProbability, {
    int? column,
    int? lane,
    List<Player> chain = const [],
    String? action,
  }) {
    final attacker = _sides[t];
    attacker.stats.shots++;
    final ShotOutcome outcome;
    final r = _rng.nextDouble();
    if (r < goalProbability) {
      outcome = ShotOutcome.goal;
    } else {
      final rest = (r - goalProbability) / (1 - goalProbability);
      if (rest < _m.blockedShare) {
        outcome = ShotOutcome.blocked;
      } else if (rest < _m.blockedShare + _m.offTargetShare) {
        outcome = ShotOutcome.offTarget;
      } else {
        outcome = ShotOutcome.saved;
      }
    }
    if (outcome == ShotOutcome.goal || outcome == ShotOutcome.saved) {
      attacker.stats.shotsOnTarget++;
    }
    if (outcome == ShotOutcome.goal) {
      attacker.stats.goals++;
      if (t == 0) {
        _goalsHome++;
      } else {
        _goalsAway++;
      }
      attacker.momentum = (attacker.momentum + _m.momentumGoalFor).limit(
        -1.0,
        1.0,
      );
      final defender = _sides[1 - t];
      defender.momentum = (defender.momentum - _m.momentumGoalAgainst).limit(
        -1.0,
        1.0,
      );
    }
    final Player? assister = outcome == ShotOutcome.goal
        ? _pickAssister(
            attacker,
            shooter,
            typeId,
            quality,
            passer: chain.isEmpty ? null : chain.last,
          )
        : null;
    _add(
      MatchEventType.shot,
      t,
      player: shooter,
      other: assister,
      shotType: typeId,
      quality: quality,
      outcome: outcome,
      column: column,
      lane: lane,
      chain: [for (final p in chain) p.id],
      action: action,
    );
  }

  // ------------------------------------------------------------ standards

  int _attackingSide() {
    final b0 = math.pow(_build(0), _m.possessionExponent).toDouble();
    final b1 = math.pow(_build(1), _m.possessionExponent).toDouble();
    return _rng.nextDouble() < b0 / (b0 + b1) ? 0 : 1;
  }

  void _standards() {
    final minutes = _m.minutes.toDouble();
    if (_rng.nextDouble() < _m.freeKicksPerMatch / minutes) {
      _freeKick(_attackingSide());
    }
    if (_rng.nextDouble() < _m.cornersPerMatch / minutes) {
      _corner(_attackingSide());
    }
    if (_rng.nextDouble() < _m.penaltiesPerMatch / minutes) {
      _penalty(_attackingSide());
    }
  }

  /// Best player of the side for the given attributes, with a bonus for the
  /// set-piece specialist ability.
  (Player, double) _taker(_Side side, List<Attribute> attributes) {
    Player? best;
    var bestScore = -1.0;
    for (final s in side.pitch) {
      if (s.position.isGoalkeeper) continue;
      var score = _slotMean(side, s, attributes);
      for (final a in s.player.abilities) {
        if (a.type.id == 'set_piece_specialist') {
          score *= 1 + _m.standardAbilityBonus;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = s.player;
      }
    }
    return (best ?? side.pitch.first.player, bestScore < 0 ? 20.0 : bestScore);
  }

  double _headerStrength(_Side side, {bool defending = false}) {
    final attributes = _m.ratingAttributes['duel_header']!;
    final positions = _m.ratingPositions['duel_header']!;
    final values = <double>[];
    for (final s in side.pitch) {
      if (!positions.contains(s.position)) continue;
      values.add(_slotMean(side, s, attributes));
    }
    values.sort((a, b) => b.compareTo(a));
    final top = values.take(4).toList();
    if (top.isEmpty) return 20;
    var mean = top.reduce((a, b) => a + b) / top.length;
    if (defending) {
      final keeper = side.pitch.where((s) => s.position.isGoalkeeper);
      if (keeper.isNotEmpty) {
        final command =
            keeper.first.player.attributes[Attribute.gkCommandOfArea];
        mean = (mean * 3 + command) / 4;
      }
    }
    return mean;
  }

  Player _headerScorer(_Side side) {
    final attributes = _m.ratingAttributes['duel_header']!;
    final slots = [
      for (final s in side.pitch)
        if (!s.position.isGoalkeeper) s,
    ];
    final weights = [
      for (final s in slots)
        math.pow(_slotMean(side, s, attributes), 3).toDouble(),
    ];
    return slots[_rng.weightedIndex(weights)].player;
  }

  void _crossChance(
    int t,
    double base,
    double takerScore,
    MatchEventType type,
  ) {
    final attacker = _sides[t];
    final defender = _sides[1 - t];
    final ratio =
        _headerStrength(attacker) / _headerStrength(defender, defending: true);
    final goal =
        (base * math.pow(ratio, _m.goalExponent) * math.pow(takerScore / 50, 1))
            .limit(_m.goalMin, _m.goalMax);
    final scorer = _headerScorer(attacker);
    if (_rng.nextDouble() < goal) {
      _shot(t, scorer, 'header', null, 1);
    } else if (_rng.nextDouble() < 0.35) {
      _shot(t, scorer, 'header', null, 0);
    }
  }

  void _freeKick(int t) {
    final attacker = _sides[t];
    attacker.stats.freeKicks++;
    final (taker, score) = _taker(attacker, _m.takerAttributes);
    _add(MatchEventType.freeKick, t, player: taker);
    if (_rng.nextDouble() < _m.freeKickDirectShare) {
      final keeper = _sides[1 - t].ratings.keeper;
      final goal =
          (_m.freeKickDirectGoal * math.pow(score / keeper, _m.goalExponent))
              .limit(_m.goalMin, _m.goalMax);
      _shot(t, taker, 'long_shot', null, goal);
    } else {
      _crossChance(t, _m.freeKickCrossGoal, score, MatchEventType.freeKick);
    }
  }

  void _corner(int t) {
    final attacker = _sides[t];
    attacker.stats.corners++;
    final (taker, score) = _taker(attacker, _m.cornerTakerAttributes);
    _add(MatchEventType.corner, t, player: taker);
    _crossChance(t, _m.cornerGoal, score, MatchEventType.corner);
  }

  void _penalty(int t) {
    final attacker = _sides[t];
    final defender = _sides[1 - t];
    attacker.stats.penalties++;
    final (taker, score) = _taker(attacker, _m.penaltyAttributes);
    var goal =
        _m.penaltyGoal *
        math.pow(score / math.max(20.0, defender.ratings.keeper), 0.5);
    for (final s in defender.pitch) {
      for (final a in s.player.abilities) {
        if (s.position.isGoalkeeper && a.type.id == 'penalty_killer') {
          goal *= 1 - _m.standardAbilityBonus;
        }
      }
    }
    _add(MatchEventType.penalty, t, player: taker);
    _shot(t, taker, 'close_range', null, goal.limit(0.2, 0.95));
  }

  // -------------------------------------------------- cards and injuries

  void _cardsAndInjuries(int minute) {
    for (var i = 0; i < 2; i++) {
      final side = _sides[i];
      final p = math.max(
        0.0,
        _m.yellowPerMinutePerTeam + (side.fx['yellow'] ?? 0),
      );
      if (side.pitch.length > 1 && _rng.nextDouble() < p) {
        final slots = [
          for (final s in side.pitch)
            if (!s.position.isGoalkeeper) s,
        ];
        final weights = [
          for (final s in slots)
            (101 - s.player.attributes[Attribute.composure]) *
                (s.position == Position.iv || s.position == Position.zdm
                    ? 1.5
                    : 1.0) *
                ((side.yellows[s.player.id] ?? 0) > 0
                    ? _m.repeatYellowWeight
                    : 1.0),
        ];
        if (slots.isNotEmpty) _yellow(i, slots[_rng.weightedIndex(weights)]);
      }
    }
    if (_rng.nextDouble() < _m.straightRedPerMinute) {
      final i = _rng.nextInt(2);
      final side = _sides[i];
      if (side.pitch.length > 7) {
        _sendOff(i, side.pitch[_rng.nextInt(side.pitch.length)], false);
      }
    }
    for (var i = 0; i < 2; i++) {
      final side = _sides[i];
      for (final s in List<_Slot>.of(side.pitch)) {
        final proneness = s.player.injuryProneness / 50;
        final chance =
            _m.injuryPerPlayerMinute *
            proneness *
            (1 + _m.injuryFatigueFactor * (1 - s.energy / 100));
        if (_rng.nextDouble() < chance) _injure(i, s);
      }
    }
  }

  void _yellow(int i, _Slot s) {
    final side = _sides[i];
    final id = s.player.id;
    final count = (side.yellows[id] ?? 0) + 1;
    side.yellows[id] = count;
    side.stats.yellowCards++;
    if (count >= 2) {
      _add(MatchEventType.secondYellow, i, player: s.player);
      _sendOff(i, s, true);
    } else {
      _add(MatchEventType.yellowCard, i, player: s.player);
    }
  }

  void _sendOff(int i, _Slot s, bool secondYellow) {
    final side = _sides[i];
    side.stats.redCards++;
    if (!secondYellow) _add(MatchEventType.redCard, i, player: s.player);
    _remove(i, s, replace: false);
  }

  void _injure(int i, _Slot s) {
    final side = _sides[i];
    side.stats.injuries++;
    final severity = _rng.weightedIndex(_m.injurySeverityWeights);
    final range = _m.injuryDays[severity];
    final days = _rng.nextIntInRange(range[0], range[1]);
    _injuries.add(
      MatchInjury(player: s.player.id, minute: _minute, days: days),
    );
    _add(MatchEventType.injury, i, player: s.player, days: days);
    _remove(i, s, replace: true);
  }

  /// Takes a player off the pitch because of a card or an injury.
  void _remove(int i, _Slot s, {required bool replace}) {
    final side = _sides[i];
    side.played[s.player.id] =
        (side.played[s.player.id] ?? 0) + _minute - s.since;
    side.pitch.remove(s);
    side.zones = null;
    _dirty = true;
    final wasKeeper = s.position.isGoalkeeper;
    if (replace && side.subsUsed < rules.tactics.maxSubstitutions) {
      final candidates = [
        for (final p in side.bench)
          if (p.position.isGoalkeeper == wasKeeper) p,
      ];
      if (candidates.isNotEmpty) {
        candidates.sort(
          (a, b) => _fit
              .slotScore(b, s.position)
              .compareTo(_fit.slotScore(a, s.position)),
        );
        _bringOn(i, candidates.first, s.position, s.role, null);
        return;
      }
    }
    side.missing++;
    if (wasKeeper) {
      final spare = side.bench.where((p) => p.position.isGoalkeeper);
      if (spare.isNotEmpty && side.subsUsed < rules.tactics.maxSubstitutions) {
        // Keeper comes on for the weakest outfield player.
        _Slot? weakest;
        var weakestScore = double.infinity;
        for (final other in side.pitch) {
          final score = _fit.slotScore(other.player, other.position);
          if (score < weakestScore) {
            weakestScore = score;
            weakest = other;
          }
        }
        if (weakest != null) {
          side.pitch.remove(weakest);
          side.played[weakest.player.id] =
              (side.played[weakest.player.id] ?? 0) + _minute - weakest.since;
          _bringOn(i, spare.first, Position.tw, null, weakest.player);
          return;
        }
      }
      // An outfield player goes in goal.
      if (side.pitch.isNotEmpty) {
        final field = side.pitch.last;
        field.position = Position.tw;
        field.role = null;
      }
    }
  }

  void _bringOn(
    int i,
    Player player,
    Position position,
    String? role,
    Player? off,
  ) {
    final side = _sides[i];
    side.bench.remove(player);
    side.subsUsed++;
    side.stats.substitutions++;
    final fitness = side.team.fitness[player.id] ?? 100.0;
    side.pitch.add(_Slot(player, position, role, fitness, _minute));
    side.zones = null;
    side.entered[player.id] = _minute;
    _add(MatchEventType.substitution, i, player: player, other: off);
    _dirty = true;
  }

  // ------------------------------------------------- substitutions, tactics

  /// Substitutes [off] by [on] for [side]. Returns false when not allowed.
  bool substitute(int side, PlayerId off, PlayerId on) {
    final ok = _substitute(side, off, on);
    if (ok) _actions.add(SessionAction.substitution(_minute, side, off, on));
    return ok;
  }

  bool _substitute(int side, PlayerId off, PlayerId on) {
    final s = _sides[side];
    if (_finished || s.subsUsed >= rules.tactics.maxSubstitutions) return false;
    final slot = s.pitch.where((x) => x.player.id == off).firstOrNull;
    final incoming = s.bench.where((p) => p.id == on).firstOrNull;
    if (slot == null || incoming == null) return false;
    if (slot.position.isGoalkeeper != incoming.position.isGoalkeeper) {
      return false;
    }
    s.pitch.remove(slot);
    s.played[off] = (s.played[off] ?? 0) + _minute - slot.since;
    _bringOn(side, incoming, slot.position, slot.role, slot.player);
    _refresh(s);
    return true;
  }

  /// Changes system and sliders. Changes after the warm-up of the first
  /// minutes and outside half time count towards the "unsettled" penalty.
  void changeTactics(
    int side, {
    String? systemId,
    int? pressing,
    int? tempo,
    int? defensiveLine,
  }) {
    _actions.add(
      SessionAction.tactics(
        _minute,
        side,
        systemId: systemId,
        pressing: pressing,
        tempo: tempo,
        defensiveLine: defensiveLine,
      ),
    );
    final s = _sides[side];
    final before = s.sheet;
    s.sheet = before.copyWith(
      systemId: systemId,
      pressing: pressing,
      tempo: tempo,
      defensiveLine: defensiveLine,
    );
    final free =
        _minute <= rules.tactics.warmupMinutes || _minute == _m.halfTimeMinute;
    if (!free) s.countedChanges++;
    _add(MatchEventType.tacticChange, side);
    _refresh(s);
  }

  void _assistant(_Side side) {
    final i = _sides.indexOf(side);
    if (side.subsUsed >= rules.tactics.maxSubstitutions || side.bench.isEmpty) {
      return;
    }
    if (_minute >= _m.aiSubTiredMinute) {
      _Slot? tired;
      for (final s in side.pitch) {
        if (s.position.isGoalkeeper) continue;
        if (s.energy < _m.aiTiredEnergy &&
            (tired == null || s.energy < tired.energy)) {
          tired = s;
        }
      }
      final target = tired;
      if (target != null) {
        final options =
            [
              for (final p in side.bench)
                if (!p.position.isGoalkeeper) p,
            ]..sort(
              (a, b) => _fit
                  .slotScore(b, target.position)
                  .compareTo(_fit.slotScore(a, target.position)),
            );
        if (options.isNotEmpty) {
          _substitute(i, target.player.id, options.first.id);
          return;
        }
      }
    }
    final own = i == 0 ? _goalsHome : _goalsAway;
    final other = i == 0 ? _goalsAway : _goalsHome;
    if (own < other && _minute >= _m.aiSubTrailingMinute) {
      final attackers = [
        for (final p in side.bench)
          if (p.position == Position.st ||
              p.position == Position.la ||
              p.position == Position.ra ||
              p.position == Position.zom)
            p,
      ];
      if (attackers.isEmpty) return;
      _Slot? weakest;
      var weakestScore = double.infinity;
      for (final s in side.pitch) {
        if (s.position != Position.iv &&
            s.position != Position.zdm &&
            s.position != Position.zm) {
          continue;
        }
        final score = _fit.slotScore(s.player, s.position);
        if (score < weakestScore) {
          weakestScore = score;
          weakest = s;
        }
      }
      if (weakest != null) {
        attackers.sort(
          (a, b) => _fit
              .slotScore(b, b.position)
              .compareTo(_fit.slotScore(a, a.position)),
        );
        final incoming = attackers.first;
        final slot = weakest;
        side.pitch.remove(slot);
        side.played[slot.player.id] =
            (side.played[slot.player.id] ?? 0) + _minute - slot.since;
        _bringOn(i, incoming, incoming.position, null, slot.player);
      }
    }
  }
}

/// Plays whole matches without a user interface.
class MatchEngine {
  const MatchEngine(this.rules);

  final Rules rules;

  MatchResult simulate(MatchTeam home, MatchTeam away, {required int seed}) {
    return MatchSession(
      rules: rules,
      home: home,
      away: away,
      seed: seed,
    ).finish();
  }

  /// A cup tie in one match: extra time and shoot-out when it is level.
  KnockoutResult simulateKnockout(
    MatchTeam home,
    MatchTeam away, {
    required int seed,
    bool neutral = false,
  }) {
    final session = MatchSession(
      rules: rules,
      home: home,
      away: away,
      seed: seed,
      neutral: neutral,
    );
    return session.finishKnockout();
  }
}
