import 'dart:io';

import 'package:bolzplatz_app/game/loaded_world.dart';
import 'package:bolzplatz_app/game/ticker.dart';
import 'package:bolzplatz_app/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

// Engine 2, step 10d: the dense ticker (about 80 lines), symbols only for
// highlights, scorer and assist as own lines, stoppage time on the clock.

void main() {
  final loaded = LoadedWorld.fromTexts(
    File('../data/world_2026_27.json').readAsStringSync(),
    File('../rules/rules_2026_27.json').readAsStringSync(),
    File('../data/names_de.json').readAsStringSync(),
    File('../rules/calendar_rules.json').readAsStringSync(),
  );
  const s = AppStringsDe();
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

  List<TickerLine> linesOf(MatchSession session, MatchResult r) {
    final lines = <TickerLine>[];
    for (var i = 0; i < r.events.length; i++) {
      lines.addAll(
        tickerLinesOf(
          r.events[i],
          i,
          templates: s.tickerTemplates,
          playerName: name,
          home: 'Heim',
          away: 'Gast',
          lead: s.tickerLead,
          captainOf: session.captainOf,
        ),
      );
    }
    return lines;
  }

  test('every kind has texts, placeholders are all known', () {
    const known = {
      '{p}',
      '{q}',
      '{team}',
      '{opp}',
      '{home}',
      '{away}',
      '{score}',
      '{days}',
      '{n}',
    };
    final placeholder = RegExp(r'\{[a-z]+\}');
    for (final kind in TickerKind.values) {
      final texts = s.tickerTemplates(kind);
      expect(texts, isNotEmpty, reason: kind.name);
      for (final t in texts) {
        for (final m in placeholder.allMatches(t)) {
          expect(known, contains(m.group(0)), reason: '$kind: $t');
        }
      }
    }
    for (final a in rules.match.actions.list) {
      if (a.isShot) continue;
      expect(s.tickerLead(a.id), contains('{q}'), reason: a.id);
    }
  });

  test('about 80 lines per match, highlights with a symbol, goals in three '
      'lines', () {
    var total = 0;
    var games = 0;
    var symbols = 0;
    for (var i = 0; i < 30; i++) {
      final home = team(clubs[i % clubs.length]);
      final away = team(clubs[(i * 7 + 3) % clubs.length]);
      if (home.clubId == away.clubId) continue;
      final session = MatchSession(
        rules: rules,
        home: home,
        away: away,
        seed: 2000 + i,
      );
      final r = session.finish();
      final lines = linesOf(session, r);
      total += lines.length;
      games++;
      for (var k = 0; k < lines.length; k++) {
        final line = lines[k];
        expect(line.text, isNot(contains('{')), reason: line.text);
        if (line.symbol != null) symbols++;
        if (line.isGoal) {
          expect(lines[k + 1].kind, TickerKind.scorer);
        }
        if (line.kind == TickerKind.lostCross ||
            line.kind == TickerKind.counter ||
            line.kind == TickerKind.corner) {
          expect(line.symbol, isNull, reason: 'story line ${line.kind}');
        }
      }
      // Stoppage time: announced twice and shown on the clock.
      final added = r.events
          .where((e) => e.type == MatchEventType.addedTime)
          .toList();
      expect(added, hasLength(2));
      expect(r.length, greaterThanOrEqualTo(90));
    }
    final perGame = total / games;
    stdout.writeln(
      'TICKER-REPORT lines/game=${perGame.toStringAsFixed(1)} '
      'symbols/game=${(symbols / games).toStringAsFixed(1)}',
    );
    expect(perGame, inInclusiveRange(55, 120));
  });

  test('reading time: big moments wait longer, fast is shorter', () {
    const goal = TickerLine(
      minute: 10,
      kind: TickerKind.goal,
      side: 0,
      homeGoals: 1,
      awayGoals: 0,
      text: '',
    );
    const story = TickerLine(
      minute: 10,
      kind: TickerKind.lostDribble,
      side: 0,
      homeGoals: 0,
      awayGoals: 0,
      text: '',
    );
    expect(readingTime(goal, 0), greaterThan(readingTime(story, 0)));
    expect(readingTime(goal, 2), lessThan(readingTime(goal, 0)));
  });
}
