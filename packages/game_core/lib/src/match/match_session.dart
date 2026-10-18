import 'dart:math' as math;
import 'dart:typed_data';

import '../model/attribute.dart';
import '../model/character.dart';
import '../model/ids.dart';
import '../model/player.dart';
import '../model/position.dart';
import '../model/referee.dart';
import '../model/special_ability.dart';
import '../rng/seeded_random.dart';
import '../rules/match_rules.dart';
import '../rules/rules.dart';
import '../squad/chemistry.dart';
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

  /// Form on the day (engine 2): a factor around 1, smaller spread for
  /// consistent players.
  double dayForm = 1;

  /// Means of attribute lists without tiredness, keyed by the list of the
  /// rules (identity): they only change when the place changes.
  final Map<Object, double> base = Map<Object, double>.identity();

  /// Fit of the player in his role on this place, once computed.
  double? fit;

  /// Character traits as -1 to 1, indexed by [CharacterTrait.index].
  Float64List tx = Float64List(CharacterTrait.values.length);

  /// Factor of a counter player on the ball during a counter attack.
  double counterMult = 1;

  /// Confidence 0 to 100 (step 10f2): moves with what he does on the day.
  double conf = 50;

  /// Mood 0 to 100 (step 10f3): from the week, moved by team talks.
  double mood = 60;

  /// Extra foul risk of a hothead fired up in the dressing room (step 10f3).
  double heat = 0;

  /// What the coach told him (step 10g1).
  PlayerInstruction? instr;

  /// Forgets the cached values after the place or role changed.
  void reset() {
    base.clear();
    fit = null;
    act = const [];
    def = const [];
  }
}

/// Who takes part in each zone, seen from one side (engine 2). Lists run
/// along the pitch of the side, indexed by zone (column * lanes + lane).
class _Zones {
  _Zones({
    required this.slots,
    required this.carry,
    required this.defend,
    required this.choice,
    required this.attRel,
    required this.defRel,
    required this.shooter,
  });

  final List<_Slot> slots;

  /// Weights of the players to have the ball in a zone of the own view.
  final List<Float64List> carry;

  /// Weights of the players to defend a zone of the opponent's view.
  final List<Float64List> defend;

  /// Per zone and player: weights of the actions (column, lane, system,
  /// skill, abilities, character).
  final List<List<Float64List>> choice;

  /// Per zone and player: value for each action compared with those
  /// usually there, with abilities (without tiredness).
  final List<List<Float64List>> attRel;

  /// The same for defending (with abilities and hard tackling).
  final List<List<Float64List>> defRel;

  /// Per lane: weights of the players to take a chance (keeper 0).
  final List<Float64List> shooter;
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

  /// Substitution windows used (IFAB Law 3) and the minute of the last one:
  /// several changes in the same stoppage are one window.
  int windowsUsed = 0;
  int? windowMinute;
  int countedChanges = 0;
  int missing = 0;

  /// The session minute of the last team talk (step 10f3); one per break.
  int talkMinute = -1;

  /// Chemistry of the players on the pitch, 0 to 1 (step 10f4), and its
  /// factor on short passes and through balls.
  double chemistry = 0.5;
  double chemFactor = 1;

  /// The assistant coaches this side (step 10f5): AI clubs always, the club
  /// of the player after he handed over.
  bool assistant = false;

  /// What the coach has done in this match (step 10f5), see [_Coach].
  int coachDone = 0;

  /// Opponents followed by a man marker of this side and the factor on
  /// their duels (step 10g1).
  Map<PlayerId, double> marked = const {};

  /// The match plan (step 10g2): focus points and whether each hits a real
  /// weakness, the wing of their weak side, their key player.
  Map<PlanFocus, bool> plan = const {};
  Wing? planWing;
  PlayerId? planKey;

  /// The shout that works now, up to which session minute, how strongly
  /// (0 to 1), and the shouts used in this half (step 10g4).
  Shout? shout;
  int shoutUntil = -1;
  double shoutPower = 0;
  int shoutsUsed = 0;

  /// The minute (session minutes) up to which the team plays a man short
  /// for a treatment or a slow change (engine 2, step 10e6).
  int shortUntil = -1;
  double momentum = 0;
  double homeFactor = 1;
  double drainMult = 1;
  _Ratings ratings = _Ratings();
  Map<String, double> fx = {};
  double fitBonus = 0;

  /// Zone tables of engine 2; null when the players on the pitch changed
  /// since they were built.
  _Zones? zones;

  /// Captain of the match: named on the sheet or the leader of the eleven.
  PlayerId? captain;

  /// System and slider effects need a new computation (players or tactics
  /// changed); tiredness alone does not change them.
  bool fxStale = true;
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
    this.side, {
    this.off,
    this.on,
    this.systemId,
    this.pressing,
    this.tempo,
    this.defensiveLine,
    this.talk,
    this.handOver = false,
    this.instructed,
    this.instruction,
    this.wing,
    this.wasteTime,
    this.plan,
    this.shout,
  });

  /// A shout from the touchline (step 10g4).
  factory SessionAction.shoutOut(int minute, int side, Shout shout) =>
      SessionAction._(minute, side, shout: shout);

  /// The match plan (step 10g2).
  factory SessionAction.plan(int minute, int side, List<PlanFocus> plan) =>
      SessionAction._(minute, side, plan: plan);

  /// A team talk (step 10f3).
  factory SessionAction.teamTalk(int minute, int side, TeamTalk talk) =>
      SessionAction._(minute, side, talk: talk);

  /// The assistant takes over for the rest of the match (step 10f5).
  factory SessionAction.handOver(int minute, int side) =>
      SessionAction._(minute, side, handOver: true);

  factory SessionAction.substitution(
    int minute,
    int side,
    PlayerId off,
    PlayerId on,
  ) => SessionAction._(minute, side, off: off, on: on);

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
    systemId: systemId,
    pressing: pressing,
    tempo: tempo,
    defensiveLine: defensiveLine,
  );

  /// An instruction for one player, null takes it back (step 10g1).
  factory SessionAction.instruction(
    int minute,
    int side,
    PlayerId player,
    PlayerInstruction? instruction,
  ) => SessionAction._(
    minute,
    side,
    instructed: player,
    instruction: instruction,
  );

  /// The team instructions (step 10g1): the wing to overload ("none" for
  /// none) and time wasting.
  factory SessionAction.team(
    int minute,
    int side, {
    required String wing,
    required bool wasteTime,
  }) => SessionAction._(minute, side, wing: wing, wasteTime: wasteTime);

  factory SessionAction.fromJson(Map<String, dynamic> m) {
    final off = m['off'] as int?;
    final on = m['on'] as int?;
    final instructed = m['instructed'] as int?;
    final instruction = m['instruction'] as String?;
    return SessionAction._(
      m['minute'] as int,
      m['side'] as int,
      off: off == null ? null : PlayerId(off),
      on: on == null ? null : PlayerId(on),
      systemId: m['system'] as String?,
      pressing: m['pressing'] as int?,
      tempo: m['tempo'] as int?,
      defensiveLine: m['line'] as int?,
      talk: m['talk'] == null ? null : TeamTalk.values.byName(m['talk'] as String),
      handOver: m['handover'] == true,
      instructed: instructed == null ? null : PlayerId(instructed),
      instruction: instruction == null
          ? null
          : PlayerInstruction.values.byName(instruction),
      wing: m['wing'] as String?,
      wasteTime: m['waste'] as bool?,
      plan: m['plan'] == null
          ? null
          : [
              for (final f in m['plan'] as List<dynamic>)
                PlanFocus.values.byName(f as String),
            ],
      shout: m['shout'] == null
          ? null
          : Shout.values.byName(m['shout'] as String),
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

  /// Set for a team talk.
  final TeamTalk? talk;

  /// True when the assistant took over.
  final bool handOver;

  /// Set for an instruction: the player and what he is told (null: none).
  final PlayerId? instructed;
  final PlayerInstruction? instruction;

  /// Set for the team instructions: wing (`left`, `right`, `none`) and
  /// time wasting.
  final String? wing;
  final bool? wasteTime;

  /// Set for the match plan.
  final List<PlanFocus>? plan;

  /// Set for a shout.
  final Shout? shout;

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
    if (talk != null) 'talk': talk!.name,
    if (handOver) 'handover': true,
    if (instructed != null) 'instructed': instructed!.value,
    if (instruction != null) 'instruction': instruction!.name,
    if (wing != null) 'wing': wing,
    if (wasteTime != null) 'waste': wasteTime,
    if (plan != null) 'plan': [for (final f in plan!) f.name],
    if (shout != null) 'shout': shout!.name,
  };

  /// Does the change in [session].
  void applyTo(MatchSession session) {
    if (shout != null) {
      session.shoutOut(side, shout!);
    } else if (plan != null) {
      session.setPlan(side, plan!);
    } else if (handOver) {
      session.handOver(side);
    } else if (talk != null) {
      session.teamTalk(side, talk!);
    } else if (instructed != null) {
      session.instruct(side, instructed!, instruction);
    } else if (wing != null || wasteTime != null) {
      session.teamInstructions(
        side,
        wing: wing == null || wing == 'none' ? null : Wing.values.byName(wing!),
        wasteTime: wasteTime ?? false,
      );
    } else if (isSubstitution) {
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
    this.referee,
    this.video = false,
    this.setting = const MatchSetting(),
  }) : _rng = SeededRandom(seed),
       _neutral = neutral,
       _fit = Fit(rules),
       _systemFit = SystemFit(rules),
       _sides = [_Side(home), _Side(away)] {
    _halfEnds = [rules.match.halfTimeMinute, rules.match.minutes];
    // A neutral venue (the cup final) gives nobody the home advantage.
    _sides[0].homeFactor = neutral
        ? 1
        : setting.capacity > 0
        ? _m.crowd.homeFactor(
            setting.attendance,
            setting.fill,
            setting.derby,
          )
        : rules.match.homeAdvantage;
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

  /// Who whistles (engine 2, step 10e1); null is a plain referee with all
  /// traits in the middle.
  final Referee? referee;

  /// True if the match has a video assistant (league 1 and 2, the big cup
  /// from the round of 16; engine 2, step 10e2).
  final bool video;

  /// Ground, crowd, derby and travel of the guests (engine 2, step 10e4).
  final MatchSetting setting;
  final bool _neutral;
  final SeededRandom _rng;

  /// Dice of the coaches (step 10f5), apart from the dice of the play.
  late final SeededRandom _coachRng = _rng.fork('coach');
  final Fit _fit;
  final SystemFit _systemFit;
  final List<_Side> _sides;
  final List<MatchEvent> _events = [];
  final List<MatchInjury> _injuries = [];
  /// Minutes played including stoppage time (the clock of the session).
  int _minute = 0;

  /// Minute on the clock (stays at 45 or 90 in stoppage time) and the
  /// minute of stoppage time.
  int _clock = 0;
  int _added = 0;

  /// Announced stoppage time of the running half, null before it is shown.
  int? _stoppage;

  /// Clock minutes at which the halves end: 45 and 90, then the halves of
  /// extra time.
  List<int> _halfEnds = const [];
  int _half = 0;

  /// True between two halves (half time, before extra time).
  bool _breakNow = false;

  /// What happened in the running half, for the stoppage time.
  int _halfGoals = 0;

  /// Session minute the current half began and the one before it (step
  /// 10g3, for the half-time analysis).
  int _halfFrom = 0;
  int _lastHalfFrom = 0;
  int _halfSubs = 0;
  int _halfInjuries = 0;
  int _halfCards = 0;
  int _halfWasted = 0;
  int _halfChecks = 0;
  int _halfTreatments = 0;
  int _goalsHome = 0;
  int _goalsAway = 0;
  bool _finished = false;
  final List<SessionAction> _actions = [];
  bool _extraTime = false;
  int? _shootoutWinner;

  MatchRules get _m => rules.match;

  /// A trait of the referee from -1 to 1, 0 without referee.
  double _rt(RefereeTrait trait) => referee?.tx(trait) ?? 0;

  /// How error-prone the referee is: rates of wrong decisions times this.
  double get _err =>
      (1 + _m.video.errorTrait * _rt(RefereeTrait.errors)).limit(0.1, 3.0);

  /// A foul with advantage that waits for the end of the attack: the team
  /// that fouled, the fouler, and whether it denied a clear chance.
  (int, _Slot, bool)? _advantage;

  /// Cards of the home team are a little rarer with a home referee, those
  /// of the away team a little more frequent (not on neutral ground).
  double _cardBias(int i) => _neutral
      ? 1
      : 1 +
            _m.referee.homeBiasCards *
                _rt(RefereeTrait.homeBias) *
                (i == 0 ? -1 : 1);

  /// Minutes played so far, stoppage time included. [advanceTo] and saved
  /// actions count in these minutes.
  int get minute => _minute;

  /// Minute on the clock (45 and 90 during stoppage time).
  int get clock => _clock;

  /// Minute of stoppage time, 0 outside it.
  int get added => _added;

  /// The clock as shown: "45+2" in stoppage time.
  String get clockLabel => _added > 0 ? '$_clock+$_added' : '$_clock';

  /// Announced stoppage time of the running half, or null.
  int? get stoppage => _stoppage;
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
      advanceTo(a.minute);
      if (knockout && _finished && _minute < a.minute) {
        _startExtraTimeIfLevel();
        advanceTo(a.minute);
      }
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

  /// Opponents followed by the man markers of [side] (step 10g1).
  Set<PlayerId> markedBy(int side) => _sides[side].marked.keys.toSet();

  /// Energy (0 to 100) of a player now: tired on the pitch, the fitness he
  /// came with on the bench.
  double energyOf(int side, PlayerId id) {
    for (final s in _sides[side].pitch) {
      if (s.player.id == id) return s.energy;
    }
    return _sides[side].team.fitness[id] ?? 100.0;
  }

  /// Confidence (0 to 100) of a player of [side] now (step 10f2).
  double confidenceOf(int side, PlayerId id) =>
      _placeOf(side, id)?.conf ?? _sides[side].team.confidence[id] ?? 50;

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

  int substitutionsLeft(int side) => _maxSubs - _sides[side].subsUsed;

  /// Substitution windows left for [side]; changes in a break (half time,
  /// before extra time) do not use one.
  int windowsLeft(int side) => _maxWindows - _sides[side].windowsUsed;

  /// True in a break of the match: before kick-off, at half time and
  /// before extra time. Changes there use no window.
  bool get inBreak => _minute == 0 || _breakNow;

  /// True if [side] may substitute now: changes and a window left (or the
  /// window of this stoppage is already open).
  bool canSubstitute(int side) => !_finished && _canSub(_sides[side]);

  int get _maxSubs =>
      rules.tactics.maxSubstitutions +
      (_extraTime ? rules.tactics.extraTimeExtraSubstitutions : 0);

  int get _maxWindows =>
      rules.tactics.substitutionWindows +
      (_extraTime ? rules.tactics.extraTimeExtraWindows : 0);

  bool _canSub(_Side side) =>
      side.subsUsed < _maxSubs &&
      (inBreak ||
          side.windowMinute == _minute ||
          side.windowsUsed < _maxWindows);

  void _useWindow(_Side side) {
    if (inBreak || side.windowMinute == _minute) return;
    side.windowsUsed++;
    side.windowMinute = _minute;
  }

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
      side.pitch.add(
        _newSlot(side, player, formation.slots[i], sheet.slotRoles[i]),
      );
      side.entered[player.id] = 0;
    }
    final named = sheet.captain;
    if (named != null && sheet.startingXi.contains(named)) {
      side.captain = named;
    } else if (side.pitch.isNotEmpty) {
      var best = side.pitch.first.player;
      for (final s in side.pitch) {
        if (s.tx[CharacterTrait.leadership.index] >
            _trait(best, CharacterTrait.leadership)) {
          best = s.player;
        }
      }
      side.captain = best.id;
    }
    for (final id in sheet.bench) {
      final player = side.byId[id];
      if (player == null || sheet.startingXi.contains(id)) {
        throw ArgumentError('Bad substitute');
      }
      side.bench.add(player);
    }
  }

  /// A new place on the pitch for [player]: energy from his fitness minus
  /// what the last night cost a party animal, and his form on the day.
  _Slot _newSlot(_Side side, Player player, Position position, String? role) {
    final c = _m.character;
    final fitness = side.team.fitness[player.id] ?? 100.0;
    final party = math.max(0.0, _trait(player, CharacterTrait.partyFactor));
    // The guests lost some energy on a long trip.
    final road = identical(side, _sides[1]) ? 1 - setting.travel : 1.0;
    final slot = _Slot(
      player,
      position,
      role,
      math.max(0.0, (fitness - c.partyEnergy * party) * road),
      _minute,
    );
    final spread =
        c.dayFormSpread *
        (1 - c.consistencyEffect * _trait(player, CharacterTrait.consistency))
            .limit(0.1, 2.0);
    slot.dayForm = 1 + spread * (2 * _rng.nextDouble() - 1);
    for (final t in CharacterTrait.values) {
      slot.tx[t.index] = _trait(player, t);
    }
    slot.conf = side.team.confidence[player.id] ?? 50;
    slot.mood = side.team.mood[player.id] ?? _moodNeutral;
    slot.instr = side.sheet.instructions[player.id];
    slot.counterMult = _abilityMult(
      player,
      const [SpecialAbilityType.counterPlayer],
      _m.counter.abilityBonus,
    );
    return slot;
  }

  /// A character trait of [p] as a number from -1 to 1 (0 is average).
  double _trait(Player p, CharacterTrait t) {
    final c = _m.character;
    final v = p.traits[t] ?? c.reference;
    return ((v - c.reference) / c.scale).limit(-1.0, 1.0);
  }

  /// Chemistry of the players of [side] on the pitch, 0 to 1 (step 10f4).
  double chemistryOf(int side) => _sides[side].chemistry;

  /// The captain of [side] (named on the sheet or chosen by leadership).
  PlayerId? captainOf(int side) => _sides[side].captain;

  /// True in moments that test the nerves: a close game late on, extra time.
  bool get _pressure {
    final c = _m.character;
    if (_extraTime) return true;
    return _clock >= c.pressureFromMinute &&
        (_goalsHome - _goalsAway).abs() <= c.pressureMaxDiff;
  }

  /// Goal difference from the view of side [t].
  int _lead(int t) => t == 0 ? _goalsHome - _goalsAway : _goalsAway - _goalsHome;

  // -------------------------------------------------------------- ratings

  double _formFactor(_Side side, Player p) {
    final form = side.team.form[p.id] ?? _m.defaultForm;
    return _m.formMinFactor +
        (_m.formMaxFactor - _m.formMinFactor) * form / 100;
  }

  /// The mood a player has without reasons (step 10f3).
  double get _moodNeutral {
    final v = _m.confidence['mood_neutral'];
    return v == 0 ? 60 : v;
  }

  /// Mood on the day form (step 10f3): a few per cent up or down.
  double _moodFactor(_Slot s) =>
      1 +
      _m.confidence['mood_form'] *
          ((s.mood - _moodNeutral) / 40).clamp(-1.5, 1.0);

  /// A sulking player fouls more (step 10f3).
  double _sulk(_Slot s) {
    final low = _m.confidence['mood_low'];
    if (s.mood >= low || low <= 0) return 0;
    return _m.confidence['mood_foul'] * (low - s.mood) / low;
  }

  double _energyFactor(_Slot s) => 1 - _m.fatigueScale * (1 - s.energy / 100);

  /// Mean of [attributes] of the player on [s] with all factors of the
  /// match; without the energy factor when [tired] is false (engine 2 keeps
  /// those values and applies the energy at the moment of the duel).
  double _slotMean(
    _Side side,
    _Slot s,
    Iterable<Attribute> attributes, {
    bool tired = true,
  }) {
    final base = s.base[attributes] ??= _slotBase(side, s, attributes);
    return tired ? base * _energyFactor(s) : base;
  }

  /// [_slotMean] without tiredness (the mean is linear in its factors).
  double _slotBase(_Side side, _Slot s, Iterable<Attribute> attributes) {
    final tactics = rules.tactics;
    final role = s.role == null ? null : tactics.role(s.role!);
    final mult =
        _fit.positionMultiplier(s.player, s.position) *
        _formFactor(side, s.player) *
        s.dayForm *
        _moodFactor(s);
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
      fitSum += s.fit ??= _fit.playerFit(s.player, s.position, s.role);
    }
    final teamFit = side.pitch.isEmpty ? 0.0 : fitSum / side.pitch.length;
    // A coach with tactical knowledge gets changes across faster (10f3).
    final unsettled =
        math.max(0, side.countedChanges - tactics.freeChanges) *
        tactics.penaltyPerExtraChange *
        (1.5 - side.team.coach.tactics / 100).clamp(0.5, 1.5);
    side.fitBonus = math.max(0.0, tactics.fitBonusMax * teamFit - unsettled);
    side.marked = _marks(side);
    final pair = side.team.chemistry;
    // Only when the players on the pitch changed (the zone tables are
    // dropped then as well).
    if (pair != null && side.zones == null) {
      final players = [
        for (final s in side.pitch) (s.player.id, s.position),
      ];
      side.chemistry = teamChemistry(players, pair);
      side.chemFactor =
          1 + 2 * _m.confidence['chemistry'] * (side.chemistry - 0.5);
    }
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
    if (side.fxStale) {
      _effects(side);
      side.fxStale = false;
    }
  }

  /// Builds the zone tables of [side] from the players on the pitch now.
  /// They stay until a player leaves or comes on; tiredness is applied in
  /// the duel itself.
  _Zones _buildZones(_Side side) {
    final z = _m.zones;
    final acts = _m.actions;
    final actions = acts.list;
    final c = _m.character;
    final n = actions.length;
    final slots = List<_Slot>.of(side.pitch);
    for (final s in slots) {
      if (s.act.isEmpty) {
        s
          ..act = [
            for (final a in actions) _slotMean(side, s, a.attack, tired: false),
          ]
          ..def = [
            for (final a in actions) _slotMean(side, s, a.defend, tired: false),
          ];
      }
    }
    // Static factors per player and action: abilities and character.
    final attStatic = [
      for (final s in slots)
        Float64List.fromList([
          for (final a in actions)
            _abilityMult(s.player, a.abilities, acts.abilityBonus),
        ]),
    ];
    final choiceStatic = [
      for (var i = 0; i < slots.length; i++)
        Float64List.fromList([
          for (var k = 0; k < n; k++)
            attStatic[i][k] * _characterWeight(slots[i], actions[k].id),
        ]),
    ];
    final defStatic = [
      for (final s in slots)
        Float64List.fromList([
          for (final a in actions)
            _abilityMult(s.player, a.defendAbilities, acts.abilityBonus) *
                (1 +
                    c.aggressionDuel *
                        s.tx[CharacterTrait.aggression.index]) *
                (s.instr == PlayerInstruction.hard
                    ? 1 + _m.instructions.get('hard_duel')
                    : 1.0),
        ]),
    ];
    final system = [
      for (final a in actions) acts.systemWeight(side.sheet.systemId, a.id),
    ];
    const lanes = ZoneRules.lanes;
    const count = ZoneRules.columns * lanes;
    final carry = <Float64List>[];
    final defend = <Float64List>[];
    final choice = <List<Float64List>>[];
    final attRel = <List<Float64List>>[];
    final defRel = <List<Float64List>>[];
    for (var zone = 0; zone < count; zone++) {
      final column = zone ~/ lanes;
      final lane = zone % lanes;
      // As carrier the zone is seen from this side, as defender from the
      // other side: column and lane are mirrored.
      final cw = Float64List.fromList([
        for (final s in slots)
          z.columnWeights[s.position]![column] *
              z.laneFactor(s.position, lane) *
              _instrCarry(s, column),
      ]);
      final dw = Float64List.fromList([
        for (final s in slots)
          s.position.isGoalkeeper
              ? 0.0
              : z.columnWeights[s.position]![ZoneRules.columns - 1 - column] *
                    z.laneFactor(s.position, lanes - 1 - lane) *
                    _instrDefend(s, ZoneRules.columns - 1 - column),
      ]);
      _fallback(cw, slots);
      _fallback(dw, slots);
      carry.add(cw);
      defend.add(dw);
      final actMean = [
        for (var k = 0; k < n; k++)
          _weightedMean(cw, [for (final s in slots) s.act[k]]),
      ];
      final defMean = [
        for (var k = 0; k < n; k++)
          _weightedMean(dw, [for (final s in slots) s.def[k]]),
      ];
      final zoneChoice = <Float64List>[];
      final zoneAtt = <Float64List>[];
      final zoneDef = <Float64List>[];
      for (var i = 0; i < slots.length; i++) {
        final s = slots[i];
        final w = Float64List(n);
        final att = Float64List(n);
        final def = Float64List(n);
        for (var k = 0; k < n; k++) {
          final a = actions[k];
          final rel = s.act[k] / actMean[k];
          att[k] = rel * attStatic[i][k];
          def[k] = s.def[k] / defMean[k] * defStatic[i][k];
          final base = a.weights[column] * a.lanes[lane] * system[k];
          w[k] = base <= 0
              ? 0
              : base *
                    math.pow(rel, acts.skillExponent).toDouble() *
                    choiceStatic[i][k];
        }
        zoneChoice.add(w);
        zoneAtt.add(att);
        zoneDef.add(def);
      }
      choice.add(zoneChoice);
      attRel.add(zoneAtt);
      defRel.add(zoneDef);
    }
    final shooter = [
      for (var lane = 0; lane < lanes; lane++)
        Float64List.fromList([
          for (final s in slots)
            s.position.isGoalkeeper
                ? 0.0
                : _m.shooterSlotWeight[s.position]! *
                          s.player.attributes[Attribute.goalInstinct] *
                          math
                              .pow(
                                z.laneFactor(s.position, lane),
                                z.shooterLaneExponent,
                              )
                              .toDouble() +
                      0.001,
        ]),
    ];
    return _Zones(
      slots: slots,
      carry: carry,
      defend: defend,
      choice: choice,
      attRel: attRel,
      defRel: defRel,
      shooter: shooter,
    );
  }

  /// Pushing up or staying back moves where a player has the ball (step
  /// 10g1): [column] of the own view, 0 at the own goal.
  double _instrCarry(_Slot s, int column) {
    final r = _m.instructions;
    final deep = column >= ZoneRules.columns - 2;
    final back = column <= 1;
    return switch (s.instr) {
      PlayerInstruction.forward when deep => r.get('forward_attack', 1),
      PlayerInstruction.forward when back => r.get('forward_back', 1),
      PlayerInstruction.stayBack when deep => r.get('stay_attack', 1),
      PlayerInstruction.stayBack when back => r.get('stay_back', 1),
      _ => 1,
    };
  }

  /// And where he defends ([column] of the own view); a man marker is busy
  /// with his man and missing in the zones.
  double _instrDefend(_Slot s, int column) {
    final r = _m.instructions;
    final back = column <= 1;
    return switch (s.instr) {
      PlayerInstruction.manMark => 1 - r.get('mark_absent'),
      PlayerInstruction.forward when back => r.get('forward_back', 1),
      PlayerInstruction.stayBack when back => r.get('stay_back', 1),
      _ => 1,
    };
  }

  /// The lanes an attack starts in: by system, more on an overloaded wing
  /// (step 10g1). Lane 0 is the left wing of the attacking team.
  List<double> _lanes(_Side side) {
    final planned = side.plan.containsKey(PlanFocus.weakSide)
        ? side.planWing
        : null;
    var base = _m.zones.lanesFor(side.sheet.systemId);
    if (side.shout == Shout.wide && side.shoutUntil >= _minute) {
      const last = ZoneRules.lanes - 1;
      base = [
        for (var l = 0; l < base.length; l++)
          base[l] * (l == 0 || l == last ? 1 + side.shoutPower : 1.0),
      ];
    }
    final wing = side.sheet.wing ?? planned;
    if (wing == null) return base;
    final r = _m.instructions;
    const last = ZoneRules.lanes - 1;
    double factor(int l) {
      // Distance of the lane from the chosen touchline: 0 wing, 1 half
      // space; the far side gets less.
      final near = wing == Wing.left ? l : last - l;
      if (near == 0) return r.get('wing', 1);
      if (near == 1) return r.get('wing_half', 1);
      if (near >= last - 1) return r.get('wing_other', 1);
      return 1;
    }

    return [for (var l = 0; l < base.length; l++) base[l] * factor(l)];
  }

  /// The opponents the man markers of [side] follow: each takes the most
  /// dangerous attacker not yet taken (step 10g1). The factor on their
  /// duels grows with the marker's defending against the target's skill.
  Map<PlayerId, double> _marks(_Side side) {
    final markers = [
      for (final s in side.pitch)
        if (s.instr == PlayerInstruction.manMark) s,
    ];
    if (markers.isEmpty) return const {};
    final other = _sides[1 - _sides.indexOf(side)];
    final attackers = [
      for (final s in other.pitch)
        if (!s.position.isGoalkeeper && lineOf(s.position) >= 2) s,
    ]..sort(
        (a, b) => _fit
            .slotScore(b.player, b.position)
            .compareTo(_fit.slotScore(a.player, a.position)),
      );
    final out = <PlayerId, double>{};
    final strength = _m.instructions.get('mark_target');
    for (var i = 0; i < markers.length && i < attackers.length; i++) {
      final marker = markers[i];
      final target = attackers[i];
      final q =
          (_fit.slotScore(marker.player, marker.position) /
                  math.max(1.0, _fit.slotScore(target.player, target.position)))
              .clamp(0.6, 1.4);
      out[target.player.id] = 1 - strength * q;
    }
    return out;
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

  /// Plays all minutes up to and including [target] (minutes played with
  /// stoppage time, see [minute]); stops at the final whistle.
  void advanceTo(int target) {
    while (_minute < target && !_finished) {
      _minute++;
      _breakNow = false;
      if (_stoppage == null) {
        _clock++;
      } else {
        _added++;
      }
      _playMinute(_minute);
      if (_stoppage == null && _clock >= _halfEnds[_half]) {
        _stoppage = _stoppageTime();
        _add(MatchEventType.addedTime, -1, value: _stoppage);
      }
      if (_stoppage != null && _added >= _stoppage!) _endHalf();
    }
  }

  static const int _whistle = 1 << 30;

  /// Plays on to the next final whistle.
  void _playOut() => advanceTo(_whistle);

  /// Stoppage time of the running half from what happened in it.
  int _stoppageTime() {
    final a = _m.addedTime;
    final base = _extraTime
        ? a.extraTimeBase
        : _half == 0
        ? a.firstHalfBase
        : a.secondHalfBase;
    final minutes =
        base +
        a.perGoal * _halfGoals +
        a.perSubstitution * _halfSubs +
        a.perInjury * _halfInjuries +
        a.perCard * _halfCards +
        a.perTimeWasting * _halfWasted +
        _m.video.stoppagePerCheck * _halfChecks +
        _m.treatment.stoppage * _halfTreatments +
        a.random * _rng.nextDouble();
    return minutes.round().clamp(0, a.max);
  }

  void _endHalf() {
    final last = _half == _halfEnds.length - 1;
    _halfGoals = 0;
    _halfSubs = 0;
    for (final side in _sides) {
      side.shoutsUsed = 0;
    }
    _halfInjuries = 0;
    _halfCards = 0;
    _halfWasted = 0;
    _halfChecks = 0;
    _halfTreatments = 0;
    if (last) {
      _add(MatchEventType.fullTime, -1);
      _closeBooks();
      _finished = true;
    } else {
      _add(MatchEventType.halfTime, -1);
      _half++;
      _breakNow = true;
      _lastHalfFrom = _halfFrom;
      _halfFrom = _minute;
    }
    _stoppage = null;
    _added = 0;
    // The AI coaches talk in the break (on the clock of the break, so the
    // conference clock runs on from the half).
    if (!last) {
      for (var i = 0; i < _sides.length; i++) {
        final side = _sides[i];
        if (side.team.autoManage || side.assistant) _aiTalk(i);
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
    _halfEnds = [_clock + halfMinutes, _clock + 2 * halfMinutes];
    _half = 0;
    _finished = false;
    _extraTime = true;
    _breakNow = true;
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
      final nerves =
          1 +
          _m.character.pressurePenalty *
              slot.tx[CharacterTrait.pressureResistance.index];
      final p = (_m.penaltyGoal * math.pow(score / keeper, 0.5) * nerves).limit(
        0.2,
        0.95,
      );
      final goal = _rng.nextDouble() < p;
      taken[t]++;
      if (goal) scored[t]++;
      _events.add(
        MatchEvent(
          minute: _clock,
          added: _added,
          tick: _minute,
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
    _playOut();
    _startExtraTimeIfLevel();
    _playOut();
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
    _playOut();
    return MatchResult(
      homeGoals: _goalsHome,
      awayGoals: _goalsAway,
      events: List.unmodifiable(_events),
      homeStats: _sides[0].stats,
      awayStats: _sides[1].stats,
      injuries: List.unmodifiable(_injuries),
      minutesPlayed: {for (final side in _sides) ...side.played},
      length: _minute,
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
    int? value,
    int? spot,
    List<AttackStep> steps = const [],
    Player? keeper,
    String? review,
  }) {
    _events.add(
      MatchEvent(
        keeper: keeper?.id,
        review: review,
        minute: _clock,
        added: _added,
        tick: _minute,
        value: value,
        spot: spot,
        steps: steps.isEmpty ? const [] : List.unmodifiable(steps),
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
    _timeWasting();
    final tempo = [
      for (final side in _sides)
        _m.tempoPhaseFactor[rules.tactics.sliders[1].levels[side.sheet.tempo
            .limit(0, 2)]]!,
    ];
    final phases =
        _m.phasesPerMatch /
        _m.minutes *
        _rate *
        (tempo[0] + tempo[1]) /
        2 *
        (1 + _m.crowd.derbyTempo * setting.derby);
    var n = phases.floor();
    if (_rng.nextDouble() < phases - n) n++;
    for (var i = 0; i < n; i++) {
      _phase();
    }
    _tire(minute);
    if (minute % _m.aiCheckInterval == 0 || _dirty) {
      for (final side in _sides) {
        if (side.team.autoManage || side.assistant) {
          _assistant(side);
          _coach(side);
        }
        _refresh(side);
      }
      _dirty = false;
    }
  }

  bool _dirty = false;

  /// Per-minute rates of the match are scaled down a little, so that the
  /// stoppage time does not make matches richer in goals and cards.
  double get _rate =>
      _m.minutes / (_m.minutes + _m.addedTime.expected);

  void _tire(int minute) {
    for (final side in _sides) {
      final phase = _clock < _m.fatigueStartMinute ? 0.5 : 1.5;
      for (final s in side.pitch) {
        final stamina = s.player.attributes[Attribute.stamina];
        final factor = (_m.staminaReference / stamina).limit(
          _m.staminaMinFactor,
          _m.staminaMaxFactor,
        );
        s.energy = math.max(
          0.0,
          s.energy -
              _m.energyLossPerMinute *
                  phase *
                  side.drainMult *
                  factor *
                  (setting.weather == 'heat' ? _m.weather.heatDrain : 1.0),
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
    final pending = _counter;
    _counter = null;
    final int t;
    if (pending != null) {
      t = pending.$1;
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
    // A man short for a minute after a treatment or a slow change.
    final shortA = attacker.shortUntil >= _minute
        ? _m.treatment.shortFactor
        : 1.0;
    final shortD = defender.shortUntil >= _minute
        ? _m.treatment.shortFactor
        : 1.0;
    var att =
        shortA *
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
        shortD *
        defender.ratings.defense *
        (1 + _fx(o, 'dfn')) *
        defender.homeFactor *
        (1 + _m.momentumEffect * defender.momentum);
    var state = 1.0;
    if (_clock >= _m.gameStateFromMinute) {
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
    final goalsBefore = _goalsHome + _goalsAway;
    _attack(t, q, counter: pending);
    _resolveAdvantage(_goalsHome + _goalsAway > goalsBefore);
  }

  /// The place of [id] on the pitch of side [i], null if he is not there.
  _Slot? _placeOf(int i, PlayerId? id) {
    if (id == null) return null;
    for (final s in _sides[i].pitch) {
      if (s.player.id == id) return s;
    }
    return null;
  }

  /// Moves the confidence of [s] by [delta] (step 10f2).
  void _boost(_Slot? s, double delta) {
    if (s == null) return;
    s.conf = (s.conf + delta).clamp(0.0, 100.0);
  }

  /// What weather and ground do to a step of [action] (engine 2, step
  /// 10e5): rain, snow and a bad ground make technical play harder, wind
  /// makes long balls and crosses less sure.
  double _conditions(String action) {
    final w = _m.weather;
    var f = 1.0;
    if (w.techniqueActions.contains(action)) {
      f *= w.technique[setting.weather] ?? 1.0;
      f *= w.technique[setting.ground] ?? 1.0;
    }
    if (setting.weather == 'wind' &&
        (action == 'long_ball' || action == 'cross')) {
      f *= w.windLong;
    }
    return f;
  }

  /// After an attack with advantage the referee comes back to the foul: no
  /// card for a Notbremse that ended in a goal (IFAB 2026/27), a yellow if
  /// the chance was not denied after all, else the usual card chance.
  void _resolveAdvantage(bool scored) {
    final adv = _advantage;
    _advantage = null;
    if (adv == null) return;
    final (o, fouler, dogso) = adv;
    if (!_sides[o].pitch.contains(fouler)) return;
    if (dogso) {
      if (!scored) _yellow(o, fouler, reason: 'advantage');
    } else if (_rng.nextDouble() < _foulCard) {
      _yellow(o, fouler, reason: 'advantage');
    }
  }

  /// Chance of a yellow card for a foul, by the strictness of the referee.
  double get _foulCard =>
      (_m.referee.cardAfterFoul *
              (1 + _m.referee.strictnessYellow * _rt(RefereeTrait.strictness)))
          .limit(0.0, 1.0);

  /// A defender may foul the attacker who just won the duel (from column 2
  /// on). The referee whistles (free kick, penalty in the box, card) or lets
  /// play run on (advantage). Returns true if the whistle ends the attack.
  bool _foul(
    int t,
    _Slot victim,
    _Slot fouler,
    int column,
    int lane,
    bool through,
  ) {
    final r = _m.referee;
    final o = 1 - t;
    final p =
        r.foulChance *
        math.max(
          0.1,
          1 + r.foulAggression * fouler.tx[CharacterTrait.aggression.index],
        ) *
        // A booked player holds back.
        ((_sides[o].yellows[fouler.player.id] ?? 0) > 0
            ? _m.repeatYellowWeight
            : 1.0) *
        (1 + fouler.heat + _sulk(fouler)) /
        _shoutF(o, Shout.calm) *
        (fouler.instr == PlayerInstruction.hard
            ? 1 +
                  _m.instructions.get('hard_foul') *
                      (1 +
                          0.5 *
                              math.max(
                                0.0,
                                fouler.tx[CharacterTrait.temper.index],
                              ))
            : 1.0);
    if (_rng.nextDouble() >= p) return false;
    final dogso = through && _rng.nextDouble() < r.dogsoShare;
    final advantage =
        _advantage == null &&
        _rng.nextDouble() <
            (r.advantageBase *
                    (1 + r.advantageTrait * _rt(RefereeTrait.advantage)))
                .limit(0.0, 0.9);
    _add(
      MatchEventType.foul,
      o,
      player: fouler.player,
      other: victim.player,
      column: column,
      lane: lane,
      action: advantage ? 'advantage' : 'whistle',
      value: dogso ? 1 : 0,
    );
    if (advantage) {
      _advantage = (o, fouler, dogso);
      return false;
    }
    final inBox =
        through &&
        _rng.nextDouble() <
            r.boxPenaltyShare *
                (1 + r.penaltyLove * _rt(RefereeTrait.penalties));
    if (dogso && !inBox) {
      // Notbremse outside the box: red.
      _sendOff(o, fouler, false, reason: 'dogso');
    } else if (dogso) {
      // In the box with a try for the ball: penalty and yellow only.
      _yellow(o, fouler, reason: 'dogso_box');
    } else if (_rng.nextDouble() < _foulCard) {
      _yellow(o, fouler, reason: 'foul');
    }
    if (inBox) {
      _penalty(t);
    } else {
      _freeKick(t);
    }
    if (inBox) _dissent(o);
    return true;
  }

  /// Protest after a decision against side [i]. Only the captain may talk
  /// to the referee (IFAB 2025/26); anyone else risks a yellow, more so
  /// with a strict referee of authority. Hot heads protest more, a strong
  /// captain does the talking, a missing captain lets it get out of hand.
  void _dissent(int i) {
    final r = _m.referee;
    final side = _sides[i];
    if (side.pitch.length < 2) return;
    var temper = 0.0;
    for (final s in side.pitch) {
      temper += s.tx[CharacterTrait.temper.index];
    }
    temper /= side.pitch.length;
    final captain = side.pitch
        .where((s) => s.player.id == side.captain)
        .firstOrNull;
    var p = r.dissentChance * math.max(0.1, 1 + r.dissentTemper * temper);
    if (captain == null) p *= 1 + r.missingCaptainDissent;
    if (_rng.nextDouble() >= p) return;
    if (captain != null &&
        _rng.nextDouble() <
            r.captainFirst *
                (1 + 0.5 * captain.tx[CharacterTrait.leadership.index])) {
      _add(
        MatchEventType.dissent,
        i,
        player: captain.player,
        action: 'captain',
      );
      return;
    }
    final others = [
      for (final s in side.pitch)
        if (s != captain && !s.position.isGoalkeeper) s,
    ];
    if (others.isEmpty) return;
    final who =
        others[_rng.weightedIndex([
          for (final s in others)
            math.max(0.1, 1 + s.tx[CharacterTrait.temper.index]),
        ])];
    _add(MatchEventType.dissent, i, player: who.player, action: 'protest');
    final card =
        (r.dissentCard *
                (1 + r.strictnessYellow * _rt(RefereeTrait.strictness)) *
                (1 + r.dissentAuthority * _rt(RefereeTrait.authority)))
            .limit(0.0, 1.0);
    if (_rng.nextDouble() < card) _yellow(i, who, reason: 'dissent');
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
    var lane = counter?.$3 ?? _rng.weightedIndex(_lanes(attacker));
    final reference = z.referenceShare;
    final chain = <Player>[];
    final steps = <AttackStep>[];
    var step = 0;
    ActionRule? lastAction;
    _Slot? lastCarrier;
    while (column < last) {
      final zone = column * lanes + lane;
      final ci = _rng.weightedIndex(own.carry[zone]);
      final carrier = own.slots[ci];
      var a = _chooseAction(own.choice[zone][ci]);
      // "Schieß doch!": now and then a shot from where he stands.
      if (column >= 2 &&
          _shoutF(t, Shout.shoot) > 1 &&
          _rng.nextDouble() <
              _m.instructions.get('shout_shoot') *
                  attacker.shoutPower) {
        final shot = acts.list.indexWhere((x) => x.id == 'long_shot');
        if (shot >= 0) a = shot;
      }
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
          steps: steps,
        );
        return;
      }
      if (chain.isEmpty || chain.last.id != carrier.player.id) {
        chain.add(carrier.player);
      }
      final ti = _rng.weightedIndex(other.defend[zone]);
      final tackler = other.slots[ti];
      var ratio =
          own.attRel[zone][ci][a] *
          _energyFactor(carrier) /
          (other.defRel[zone][ti][a] * _energyFactor(tackler));
      if (counter != null && step < _m.counter.disorderSteps) {
        ratio *= carrier.counterMult / _m.counter.disorder;
      }
      ratio *= _characterDuel(t, carrier, tackler);
      ratio *= defender.marked[carrier.player.id] ?? 1.0;
      ratio *= _planStep(
        t,
        carrier,
        action.id,
        column,
        lane,
        counter: counter != null,
      );
      // Shouts (step 10g4): pressure up front, calm on the ball, the back
      // closed.
      if (column <= 2) ratio /= _shoutF(o, Shout.push);
      ratio *= 1 + (_shoutF(t, Shout.calm) - 1) / 2;
      if (column >= 3) ratio /= _shoutF(o, Shout.tight);
      final duel = math
          .pow(ratio, z.duelExponent)
          .toDouble()
          .limit(z.duelRatioMin, z.duelRatioMax);
      final target = math.min(column + action.advance, last);
      final share = z.shareFrom(column) - z.shareFrom(target);
      final creative = action.id == 'through_ball'
          ? 1 -
                _m.character.creativityRisk *
                    carrier.tx[CharacterTrait.creativity.index]
          : 1.0;
      final p =
          (math.pow(q, share / reference).toDouble() *
                  action.risk *
                  creative *
                  duel *
                  _conditions(action.id) *
                  (action.id == 'short_pass' || action.id == 'through_ball'
                      ? _sides[t].chemFactor
                      : 1.0) *
                  _instrStep(carrier, action.id) *
                  (action.id == 'dribble' || action.id == 'through_ball'
                      ? 1 + _m.confidence['bold'] * (carrier.conf - 50) / 50
                      : 1.0))
              .limit(z.stepMin, z.stepMax);
      final roll = _rng.nextDouble();
      final won = roll < p;
      // What the reporter can tell about this step, from the numbers the
      // duel used anyway (no extra dice).
      var flags = 0;
      if (other.defRel[zone][ti][a] > 1.15 || p < 0.45) {
        flags |= AttackStep.pressure;
      }
      if (won ? duel >= 1.25 : duel <= 0.8) flags |= AttackStep.clear;
      if ((roll - p).abs() < 0.08) flags |= AttackStep.close;
      if (won && own.attRel[zone][ci][a] >= 1.2 && action.id != 'short_pass') {
        flags |= AttackStep.pretty;
      }
      if ((counter != null && step < _m.counter.disorderSteps) ||
          (action.advance > 1 &&
              carrier.player.attributes[Attribute.acceleration] >= 75)) {
        flags |= AttackStep.fast;
      }
      steps.add(
        AttackStep(
          player: carrier.player.id,
          action: action.id,
          column: column,
          lane: lane,
          won: won,
          opponent: tackler.player.id,
          flags: flags,
        ),
      );
      if (!won) {
        _lost(t, carrier, tackler, column, lane, action.id, steps);
        return;
      }
      if (column >= 2 &&
          action.id != 'short_pass' &&
          _foul(t, carrier, tackler, column, lane, target == last)) {
        return;
      }
      column = target;
      lastAction = action;
      lastCarrier = carrier;
      step++;
      if (_rng.nextDouble() < z.laneChange) lane = _newLane(lane);
    }
    _chance(
      t,
      lane: lane,
      chain: chain,
      carrier: lastCarrier?.player,
      selfShot: lastAction?.selfShot ?? 1,
      shotBias: lastAction?.shotBias ?? const {},
      action: lastAction?.id,
      steps: steps,
      bigChance: lastAction?.id == 'through_ball' && lastCarrier != null
          ? 1 +
                _m.character.creativityBigChance *
                    lastCarrier.tx[CharacterTrait.creativity.index]
          : 1,
    );
  }

  /// The lane after a change: mostly next door, sometimes a switch of play
  /// over two lanes, never off the pitch.
  int _newLane(int lane) {
    const last = ZoneRules.lanes - 1;
    final step = _rng.nextDouble() < _m.zones.laneJumpTwo ? 2 : 1;
    final towardsCentre = lane < ZoneRules.centre ? step : -step;
    final away = -towardsCentre;
    final goAway = lane != ZoneRules.centre && _rng.nextDouble() < 0.3;
    final candidate = lane == ZoneRules.centre
        ? lane + (_rng.nextDouble() < 0.5 ? step : -step)
        : lane + (goAway ? away : towardsCentre);
    return candidate.clamp(0, last);
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
    List<AttackStep> steps,
  ) {
    final o = 1 - t;
    final z = _m.zones;
    final c = _m.counter;
    final winner = _sides[o];
    winner.stats.ballsWon++;
    _boost(tackler, _m.confidence['ball_won']);
    _boost(carrier, -_m.confidence['ball_lost']);
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
        steps: steps,
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
        steps: steps,
      );
    }
  }

  /// Picks what the player in [slot] does with the ball: the weight of an
  /// action comes from the column and lane, the system of the team and how
  /// good the player is at it compared with those usually in the zone.
  int _chooseAction(Float64List weights) {
    var total = 0.0;
    for (final w in weights) {
      total += w;
    }
    if (total <= 0) return _m.actions.list.indexWhere((a) => !a.isShot);
    return _rng.weightedIndex(weights);
  }

  /// How the character of [p] changes the weight of the action [id]:
  /// egoists shoot from distance, creative players try the through ball.
  double _characterWeight(_Slot s, String id) =>
      _traitWeight(s, id) * _instrWeight(s, id);

  /// How an instruction moves the choice of an action (step 10g1).
  double _instrWeight(_Slot s, String id) {
    final r = _m.instructions;
    switch (s.instr) {
      case PlayerInstruction.shootMore:
        if (id == 'long_shot') return r.get('shoot_weight', 1);
        if (id == 'short_pass') return r.get('shoot_pass', 1);
      case PlayerInstruction.safe:
        if (id == 'short_pass') return r.get('safe_short', 1);
        if (id == 'through_ball' || id == 'dribble' || id == 'long_ball') {
          return r.get('safe_risky', 1);
        }
      case PlayerInstruction.through:
        if (id == 'through_ball') return r.get('through_weight', 1);
      default:
        break;
    }
    return 1;
  }

  /// How an instruction moves the success of a step (step 10g1).
  double _instrStep(_Slot s, String id) {
    final r = _m.instructions;
    if (s.instr == PlayerInstruction.safe && id == 'short_pass') {
      return 1 + r.get('safe_step');
    }
    if (s.instr == PlayerInstruction.through && id == 'through_ball') {
      return 1 + r.get('through_step');
    }
    return 1;
  }

  double _traitWeight(_Slot s, String id) {
    final c = _m.character;
    switch (id) {
      case 'long_shot':
        return math.max(
          0.05,
          1 + c.egoismLongShot * s.tx[CharacterTrait.egoism.index],
        );
      case 'through_ball':
        return math.max(
          0.05,
          1 + c.creativityThroughBall * s.tx[CharacterTrait.creativity.index],
        );
      default:
        return 1;
    }
  }

  /// Character in a duel between [carrier] and [tackler] of side [t]:
  /// hard tacklers win more balls, ambitious players fight harder when
  /// behind, and nerves count in tight moments.
  double _characterDuel(int t, _Slot carrier, _Slot tackler) {
    final c = _m.character;
    var ratio = 1.0;
    final lead = _lead(t);
    if (lead < 0) {
      ratio *=
          1 + c.ambitionTrailing * carrier.tx[CharacterTrait.ambition.index];
    } else if (lead > 0) {
      ratio /=
          1 + c.ambitionTrailing * tackler.tx[CharacterTrait.ambition.index];
    }
    if (_pressure) {
      const pr = CharacterTrait.pressureResistance;
      ratio *=
          (1 + c.pressureDuel * carrier.tx[pr.index]) /
          (1 + c.pressureDuel * tackler.tx[pr.index]);
    }
    return ratio;
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
    final zones = _zonesOf(side);
    final weights = Float64List.fromList(zones.shooter[lane]);
    var any = false;
    for (var i = 0; i < weights.length; i++) {
      final s = zones.slots[i];
      if (s.position.isGoalkeeper) continue;
      any = true;
      if (s.player.id == carrier?.id) {
        weights[i] *=
            selfShot *
            math.max(
              0.05,
              1 + _m.character.egoismSelfShot * s.tx[CharacterTrait.egoism.index],
            );
      }
    }
    if (!any) return null;
    return zones.slots[_rng.weightedIndex(weights)].player;
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
    int lane = ZoneRules.centre,
    List<Player> chain = const [],
    Player? shooter,
    String? forceType,
    int? column,
    Player? carrier,
    double selfShot = 1,
    Map<String, double> shotBias = const {},
    String? action,
    double bigChance = 1,
    List<AttackStep> steps = const [],
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
    // Where the chance comes from: edge of the box, box or six-yard box;
    // the spot sets the quality. A shot the player chose from distance has
    // no spot and is always a half chance.
    final spots = _m.zones.chanceSpot;
    final spot = forced >= 0
        ? null
        : _rng.weightedIndex(spots.spotsFor(action));
    final base = spot == null ? _m.qualityWeights : spots.quality[spot];
    final qualityWeights = [
      for (var i = 0; i < base.length; i++)
        base[i] * (i == base.length - 1 ? math.max(0.05, bigChance) : 1),
    ];
    final qualityIndex = forced >= 0 ? 0 : _rng.weightedIndex(qualityWeights);
    final spotBias = spot == null
        ? const <String, double>{}
        : spots.typeBias[spot];
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
                (spotBias[_m.shotTypes[i].id] ?? 1.0) *
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
                ) *
                (_pressure
                    ? 1 +
                          _m.character.pressureGoal *
                              _trait(picked, CharacterTrait.pressureResistance)
                    : 1))
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
      spot: spot,
      steps: steps,
    );
  }

  void _shot(
    int t,
    Player shooter,
    String typeId,
    ChanceQuality? quality,
    double baseGoal, {
    int? column,
    int? lane,
    List<Player> chain = const [],
    String? action,
    int? spot,
    List<AttackStep> steps = const [],
  }) {
    final attacker = _sides[t];
    attacker.stats.shots++;
    // Wind makes shots from distance less sure (engine 2, step 10e5), a
    // confident shooter finishes better (step 10f2).
    final shooterSlot = _placeOf(t, shooter.id);
    final conf = shooterSlot?.conf ?? 50;
    final goalProbability =
        ((typeId == 'long_shot' && setting.weather == 'wind'
                    ? baseGoal * _m.weather.windLongShot
                    : baseGoal) *
                (1 + _m.confidence['shot'] * (conf - 50) / 50) *
                (typeId == 'long_shot' ? _plan(t, PlanFocus.longShots) : 1.0))
            .limit(0.0, 0.97);
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
    // Was it offside? The assistant may miss it or flag a fair goal; the
    // VAR, where there is one, puts it right (engine 2, step 10e2).
    String? review;
    if (outcome == ShotOutcome.goal) {
      final v = _m.video;
      final roll = _rng.nextDouble();
      if (roll < v.goalOffsideMissed * _err) {
        review = video ? 'goal_overturned' : 'offside_missed';
      } else if (roll < (v.goalOffsideMissed + v.goalWronglyFlagged) * _err) {
        review = video ? 'goal_given' : 'goal_disallowed';
      } else if (video && _rng.nextDouble() < v.goalCheck) {
        review = 'goal_confirmed';
      }
      if (video && review != null) _halfChecks++;
    }
    final counts =
        outcome == ShotOutcome.goal &&
        review != 'goal_overturned' &&
        review != 'goal_disallowed';
    if (counts) {
      attacker.stats.goals++;
      _halfGoals++;
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
      defender.momentum = (defender.momentum - _blow(defender)).limit(
        -1.0,
        1.0,
      );
    }
    final Player? assister = counts
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
      spot: spot,
      steps: steps,
      keeper: _sides[1 - t].pitch
          .where((s) => s.position.isGoalkeeper)
          .firstOrNull
          ?.player,
      review: review,
    );
    // Confidence after the shot (step 10f2).
    final cr = _m.confidence;
    final keeperSlot = _sides[1 - t].pitch
        .where((s) => s.position.isGoalkeeper)
        .firstOrNull;
    if (counts) {
      _boost(shooterSlot, cr['goal']);
      _boost(_placeOf(t, assister?.id), cr['assist']);
      _boost(keeperSlot, -cr['conceded']);
    } else {
      if (quality == ChanceQuality.big) _boost(shooterSlot, -cr['big_miss']);
      if (outcome == ShotOutcome.saved) _boost(keeperSlot, cr['save']);
    }
  }

  /// How hard a goal against hits [side]: a strong captain on the pitch
  /// softens it, a missing captain makes it worse.
  double _blow(_Side side) {
    final c = _m.character;
    final captain = side.captain;
    final onPitch = side.pitch
        .where((s) => s.player.id == captain)
        .firstOrNull;
    if (onPitch == null) {
      return _m.momentumGoalAgainst * (1 + c.missingCaptainMomentum);
    }
    return _m.momentumGoalAgainst *
        (1 -
                c.leadershipMomentum *
                    onPitch.tx[CharacterTrait.leadership.index])
            .limit(0.2, 2.0);
  }

  // ------------------------------------------------------------ standards

  int _attackingSide() {
    final b0 = math.pow(_build(0), _m.possessionExponent).toDouble();
    final b1 = math.pow(_build(1), _m.possessionExponent).toDouble();
    return _rng.nextDouble() < b0 / (b0 + b1) ? 0 : 1;
  }

  void _standards() {
    final minutes = _m.minutes / _rate;
    final r = _m.referee;
    if (_rng.nextDouble() <
        _m.freeKicksPerMatch * r.freeKickMinuteShare / minutes) {
      _freeKick(_attackingSide());
    }
    if (_rng.nextDouble() < _m.cornersPerMatch / minutes) {
      _corner(_attackingSide());
    }
    final penalty =
        _m.penaltiesPerMatch *
        r.penaltyMinuteShare *
        (1 + r.penaltyLove * _rt(RefereeTrait.penalties)) /
        minutes;
    if (_rng.nextDouble() < penalty) {
      final t = _attackingSide();
      final bias = _neutral
          ? 1.0
          : 1 +
                r.homeBiasPenalties *
                    _rt(RefereeTrait.homeBias) *
                    (t == 0 ? 1 : -1);
      if (_rng.nextDouble() < bias) {
        _penalty(t);
        _dissent(1 - t);
      }
    }
    // A penalty the referee did not see: the VAR gives it, without VAR the
    // reporter can only complain.
    if (_rng.nextDouble() < _m.video.penaltyMissedPerMatch * _err / minutes) {
      final t = _attackingSide();
      _add(
        MatchEventType.varReview,
        t,
        action: video ? 'penalty_given' : 'penalty_missed',
        value: video ? 1 : 0,
      );
      if (video) {
        _halfChecks++;
        _penalty(t, reviewed: true);
        _dissent(1 - t);
      }
    }
  }

  /// A leading team late in the match plays for time; the Laws punish it
  /// (IFAB 2025/26 and 2026/27): a keeper who holds the ball over eight
  /// seconds or a late goal kick gives a corner, a late throw-in goes to
  /// the opponent.
  void _timeWasting() {
    for (var t = 0; t < _sides.length; t++) {
      _wasteFor(t);
    }
  }

  /// Time wasting of side [t]: when ahead late, or earlier and also level
  /// when the coach told them to (step 10g1, then more often and with a
  /// yellow card now and then).
  void _wasteFor(int t) {
    final w = _m.timeWasting;
    final r0 = _m.instructions;
    final side = _sides[t];
    final lead = _lead(t);
    final told = side.sheet.wasteTime ||
        (side.shout == Shout.slow && side.shoutUntil >= _minute);
    final from = told ? w.fromMinute - r0.get('waste_early') : w.fromMinute;
    if (_clock < from || lead < 0 || (lead == 0 && !told)) return;
    if (side.pitch.isEmpty) return;
    final keeper = side.pitch
        .where((s) => s.position.isGoalkeeper)
        .firstOrNull;
    final r = _rng.nextDouble() / (told ? r0.get('waste_factor', 1) : 1);
    String? kind;
    _Slot? culprit;
    if (r < w.keeperEightSeconds && keeper != null) {
      kind = 'keeper_eight_seconds';
      culprit = keeper;
    } else if (r < w.keeperEightSeconds + w.goalKickCountdown &&
        keeper != null) {
      kind = 'goal_kick_countdown';
      culprit = keeper;
    } else if (r <
        w.keeperEightSeconds + w.goalKickCountdown + w.throwInCountdown) {
      kind = 'throw_in_countdown';
      final field = [
        for (final s in side.pitch)
          if (!s.position.isGoalkeeper) s,
      ];
      if (field.isEmpty) return;
      culprit = field[_rng.nextInt(field.length)];
    }
    if (kind == null || culprit == null) return;
    _halfWasted++;
    _add(MatchEventType.timeWasting, t, player: culprit.player, action: kind);
    if (told && _rng.nextDouble() < r0.get('waste_yellow')) {
      _yellow(t, culprit, reason: 'delay');
    }
    if (kind != 'throw_in_countdown') _corner(1 - t);
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

  void _penalty(int t, {bool reviewed = false}) {
    final attacker = _sides[t];
    final defender = _sides[1 - t];
    final (taker, score) = _taker(attacker, _m.penaltyAttributes);
    // A penalty without a foul: the VAR takes it back, without VAR it is
    // taken (engine 2, step 10e2).
    String? review;
    if (!reviewed && _rng.nextDouble() < _m.video.penaltySoft * _err) {
      review = video ? 'penalty_overturned' : 'penalty_soft';
    }
    if (review == 'penalty_overturned') {
      _halfChecks++;
      _add(MatchEventType.penalty, t, player: taker, review: review);
      return;
    }
    attacker.stats.penalties++;
    var goal =
        _m.penaltyGoal *
        math.pow(score / math.max(20.0, defender.ratings.keeper), 0.5) *
        (1 +
            _m.character.pressurePenalty *
                _trait(taker, CharacterTrait.pressureResistance));
    for (final s in defender.pitch) {
      for (final a in s.player.abilities) {
        if (s.position.isGoalkeeper && a.type.id == 'penalty_killer') {
          goal *= 1 - _m.standardAbilityBonus;
        }
      }
    }
    _add(MatchEventType.penalty, t, player: taker, review: review);
    _shot(t, taker, 'close_range', null, goal.limit(0.2, 0.95));
    if (!_events.last.isGoal) {
      _boost(_placeOf(t, taker.id), -_m.confidence['penalty_miss']);
    }
  }

  // -------------------------------------------------- cards and injuries

  void _cardsAndInjuries(int minute) {
    for (var i = 0; i < 2; i++) {
      final side = _sides[i];
      var temper = 0.0;
      for (final s in side.pitch) {
        temper +=
            (s.tx[CharacterTrait.temper.index] +
                s.tx[CharacterTrait.aggression.index]) /
            2;
      }
      if (side.pitch.isNotEmpty) temper /= side.pitch.length;
      final p = math.max(
        0.0,
        (_m.yellowPerMinutePerTeam + (side.fx['yellow'] ?? 0)) *
            _rate *
            math.max(0.2, 1 + _m.character.cardTeamWeight * temper) *
            _m.referee.yellowMinuteShare *
            (1 + _m.crowd.derbyCards * setting.derby) *
            (1 +
                _m.referee.strictnessYellow * _rt(RefereeTrait.strictness)) *
            _cardBias(i),
      );
      if (side.pitch.length > 1 && _rng.nextDouble() < p) {
        final slots = [
          for (final s in side.pitch)
            if (!s.position.isGoalkeeper) s,
        ];
        final weights = [
          for (final s in slots)
            (101 - s.player.attributes[Attribute.composure]) *
                math.max(
                  0.1,
                  1 +
                      _m.character.cardTraitsWeight *
                          (s.tx[CharacterTrait.temper.index] +
                              s.tx[CharacterTrait.aggression.index]) /
                          2,
                ) *
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
    if (_rng.nextDouble() <
        _m.straightRedPerMinute *
            _rate *
            _m.referee.redMinuteShare *
            (1 + _m.referee.strictnessRed * _rt(RefereeTrait.strictness))) {
      final i = _rng.nextInt(2);
      final side = _sides[i];
      if (side.pitch.length > 7) {
        final weights = [
          for (final s in side.pitch)
            math.max(
              0.1,
              1 +
                  _m.character.redTemperWeight *
                      s.tx[CharacterTrait.temper.index],
            ),
        ];
        final who = side.pitch[_rng.weightedIndex(weights)];
        _sendOff(i, who, false, reason: _redKind(who));
      }
    }
    // A knock: treated on the pitch, then a minute off (IFAB 2026/27); the
    // keeper may stay.
    if (_rng.nextDouble() < _m.treatment.perMatch * _rate / _m.minutes) {
      final i = _rng.nextInt(2);
      final side = _sides[i];
      if (side.pitch.isNotEmpty) {
        final who =
            side.pitch[_rng.weightedIndex([
              for (final s in side.pitch) s.player.injuryProneness.toDouble(),
            ])];
        final off = !who.position.isGoalkeeper;
        _halfTreatments++;
        if (off) side.shortUntil = _minute + 1;
        _add(
          MatchEventType.treatment,
          i,
          player: who.player,
          value: off ? 1 : 0,
        );
      }
    }
    // A red behind the referee's back: the VAR sees it.
    if (_rng.nextDouble() <
        _m.video.redMissedPerMatch * _err * _rate / _m.minutes) {
      final i = _rng.nextInt(2);
      final side = _sides[i];
      if (side.pitch.length > 7) {
        final who =
            side.pitch[_rng.weightedIndex([
              for (final s in side.pitch)
                math.max(0.1, 1 + s.tx[CharacterTrait.temper.index]),
            ])];
        _add(
          MatchEventType.varReview,
          i,
          player: who.player,
          action: video ? 'red_given' : 'red_missed',
          value: video ? 1 : 0,
        );
        if (video) {
          _halfChecks++;
          _sendOff(i, who, false, reason: 'violent', reviewed: true);
        }
      }
    }
    for (var i = 0; i < 2; i++) {
      final side = _sides[i];
      for (final s in List<_Slot>.of(side.pitch)) {
        final proneness = s.player.injuryProneness / 50;
        final chance =
            _m.injuryPerPlayerMinute *
            _rate *
            proneness *
            (1 + _m.injuryFatigueFactor * (1 - s.energy / 100)) *
            (1 +
                rules.season.condition['load_injury'] *
                    math.max(
                      0.0,
                      (side.team.load[s.player.id] ?? 0) -
                          rules.season.condition['load_free'],
                    ));
        if (_rng.nextDouble() < chance) _injure(i, s);
      }
    }
  }

  /// The kind of a straight red the match does not explain otherwise, for
  /// the sports court (engine 2, step 10e3): rough play, violent conduct or
  /// insulting the referee; hot heads lean to the last two.
  String _redKind(_Slot s) {
    final w = rules.season.court.kindWeights;
    final temper = s.tx[CharacterTrait.temper.index];
    const kinds = ['rough', 'violent', 'insult'];
    final weights = [
      (w['rough'] ?? 1).toDouble(),
      (w['violent'] ?? 0) * math.max(0.1, 1 + 0.5 * temper),
      (w['insult'] ?? 0) * math.max(0.1, 1 + 0.5 * temper),
    ];
    return kinds[_rng.weightedIndex(weights)];
  }

  void _yellow(int i, _Slot s, {String? reason}) {
    if (!_sides[i].pitch.contains(s)) return;
    _halfCards++;
    final side = _sides[i];
    final id = s.player.id;
    _boost(s, -_m.confidence['card']);
    final count = (side.yellows[id] ?? 0) + 1;
    // A clearly wrong second yellow: the VAR takes it back (IFAB 2026/27).
    String? review;
    if (count >= 2 && _rng.nextDouble() < _m.video.secondHarsh * _err) {
      if (video) {
        _halfChecks++;
        _add(
          MatchEventType.varReview,
          i,
          player: s.player,
          action: 'second_cancelled',
          value: 1,
        );
        return;
      }
      review = 'second_harsh';
    }
    side.yellows[id] = count;
    side.stats.yellowCards++;
    if (count >= 2) {
      _add(
        MatchEventType.secondYellow,
        i,
        player: s.player,
        action: reason,
        review: review,
      );
      _sendOff(i, s, true);
    } else {
      _add(MatchEventType.yellowCard, i, player: s.player, action: reason);
    }
    if (reason != 'dissent') _dissent(i);
  }

  void _sendOff(
    int i,
    _Slot s,
    bool secondYellow, {
    String? reason,
    bool reviewed = false,
  }) {
    if (!_sides[i].pitch.contains(s)) return;
    final side = _sides[i];
    var target = s;
    _Slot? culprit;
    String? review;
    if (!secondYellow && !reviewed) {
      // Too hard, or the wrong man (engine 2, step 10e2).
      final v = _m.video;
      final roll = _rng.nextDouble();
      if (roll < v.redHarsh * _err) {
        if (video) {
          _halfChecks++;
          _add(
            MatchEventType.varReview,
            i,
            player: s.player,
            action: 'red_downgraded',
            value: 1,
          );
          _yellow(i, s, reason: reason);
          return;
        }
        review = 'red_harsh';
      } else if (roll < (v.redHarsh + v.identity) * _err) {
        final others = [
          for (final o in side.pitch)
            if (o != s && !o.position.isGoalkeeper) o,
        ];
        if (others.isNotEmpty) {
          final wrong = others[_rng.nextInt(others.length)];
          if (video) {
            _halfChecks++;
            _add(
              MatchEventType.varReview,
              i,
              player: s.player,
              other: wrong.player,
              action: 'identity',
              value: 1,
            );
          } else {
            culprit = s;
            target = wrong;
            review = 'identity';
          }
        }
      }
    }
    if (!secondYellow) _halfCards++;
    side.stats.redCards++;
    if (!secondYellow) {
      _add(
        MatchEventType.redCard,
        i,
        player: target.player,
        other: culprit?.player,
        action: reason,
        review: review,
      );
    }
    _remove(i, target, replace: false);
    if (!secondYellow) _dissent(i);
  }

  void _injure(int i, _Slot s) {
    _halfInjuries++;
    final side = _sides[i];
    side.stats.injuries++;
    final severity = _rng.weightedIndex(_m.injurySeverityWeights);
    final range = _m.injuryDays[severity];
    final days = _rng.nextIntInRange(range[0], range[1]);
    _injuries.add(
      MatchInjury(player: s.player.id, minute: _clock, days: days),
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
    side.fxStale = true;
    _dirty = true;
    final wasKeeper = s.position.isGoalkeeper;
    if (replace && _canSub(side)) {
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
      if (spare.isNotEmpty && _canSub(side)) {
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
        field.reset();
        side.zones = null;
        side.fxStale = true;
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
    if (!inBreak) _halfSubs++;
    _useWindow(side);
    side.subsUsed++;
    side.stats.substitutions++;
    side.pitch.add(_newSlot(side, player, position, role));
    side.zones = null;
    side.fxStale = true;
    side.entered[player.id] = _minute;
    _add(MatchEventType.substitution, i, player: player, other: off);
    _dirty = true;
    // A leading team late on changes slowly; over ten seconds and the new
    // man waits a minute (IFAB 2026/27).
    final lead = i == 0 ? _goalsHome - _goalsAway : _goalsAway - _goalsHome;
    if (off != null &&
        !inBreak &&
        lead > 0 &&
        _clock >= _m.timeWasting.fromMinute &&
        _rng.nextDouble() < _m.treatment.subTenSeconds) {
      side.shortUntil = _minute + 1;
      _halfWasted++;
      _add(
        MatchEventType.timeWasting,
        i,
        player: off,
        action: 'sub_ten_seconds',
      );
    }
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
    if (_finished || !_canSub(s)) return false;
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

  /// True if [side] may give a team talk now: before kick-off or at a
  /// break, once per break.
  bool canTalk(int side) =>
      !_finished && inBreak && _sides[side].talkMinute != _minute;

  /// A team talk for [side] (step 10f3): moves confidence and mood of the
  /// players on the pitch for this match. How much depends on the coach
  /// (charisma, motivation), whether it fits the score, and the character:
  /// professionals stay cool, divas love praise, hotheads boil over when
  /// fired up. Returns how it landed (1 well, 0 flat, -1 badly), null when
  /// not allowed now.
  int? teamTalk(int side, TeamTalk talk) {
    if (!canTalk(side)) return null;
    _actions.add(SessionAction.teamTalk(_minute, side, talk));
    return _talk(side, talk);
  }

  /// The half-time talk of an AI coach (step 10f5): he picks what fits the
  /// score, a coach without charisma sometimes picks at random.
  void _aiTalk(int side) {
    final coach = _sides[side].team.coach;
    final fitting = TeamTalk.values.reduce(
      (a, b) => _talkFit(side, a) >= _talkFit(side, b) ? a : b,
    );
    final sure = 0.4 + 0.6 * coach.charisma / 100;
    final talk = _coachRng.nextDouble() < sure
        ? fitting
        : TeamTalk.values[_coachRng.nextInt(TeamTalk.values.length)];
    _talk(side, talk);
  }

  int _talk(int side, TeamTalk talk) {
    final s = _sides[side];
    s.talkMinute = _minute;
    final c = _m.confidence;
    final fit = _talkFit(side, talk);
    final strength = s.team.coach.talk;
    var sum = 0.0;
    for (final slot in s.pitch) {
      final prof = math.max(0.0, slot.tx[CharacterTrait.professionalism.index]);
      final ego = math.max(
        slot.tx[CharacterTrait.egoism.index],
        slot.tx[CharacterTrait.mediaHunger.index],
      );
      final temper = slot.tx[CharacterTrait.temper.index];
      var react = 1 - c['talk_professional'] * prof;
      switch (talk) {
        case TeamTalk.praise:
          react *= 1 + c['talk_diva'] * math.max(0.0, ego);
        case TeamTalk.fire:
          react *= 1 - 0.5 * c['talk_diva'] * math.max(0.0, ego);
          if (temper > 0.3) slot.heat += c['talk_heat'] * temper;
        case TeamTalk.calm:
          react *=
              1 +
              c['talk_nervous'] *
                  math.max(
                    0.0,
                    -slot.tx[CharacterTrait.pressureResistance.index],
                  );
          slot.heat *= 0.5;
      }
      final effect = fit * strength * react;
      sum += effect;
      slot.conf = (slot.conf + c['talk_confidence'] * effect).clamp(0.0, 100.0);
      // The mood is a factor in the cached means (linear): scale them
      // instead of building everything anew. The zone tables keep their
      // order within the team; the talk moves the strength of the team.
      final before = _moodFactor(slot);
      slot.mood = (slot.mood + c['talk_mood'] * effect).clamp(0.0, 100.0);
      final ratio = _moodFactor(slot) / before;
      if (ratio != 1) {
        slot.base.updateAll((k, v) => v * ratio);
        slot
          ..act = [for (final x in slot.act) x * ratio]
          ..def = [for (final x in slot.def) x * ratio];
      }
    }
    _refresh(s);
    final mean = s.pitch.isEmpty ? 0.0 : sum / s.pitch.length;
    final landed = mean >= 0.35
        ? 1
        : mean < -0.05
        ? -1
        : 0;
    _add(MatchEventType.teamTalk, side, action: talk.name, value: landed);
    return landed;
  }

  /// How well a team talk fits the moment, -1 to 1: before kick-off
  /// anything goes a little (calm in a derby), at the break it follows the
  /// score (fire when behind, calm or praise when ahead).
  double _talkFit(int side, TeamTalk talk) {
    if (_minute == 0) {
      return switch (talk) {
        TeamTalk.calm => setting.derby > 0 ? 0.8 : 0.3,
        TeamTalk.fire => 0.5,
        TeamTalk.praise => 0.2,
      };
    }
    final lead = _lead(side);
    if (lead > 0) {
      return switch (talk) {
        TeamTalk.calm => 0.9,
        TeamTalk.praise => 0.7,
        TeamTalk.fire => 0.0,
      };
    }
    if (lead == 0) {
      return switch (talk) {
        TeamTalk.fire => 0.8,
        TeamTalk.calm => 0.3,
        TeamTalk.praise => 0.1,
      };
    }
    return switch (talk) {
      TeamTalk.fire => 1.0,
      TeamTalk.calm => lead < -1 ? -0.3 : 0.2,
      TeamTalk.praise => -0.8,
    };
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
    _setTactics(
      side,
      systemId: systemId,
      pressing: pressing,
      tempo: tempo,
      defensiveLine: defensiveLine,
    );
  }

  /// Gives [player] of [side] an instruction, null takes it back (step
  /// 10g1). Free of the penalty for changes.
  void instruct(int side, PlayerId player, PlayerInstruction? instruction) {
    final s = _sides[side];
    final now = s.sheet.instructions[player];
    if (now == instruction || _finished) return;
    _actions.add(SessionAction.instruction(_minute, side, player, instruction));
    final map = Map.of(s.sheet.instructions);
    if (instruction == null) {
      map.remove(player);
    } else {
      map[player] = instruction;
    }
    s.sheet = s.sheet.copyWith(instructions: map);
    for (final slot in s.pitch) {
      if (slot.player.id == player) slot.instr = instruction;
    }
    s.zones = null;
    _refresh(s);
  }

  /// The team instructions of [side] (step 10g1): a wing to overload (null
  /// for none) and time wasting.
  void teamInstructions(int side, {Wing? wing, bool wasteTime = false}) {
    final s = _sides[side];
    if (_finished ||
        (s.sheet.wing == wing && s.sheet.wasteTime == wasteTime)) {
      return;
    }
    _actions.add(
      SessionAction.team(
        _minute,
        side,
        wing: wing?.name ?? 'none',
        wasteTime: wasteTime,
      ),
    );
    s.sheet = s.sheet.copyWith(
      wing: wing,
      clearWing: wing == null,
      wasteTime: wasteTime,
    );
  }

  /// What the assistant sees in the opponent of [side] before kick-off
  /// (step 10g2). A coach with tactical knowledge [tactics] sees more and
  /// errs less; the dice come from [seed], so the same match shows the
  /// same notes.
  List<ScoutNote> scout(int side, {required double tactics, int seed = 0}) {
    final r = _m.instructions;
    final q = (tactics / 100).clamp(0.0, 1.0);
    final rng = SeededRandom(seed).fork('scout:$side');
    final notes = <ScoutNote>[];
    for (final f in PlanFocus.values) {
      final (real, wing, key) = _weakness(side, f);
      final roll = rng.nextDouble();
      if (real) {
        if (roll < r.get('scout_miss') * (1 - q)) continue;
      } else if (roll >= r.get('scout_error') * (1 - q)) {
        continue;
      }
      notes.add(ScoutNote(f, real: real, wing: wing, player: key));
    }
    final most = (2 + 3 * q).round();
    return notes.take(most).toList();
  }

  /// Sets the match plan of [side] before kick-off: up to two focus points
  /// (step 10g2). Each that hits a real weakness of the opponent helps the
  /// actions it is about; one that does not costs a little.
  void setPlan(int side, List<PlanFocus> plan) {
    if (_minute != 0 || _finished) return;
    final s = _sides[side];
    final chosen = plan.toSet().take(2).toList();
    _actions.add(SessionAction.plan(_minute, side, chosen));
    final map = <PlanFocus, bool>{};
    for (final f in chosen) {
      final (real, wing, key) = _weakness(side, f);
      map[f] = real;
      if (f == PlanFocus.weakSide) s.planWing = wing;
      if (f == PlanFocus.stopKey) s.planKey = key;
    }
    s.plan = map;
    if (chosen.isNotEmpty) {
      _add(
        MatchEventType.matchPlan,
        side,
        action: [for (final f in chosen) f.name].join(','),
      );
    }
  }

  /// Is [focus] a real weakness of the opponent of [side]? With the wing to
  /// attack and the key player where it matters.
  (bool, Wing?, PlayerId?) _weakness(int side, PlanFocus focus) {
    final r = _m.instructions;
    final own = _sides[side];
    final o = _sides[1 - side];
    final outfield = [
      for (final s in o.pitch)
        if (!s.position.isGoalkeeper) s,
    ];
    double score(_Slot s) => _fit.slotScore(s.player, s.position);
    switch (focus) {
      case PlanFocus.weakSide:
        final backs = [
          for (final s in outfield)
            if (lineOf(s.position) == 1) s,
        ];
        final left = backs.where((s) => s.position == Position.lv);
        final right = backs.where((s) => s.position == Position.rv);
        if (backs.isEmpty || left.isEmpty || right.isEmpty) {
          return (false, null, null);
        }
        final mean = backs.map(score).reduce((a, b) => a + b) / backs.length;
        final l = score(left.first);
        final rr = score(right.first);
        // Their right back faces our left wing.
        final wing = rr < l ? Wing.left : Wing.right;
        return (
          math.min(l, rr) < r.get('scout_weak', 0.92) * mean,
          wing,
          null,
        );
      case PlanFocus.pressHigh:
        final rt = o.ratings;
        return (
          rt.build < r.get('scout_build', 0.95) * (rt.attack + rt.defense) / 2,
          null,
          null,
        );
      case PlanFocus.counter:
        final centre = [
          for (final s in outfield)
            if (s.position == Position.iv) s,
        ];
        final pace = centre.isEmpty
            ? 50.0
            : centre
                      .map((s) => s.player.attributes[Attribute.acceleration])
                      .reduce((a, b) => a + b) /
                  centre.length;
        return (
          o.sheet.defensiveLine == 2 || pace < r.get('scout_slow', 62),
          null,
          null,
        );
      case PlanFocus.longShots:
        return (
          o.ratings.keeper < r.get('scout_keeper', 0.93) * o.ratings.defense,
          null,
          null,
        );
      case PlanFocus.avoidAir:
        return (
          _headerStrength(o, defending: true) >
              r.get('scout_air', 1.1) * _headerStrength(own),
          null,
          null,
        );
      case PlanFocus.stopKey:
        final attackers = [
          for (final s in outfield)
            if (lineOf(s.position) >= 2) s,
        ];
        if (attackers.isEmpty || outfield.isEmpty) return (false, null, null);
        attackers.sort((a, b) => score(b).compareTo(score(a)));
        final best = attackers.first;
        final mean = outfield.map(score).reduce((a, b) => a + b) /
            outfield.length;
        return (
          score(best) >= r.get('scout_key', 1.12) * mean,
          null,
          best.player.id,
        );
    }
  }

  /// The factor of a focus point of [side]: a hit helps, a miss costs, no
  /// plan is neutral.
  double _plan(int side, PlanFocus focus) {
    final real = _sides[side].plan[focus];
    if (real == null) return 1;
    final r = _m.instructions;
    return real ? 1 + r.get('plan_hit') : 1 - r.get('plan_miss');
  }

  /// The match plan in a step of an attack of side [t] (step 10g2).
  double _planStep(
    int t,
    _Slot carrier,
    String action,
    int column,
    int lane, {
    required bool counter,
  }) {
    final o = 1 - t;
    final att = _sides[t];
    final def = _sides[o];
    var f = 1.0;
    final wing = att.planWing;
    if (wing != null &&
        att.plan.containsKey(PlanFocus.weakSide) &&
        (wing == Wing.left ? lane <= 1 : lane >= ZoneRules.lanes - 2)) {
      f *= _plan(t, PlanFocus.weakSide);
    }
    if (counter) f *= _plan(t, PlanFocus.counter);
    if (action == 'short_pass' || action == 'dribble') {
      f *= _plan(t, PlanFocus.avoidAir);
    }
    // The defending side presses their build-up or stops their key man.
    if (column <= 1) f /= _plan(o, PlanFocus.pressHigh);
    final key = def.plan[PlanFocus.stopKey];
    if (key != null) {
      if (!key) {
        f /= _plan(o, PlanFocus.stopKey);
      } else if (carrier.player.id == def.planKey) {
        f *= 1 - 2 * _m.instructions.get('plan_hit');
      }
    }
    return f;
  }

  /// The half-time analysis of the assistant for [side] (step 10g3): the
  /// half that just ended (or the running one), shots, duels and up to
  /// three observations with a suggested change. A coach with tactical
  /// knowledge [tactics] gets more notes and fewer wrong ones.
  HalfTimeReport halfTimeReport(
    int side, {
    required double tactics,
    int seed = 0,
  }) {
    final r = _m.instructions;
    final q = (tactics / 100).clamp(0.0, 1.0);
    final rng = SeededRandom(seed).fork('half:$side:$_minute');
    final from = inBreak && _minute > 0 ? _lastHalfFrom : _halfFrom;
    final own = _sides[side];
    final other = 1 - side;
    var shots = 0;
    var against = 0;
    var won = 0;
    var duels = 0;
    // Duels per flank of our view: 0 left, 1 right.
    final flankWon = [0, 0];
    final flankAll = [0, 0];
    final threat = <PlayerId, int>{};
    const lanes = ZoneRules.lanes;
    for (final e in _events) {
      if (e.tick < from || e.tick > _minute) continue;
      if (e.type == MatchEventType.shot) {
        e.side == side ? shots++ : against++;
        if (e.side == other && e.player != null) {
          threat[e.player!] = (threat[e.player!] ?? 0) + 2;
        }
      }
      for (final st in e.steps) {
        final ours = e.side == side;
        final weWon = ours ? st.won : !st.won;
        duels++;
        if (weWon) won++;
        // Their lanes are mirrored: their right is our left.
        final lane = ours ? st.lane : lanes - 1 - st.lane;
        final flank = lane <= 1
            ? 0
            : lane >= lanes - 2
            ? 1
            : -1;
        if (flank >= 0) {
          flankAll[flank]++;
          if (weWon) flankWon[flank]++;
        }
        if (!ours && st.won) {
          threat[st.player] = (threat[st.player] ?? 0) + 1;
        }
      }
    }
    final notes = <HalfNote>[];
    double err() => rng.nextDouble() < r.get('half_error') * (1 - q) ? 1 : 0;

    // A flank where we lose clearly more duels.
    if (flankAll[0] >= 6 && flankAll[1] >= 6) {
      final rate = [
        for (var i = 0; i < 2; i++) flankWon[i] / flankAll[i],
      ];
      final worse = rate[0] < rate[1] ? 0 : 1;
      if ((rate[0] - rate[1]).abs() >= r.get('half_flank_gap', 0.15)) {
        final wrong = err() > 0;
        final f = wrong ? 1 - worse : worse;
        final wing = f == 0 ? Wing.left : Wing.right;
        final back = own.pitch
            .where(
              (s) => s.position == (f == 0 ? Position.lv : Position.rv),
            )
            .firstOrNull;
        notes.add(
          HalfNote(
            HalfNoteKind.losingFlank,
            real: !wrong,
            wing: wing,
            player: back?.player.id,
            fix: back == null
                ? SessionAction.team(
                    _minute,
                    side,
                    wing: (wing == Wing.left ? Wing.right : Wing.left).name,
                    wasteTime: own.sheet.wasteTime,
                  )
                : SessionAction.instruction(
                    _minute,
                    side,
                    back.player.id,
                    PlayerInstruction.stayBack,
                  ),
          ),
        );
      }
    }
    // Their man of the half.
    if (threat.isNotEmpty) {
      final onPitch = {for (final s in _sides[other].pitch) s.player.id};
      final ranked = threat.entries.where((e) => onPitch.contains(e.key))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (ranked.isNotEmpty && ranked.first.value >= r.get('half_threat', 6)) {
        final wrong = err() > 0 && ranked.length > 1;
        final who = wrong ? ranked.last.key : ranked.first.key;
        final markers = [
          for (final s in own.pitch)
            if ((s.position == Position.zdm || s.position == Position.iv) &&
                s.instr == null)
              s,
        ]..sort(
            (a, b) => _fit
                .slotScore(b.player, b.position)
                .compareTo(_fit.slotScore(a.player, a.position)),
          );
        notes.add(
          HalfNote(
            HalfNoteKind.dominant,
            real: !wrong,
            player: who,
            fix: markers.isEmpty
                ? null
                : SessionAction.instruction(
                    _minute,
                    side,
                    markers.first.player.id,
                    PlayerInstruction.manMark,
                  ),
          ),
        );
      }
    }
    // Ours: tired or booked and hot.
    SessionAction? subFor(_Slot s) {
      if (!_canSub(own)) return null;
      final options = [
        for (final b in own.bench)
          if (b.position.isGoalkeeper == s.position.isGoalkeeper) b,
      ]..sort(
          (a, b) => _fit
              .slotScore(b, s.position)
              .compareTo(_fit.slotScore(a, s.position)),
        );
      if (options.isEmpty) return null;
      return SessionAction.substitution(
        _minute,
        side,
        s.player.id,
        options.first.id,
      );
    }

    final field = [
      for (final s in own.pitch)
        if (!s.position.isGoalkeeper) s,
    ]..sort((a, b) => a.energy.compareTo(b.energy));
    if (field.isNotEmpty && field.first.energy < r.get('half_tired', 60)) {
      notes.add(
        HalfNote(
          HalfNoteKind.tired,
          real: true,
          player: field.first.player.id,
          fix: subFor(field.first),
        ),
      );
    }
    for (final s in own.pitch) {
      if ((own.yellows[s.player.id] ?? 0) == 0) continue;
      final hot =
          s.tx[CharacterTrait.temper.index] > 0.3 ||
          s.tx[CharacterTrait.aggression.index] > 0.3 ||
          s.instr == PlayerInstruction.hard;
      if (!hot) continue;
      notes.add(
        HalfNote(
          HalfNoteKind.booked,
          real: true,
          player: s.player.id,
          fix: subFor(s),
        ),
      );
      break;
    }
    // The plan.
    if (own.plan.isNotEmpty) {
      final works = own.plan.values.every((v) => v);
      final wrong = err() > 0;
      notes.add(
        HalfNote(
          works != wrong ? HalfNoteKind.planWorks : HalfNoteKind.planFails,
          real: !wrong,
        ),
      );
    }
    // Behind and passive.
    if (_lead(side) < 0 && own.sheet.pressing < 2) {
      notes.add(
        HalfNote(
          HalfNoteKind.pressNeeded,
          real: true,
          fix: SessionAction.tactics(_minute, side, pressing: 2),
        ),
      );
    }
    final most = 1 + (2 * q).round();
    return HalfTimeReport(
      shots: shots,
      shotsAgainst: against,
      duelsWon: won,
      duels: duels,
      notes: notes.take(most).toList(),
    );
  }

  /// Shouts left for [side] in this half (step 10g4).
  int shoutsLeft(int side) => math.max(
    0,
    _m.instructions.get('shouts_per_half', 3).round() - _sides[side].shoutsUsed,
  );

  /// True if [side] may shout now: while the ball rolls, shouts left.
  bool canShout(int side) =>
      !_finished && !inBreak && _minute > 0 && shoutsLeft(side) > 0;

  /// The shout of [side] that works now, null for none.
  Shout? activeShout(int side) {
    final s = _sides[side];
    return s.shoutUntil >= _minute ? s.shout : null;
  }

  /// A shout from the touchline (step 10g4): works for a few minutes, free
  /// of the penalty for changes. How loud it gets through depends on the
  /// charisma of the coach, the noise of the crowd (louder at the ground
  /// of the other side and in a derby) and the players: professionals
  /// listen, egoists less. Returns 1, 0 or -1 (see [MatchEventType.shout]),
  /// null when not allowed now.
  int? shoutOut(int side, Shout shout) {
    if (!canShout(side)) return null;
    final r = _m.instructions;
    final s = _sides[side];
    _actions.add(SessionAction.shoutOut(_minute, side, shout));
    s.shoutsUsed++;
    var listen = 0.0;
    for (final slot in s.pitch) {
      listen +=
          1 +
          0.3 * math.max(0.0, slot.tx[CharacterTrait.professionalism.index]) -
          0.5 * math.max(0.0, slot.tx[CharacterTrait.egoism.index]);
    }
    if (s.pitch.isNotEmpty) listen /= s.pitch.length;
    final away = side == 1 && !_neutral;
    final noise =
        (setting.attendance / 80000).clamp(0.0, 1.0) *
            r.get('shout_noise', 0.3) *
            (away ? 1.5 : 0.5) +
        0.05 * setting.derby;
    final power =
        ((0.4 + s.team.coach.charisma / 200) * listen * (1 - noise)).clamp(
          0.0,
          1.0,
        );
    s
      ..shout = shout
      ..shoutPower = power
      ..shoutUntil = _minute + r.get('shout_minutes', 10).round();
    final landed = power >= 0.6
        ? 1
        : power >= 0.35
        ? 0
        : -1;
    _add(MatchEventType.shout, side, action: shout.name, value: landed);
    return landed;
  }

  /// The factor of the active shout [shout] of side [t] (1 when none).
  double _shoutF(int t, Shout shout) {
    final s = _sides[t];
    if (s.shoutUntil < _minute || s.shout != shout) return 1;
    return 1 + _m.instructions.get('shout_effect') * s.shoutPower;
  }

  /// The assistant takes over [side] for the rest of the match (step
  /// 10f5): substitutions and changes like the AI coaches, with average
  /// tactical knowledge.
  void handOver(int side) {
    final s = _sides[side];
    if (s.assistant || _finished) return;
    _actions.add(SessionAction.handOver(_minute, side));
    s.assistant = true;
  }

  void _setTactics(
    int side, {
    String? systemId,
    int? pressing,
    int? tempo,
    int? defensiveLine,
    String? action,
  }) {
    final s = _sides[side];
    final before = s.sheet;
    s.sheet = before.copyWith(
      systemId: systemId,
      pressing: pressing,
      tempo: tempo,
      defensiveLine: defensiveLine,
    );
    s.fxStale = true;
    // The zone tables only know the system, not the sliders.
    if (systemId != null && systemId != before.systemId) s.zones = null;
    final free =
        _clock <= rules.tactics.warmupMinutes || inBreak;
    if (!free) s.countedChanges++;
    _add(MatchEventType.tacticChange, side, action: action);
    _refresh(s);
  }

  /// The coach of an AI side reads the match (step 10f5): deeper against a
  /// stronger team, everything forward when behind, the bus parked when
  /// ahead late, a back line of four after a red card, a booked defender
  /// off. Tactical knowledge decides how early he sees it; a weak coach
  /// now and then does the opposite.
  void _coach(_Side side) {
    final i = _sides.indexOf(side);
    final c = _m.confidence;
    final q = (side.assistant ? 50.0 : side.team.coach.tactics) / 100;
    final delay = ((1 - q) * c['coach_delay']).round();
    final wrong =
        _coachRng.nextDouble() <
        c['coach_error'] * math.max(0.0, 0.5 - q) * 2;
    final lead = _lead(i);
    final sheet = side.sheet;
    void set(int pressing, int tempo, int line, String action) {
      if (sheet.pressing == pressing &&
          sheet.tempo == tempo &&
          sheet.defensiveLine == line) {
        return;
      }
      _setTactics(
        i,
        pressing: pressing,
        tempo: tempo,
        defensiveLine: line,
        action: action,
      );
    }

    // Against a clearly stronger team: deeper from the start.
    if (side.coachDone & _Coach.start == 0) {
      side.coachDone |= _Coach.start;
      final other = _sides[1 - i].ratings;
      final own = side.ratings;
      final mine = own.build + own.attack + own.defense;
      final theirs = other.build + other.attack + other.defense;
      if (theirs > mine * (1 + c['coach_stronger']) && q >= 0.3) {
        wrong ? set(2, 2, 2, 'panic') : set(sheet.pressing, 1, 0, 'deep');
      }
      return;
    }
    // A red card: tighten up unless chasing the game.
    if (side.missing > 0 && side.coachDone & _Coach.tenMen == 0 && q >= 0.25) {
      side.coachDone |= _Coach.tenMen;
      if (lead >= 0) set(0, 1, 0, 'ten');
      return;
    }
    // Behind: everything forward.
    if (lead < 0 &&
        side.coachDone & _Coach.chase == 0 &&
        _clock >= c['coach_chase_minute'] + delay) {
      side.coachDone = (side.coachDone | _Coach.chase) & ~_Coach.hold;
      if (wrong) {
        set(0, 0, 0, 'panic');
      } else {
        set(2, 2, lead <= -2 || _clock >= 75 ? 2 : 1, 'chase');
      }
      return;
    }
    // Ahead late: park the bus.
    if (lead > 0 &&
        side.coachDone & _Coach.hold == 0 &&
        _clock >= c['coach_hold_minute'] + delay) {
      side.coachDone = (side.coachDone | _Coach.hold) & ~_Coach.chase;
      wrong ? set(2, 2, 2, 'panic') : set(0, 0, 0, 'hold');
      return;
    }
    // The lead is gone: a good coach opens up again.
    if (lead <= 0 && side.coachDone & _Coach.hold != 0 && q >= 0.4) {
      side.coachDone &= ~_Coach.hold;
      set(1, 1, 1, 'open');
      return;
    }
    // A booked defender goes off before he sees red.
    if (_clock >= c['coach_booked_minute'] &&
        q >= 0.5 &&
        _canSub(side) &&
        _coachRng.nextDouble() < c['coach_booked_sub'] * q) {
      for (final s in side.pitch) {
        final p = s.position;
        if ((side.yellows[s.player.id] ?? 0) == 0 ||
            !(p == Position.iv ||
                p == Position.lv ||
                p == Position.rv ||
                p == Position.zdm)) {
          continue;
        }
        final options =
            [
              for (final b in side.bench)
                if (!b.position.isGoalkeeper) b,
            ]..sort(
              (a, b) => _fit
                  .slotScore(b, p)
                  .compareTo(_fit.slotScore(a, p)),
            );
        if (options.isEmpty) return;
        _substitute(i, s.player.id, options.first.id);
        return;
      }
    }
  }

  void _assistant(_Side side) {
    final i = _sides.indexOf(side);
    if (!_canSub(side) || side.bench.isEmpty) {
      return;
    }
    if (_clock >= _m.aiSubTiredMinute) {
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
    if (own < other && _clock >= _m.aiSubTrailingMinute) {
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

/// What an AI coach has done in a match (step 10f5), as bits.
abstract final class _Coach {
  static const start = 1;
  static const chase = 2;
  static const hold = 4;
  static const tenMen = 8;
}

/// Plays whole matches without a user interface.
class MatchEngine {
  const MatchEngine(this.rules);

  final Rules rules;

  MatchResult simulate(
    MatchTeam home,
    MatchTeam away, {
    required int seed,
    Referee? referee,
    bool video = false,
    MatchSetting setting = const MatchSetting(),
  }) {
    return MatchSession(
      rules: rules,
      home: home,
      away: away,
      seed: seed,
      referee: referee,
      video: video,
      setting: setting,
    ).finish();
  }

  /// A cup tie in one match: extra time and shoot-out when it is level.
  KnockoutResult simulateKnockout(
    MatchTeam home,
    MatchTeam away, {
    required int seed,
    bool neutral = false,
    Referee? referee,
    bool video = false,
    MatchSetting setting = const MatchSetting(),
  }) {
    final session = MatchSession(
      rules: rules,
      home: home,
      away: away,
      seed: seed,
      neutral: neutral,
      referee: referee,
      video: video,
      setting: setting,
    );
    return session.finishKnockout();
  }
}
