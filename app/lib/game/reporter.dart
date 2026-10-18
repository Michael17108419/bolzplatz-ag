import 'package:game_core/game_core.dart';

import '../l10n/reporter_strings.dart';
import 'ticker.dart';

/// The radio reporter of the live match (step 10d2, document "Plan 10d2
/// Radio"): dangerous attacks are told as scenes, step by step from the
/// protocol of the engine, with a pause before the end; quiet phases get a
/// line now and then; the voice rises with the minute and the score, sides
/// with the own club (fair, and mocking its own players too), remembers what
/// happened in the match and knows the character of the players.
///
/// One reporter per match. It holds a memory, so the events must come in
/// order, each once; read in again after loading, it tells the same match.
class Reporter {
  Reporter({
    required this.strings,
    required this.ownSide,
    required this.home,
    required this.away,
    required this.playerName,
    this.player,
    this.captainOf,
    this.tier = 1,
    this.referee,
    this.setting = const MatchSetting(),
  });

  final ReporterStrings strings;

  /// 0 home, 1 away: the club the reporter sides with.
  final int ownSide;
  final String home;
  final String away;
  final String Function(PlayerId? id) playerName;

  /// The player behind an id, for traits and abilities (wit layer).
  final Player? Function(PlayerId id)? player;
  final PlayerId? Function(int side)? captainOf;

  /// League level of the match: from 3 on the reporter talks like a local.
  final int tier;

  /// Who whistles (step 10e1), named at kick-off; null for a plain referee.
  final Referee? referee;

  /// Ground, crowd, derby and travel of the match (step 10e4).
  final MatchSetting setting;

  /// "24.500": a number with dots between the thousands.
  static String thousands(int n) {
    final digits = '$n';
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
      out.write(digits[i]);
    }
    return out.toString();
  }

  /// A foul with advantage: the attacking side and whether it was a
  /// Notbremse; told once the attack is over.
  int _advSide = -1;
  bool _advDogso = false;

  /// Counts of the memory ("the third time down the left").
  final Map<String, int> _count = {};

  /// Texts used lately: not again so soon.
  final List<String> _recent = [];
  MatchEvent? _previous;
  int _lastLineTick = 0;
  int _homeGoals = 0;
  int _awayGoals = 0;
  int _streakSide = -1;
  int _streak = 0;
  int _counterSide = -1;
  int _counterTick = -10;
  int _seed = 0;

  /// In a goal scene the lines before the goal still show the old score.
  bool _goalSaid = true;

  /// The side the reporter calls "own" or "opp" in the keys.
  String _who(int side) => side == ownSide ? 'own' : 'opp';

  int _bump(String key) => _count[key] = (_count[key] ?? 0) + 1;

  static int _hash(String s) {
    var h = 7;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x3fffffff;
    }
    return h;
  }

  /// The first key with texts gives one of them, not one used lately; empty
  /// if no key has any.
  String _pick(List<String> keys, {bool Function(String text)? ok}) {
    for (final key in keys) {
      final all = strings.texts(key);
      final texts = ok == null ? all : [for (final t in all) if (ok(t)) t];
      if (texts.isEmpty) continue;
      _seed = (_seed * 1103515245 + 12345) & 0x3fffffff;
      final start = (_seed + _hash(key)) % texts.length;
      var pick = texts[start];
      for (var i = 0; i < texts.length; i++) {
        final t = texts[(start + i) % texts.length];
        if (!_recent.contains(t)) {
          pick = t;
          break;
        }
      }
      _recent.add(pick);
      if (_recent.length > 60) _recent.removeAt(0);
      return pick;
    }
    return '';
  }

  /// True about every [n]th time: wit and memory are spice, not every line.
  bool _sometimes(int n) {
    _seed = (_seed * 1103515245 + 12345) & 0x3fffffff;
    return (_seed >> 8) % n == 0;
  }

  double _trait(PlayerId? id, CharacterTrait trait) {
    if (id == null) return 50;
    return player?.call(id)?.traits[trait] ?? 50;
  }

  bool _ability(PlayerId? id, SpecialAbilityType type) {
    if (id == null) return false;
    final p = player?.call(id);
    if (p == null) return false;
    for (final a in p.abilities) {
      if (a.type == type) return true;
    }
    return false;
  }

  /// How loud: 0 calm to 3 wild, by chance, minute, score and stoppage.
  int energy(MatchEvent e) {
    var x = 0;
    if (e.quality == ChanceQuality.big || e.spot == 2) x++;
    final close = (e.homeGoals - e.awayGoals).abs() <= 1;
    if (e.minute >= 75 && close) x++;
    if (e.minute >= 85) x++;
    if (e.added > 0 && e.minute >= 90) x++;
    return x.clamp(0, 3);
  }

  String _fill(
    String text,
    MatchEvent e, {
    PlayerId? p,
    PlayerId? o,
    PlayerId? q,
    int? lane,
    int? side,
  }) {
    final s = side ?? e.side;
    final team = s == 1 ? away : home;
    final opp = s == 1 ? home : away;
    final own = ownSide == 0 ? e.homeGoals : e.awayGoals;
    final other = ownSide == 0 ? e.awayGoals : e.homeGoals;
    var out = text;
    if (out.contains('{where}')) {
      out = out.replaceAll('{where}', _pick(['lane.${lane ?? e.lane ?? 2}']));
    }
    return out
        .replaceAll('{p}', playerName(p ?? e.player))
        .replaceAll('{o}', playerName(o ?? e.otherPlayer))
        .replaceAll('{q}', playerName(q ?? e.otherPlayer))
        .replaceAll('{team}', team)
        .replaceAll('{opp}', opp)
        .replaceAll('{home}', home)
        .replaceAll('{away}', away)
        .replaceAll('{score}', '${e.homeGoals}:${e.awayGoals}')
        .replaceAll('{ours}', '$own:$other')
        .replaceAll('{days}', '${e.injuryDays ?? 0}')
        .replaceAll('{n}', '${e.value ?? 0}')
        .replaceAll('{k}', playerName(e.keeper))
        .replaceAll('{ref}', referee?.name ?? '')
        .replaceAll('{crowd}', thousands(setting.attendance))
        .replaceAll('{stadium}', setting.stadium ?? '')
        .replaceAll('{derby}', setting.derbyName ?? '')
        .replaceAll('{km}', '${setting.travelKm}');
  }

  static const _neutral = {
    TickerKind.kickOff,
    TickerKind.halfTime,
    TickerKind.fullTime,
    TickerKind.extraTime,
    TickerKind.addedTime,
    TickerKind.calm,
  };

  TickerLine _line(MatchEvent e, TickerKind kind, String text, {int? side}) {
    if (e.isGoal && kind == tickerKindOf(e)) _goalSaid = true;
    final before = !_goalSaid;
    return TickerLine(
      minute: e.minute,
      clock: e.clockLabel,
      kind: kind,
      side: _neutral.contains(kind) ? -1 : (side ?? e.side),
      homeGoals: before ? _homeGoals : e.homeGoals,
      awayGoals: before ? _awayGoals : e.awayGoals,
      text: text,
    );
  }


  /// Adds a line from the first key with texts; nothing if none has any.
  void _say(
    List<TickerLine> out,
    MatchEvent e,
    TickerKind kind,
    List<String> keys, {
    PlayerId? p,
    PlayerId? o,
    PlayerId? q,
    int? lane,
    int? side,
    bool step = false,
  }) {
    // A text that names a player nobody is can not be used. In a step the
    // opponent is the one of the step, never the one of the event.
    final hasO = step ? o != null : (o ?? e.otherPlayer) != null;
    final hasQ = (q ?? e.otherPlayer) != null;
    final hasP = (p ?? e.player) != null;
    final hasK = e.keeper != null;
    final hasRef = referee != null;
    final hasStadium = setting.stadium != null;
    final hasDerby = setting.derbyName != null;
    final text = _pick(
      keys,
      ok: (t) =>
          (hasO || !t.contains('{o}')) &&
          (hasQ || !t.contains('{q}')) &&
          (hasP || !t.contains('{p}')) &&
          (hasK || !t.contains('{k}')) &&
          (hasRef || !t.contains('{ref}')) &&
          (hasStadium || !t.contains('{stadium}')) &&
          (hasDerby || !t.contains('{derby}')),
    );
    if (text.isEmpty) return;
    out.add(
      _line(
        e,
        kind,
        _fill(
          step && o == null ? text.replaceAll('{o}', '') : text,
          e,
          p: p,
          o: o,
          q: q,
          lane: lane,
          side: side,
        ),
        side: side,
      ),
    );
  }

  /// The lines of one event, oldest first; the live page shows them one
  /// after the other with a pause each (see [readingTime]).
  List<TickerLine> linesOf(MatchEvent e, int index) {
    _seed = (index * 7919 + e.tick * 31) & 0x3fffffff;
    _goalSaid = !e.isGoal;
    final out = <TickerLine>[];
    // An advantage that led to nothing: the attack ended without a shot.
    if (_advSide >= 0 &&
        e.type != MatchEventType.shot &&
        e.type != MatchEventType.foul) {
      _advantageOver(e, out, scored: false);
    }
    switch (e.type) {
      case MatchEventType.kickOff:
        _say(out, e, TickerKind.kickOff, ['kickoff']);
        _venueIntro(e, out);
        _refereeIntro(e, out);
        if (tier >= 3) _say(out, e, TickerKind.colour, ['local.kickoff']);
      case MatchEventType.shot:
        _shot(e, out);
      case MatchEventType.ballWon:
        _ballWon(e, out);
      case MatchEventType.counterAttack:
        _counterSide = e.side;
        _counterTick = e.tick;
        _say(out, e, TickerKind.counter, ['counter.${_who(e.side)}']);
      case MatchEventType.penalty:
        final w = _who(e.side);
        final prev = _previous;
        // After the VAR gave it, the award was told already.
        final given =
            prev != null &&
            prev.type == MatchEventType.varReview &&
            prev.action == 'penalty_given';
        if (!given) _say(out, e, TickerKind.penalty, ['pen.award.$w']);
        if (e.review == 'penalty_overturned') {
          _say(out, e, TickerKind.varCheck, ['var.check.penalty', 'var.check']);
          _say(out, e, TickerKind.varDecision, ['var.penalty_overturned.$w']);
        } else if (e.review == 'penalty_soft' && _sometimes(2)) {
          _say(out, e, TickerKind.colour, ['ref.penalty_soft.$w']);
        }
      case MatchEventType.varReview:
        final w = _who(e.side);
        final a = e.action;
        if ((e.value ?? 0) == 1) {
          _say(out, e, TickerKind.varCheck, ['var.check.$a', 'var.check']);
          _say(out, e, TickerKind.varDecision, ['var.$a.$w']);
        } else {
          _say(out, e, TickerKind.colour, ['ref.$a.$w']);
        }
      case MatchEventType.corner:
        final n = _bump('corner.${e.side}');
        _say(out, e, TickerKind.corner, ['corner.${_who(e.side)}']);
        if (n == 5 || n == 8) {
          _say(out, e, TickerKind.colour, ['mem.corners.${_who(e.side)}']);
        }
      case MatchEventType.freeKick:
        _say(out, e, TickerKind.freeKick, ['free.${_who(e.side)}']);
      case MatchEventType.yellowCard:
      case MatchEventType.secondYellow:
      case MatchEventType.redCard:
        _card(e, out);
      case MatchEventType.injury:
        _say(out, e, TickerKind.injury, ['injury.${_who(e.side)}']);
        _captain(e, e.player, out);
      case MatchEventType.substitution:
        final late = e.minute >= 80 ? '.late' : '';
        _say(out, e, TickerKind.substitution, [
          'sub.${_who(e.side)}$late',
          'sub.${_who(e.side)}',
        ]);
        _captain(e, e.otherPlayer, out);
      case MatchEventType.tacticChange:
        _say(out, e, TickerKind.tactic, [
          if (e.action != null) 'coach.${e.action}.${_who(e.side)}',
          'tactic.${_who(e.side)}',
        ]);
      case MatchEventType.addedTime:
        final situation = _situation(e);
        final half = e.minute <= 45 ? 'half' : situation;
        _say(out, e, TickerKind.addedTime, ['added.$half', 'added.level']);
      case MatchEventType.timeWasting:
        final kind = tickerKindOf(e);
        if (kind != null) {
          _say(out, e, kind, ['waste.${e.action}.${_who(e.side)}']);
        }
      case MatchEventType.halfTime:
        _say(out, e, TickerKind.halfTime, ['break.${_situation(e)}']);
      case MatchEventType.extraTime:
        _say(out, e, TickerKind.extraTime, ['extra']);
      case MatchEventType.fullTime:
        _fullTime(e, out);
      case MatchEventType.foul:
        _foul(e, out);
      case MatchEventType.dissent:
        _say(out, e, TickerKind.colour, ['dissent.${e.action}.${_who(e.side)}']);
      case MatchEventType.treatment:
        final w = _who(e.side);
        _say(out, e, TickerKind.treatment, [
          (e.value ?? 0) == 1 ? 'treatment.$w' : 'treatment.keeper.$w',
        ]);
      case MatchEventType.teamTalk:
        final how = switch (e.value ?? 0) {
          1 => 'good',
          -1 => 'bad',
          _ => 'flat',
        };
        _say(out, e, TickerKind.colour, [
          'talk.${e.action}.$how.${_who(e.side)}',
        ]);
      case MatchEventType.shootoutKick:
        break;
    }
    _previous = e;
    if (out.isNotEmpty) _lastLineTick = e.tick;
    _homeGoals = e.homeGoals;
    _awayGoals = e.awayGoals;
    return out;
  }

  /// "lead", "behind" or "level", seen from the own club.
  String _situation(MatchEvent e) {
    final own = ownSide == 0 ? e.homeGoals : e.awayGoals;
    final other = ownSide == 0 ? e.awayGoals : e.homeGoals;
    return own > other
        ? 'lead'
        : own < other
        ? 'behind'
        : 'level';
  }

  /// The steps of an attack before the end: only the dangerous part, at most
  /// [most] steps; the last one is left out when [lastIsLoss] (the loss
  /// tells it).
  void _steps(
    MatchEvent e,
    List<TickerLine> out, {
    required int most,
    bool lastIsLoss = false,
  }) {
    final steps = e.steps;
    final end = lastIsLoss ? steps.length - 1 : steps.length;
    final told = <AttackStep>[];
    for (var i = end - 1; i >= 0 && told.length < most; i--) {
      final s = steps[i];
      if (s.action == 'long_shot') continue;
      if (s.column < 2 && s.action == 'short_pass' && told.isNotEmpty) break;
      told.insert(0, s);
    }
    for (final s in told) {
      final a = s.action;
      final res = s.won ? 'won' : 'lost';
      final keys = [
        if (s.has(AttackStep.pretty)) 'step.$a.$res.pretty',
        if (s.has(AttackStep.fast)) 'step.$a.$res.fast',
        if (s.has(AttackStep.pressure)) 'step.$a.$res.press',
        if (s.has(AttackStep.clear)) 'step.$a.$res.clear',
        'step.$a.$res',
      ];
      _say(
        out,
        e,
        TickerKind.play,
        keys,
        p: s.player,
        o: s.opponent,
        lane: s.lane,
        step: true,
      );
      if (!s.won) continue;
      // Memory: the same player down the same lane again and again.
      if (a == 'dribble' || a == 'cross' || a == 'through_ball') {
        final n = _bump('${s.player.value}.$a.${s.lane}');
        if (n == 3 || n == 5) {
          _say(
            out,
            e,
            TickerKind.colour,
            ['mem.again.$a'],
            p: s.player,
            lane: s.lane,
          );
          continue;
        }
      }
      if (a == 'dribble' &&
          s.has(AttackStep.pretty) &&
          _ability(s.player, SpecialAbilityType.dribbler) &&
          _sometimes(2)) {
        _say(out, e, TickerKind.colour, ['wit.step.dribbler'], p: s.player);
      }
    }
  }

  void _shot(MatchEvent e, List<TickerLine> out) {
    // A goal taken away is still a goal scene first.
    final kind = e.annulled
        ? (e.otherPlayer == null ? TickerKind.goal : TickerKind.goalAssist)
        : tickerKindOf(e);
    if (kind == null) return;
    final w = _who(e.side);
    final prev = _previous;
    final setPiece =
        prev != null && prev.tick == e.tick && prev.side == e.side
        ? prev.type
        : null;
    final pen = setPiece == MatchEventType.penalty;
    final big = e.quality == ChanceQuality.big;
    // Pressure: shots of one side in a row.
    if (_streakSide == e.side) {
      _streak++;
    } else {
      _streakSide = e.side;
      _streak = 1;
    }
    final level = energy(e);

    // A half chance is told quietly, in one line.
    if (kind == TickerKind.halfChance) {
      _say(out, e, kind, ['half.$w']);
      _pressure(e, out);
      return;
    }

    // The build-up.
    if (pen) {
      _say(out, e, TickerKind.shotUp, ['pen.up']);
    } else if (setPiece == MatchEventType.corner ||
        setPiece == MatchEventType.freeKick) {
      _say(out, e, TickerKind.shotUp, [
        if (e.shotType == 'header') 'shot.header.set',
        'free.up',
      ]);
    } else {
      final counter = _counterSide == e.side && e.tick - _counterTick <= 2;
      if (counter) {
        _say(out, e, TickerKind.colour, ['open.counter.$w']);
      } else if (level >= 2 && e.steps.isNotEmpty) {
        _say(out, e, TickerKind.colour, ['open.$w.e$level', 'open.$w']);
      }
      _steps(e, out, most: big ? 3 : 2);
      _say(out, e, TickerKind.shotUp, [
        'shot.${e.shotType}.${e.spot}',
        'shot.${e.shotType}',
        'shot.close_range',
      ]);
    }
    _counterSide = -1;

    // The end.
    switch (e.outcome) {
      case ShotOutcome.goal:
        _goalReviewed(e, out, kind, pen: pen, level: level);
      case ShotOutcome.saved:
        final named = e.keeper != null && _sometimes(2);
        _say(out, e, kind, [
          if (pen) 'pen.save.$w',
          if (big && named) 'save.$w.big.k',
          if (big) 'save.$w.big',
          if (named) 'save.$w.k',
          'save.$w',
        ]);
        final keeper = 1 - e.side;
        final n = _bump('saves.$keeper');
        if (n == 4 || n == 7) {
          _say(out, e, TickerKind.colour, [
            'mem.keeper.${_who(keeper)}',
          ], side: keeper);
        }
      case ShotOutcome.blocked:
        _say(out, e, kind, ['block.$w']);
      case ShotOutcome.offTarget:
      case null:
        _say(out, e, kind, [
          if (pen) 'pen.miss.$w',
          if (big) 'miss.$w.big',
          'miss.$w',
        ]);
        _missed(e, out);
    }
    if (e.outcome != ShotOutcome.goal) _pressure(e, out);
    _advantageOver(e, out, scored: e.isGoal);
  }

  /// The ground at kick-off: the crowd, a derby, a long trip (step 10e4).
  void _venueIntro(MatchEvent e, List<TickerLine> out) {
    final s = setting;
    if (s.capacity > 0) {
      final band = s.stadium == null
          ? 'final'
          : s.fill >= 0.97
          ? 'sold'
          : s.fill >= 0.75
          ? 'high'
          : s.fill >= 0.45
          ? 'mid'
          : 'low';
      _say(out, e, TickerKind.colour, ['crowd.$band'], side: -1);
    }
    if (s.derby > 0) {
      _say(out, e, TickerKind.colour, [
        if (s.derbyName != null) 'derby.named.${s.derby}',
        if (s.derbyName != null) 'derby.named',
        'derby.${s.derby}',
      ], side: -1);
    }
    if (s.travel > 0) {
      _say(out, e, TickerKind.colour, [
        'travel.${_who(1)}',
      ], side: 1);
    }
    // Weather and ground (step 10e5): only told when worth a word.
    if (s.weather != 'cloudy' || s.ground != 'good') {
      _say(out, e, TickerKind.colour, [
        if (s.ground != 'good') 'ground.${s.ground}',
        'weather.${s.weather}',
      ], side: -1);
    }
  }

  /// The referee at kick-off, by the trait he is known for.
  void _refereeIntro(MatchEvent e, List<TickerLine> out) {
    final r = referee;
    if (r == null) return;
    final trait = r.standsOut;
    final keys = [
      if (trait != null)
        'ref.intro.${trait.id}.${(r.traits[trait] ?? 50) >= 50 ? 'hi' : 'lo'}',
      'ref.intro',
    ];
    _say(out, e, TickerKind.colour, keys, side: -1);
  }

  /// A foul: told when it denied a clear chance or when play ran on.
  void _foul(MatchEvent e, List<TickerLine> out) {
    final attacker = 1 - e.side;
    final w = _who(attacker);
    final dogso = (e.value ?? 0) == 1;
    if (e.action == 'advantage') {
      _advSide = attacker;
      _advDogso = dogso;
      _say(
        out,
        e,
        TickerKind.colour,
        [if (dogso) 'adv.dogso.$w', 'adv.$w'],
        p: e.otherPlayer,
        o: e.player,
        side: attacker,
      );
      return;
    }
    if (dogso) {
      _say(
        out,
        e,
        TickerKind.colour,
        ['foul.dogso.$w'],
        p: e.otherPlayer,
        o: e.player,
        side: attacker,
      );
    } else if (_sometimes(3)) {
      _say(
        out,
        e,
        TickerKind.colour,
        ['foul.whistle.$w'],
        p: e.otherPlayer,
        o: e.player,
        side: attacker,
      );
    }
  }

  /// After an attack with advantage: worth it, or wasted.
  void _advantageOver(MatchEvent e, List<TickerLine> out, {required bool scored}) {
    if (_advSide < 0) return;
    final w = _who(_advSide);
    final side = _advSide;
    final dogso = _advDogso;
    _advSide = -1;
    if (scored) {
      _say(out, e, TickerKind.colour, [
        if (dogso) 'adv.nocard',
        'adv.goal.$w',
      ], side: side);
    } else {
      _say(out, e, TickerKind.colour, ['adv.wasted.$w'], side: side);
    }
  }

  /// A goal, with what the flag and the VAR made of it (step 10e2).
  void _goalReviewed(
    MatchEvent e,
    List<TickerLine> out,
    TickerKind kind, {
    required bool pen,
    required int level,
  }) {
    final w = _who(e.side);
    final loud = (level + 1).clamp(0, 3);
    switch (e.review) {
      case 'goal_overturned':
        _say(out, e, TickerKind.colour, ['goal.$w.e$loud', 'goal.$w']);
        _say(out, e, TickerKind.varCheck, ['var.check.goal', 'var.check']);
        _say(out, e, TickerKind.varDecision, ['var.goal_overturned.$w']);
      case 'goal_disallowed':
        _say(out, e, TickerKind.colour, ['goal.$w.e$loud', 'goal.$w']);
        _say(out, e, TickerKind.miss, ['ref.goal_disallowed.$w']);
      case 'goal_given':
        _say(out, e, TickerKind.colour, ['flag.up']);
        _say(out, e, TickerKind.varCheck, ['var.check.offside', 'var.check']);
        _goal(e, out, kind, pen: pen, level: level);
        _say(out, e, TickerKind.colour, ['var.goal_given.$w']);
      case 'goal_confirmed':
        _goal(e, out, kind, pen: pen, level: level);
        _say(out, e, TickerKind.varCheck, ['var.check.goal', 'var.check']);
        _say(out, e, TickerKind.varDecision, ['var.goal_confirmed.$w']);
      case 'offside_missed':
        _goal(e, out, kind, pen: pen, level: level);
        _say(out, e, TickerKind.colour, ['ref.offside_missed.$w']);
      default:
        _goal(e, out, kind, pen: pen, level: level);
    }
  }

  void _pressure(MatchEvent e, List<TickerLine> out) {
    if (_streak == 3 || _streak == 5) {
      _say(out, e, TickerKind.colour, ['mem.pressure.${_who(e.side)}']);
    }
  }

  void _missed(MatchEvent e, List<TickerLine> out) {
    final shooter = e.player;
    final n = shooter == null ? 0 : _bump('miss.${shooter.value}');
    if (n >= 3) {
      _say(out, e, TickerKind.colour, ['mem.miss3']);
      return;
    }
    if (n == 2) {
      _say(out, e, TickerKind.colour, ['mem.miss2']);
      return;
    }
    if (!_sometimes(2)) return;
    if (_trait(shooter, CharacterTrait.egoism) >= 75 &&
        e.shotType == 'long_shot') {
      _say(out, e, TickerKind.colour, ['wit.miss.egoism']);
    } else if (_trait(shooter, CharacterTrait.partyFactor) >= 75 &&
        e.minute >= 55) {
      _say(out, e, TickerKind.colour, ['wit.miss.party']);
    } else if (_trait(shooter, CharacterTrait.consistency) <= 25) {
      _say(out, e, TickerKind.colour, ['wit.miss.consistency']);
    } else if (_trait(shooter, CharacterTrait.pressureResistance) <= 25 &&
        energy(e) >= 2) {
      _say(out, e, TickerKind.colour, ['wit.miss.pressure']);
    }
  }

  void _goal(
    MatchEvent e,
    List<TickerLine> out,
    TickerKind kind, {
    required bool pen,
    required int level,
  }) {
    final w = _who(e.side);
    final loud = (level + 1).clamp(0, 3);
    _say(out, e, kind, [if (pen) 'pen.goal.$w', 'goal.$w.e$loud', 'goal.$w']);
    _say(out, e, TickerKind.scorer, ['scorer.$w', 'scorer']);
    if (e.otherPlayer != null && !pen) {
      _say(out, e, TickerKind.assist, ['assist.$w', 'assist']);
    }
    // What the goal means: from the score before it.
    final before = e.side == 0
        ? (_homeGoals - _awayGoals)
        : (_awayGoals - _homeGoals);
    final after = before + 1;
    final what = switch (before) {
      -1 => 'equal',
      0 => 'lead',
      < -1 => 'cut',
      _ => after >= 3 ? 'rout' : 'extend',
    };
    final when = e.minute >= 85
        ? '.late'
        : e.minute <= 3
        ? '.early'
        : '';
    _say(out, e, TickerKind.colour, [
      'ctx.$what$when.$w',
      'ctx.$what.$w',
    ]);
    // Memory: two or three today.
    final scorer = e.player;
    final goals = scorer == null ? 0 : _bump('goals.${scorer.value}');
    if (goals == 2) {
      _say(out, e, TickerKind.colour, ['mem.brace']);
    } else if (goals == 3) {
      _say(out, e, TickerKind.colour, ['mem.hattrick']);
    }
    _streak = 0;
    if (!_sometimes(2)) return;
    // Wit: who scored, by character and abilities.
    final keys = [
      if (e.shotType == 'header' &&
          _ability(scorer, SpecialAbilityType.headerMonster))
        'wit.goal.header_monster',
      if (e.shotType == 'long_shot' &&
          _ability(scorer, SpecialAbilityType.longShooter))
        'wit.goal.long_shooter',
      if (e.spot == 2 && _ability(scorer, SpecialAbilityType.goalPoacher))
        'wit.goal.goal_poacher',
      if (_trait(scorer, CharacterTrait.mediaHunger) >= 75)
        'wit.goal.media_hunger',
      if (_trait(scorer, CharacterTrait.egoism) >= 75) 'wit.goal.egoism',
      if (_trait(scorer, CharacterTrait.partyFactor) >= 75)
        'wit.goal.party',
      if (_trait(scorer, CharacterTrait.consistency) <= 25)
        'wit.goal.consistency',
    ];
    if (keys.isNotEmpty) _say(out, e, TickerKind.colour, [keys.first]);
  }

  void _ballWon(MatchEvent e, List<TickerLine> out) {
    final kind = tickerKindOf(e);
    if (kind == null) return;
    final attacker = 1 - e.side;
    final w = _who(attacker);
    if (_streakSide == attacker) _streak = 0;
    _steps(e, out, most: 1, lastIsLoss: true);
    _say(
      out,
      e,
      kind,
      ['lost.${e.action}.$w'],
      p: e.otherPlayer,
      o: e.player,
      side: attacker,
    );
    final loser = e.otherPlayer;
    final n = loser == null ? 0 : _bump('lost.${loser.value}');
    if (n == 3 || n == 6) {
      _say(
        out,
        e,
        TickerKind.colour,
        ['mem.loses'],
        p: loser,
        o: e.player,
        side: attacker,
      );
    }
  }

  void _card(MatchEvent e, List<TickerLine> out) {
    final w = _who(e.side);
    final (kind, key) = switch (e.type) {
      MatchEventType.yellowCard => (TickerKind.yellow, 'yellow'),
      MatchEventType.secondYellow => (TickerKind.secondYellow, 'second'),
      _ => (TickerKind.red, 'red'),
    };
    _say(out, e, kind, [
      if (e.action != null) '$key.${e.action}.$w',
      '$key.$w',
    ]);
    final n = _bump('cards.${e.side}');
    if (n == 4) {
      _say(out, e, TickerKind.colour, ['mem.cards.$w']);
    } else if (_sometimes(2)) {
      if (_trait(e.player, CharacterTrait.temper) >= 75) {
        _say(out, e, TickerKind.colour, ['wit.card.temper']);
      } else if (_trait(e.player, CharacterTrait.aggression) >= 75) {
        _say(out, e, TickerKind.colour, ['wit.card.aggression']);
      }
    }
    if (e.review != null) {
      _say(out, e, TickerKind.colour, ['ref.${e.review}.$w']);
    }
    if (kind != TickerKind.yellow) _captain(e, e.player, out);
  }

  void _captain(MatchEvent e, PlayerId? leaving, List<TickerLine> out) {
    final captain = captainOf?.call(e.side);
    if (captain == null || leaving != captain) return;
    _say(out, e, TickerKind.captainOff, [
      'captain.${_who(e.side)}',
    ], p: captain);
  }

  void _fullTime(MatchEvent e, List<TickerLine> out) {
    final own = ownSide == 0 ? e.homeGoals : e.awayGoals;
    final other = ownSide == 0 ? e.awayGoals : e.homeGoals;
    final key = own > other
        ? (own - other >= 3 ? 'full.win.big' : 'full.win')
        : own < other
        ? (other - own >= 3 ? 'full.loss.big' : 'full.loss')
        : (own == 0 ? 'full.draw.goalless' : 'full.draw');
    _say(out, e, TickerKind.fullTime, [key, key.split('.').take(2).join('.')]);
    if (tier >= 3) _say(out, e, TickerKind.colour, ['local.fulltime']);
  }

  /// A line for a quiet phase: after some minutes without a line the
  /// reporter fills the air (by score and minute, in the lower leagues with
  /// local colour). Null while the match still talks by itself.
  TickerLine? quiet(int tick, int minute, String clock) {
    if (tick - _lastLineTick < 5) return null;
    _lastLineTick = tick;
    _seed = (tick * 4099 + 17) & 0x3fffffff;
    final own = ownSide == 0 ? _homeGoals : _awayGoals;
    final other = ownSide == 0 ? _awayGoals : _homeGoals;
    final situation = own > other
        ? 'lead'
        : own < other
        ? 'behind'
        : 'level';
    final local = tier >= 3 && _sometimes(2);
    final keys = [
      if (local) 'local.calm',
      if (minute >= 80) 'calm.$situation.late',
      'calm.$situation',
    ];
    final text = _pick(keys);
    if (text.isEmpty) return null;
    return TickerLine(
      minute: minute,
      clock: clock,
      kind: TickerKind.calm,
      side: -1,
      homeGoals: _homeGoals,
      awayGoals: _awayGoals,
      text: text
          .replaceAll('{home}', home)
          .replaceAll('{away}', away)
          .replaceAll('{team}', ownSide == 0 ? home : away)
          .replaceAll('{opp}', ownSide == 0 ? away : home)
          .replaceAll('{score}', '$_homeGoals:$_awayGoals')
          .replaceAll('{ours}', '$own:$other'),
    );
  }
}
