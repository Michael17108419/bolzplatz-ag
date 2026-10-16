import 'dart:math' as math;

import '../calendar/calendar_rules.dart';
import '../calendar/game_date.dart';
import '../calendar/season.dart';
import '../calendar/season_calendar.dart';
import '../development/squad_turnover.dart';
import '../generation/player_generator.dart';
import '../match/auto_manager.dart';
import '../match/limits.dart';
import '../match/match_session.dart';
import '../match/match_types.dart';
import '../match/team_sheet.dart';
import '../model/ids.dart';
import '../model/region.dart';
import '../pyramid/pyramid.dart';
import '../result/result.dart';
import '../rng/seeded_random.dart';
import '../rules/rules.dart';
import 'conference.dart';
import 'cup.dart';
import 'league_table.dart';
import 'schedule.dart';
import 'season_state.dart';
import 'timeline.dart';

/// Result of one played season.
class SeasonOutcome {
  SeasonOutcome({
    required this.tables,
    required this.bolzplatz,
    required this.pottWinners,
    required this.pottQualifiers,
    required this.matchesPlayed,
    required this.goalsScored,
    required this.homeWins,
    required this.draws,
    required this.awayWins,
    required this.goalsByPlayer,
    required this.injuries,
    required this.redCards,
    required this.yellowCards,
    required this.minutesByPlayer,
    required this.shots,
    required this.leagueGoalsByPlayer,
    required this.leagueAssistsByPlayer,
  });

  final Map<LeagueId, List<TableEntry>> tables;
  final KnockoutCup bolzplatz;
  final Map<Region, ClubId> pottWinners;

  /// The 24 clubs that earned a place in the next Bolzplatzpokal.
  final List<ClubId> pottQualifiers;
  final int matchesPlayed;
  final int goalsScored;
  final int homeWins;
  final int draws;
  final int awayWins;
  final Map<PlayerId, int> goalsByPlayer;
  final int injuries;
  final int redCards;
  final int yellowCards;

  /// Minutes played per player over all matches of the season.
  final Map<PlayerId, int> minutesByPlayer;

  /// All shots of the season (league and cups).
  final int shots;

  /// Goals per player in league matches only.
  final Map<PlayerId, int> leagueGoalsByPlayer;

  /// Assists per player in league matches only.
  final Map<PlayerId, int> leagueAssistsByPlayer;

  List<ClubId> standing(LeagueId league) => [
    for (final e in tables[league]!) e.club,
  ];
}

/// Why a player misses the next match.
enum Absence { injured, suspended }

/// A season in progress, played day by day by [SeasonRunner].
class SeasonRun {
  SeasonRun._({
    required this.state,
    required this.seed,
    required this.schedules,
    required this.tables,
    required this.timeline,
    required this.bolzplatz,
    required this.pott,
  });

  final SeasonState state;
  final int seed;
  final Map<LeagueId, List<List<Fixture>>> schedules;
  final Map<LeagueId, LeagueTable> tables;

  /// Every day with matches of the season on the calendar.
  final SeasonTimeline timeline;
  final KnockoutCup bolzplatz;
  final Map<Region, KnockoutCup> pott;

  /// Index of the next day to play in [timeline].
  int dayIndex = 0;

  /// The last day that was played, null before the first one.
  GameDate? date;

  /// Matchdays played so far per league.
  final Map<LeagueId, int> leagueDays = {};

  /// Cup ties of later windows of a round that was decided on its first day.
  final Map<int, List<ConferenceMatch>> carry = {};
  int bolzRound = 0;
  int pottRound = 0;
  int matches = 0;
  int goals = 0;
  int homeWins = 0;
  int draws = 0;
  int awayWins = 0;

  bool get isOver => dayIndex >= timeline.days.length;

  /// The next day with matches, or null when the season is over.
  GameDate? get nextDate => isOver ? null : timeline.days[dayIndex].date;

  /// Matchdays of [league] played so far.
  int matchdaysPlayed(LeagueId league) => leagueDays[league] ?? 0;
}

/// Plays a whole season of all leagues and both cups without a user
/// interface. Everything depends only on the state, the rules and the seed.
class SeasonRunner {
  SeasonRunner(this.rules, {required this.calendarRules, this.forcedFormation})
    : _engine = MatchEngine(rules),
      _auto = AutoManager(rules),
      _calendar = CalendarGenerator(calendarRules);

  final Rules rules;

  /// Where the matches of the leagues and cups lie on the calendar.
  final CalendarRules calendarRules;
  final CalendarGenerator _calendar;

  /// If set, every club plays this formation (for tests and analysis).
  final String? forcedFormation;
  final MatchEngine _engine;
  final AutoManager _auto;

  // Per-season working data.
  late Map<ClubId, double> _form;
  late Map<PlayerId, int> _injuredUntil;
  late Map<String, int> _bans;
  late Map<String, int> _cardsByCompetition;
  late Map<ClubId, TeamSheet> _sheets;
  late Map<ClubId, String> _sheetKey;
  late SeasonState _state;
  late int _today;
  int _injuries = 0;
  int _reds = 0;
  int _yellows = 0;
  int _shots = 0;
  final Map<PlayerId, int> _goals = {};
  final Map<PlayerId, int> _leagueGoals = {};
  final Map<PlayerId, int> _leagueAssists = {};
  final Map<PlayerId, int> _minutes = {};
  int _seed = 0;
  Map<ClubId, TeamSheet> _userSheets = {};

  Map<ClubId, int> _tiers(SeasonState state) {
    final tiers = <ClubId, int>{};
    final levels = {for (final l in rules.leagues) LeagueId(l.id): l.level};
    for (final e in state.members.entries) {
      for (final c in e.value) {
        tiers[c] = levels[e.key]!;
      }
    }
    return tiers;
  }

  SeasonState? _tierState;
  Map<ClubId, int> _tierMap = const {};

  /// The league level of a club in the current season state.
  int _tierOf(SeasonState state, ClubId club) {
    if (!identical(_tierState, state)) {
      _tierMap = _tiers(state);
      _tierState = state;
    }
    return _tierMap[club] ?? 4;
  }

  static String _compKey(Competition c) => switch (c) {
    Competition.league => 'L',
    Competition.bolzplatz => 'B',
    Competition.pott => 'P',
  };

  /// True if the player misses a match of [comp] on the day [epochDay]:
  /// injured, or banned in this competition.
  bool _isOut(PlayerId p, String comp, int epochDay) =>
      (_injuredUntil[p] ?? -1) >= epochDay ||
      (_bans['$comp:${p.value}'] ?? 0) > 0;

  MatchTeam _team(ClubId club, String comp) {
    final squad = _state.squads[club]!;
    final out = <PlayerId>{
      for (final p in squad)
        if (_isOut(p.id, comp, _today)) p.id,
    };
    final key = (out.toList()..sort((a, b) => a.value.compareTo(b.value)))
        .map((e) => e.value)
        .join(',');
    var sheet = _sheets[club];
    final own = _userSheets[club];
    if (own != null &&
        !own.startingXi.any(out.contains) &&
        !own.bench.any(out.contains)) {
      sheet = own;
    } else if (sheet == null || _sheetKey[club] != key || sheet == own) {
      sheet =
          _auto.build(
            squad,
            exclude: out,
            formationId: forcedFormation,
            benchSize: rules.tactics.benchSize(_tierOf(_state, club)),
          ) ??
          _auto.build(
            squad,
            formationId: forcedFormation,
            benchSize: rules.tactics.benchSize(_tierOf(_state, club)),
          )!;
      _sheets[club] = sheet;
      _sheetKey[club] = key;
    }
    final form = _form[club] ?? rules.match.defaultForm;
    return MatchTeam(
      clubId: club,
      name: _state.clubs[club]!.name,
      squad: squad,
      sheet: sheet,
      form: {for (final p in squad) p.id: form},
    );
  }

  int _matchSeed(String label) => SeededRandom(_seed).fork(label).seed;

  void _afterMatch(
    ClubId home,
    ClubId away,
    MatchResult r, {
    required bool countForm,
    required String comp,
  }) {
    // A club that plays serves one match of every ban it has in this
    // competition (before new cards of this match count).
    for (final club in [home, away]) {
      for (final p in _state.squads[club]!) {
        final key = '$comp:${p.id.value}';
        final left = _bans[key] ?? 0;
        if (left > 0) _bans[key] = left - 1;
      }
    }
    for (final e in r.events) {
      if (e.type == MatchEventType.shot && e.isGoal && e.player != null) {
        _goals[e.player!] = (_goals[e.player!] ?? 0) + 1;
        if (countForm) {
          _leagueGoals[e.player!] = (_leagueGoals[e.player!] ?? 0) + 1;
          final a = e.otherPlayer;
          if (a != null) _leagueAssists[a] = (_leagueAssists[a] ?? 0) + 1;
        }
      }
      final key = e.player == null ? '' : '$comp:${e.player!.value}';
      if (e.type == MatchEventType.secondYellow ||
          e.type == MatchEventType.redCard) {
        _bans[key] = math.max(_bans[key] ?? 0, 1);
      }
      if (e.type == MatchEventType.yellowCard ||
          e.type == MatchEventType.secondYellow) {
        final n = (_cardsByCompetition[key] ?? 0) + 1;
        _cardsByCompetition[key] = n;
        if (n % rules.season.suspensionYellowCards == 0) {
          _bans[key] = math.max(_bans[key] ?? 0, 1);
        }
      }
    }
    for (final inj in r.injuries) {
      // One matchday stands for a week: the player is back after the injury
      // plus the days up to the next weekly match.
      final grace = rules.season.injuryDaysPerMatchday.round() - 1;
      _injuredUntil[inj.player] = _today + inj.days + grace;
      _injuries++;
    }
    for (final e in r.minutesPlayed.entries) {
      _minutes[e.key] = (_minutes[e.key] ?? 0) + e.value;
    }
    _shots += r.homeStats.shots + r.awayStats.shots;
    _reds += r.homeStats.redCards + r.awayStats.redCards;
    _yellows += r.homeStats.yellowCards + r.awayStats.yellowCards;
    if (countForm) {
      void move(ClubId club, double delta) {
        final f = _form[club] ?? rules.match.defaultForm;
        final next = f + delta;
        _form[club] =
            next + (rules.match.defaultForm - next) * rules.season.formDrift;
      }

      if (r.homeGoals > r.awayGoals) {
        move(home, rules.season.formWin);
        move(away, rules.season.formLoss);
      } else if (r.homeGoals < r.awayGoals) {
        move(away, rules.season.formWin);
        move(home, rules.season.formLoss);
      } else {
        move(home, 0);
        move(away, 0);
      }
    }
  }

  /// The schedule of one league in the season with this [seed]: one list of
  /// fixtures per matchday. [play] uses the same function, so a screen can
  /// show the real next match before the season is played.
  static List<List<Fixture>> leagueSchedule(
    List<ClubId> clubs,
    LeagueId league,
    int seed,
  ) => Schedule.doubleRoundRobin(
    clubs,
    SeededRandom(seed).fork('schedule:${league.value}'),
  );

  /// Starts the season described by [state]: schedules, tables and the
  /// draw of both cups. [playMatchday] then plays it day by day and
  /// [conclude] closes it. [play] does all three in one go.
  ///
  /// [userSheets] are line-ups of clubs that are not set up by the
  /// assistant (the club of the player).
  SeasonRun begin(
    SeasonState state, {
    required int seed,
    Map<ClubId, TeamSheet> userSheets = const {},
  }) {
    _userSheets = Map.of(userSheets);
    _state = state;
    _seed = seed;
    _form = {};
    _injuredUntil = {};
    _bans = {};
    _cardsByCompetition = {};
    _sheets = {};
    _sheetKey = {};
    _today = 0;
    _injuries = 0;
    _reds = 0;
    _yellows = 0;
    _shots = 0;
    _goals.clear();
    _leagueGoals.clear();
    _leagueAssists.clear();
    _minutes.clear();
    final root = SeededRandom(seed);
    final tiers = _tiers(state);
    int tier(ClubId c) => tiers[c] ?? 5;

    // Schedules and tables.
    final schedules = <LeagueId, List<List<Fixture>>>{};
    final tables = <LeagueId, LeagueTable>{};
    for (final e in state.members.entries) {
      schedules[e.key] = leagueSchedule(e.value, e.key, seed);
      tables[e.key] = LeagueTable(e.value);
    }

    // Cups.
    final cups = rules.season.cups;
    final league1 = _leagueByLevel(state, 1);
    final league2 = _leagueByLevel(state, 2);
    final league3 = _leagueByLevel(state, 3);
    final fourth = _fourthLeagues(state);
    final top = [...league1, ...league2];
    final List<ClubId> lower;
    final fourthLeagueClubs = [for (final l in fourth.values) ...l];
    // Second teams do not take part in the Bolzplatzpokal and cannot qualify
    // for it (Block 2); the next club takes their place.
    final secondTeams = {
      for (final c in state.clubs.values)
        if (c.isSecondTeam) c.id,
    };
    bool eligible(ClubId c) => !secondTeams.contains(c);
    if (state.isFirstSeason) {
      final thirdEligible = [
        for (final c in league3)
          if (eligible(c)) c,
      ];
      final draw = [
        for (final c in fourthLeagueClubs)
          if (eligible(c)) c,
      ];
      root.fork('bolzplatz:fourth').shuffle(draw);
      lower = [
        ...thirdEligible,
        ...draw.take(
          cups.yearOneFourthLeaguePlaces +
              league3.length -
              thirdEligible.length,
        ),
      ];
    } else {
      final inTop = top.toSet();
      final inThird = league3.toSet();
      final third = [
        for (final c in state.thirdLeagueQualifiers)
          if (inThird.contains(c) && eligible(c)) c,
      ].take(cups.thirdLeaguePlaces);
      final taken = {...inTop, ...third};
      final qualified = [
        for (final c in state.pottQualifiers)
          if (!taken.contains(c) && eligible(c)) c,
      ].take(cups.bolzplatzLowerGroupSize - cups.thirdLeaguePlaces);
      final chosen = <ClubId>[...third, ...qualified];
      // Not enough qualified clubs (some moved up): fill with the best
      // remaining clubs of the third and then the fourth leagues.
      final reserve = <ClubId>[
        for (final c in state.thirdLeagueQualifiers)
          if (inThird.contains(c) && eligible(c)) c,
        ...(List<ClubId>.of(fourthLeagueClubs.where(eligible))..sort((a, b) {
          final ra = state.previousRank[a] ?? 99;
          final rb = state.previousRank[b] ?? 99;
          return ra != rb ? ra.compareTo(rb) : a.value.compareTo(b.value);
        })),
      ];
      for (final c in reserve) {
        if (chosen.length >= cups.bolzplatzLowerGroupSize) break;
        if (!taken.contains(c) && !chosen.contains(c)) chosen.add(c);
      }
      lower = chosen;
    }
    final bolzplatz = KnockoutCup.bolzplatz(
      top: top,
      lower: lower,
      tier: tier,
      rng: root.fork('bolzplatz'),
    );
    final inBolzplatz = {...top, ...lower};
    final pott = <Region, KnockoutCup>{};
    for (final region in Region.values) {
      final participants = [
        for (final id in [...league3, ...fourthLeagueClubs])
          if (state.clubs[id]!.region == region && !inBolzplatz.contains(id))
            id,
      ];
      // The year-one draw above removed some fourth-league clubs; they play
      // in the main cup only.
      final fourthOfRegion =
          [
            for (final id in participants)
              if (tier(id) == 4) id,
          ]..sort((a, b) {
            final ra = state.previousRank[a];
            final rb = state.previousRank[b];
            if (ra != null && rb != null) return ra.compareTo(rb);
            if (ra != null) return -1;
            if (rb != null) return 1;
            return a.value.compareTo(b.value);
          });
      final thirdOfRegion = [
        for (final id in participants)
          if (tier(id) == 3) id,
      ];
      final prng = root.fork('pott:${region.id}');
      if (state.previousRank.isEmpty) prng.shuffle(fourthOfRegion);
      pott[region] = KnockoutCup.provinz(
        name: 'pott:${region.id}',
        participants: participants,
        byePriority: [...thirdOfRegion, ...fourthOfRegion],
        bracketSize: cups.pottBracketSize,
        tier: tier,
        rng: prng,
      );
    }
    return SeasonRun._(
      state: state,
      seed: seed,
      schedules: schedules,
      tables: tables,
      timeline: SeasonTimeline.build(
        rules: rules,
        calendarRules: calendarRules,
        generator: _calendar,
        season: Season(state.startYear),
        schedules: schedules,
        seed: seed,
      ),
      bolzplatz: bolzplatz,
      pott: pott,
    );
  }

  ClubId _playTie(
    ClubId home,
    ClubId away,
    String label,
    String comp, {
    bool neutral = false,
  }) {
    final k = _engine.simulateKnockout(
      _team(home, comp),
      _team(away, comp),
      seed: _matchSeed(label),
      neutral: neutral,
    );
    _afterMatch(home, away, k.match, countForm: false, comp: comp);
    return k.winnerSide == 0 ? home : away;
  }

  /// Sets the line-up of a club that is not set up by the assistant. It is
  /// used from the next match on, as long as none of its players is out.
  void setUserSheet(ClubId club, TeamSheet sheet) => _userSheets[club] = sheet;

  /// Goals per player in league matches so far.
  Map<PlayerId, int> get leagueGoals => Map.of(_leagueGoals);

  /// Assists per player in league matches so far.
  Map<PlayerId, int> get leagueAssists => Map.of(_leagueAssists);

  /// The next day of the season with all its matches. The matches of other
  /// clubs are simulated in advance. If [own] and [sheet] are given, the own
  /// league match of that club is a live session played with [sheet]
  /// (not managed by the assistant). Opening a day changes nothing: the
  /// day becomes part of the season with [completeDay].
  ConferenceDay openDay(SeasonRun run, {ClubId? own, TeamSheet? sheet}) {
    if (run.isOver) throw StateError('The season is over');
    _state = run.state;
    _seed = run.seed;
    final plan = run.timeline.days[run.dayIndex];
    _today = plan.date.epochDay;
    final matches = <ConferenceMatch>[];
    ConferenceMatch? ownMatch;

    final out = <PlayerId>{
      if (own != null)
        for (final p in run.state.squads[own]!)
          if (_isOut(p.id, 'L', _today)) p.id,
    };
    for (final slot in plan.leagueSlots) {
      for (final k in slot.kicks) {
        final f = k.fixture;
        final seed = _matchSeed(
          'l:${k.league.value}:${k.matchday}:${f.home.value}',
        );
        final isOwn = own != null && (f.home == own || f.away == own);
        if (isOwn && sheet != null) {
          final usable =
              !sheet.startingXi.any(out.contains) &&
              !sheet.bench.any(out.contains);
          MatchTeam team(ClubId c) {
            final base = _team(c, 'L');
            if (c != own) return base;
            return MatchTeam(
              clubId: c,
              name: base.name,
              squad: base.squad,
              sheet: usable ? sheet : base.sheet,
              form: base.form,
              autoManage: false,
            );
          }

          final m = ConferenceMatch(
            competition: Competition.league,
            league: k.league,
            fixture: f,
            date: plan.date,
            minuteOfDay: slot.minuteOfDay,
            round: k.matchday,
            session: MatchSession(
              rules: rules,
              home: team(f.home),
              away: team(f.away),
              seed: seed,
            ),
            isOwn: true,
            sheetReplaced: !usable,
          );
          ownMatch = m;
          matches.add(m);
        } else {
          matches.add(
            ConferenceMatch(
              competition: Competition.league,
              league: k.league,
              fixture: f,
              date: plan.date,
              minuteOfDay: slot.minuteOfDay,
              round: k.matchday,
              result: _engine.simulate(
                _team(f.home, 'L'),
                _team(f.away, 'L'),
                seed: seed,
              ),
              isOwn: isOwn,
            ),
          );
        }
      }
    }

    // Cup rounds are decided on the first day of their windows; ties of
    // later windows are shown on their own day.
    final cupPlans = <CupRoundPlan>[];
    final started = <String>{};
    for (final w in plan.cupWindows) {
      final key = '${w.kind.name}:${w.round}';
      if (!started.add(key)) continue;
      final windows = run.timeline.cupWindowsOf(w.kind, w.round);
      if (windows.first.$1 != plan.date) continue;
      if (w.kind == CupKind.bolzplatz) {
        if (run.bolzRound != w.round || run.bolzplatz.isFinished) continue;
        cupPlans.add(
          _planCupRound(
            Competition.bolzplatz,
            null,
            run.bolzplatz,
            w.round,
            windows,
            own,
          ),
        );
      } else {
        if (run.pottRound != w.round) continue;
        for (final region in Region.values) {
          final cup = run.pott[region]!;
          if (cup.isFinished) continue;
          cupPlans.add(
            _planCupRound(Competition.pott, region, cup, w.round, windows, own),
          );
        }
      }
    }
    for (final cp in cupPlans) {
      for (final t in cp.ties) {
        if (t.date == plan.date) matches.add(t);
      }
    }
    matches.addAll(run.carry[plan.date.epochDay] ?? const []);
    matches.sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    return ConferenceDay(
      date: plan.date,
      matches: matches,
      own: ownMatch,
      openedIndex: run.dayIndex,
      cupPlans: cupPlans,
    );
  }

  /// Simulates all ties of the next round of [cup] and spreads them over the
  /// kickoff [windows] of the round.
  CupRoundPlan _planCupRound(
    Competition competition,
    Region? region,
    KnockoutCup cup,
    int round,
    List<(GameDate, CupWindow)> windows,
    ClubId? own,
  ) {
    final comp = _compKey(competition);
    final pending = cup.pendingTies;
    final neutral = cup.nextRoundIsNeutral;
    final ties = <ConferenceMatch>[];
    for (var i = 0; i < pending.length; i++) {
      final (h, a) = pending[i];
      final label = competition == Competition.bolzplatz
          ? 'bp:$round:${h.value}'
          : 'pott:${region!.id}:$round:${h.value}';
      final window = windows[i * windows.length ~/ pending.length];
      ties.add(
        ConferenceMatch(
          competition: competition,
          region: region,
          fixture: Fixture(h, a),
          date: window.$1,
          minuteOfDay: window.$2.minuteOfDay,
          round: round,
          knockout: _engine.simulateKnockout(
            _team(h, comp),
            _team(a, comp),
            seed: _matchSeed(label),
            neutral: neutral,
          ),
          isOwn: own != null && (h == own || a == own),
        ),
      );
    }
    return CupRoundPlan(
      competition: competition,
      region: region,
      round: round,
      ties: ties,
    );
  }

  /// Makes the opened [day] part of the season. [ownResult] is the result
  /// of the live own league match, if there was one.
  void completeDay(SeasonRun run, ConferenceDay day, {MatchResult? ownResult}) {
    if (run.isOver || run.dayIndex != day.openedIndex) {
      throw StateError('This is not the next day of the season');
    }
    _state = run.state;
    _seed = run.seed;
    _today = day.date.epochDay;
    for (final m in day.matches) {
      if (!m.isLeague || m.applied) continue;
      final MatchResult r;
      if (m.isLive) {
        if (ownResult == null) throw StateError('The own result is missing');
        r = ownResult;
      } else {
        r = m.result!;
      }
      final f = m.fixture;
      final league = m.league!;
      _afterMatch(f.home, f.away, r, countForm: true, comp: 'L');
      run.tables[league]!.record(f.home, f.away, r.homeGoals, r.awayGoals);
      run.matches++;
      run.goals += r.homeGoals + r.awayGoals;
      if (r.homeGoals > r.awayGoals) {
        run.homeWins++;
      } else if (r.homeGoals < r.awayGoals) {
        run.awayWins++;
      } else {
        run.draws++;
      }
      run.leagueDays[league] = math.max(run.leagueDays[league] ?? 0, m.round);
      m.applied = true;
    }
    var pottDone = false;
    for (final cp in day.cupPlans) {
      final comp = _compKey(cp.competition);
      final winners = <(ClubId, ClubId), ClubId>{};
      for (final t in cp.ties) {
        final k = t.knockout!;
        final f = t.fixture;
        _afterMatch(f.home, f.away, k.match, countForm: false, comp: comp);
        winners[(f.home, f.away)] = k.winnerSide == 0 ? f.home : f.away;
        t.applied = true;
        if (t.date != day.date) {
          run.carry.putIfAbsent(t.date.epochDay, () => []).add(t);
        }
      }
      if (cp.competition == Competition.bolzplatz) {
        run.bolzplatz.playNextRound((h, a) => winners[(h, a)]!);
        run.bolzRound++;
      } else {
        run.pott[cp.region!]!.playNextRound((h, a) => winners[(h, a)]!);
        pottDone = true;
      }
    }
    if (pottDone) run.pottRound++;
    run.carry.remove(day.date.epochDay);
    run.date = day.date;
    run.dayIndex++;
  }

  /// The date and competition of the next match of [club], or null.
  (GameDate, Competition)? nextMatchOf(SeasonRun run, ClubId club) {
    bool plays(List<(ClubId, ClubId)> ties) =>
        ties.any((t) => t.$1 == club || t.$2 == club);
    final region = run.state.clubs[club]?.region;
    for (var i = run.dayIndex; i < run.timeline.days.length; i++) {
      final d = run.timeline.days[i];
      for (final s in d.leagueSlots) {
        for (final k in s.kicks) {
          if (k.fixture.home == club || k.fixture.away == club) {
            return (d.date, Competition.league);
          }
        }
      }
      for (final m in run.carry[d.date.epochDay] ?? const <ConferenceMatch>[]) {
        if (m.fixture.home == club || m.fixture.away == club) {
          return (d.date, m.competition);
        }
      }
      for (final w in d.cupWindows) {
        if (w.kind == CupKind.bolzplatz) {
          if (w.round == run.bolzRound && plays(run.bolzplatz.pendingTies)) {
            return (d.date, Competition.bolzplatz);
          }
        } else if (region != null && w.round == run.pottRound) {
          final cup = run.pott[region];
          if (cup != null && plays(cup.pendingTies)) {
            return (d.date, Competition.pott);
          }
        }
      }
    }
    return null;
  }

  /// Players who cannot play the next match of [club], with the reason.
  Map<PlayerId, Absence> absences(SeasonRun run, ClubId club) {
    final next = nextMatchOf(run, club);
    if (next == null) return const {};
    final comp = _compKey(next.$2);
    final day = next.$1.epochDay;
    final out = <PlayerId, Absence>{};
    for (final p in run.state.squads[club]!) {
      if ((_injuredUntil[p.id] ?? -1) >= day) {
        out[p.id] = Absence.injured;
      } else if ((_bans['$comp:${p.id.value}'] ?? 0) > 0) {
        out[p.id] = Absence.suspended;
      }
    }
    return out;
  }

  /// Finishes cups that are still running and closes the season.
  SeasonOutcome conclude(SeasonRun run) {
    _state = run.state;
    _seed = run.seed;
    final state = run.state;
    final bolzplatz = run.bolzplatz;
    final pott = run.pott;
    final tables = run.tables;
    var bolzRound = run.bolzRound;
    final pottRound = run.pottRound;
    final matches = run.matches;
    final goals = run.goals;
    final hw = run.homeWins;
    final dr = run.draws;
    final aw = run.awayWins;
    final secondTeams = {
      for (final c in state.clubs.values)
        if (c.isSecondTeam) c.id,
    };
    bool eligible(ClubId c) => !secondTeams.contains(c);
    // Finish cups that did not finish within the planned rounds.
    while (!bolzplatz.isFinished) {
      final round = bolzRound++;
      final neutral = bolzplatz.nextRoundIsNeutral;
      bolzplatz.playNextRound(
        (h, a) => _playTie(h, a, 'bp:$round:${h.value}', 'B', neutral: neutral),
      );
    }
    for (final region in Region.values) {
      final cup = pott[region]!;
      while (!cup.isFinished) {
        final round = pottRound;
        final neutral = cup.nextRoundIsNeutral;
        cup.playNextRound(
          (h, a) => _playTie(
            h,
            a,
            'pott:${region.id}:$round:${h.value}',
            'P',
            neutral: neutral,
          ),
        );
      }
    }

    final standings = {for (final e in tables.entries) e.key: e.value.standing};

    // Places for the next Bolzplatzpokal, in this order: the five cup
    // winners, the fourth-league champions and then the runners-up (most
    // points first), the losing finalists, then the losing semi-finalists
    // (most points per game in their league first).
    int compareEntries(TableEntry a, TableEntry b) {
      final p = b.points.compareTo(a.points);
      if (p != 0) return p;
      final g = b.goalDifference.compareTo(a.goalDifference);
      if (g != 0) return g;
      final f = b.goalsFor.compareTo(a.goalsFor);
      return f != 0 ? f : a.club.value.compareTo(b.club.value);
    }

    final firsts = <TableEntry>[];
    final seconds = <TableEntry>[];
    for (final l in rules.leagues.where((l) => l.level == 4)) {
      final table = [
        for (final t in standings[LeagueId(l.id)]!)
          if (eligible(t.club)) t,
      ];
      firsts.add(table[0]);
      seconds.add(table[1]);
    }
    firsts.sort(compareEntries);
    seconds.sort(compareEntries);
    final entryOf = {
      for (final table in standings.values)
        for (final t in table) t.club: t,
    };
    double ppg(ClubId c) {
      final t = entryOf[c]!;
      return t.played == 0 ? 0 : t.points / t.played;
    }

    final finalLosers = <ClubId>[];
    final semiLosers = <ClubId>[];
    final quarterLosers = <ClubId>[];
    for (final region in Region.values) {
      final cup = pott[region]!;
      final out = cup.eliminated;
      finalLosers.add(out.last.first);
      semiLosers.addAll(out[out.length - 2]);
      if (out.length >= 3) quarterLosers.addAll(out[out.length - 3]);
    }
    finalLosers.sort((a, b) => ppg(b).compareTo(ppg(a)));
    semiLosers.sort((a, b) {
      final d = ppg(b).compareTo(ppg(a));
      return d != 0 ? d : a.value.compareTo(b.value);
    });
    quarterLosers.sort((a, b) {
      final d = ppg(b).compareTo(ppg(a));
      return d != 0 ? d : a.value.compareTo(b.value);
    });
    final qualifiers = <ClubId>[];
    for (final c in [
      for (final region in Region.values) pott[region]!.winner!,
      for (final t in firsts) t.club,
      for (final t in seconds) t.club,
      ...finalLosers,
      ...semiLosers,
      ...quarterLosers,
    ]) {
      if (eligible(c) && !qualifiers.contains(c)) qualifiers.add(c);
    }

    return SeasonOutcome(
      tables: standings,
      bolzplatz: bolzplatz,
      pottWinners: {for (final e in pott.entries) e.key: e.value.winner!},
      pottQualifiers: qualifiers,
      matchesPlayed: matches,
      goalsScored: goals,
      homeWins: hw,
      draws: dr,
      awayWins: aw,
      goalsByPlayer: Map.of(_goals),
      injuries: _injuries,
      redCards: _reds,
      yellowCards: _yellows,
      minutesByPlayer: Map.of(_minutes),
      shots: _shots,
      leagueGoalsByPlayer: Map.of(_leagueGoals),
      leagueAssistsByPlayer: Map.of(_leagueAssists),
    );
  }

  /// Plays the season described by [state] in one go.
  SeasonOutcome play(SeasonState state, {required int seed}) {
    final run = begin(state, seed: seed);
    while (!run.isOver) {
      completeDay(run, openDay(run));
    }
    return conclude(run);
  }

  List<ClubId> _leagueByLevel(SeasonState state, int level) {
    final rule = rules.leagues.firstWhere((l) => l.level == level);
    return state.members[LeagueId(rule.id)]!;
  }

  Map<Region, List<ClubId>> _fourthLeagues(SeasonState state) {
    return {
      for (final l in rules.leagues)
        if (l.level == 4) l.region!: state.members[LeagueId(l.id)]!,
    };
  }

  /// Promotion and relegation: the state of the next season.
  Result<SeasonState, PyramidError> nextSeason(
    SeasonState state,
    SeasonOutcome outcome, {
    required int seed,
    NameLists? names,
  }) {
    ClubId playoff(ClubId higher, ClubId lower) {
      // Two legs; the lower-league club hosts the first leg.
      final first = _engine.simulate(
        _tempTeam(state, lower),
        _tempTeam(state, higher),
        seed: SeededRandom(seed)
            .fork('po1:${higher.value}:${lower.value}')
            .seed,
      );
      final second = _engine.simulateKnockout(
        _tempTeam(state, higher),
        _tempTeam(state, lower),
        seed: SeededRandom(seed)
            .fork('po2:${higher.value}:${lower.value}')
            .seed,
      );
      final higherTotal = first.awayGoals + second.match.homeGoals;
      final lowerTotal = first.homeGoals + second.match.awayGoals;
      if (higherTotal > lowerTotal) return higher;
      if (lowerTotal > higherTotal) return lower;
      return second.winnerSide == 0 ? higher : lower;
    }

    final input = PyramidInput(
      standings: {
        for (final e in outcome.tables.entries)
          e.key: [for (final t in e.value) t.club],
      },
      clubRegion: {for (final c in state.clubs.values) c.id: c.region},
      pools: state.pools,
      cycleYear: state.cycleYear,
      secondTeams: {
        for (final c in state.clubs.values)
          if (c.parentClubId != null) c.id: c.parentClubId!,
      },
      seed: SeededRandom(seed).fork('pyramid').seed,
    );
    return PyramidTransition.run(
      rules,
      input,
      playoff,
    ).map((moved) => _buildNext(state, outcome, moved, seed, names));
  }

  MatchTeam _tempTeam(SeasonState state, ClubId club) {
    final squad = state.squads[club]!;
    final sheet = _auto.build(
      squad,
      formationId: forcedFormation,
      benchSize: rules.tactics.benchSize(_tierOf(state, club)),
    )!;
    return MatchTeam(
      clubId: club,
      name: state.clubs[club]!.name,
      squad: squad,
      sheet: sheet,
    );
  }

  SeasonState _buildNext(
    SeasonState state,
    SeasonOutcome outcome,
    PyramidResult moved,
    int seed,
    NameLists? names,
  ) {
    final rank = <ClubId, int>{};
    for (final entries in outcome.tables.values) {
      for (var i = 0; i < entries.length; i++) {
        rank[entries[i].club] = i + 1;
      }
    }
    final third = rules.leagues.firstWhere((l) => l.level == 3);
    final thirdTable = outcome.standing(LeagueId(third.id));
    var squads = state.squads;
    if (names != null) {
      final levels = {for (final l in rules.leagues) LeagueId(l.id): l.level};
      final tiers = <ClubId, int>{};
      for (final e in moved.leagues.entries) {
        for (final c in e.value) {
          tiers[c] = levels[e.key]!;
        }
      }
      final matchesPerPlayer = <ClubId, int>{};
      for (final e in state.members.entries) {
        matchesPerPlayer.addAll({
          for (final c in e.value) c: (e.value.length - 1) * 2,
        });
      }
      final share = <PlayerId, double>{};
      for (final entry in state.squads.entries) {
        final league = matchesPerPlayer[entry.key];
        for (final p in entry.value) {
          share[p.id] = league == null
              ? rules.development.poolMinutesShare
              : ((outcome.minutesByPlayer[p.id] ?? 0) / (90 * league)).limit(
                  0.0,
                  1.0,
                );
        }
      }
      squads = SquadTurnover(rules, names).apply(
        state.squads,
        newStartYear: state.startYear + 1,
        tiers: tiers,
        minutesShare: share,
        rng: SeededRandom(seed).fork('turnover'),
      );
    }
    return SeasonState(
      startYear: state.startYear + 1,
      members: moved.leagues,
      pools: moved.pools,
      clubs: state.clubs,
      squads: squads,
      cycleYear: (state.cycleYear + 1) % 3,
      pottQualifiers: outcome.pottQualifiers,
      thirdLeagueQualifiers: thirdTable,
      previousRank: rank,
    );
  }
}
