import 'dart:math' as math;

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
import 'cup.dart';
import 'league_table.dart';
import 'schedule.dart';
import 'season_state.dart';

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

/// Plays a whole season of all leagues and both cups without a user
/// interface. Everything depends only on the state, the rules and the seed.
class SeasonRunner {
  SeasonRunner(this.rules, {this.forcedFormation})
    : _engine = MatchEngine(rules),
      _auto = AutoManager(rules);

  final Rules rules;

  /// If set, every club plays this formation (for tests and analysis).
  final String? forcedFormation;
  final MatchEngine _engine;
  final AutoManager _auto;

  // Per-season working data.
  late Map<ClubId, double> _form;
  late Map<PlayerId, int> _outUntil;
  late Map<PlayerId, int> _yellowCount;
  late Map<ClubId, TeamSheet> _sheets;
  late Map<ClubId, String> _sheetKey;
  late SeasonState _state;
  late int _tick;
  int _injuries = 0;
  int _reds = 0;
  int _yellows = 0;
  int _shots = 0;
  final Map<PlayerId, int> _goals = {};
  final Map<PlayerId, int> _leagueGoals = {};
  final Map<PlayerId, int> _leagueAssists = {};
  final Map<PlayerId, int> _minutes = {};
  int _seed = 0;

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

  MatchTeam _team(ClubId club) {
    final squad = _state.squads[club]!;
    final out = <PlayerId>{
      for (final p in squad)
        if ((_outUntil[p.id] ?? -1) >= _tick) p.id,
    };
    final key = (out.toList()..sort((a, b) => a.value.compareTo(b.value)))
        .map((e) => e.value)
        .join(',');
    var sheet = _sheets[club];
    if (sheet == null || _sheetKey[club] != key) {
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
  }) {
    for (final e in r.events) {
      if (e.type == MatchEventType.shot && e.isGoal && e.player != null) {
        _goals[e.player!] = (_goals[e.player!] ?? 0) + 1;
        if (countForm) {
          _leagueGoals[e.player!] = (_leagueGoals[e.player!] ?? 0) + 1;
          final a = e.otherPlayer;
          if (a != null) _leagueAssists[a] = (_leagueAssists[a] ?? 0) + 1;
        }
      }
      if (e.type == MatchEventType.secondYellow ||
          e.type == MatchEventType.redCard) {
        _outUntil[e.player!] = _tick + 1;
      }
      if (e.type == MatchEventType.yellowCard ||
          e.type == MatchEventType.secondYellow) {
        final n = (_yellowCount[e.player!] ?? 0) + 1;
        _yellowCount[e.player!] = n;
        if (n % rules.season.suspensionYellowCards == 0) {
          _outUntil[e.player!] = math.max(
            _outUntil[e.player!] ?? -1,
            _tick + 1,
          );
        }
      }
    }
    for (final inj in r.injuries) {
      final ticks = (inj.days / rules.season.injuryDaysPerMatchday).ceil();
      _outUntil[inj.player] = _tick + ticks;
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

  /// Plays the season described by [state].
  SeasonOutcome play(SeasonState state, {required int seed}) {
    _state = state;
    _seed = seed;
    _form = {};
    _outUntil = {};
    _yellowCount = {};
    _sheets = {};
    _sheetKey = {};
    _tick = 0;
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
    var maxDays = 0;
    for (final e in state.members.entries) {
      schedules[e.key] = leagueSchedule(e.value, e.key, seed);
      tables[e.key] = LeagueTable(e.value);
      maxDays = math.max(maxDays, schedules[e.key]!.length);
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

    var matches = 0;
    var goals = 0;
    var hw = 0;
    var dr = 0;
    var aw = 0;
    ClubId playTie(ClubId home, ClubId away, String label) {
      final k = _engine.simulateKnockout(
        _team(home),
        _team(away),
        seed: _matchSeed(label),
      );
      _afterMatch(home, away, k.match, countForm: false);
      return k.winnerSide == 0 ? home : away;
    }

    var bolzRound = 0;
    var pottRound = 0;
    for (var day = 1; day <= maxDays; day++) {
      _tick = day;
      for (final e in state.members.entries) {
        final schedule = schedules[e.key]!;
        if (day > schedule.length) continue;
        for (final f in schedule[day - 1]) {
          final r = _engine.simulate(
            _team(f.home),
            _team(f.away),
            seed: _matchSeed('l:${e.key.value}:$day:${f.home.value}'),
          );
          _afterMatch(f.home, f.away, r, countForm: true);
          tables[e.key]!.record(f.home, f.away, r.homeGoals, r.awayGoals);
          matches++;
          goals += r.homeGoals + r.awayGoals;
          if (r.homeGoals > r.awayGoals) {
            hw++;
          } else if (r.homeGoals < r.awayGoals) {
            aw++;
          } else {
            dr++;
          }
        }
      }
      if (bolzRound < cups.bolzplatzAfterMatchday.length &&
          day == cups.bolzplatzAfterMatchday[bolzRound]) {
        final round = bolzRound;
        bolzplatz.playNextRound(
          (h, a) => playTie(h, a, 'bp:$round:${h.value}'),
        );
        bolzRound++;
      }
      if (pottRound < cups.pottAfterMatchday.length &&
          day == cups.pottAfterMatchday[pottRound]) {
        final round = pottRound;
        for (final region in Region.values) {
          final cup = pott[region]!;
          if (cup.isFinished) continue;
          cup.playNextRound(
            (h, a) => playTie(h, a, 'pott:${region.id}:$round:${h.value}'),
          );
        }
        pottRound++;
      }
    }
    // Finish cups that did not finish within the planned rounds.
    while (!bolzplatz.isFinished) {
      final round = bolzRound++;
      bolzplatz.playNextRound((h, a) => playTie(h, a, 'bp:$round:${h.value}'));
    }
    for (final region in Region.values) {
      final cup = pott[region]!;
      while (!cup.isFinished) {
        final round = pottRound;
        cup.playNextRound(
          (h, a) => playTie(h, a, 'pott:${region.id}:$round:${h.value}'),
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
