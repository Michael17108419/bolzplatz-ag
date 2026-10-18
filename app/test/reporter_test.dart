import 'dart:io';

import 'package:bolzplatz_app/game/loaded_world.dart';
import 'package:bolzplatz_app/game/reporter.dart';
import 'package:bolzplatz_app/game/ticker.dart';
import 'package:bolzplatz_app/l10n/reporter_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

// Step 10d2: the radio reporter. Scenes from the protocol of the engine,
// own and opposing voice, memory, wit, quiet phases, local colour; about a
// thousand texts.

void main() {
  final loaded = LoadedWorld.fromTexts(
    File('../data/world_2026_27.json').readAsStringSync(),
    File('../rules/rules_2026_27.json').readAsStringSync(),
    File('../data/names_de.json').readAsStringSync(),
    File('../rules/calendar_rules.json').readAsStringSync(),
  );
  const strings = ReporterStringsDe();
  final pool = RefereePool.fromJson(
    File('../data/referees_de.json').readAsStringSync(),
  );
  final rules = loaded.rules;
  final top = loaded.world.leagues.firstWhere((l) => l.level == 1).id;
  final clubs = [
    for (final c in loaded.world.clubs)
      if (c.leagueId == top) c,
  ];
  MatchTeam team(Club c) {
    final squad = [
      for (final p in loaded.world.players)
        if (p.clubId == c.id) p,
    ];
    return MatchTeam(
      clubId: c.id,
      name: c.name,
      squad: squad,
      sheet: AutoManager(rules).build(squad)!,
    );
  }

  String name(PlayerId? id) =>
      id == null ? '' : (loaded.player(id)?.lastName ?? '?');

  Reporter reporter(MatchSession session, {int ownSide = 0, int tier = 1}) =>
      Reporter(
        strings: strings,
        ownSide: ownSide,
        home: 'Heim',
        away: 'Gast',
        playerName: name,
        player: loaded.player,
        captainOf: session.captainOf,
        tier: tier,
        referee: session.referee,
      );

  (MatchSession, MatchResult) play(int i) {
    final home = team(clubs[i % clubs.length]);
    final away = team(clubs[(i * 7 + 3) % clubs.length]);
    final session = MatchSession(
      rules: rules,
      home: home,
      away: away,
      seed: 3000 + i,
      referee: pool.referees[i % pool.referees.length],
    );
    return (session, session.finish());
  }

  test('about a thousand texts, every key the reporter asks has texts, '
      'placeholders are known', () {
    const sides = ['own', 'opp'];
    const actions = [
      'short_pass',
      'through_ball',
      'long_ball',
      'cross',
      'dribble',
    ];
    final needed = <String>[
      for (var l = 0; l < 5; l++) 'lane.$l',
      'kickoff',
      'local.kickoff',
      for (final a in actions) ...['step.$a.won', 'step.$a.lost'],
      for (final w in sides) ...[
        'counter.$w',
        'open.counter.$w',
        'open.$w',
        'open.$w.e2',
        'open.$w.e3',
        'pen.award.$w',
        'pen.goal.$w',
        'pen.save.$w',
        'pen.miss.$w',
        'corner.$w',
        'mem.corners.$w',
        'free.$w',
        'half.$w',
        'goal.$w.e1',
        'goal.$w.e2',
        'goal.$w.e3',
        for (final c in ['equal', 'lead', 'cut', 'rout', 'extend']) 'ctx.$c.$w',
        'save.$w',
        'save.$w.big',
        'mem.keeper.$w',
        'block.$w',
        'miss.$w',
        'miss.$w.big',
        'mem.pressure.$w',
        for (final a in ['cross', 'through_ball', 'dribble', 'long_ball'])
          'lost.$a.$w',
        'yellow.$w',
        'second.$w',
        'red.$w',
        'mem.cards.$w',
        'injury.$w',
        'sub.$w',
        'captain.$w',
        'tactic.$w',
        for (final how in [
          'keeper_eight_seconds',
          'goal_kick_countdown',
          'throw_in_countdown',
        ])
          'waste.$how.$w',
      ],
      'pen.up',
      'free.up',
      'shot.header.set',
      'shot.close_range',
      'shot.long_shot',
      'shot.header',
      'scorer',
      'assist',
      'mem.brace',
      'mem.hattrick',
      'mem.miss2',
      'mem.miss3',
      'mem.loses',
      for (final a in ['dribble', 'cross', 'through_ball']) 'mem.again.$a',
      for (final t in [
        'header_monster',
        'long_shooter',
        'goal_poacher',
        'media_hunger',
        'egoism',
        'party',
        'consistency',
      ])
        'wit.goal.$t',
      for (final t in ['egoism', 'party', 'consistency', 'pressure'])
        'wit.miss.$t',
      'wit.card.temper',
      'wit.card.aggression',
      'wit.step.dribbler',
      for (final s in ['half', 'lead', 'behind', 'level']) 'added.$s',
      for (final s in ['lead', 'behind', 'level']) ...[
        'break.$s',
        'calm.$s',
        'calm.$s.late',
      ],
      'extra',
      for (final k in [
        'win',
        'win.big',
        'loss',
        'loss.big',
        'draw',
        'draw.goalless',
      ])
        'full.$k',
      'local.fulltime',
      'local.calm',
      for (final k in ['calm', 'fire', 'praise'])
        for (final h in ['good', 'flat', 'bad'])
          for (final w in sides) 'talk.$k.$h.$w',
      for (final k in ['deep', 'chase', 'hold', 'open', 'ten', 'panic'])
        for (final w in sides) 'coach.$k.$w',
    ];
    for (final key in needed) {
      expect(strings.texts(key), isNotEmpty, reason: key);
    }
    const known = {
      '{p}',
      '{o}',
      '{q}',
      '{team}',
      '{opp}',
      '{home}',
      '{away}',
      '{score}',
      '{ours}',
      '{where}',
      '{n}',
      '{days}',
      '{k}',
      '{ref}',
      '{crowd}',
      '{stadium}',
      '{derby}',
      '{km}',
    };
    final placeholder = RegExp(r'\{[a-z]+\}');
    var total = 0;
    for (final key in strings.keys) {
      final texts = strings.texts(key);
      expect(texts, isNotEmpty, reason: key);
      expect(texts.toSet(), hasLength(texts.length), reason: 'twice: $key');
      for (final t in texts) {
        total++;
        expect(t.trim(), isNotEmpty, reason: key);
        for (final m in placeholder.allMatches(t)) {
          expect(known, contains(m.group(0)), reason: '$key: $t');
        }
        // Quiet lines know no players.
        if (key.startsWith('calm') || key.startsWith('local.')) {
          expect(t, isNot(contains('{p}')), reason: key);
        }
      }
    }
    stdout.writeln('REPORTER-REPORT texts=$total keys=${strings.keys.length}');
    expect(total, greaterThanOrEqualTo(950));
  });

  test('a match told as scenes: no open placeholders, the goal after the '
      'build-up, the board keeps the old score until the goal', () {
    var lines = 0;
    var scenes = 0;
    var colour = 0;
    var games = 0;
    for (var i = 0; i < 30; i++) {
      if (i % clubs.length == (i * 7 + 3) % clubs.length) continue;
      final (session, r) = play(i);
      games++;
      final rep = reporter(session, ownSide: i % 2);
      for (var k = 0; k < r.events.length; k++) {
        final e = r.events[k];
        final out = rep.linesOf(e, k);
        lines += out.length;
        for (final line in out) {
          expect(line.text, isNot(contains('{')), reason: line.text);
          expect(line.text.trim(), isNotEmpty);
          if (line.kind == TickerKind.colour) colour++;
        }
        if (out.any((l) => l.kind == TickerKind.play)) scenes++;
        if (e.isGoal && e.type == MatchEventType.shot) {
          final g = out.indexWhere((l) => l.isGoal);
          expect(g, greaterThanOrEqualTo(0));
          expect(out[g + 1].kind, TickerKind.scorer);
          // Before the goal line the board still shows the old score.
          for (var j = 0; j < g; j++) {
            expect(
              out[j].homeGoals + out[j].awayGoals,
              e.homeGoals + e.awayGoals - 1,
            );
          }
          expect(out[g].homeGoals, e.homeGoals);
        }
      }
    }
    stdout.writeln(
      'REPORTER-REPORT lines/game=${(lines / games).toStringAsFixed(1)} '
      'scenes/game=${(scenes / games).toStringAsFixed(1)} '
      'colour/game=${(colour / games).toStringAsFixed(1)}',
    );
    expect(lines / games, inInclusiveRange(60, 220));
    expect(scenes, greaterThan(games * 3));
    expect(colour, greaterThan(games));
  });

  test('the same match reads the same, read in again', () {
    final (session, r) = play(4);
    List<String> tell() {
      final rep = reporter(session);
      return [
        for (var k = 0; k < r.events.length; k++)
          for (final l in rep.linesOf(r.events[k], k)) l.text,
      ];
    }

    expect(tell(), tell());
  });

  test('own goals are cheered, goals against suffered', () {
    final (session, r) = play(7);
    for (final own in [0, 1]) {
      final rep = reporter(session, ownSide: own);
      for (var k = 0; k < r.events.length; k++) {
        final e = r.events[k];
        final out = rep.linesOf(e, k);
        if (!(e.isGoal && e.type == MatchEventType.shot)) continue;
        final goal = out.firstWhere((l) => l.isGoal).text;
        final w = e.side == own ? 'own' : 'opp';
        final pool = <String>{
          for (final key in strings.keys)
            if (key.startsWith('goal.$w') || key == 'pen.goal.$w')
              ...strings.texts(key),
        };
        expect(
          pool.any((t) => goal == t.replaceAll('{team}', e.side == 0 ? 'Heim' : 'Gast')),
          isTrue,
          reason: goal,
        );
      }
    }
  });

  test('quiet phases get a line, in the lower leagues with local '
      'colour', () {
    final (session, r) = play(2);
    final rep = reporter(session, tier: 4);
    final kick = rep.linesOf(r.events.first, 0);
    expect(kick.map((l) => l.kind), contains(TickerKind.colour));
    // The referee is named at kick-off.
    expect(
      kick.any((l) => l.text.contains(session.referee!.lastName)),
      isTrue,
    );
    expect(rep.quiet(3, 3, '3'), isNull);
    final calm = rep.quiet(9, 9, '9');
    expect(calm, isNotNull);
    expect(calm!.kind, TickerKind.calm);
    expect(calm.text, isNot(contains('{')));
    // Right after a line no new one.
    expect(rep.quiet(10, 10, '10'), isNull);
  });
}
