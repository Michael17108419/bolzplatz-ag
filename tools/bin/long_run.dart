import 'dart:io';
import 'dart:math' as math;

import 'package:game_core/game_core.dart';

/// Plays many seasons in a row and writes `data/langzeit_report.md`.
/// Run from the `tools` folder:
///
///     dart run bin/long_run.dart [seasons]
class _Acc {
  int seasons = 0;
  int games = 0;
  int goals = 0;
  int draws = 0;
  double age = 0;
  double squad = 0;
  double strength = 0;
  double allOverall = 0;
  double spread = 0;
  double corr = 0;
  double top = 0;
  double bottom = 0;
  int strongestChampion = 0;
  int strongestTop3 = 0;
  double old = 0;
  double young = 0;
  double potentialGap = 0;
}

double _strength(List<Player> squad, Rules rules) {
  final v = [for (final p in squad) WorldReport.overall(p, rules)]
    ..sort((a, b) => b.compareTo(a));
  return v.take(14).fold(0.0, (a, b) => a + b) / 14;
}

double _corr(List<double> x, List<double> y) {
  final n = x.length;
  final mx = x.fold(0.0, (a, b) => a + b) / n;
  final my = y.fold(0.0, (a, b) => a + b) / n;
  var sxy = 0.0;
  var sxx = 0.0;
  var syy = 0.0;
  for (var i = 0; i < n; i++) {
    sxy += (x[i] - mx) * (y[i] - my);
    sxx += (x[i] - mx) * (x[i] - mx);
    syy += (y[i] - my) * (y[i] - my);
  }
  return sxy / math.sqrt(sxx * syy);
}

String _f(double v, [int d = 2]) => v.toStringAsFixed(d);

void main(List<String> args) {
  const root = '..';
  final seasons = args.isEmpty ? 50 : int.parse(args.first);
  final rules = Rules.parse(
    File('$root/rules/rules_2026_27.json').readAsStringSync(),
  ).valueOrNull!;
  final world = WorldJson.decode(
    File('$root/data/world_2026_27.json').readAsStringSync(),
  );
  final names = NameLists.fromJson(
    File('$root/data/names_de.json').readAsStringSync(),
  );
  final tierOf = {for (final l in rules.leagues) LeagueId(l.id): l.level};
  final runner = SeasonRunner(rules);
  var state = SeasonState.fromWorld(world);
  final watch = Stopwatch()..start();

  // [tier][decade]
  final acc = <int, Map<int, _Acc>>{};
  _Acc at(int tier, int decade) =>
      (acc[tier] ??= {})[decade] ??= _Acc();

  var matches = 0;
  var goalsAll = 0;
  var yellow = 0;
  var red = 0;
  var injuries = 0;
  var hw = 0;
  var dr = 0;
  var aw = 0;
  final titles = <ClubId, int>{};
  final cupWinnerTier = <int, int>{};
  final pottWinnerTier = <int, int>{};
  final everInTop = <ClubId>{};
  var retiredTotal = 0;
  var topScorerGoals = 0.0;
  final poolStrength = <double>[];
  final seasonLines = StringBuffer();

  for (var year = 0; year < seasons; year++) {
    final decade = year ~/ 10;
    final tiers = <ClubId, int>{};
    for (final e in state.members.entries) {
      for (final c in e.value) {
        tiers[c] = tierOf[e.key]!;
      }
    }
    final outcome = runner.play(state, seed: 1000 + year);
    matches += outcome.matchesPlayed;
    goalsAll += outcome.goalsScored;
    yellow += outcome.yellowCards;
    red += outcome.redCards;
    injuries += outcome.injuries;
    hw += outcome.homeWins;
    dr += outcome.draws;
    aw += outcome.awayWins;
    var best = 0;
    for (final g in outcome.goalsByPlayer.values) {
      if (g > best) best = g;
    }
    topScorerGoals += best;
    cupWinnerTier[tiers[outcome.bolzplatz.winner!] ?? 5] =
        (cupWinnerTier[tiers[outcome.bolzplatz.winner!] ?? 5] ?? 0) + 1;
    for (final w in outcome.pottWinners.values) {
      pottWinnerTier[tiers[w] ?? 5] = (pottWinnerTier[tiers[w] ?? 5] ?? 0) + 1;
    }

    for (final e in outcome.tables.entries) {
      final tier = tierOf[e.key]!;
      final a = at(tier, decade);
      final table = e.value;
      final n = table.length;
      final played = table.first.played;
      a.seasons++;
      final s = [
        for (final t in table) _strength(state.squads[t.club]!, rules),
      ];
      final pts = [for (final t in table) t.points.toDouble()];
      for (final t in table) {
        a.games += t.played;
        a.goals += t.goalsFor;
        a.draws += t.drawn;
      }
      a.corr += _corr(s, pts);
      a.top += table.take(3).fold(0, (x, t) => x + t.points) / 3 / played;
      a.bottom +=
          table.skip(n - 3).fold(0, (x, t) => x + t.points) / 3 / played;
      final mean = s.fold(0.0, (x, y) => x + y) / n;
      a.strength += mean;
      a.spread += math.sqrt(
        s.fold(0.0, (x, y) => x + (y - mean) * (y - mean)) / n,
      );
      var bi = 0;
      for (var i = 1; i < n; i++) {
        if (s[i] > s[bi]) bi = i;
      }
      final pos = table.indexWhere((t) => t.club == table[bi].club);
      if (pos == 0) a.strongestChampion++;
      if (pos < 3) a.strongestTop3++;
      if (tier == 1) {
        titles[table.first.club] = (titles[table.first.club] ?? 0) + 1;
        everInTop.addAll(e.value.map((t) => t.club));
      }
      var count = 0;
      var ages = 0.0;
      var all = 0.0;
      var old = 0;
      var young = 0;
      var gap = 0.0;
      final on = GameDate(state.startYear, 7, 1);
      for (final t in table) {
        for (final p in state.squads[t.club]!) {
          count++;
          final age = p.ageOn(on);
          ages += age;
          all += WorldReport.overall(p, rules);
          if (age >= 33) old++;
          if (age <= 20) young++;
          gap += p.potentialCore + p.potentialDynamic -
              WorldReport.overall(p, rules);
        }
      }
      a.age += ages / count;
      a.squad += count / n;
      a.allOverall += all / count;
      a.old += old / count;
      a.young += young / count;
      a.potentialGap += gap / count;
    }
    final poolClubs = [for (final l in state.pools.values) ...l];
    if (poolClubs.isNotEmpty) {
      poolStrength.add(
        poolClubs
                .map((c) => _strength(state.squads[c]!, rules))
                .fold(0.0, (x, y) => x + y) /
            poolClubs.length,
      );
    }
    final next = runner.nextSeason(state, outcome, seed: 5000 + year, names: names);
    if (next.valueOrNull == null) {
      stderr.writeln('Season ${state.startYear} failed: ${next.errorOrNull}');
      exit(1);
    }
    final before = {
      for (final sq in state.squads.values)
        for (final p in sq) p.id,
    };
    final after = {
      for (final sq in next.valueOrNull!.squads.values)
        for (final p in sq) p.id,
    };
    retiredTotal += before.difference(after).length;
    seasonLines.writeln(
      '| ${state.startYear}/${(state.startYear + 1) % 100} | '
      '${_f(outcome.goalsScored / outcome.matchesPlayed)} | '
      '${outcome.standing(LeagueId(rules.leagues.firstWhere((l) => l.level == 1).id)).first.value} | '
      '${outcome.bolzplatz.winner!.value} |',
    );
    state = next.valueOrNull!;
  }

  final b = StringBuffer()
    ..writeln('# Langzeitlauf: $seasons Saisons')
    ..writeln()
    ..writeln(
      'Startwelt 2026/27, Entwicklung und Rücktritte an, Saisonseeds fest. '
      'Rechenzeit ${watch.elapsed.inSeconds} s.',
    )
    ..writeln()
    ..writeln('## Gesamt')
    ..writeln()
    ..writeln('| Kennzahl | Wert |')
    ..writeln('| --- | --- |')
    ..writeln('| Spiele pro Saison | ${matches ~/ seasons} |')
    ..writeln('| Tore pro Spiel | ${_f(goalsAll / matches)} |')
    ..writeln(
      '| Heim/Remis/Auswärts | ${_f(hw / matches)}/${_f(dr / matches)}/${_f(aw / matches)} |',
    )
    ..writeln('| Gelbe Karten pro Spiel | ${_f(yellow / matches)} |')
    ..writeln('| Rote Karten pro Spiel | ${_f(red / matches, 3)} |')
    ..writeln('| Verletzungen pro Spiel | ${_f(injuries / matches)} |')
    ..writeln(
      '| Torschützenkönig, Tore im Schnitt (alle Ligen) | ${_f(topScorerGoals / seasons, 1)} |',
    )
    ..writeln(
      '| Rücktritte und Neuzugänge pro Saison | ${_f(retiredTotal / seasons, 0)} |',
    )
    ..writeln(
      '| Stärke der Pool-Klubs (Top-14-Schnitt) | ${_f(poolStrength.fold(0.0, (x, y) => x + y) / poolStrength.length, 1)} |',
    )
    ..writeln(
      '| Verschiedene Meister in Liga 1 | ${titles.length} (Rekordmeister ${titles.values.reduce(math.max)} Titel) |',
    )
    ..writeln('| Klubs, die je in Liga 1 spielten | ${everInTop.length} |')
    ..writeln(
      '| Bolzplatzpokal-Sieger nach Liga | ${(cupWinnerTier.keys.toList()..sort()).map((k) => 'L$k: ${cupWinnerTier[k]}').join(', ')} |',
    )
    ..writeln(
      '| Pott-Sieger nach Liga | ${(pottWinnerTier.keys.toList()..sort()).map((k) => 'L$k: ${pottWinnerTier[k]}').join(', ')} |',
    )
    ..writeln();

  for (final tier in acc.keys.toList()..sort()) {
    b
      ..writeln('## Liga-Ebene $tier')
      ..writeln()
      ..writeln(
        '| Saisons | Tore/Spiel | Remis | Alter | Kader | Stärke Top14 | '
        'Stärke alle | Streuung Klubs | Korrelation | Top-3 Pkt/Sp | '
        'Letzte 3 Pkt/Sp | Stärkster wird Meister | Stärkster Top 3 | '
        'Anteil ab 33 | Anteil bis 20 | Potenzial-Abstand |',
      )
      ..writeln('|${' --- |' * 16}');
    void row(String label, Iterable<_Acc> list) {
      final n = list.fold(0, (x, a) => x + a.seasons);
      double avg(double Function(_Acc) f) =>
          list.fold(0.0, (x, a) => x + f(a)) / n;
      final games = list.fold(0, (x, a) => x + a.games);
      final goals = list.fold(0, (x, a) => x + a.goals);
      final draws = list.fold(0, (x, a) => x + a.draws);
      final sc = list.fold(0, (x, a) => x + a.strongestChampion);
      final s3 = list.fold(0, (x, a) => x + a.strongestTop3);
      b.writeln(
        '| $label | ${_f(2 * goals / games)} | ${_f(draws / games)} | '
        '${_f(avg((a) => a.age), 1)} | ${_f(avg((a) => a.squad), 1)} | '
        '${_f(avg((a) => a.strength), 1)} | ${_f(avg((a) => a.allOverall), 1)} | '
        '${_f(avg((a) => a.spread), 1)} | ${_f(avg((a) => a.corr))} | '
        '${_f(avg((a) => a.top))} | ${_f(avg((a) => a.bottom))} | '
        '${_f(sc / n, 2)} | ${_f(s3 / n, 2)} | '
        '${_f(avg((a) => a.old))} | ${_f(avg((a) => a.young))} | '
        '${_f(avg((a) => a.potentialGap), 1)} |',
      );
    }

    final decades = acc[tier]!.keys.toList()..sort();
    for (final d in decades) {
      row('${d * 10 + 1}–${d * 10 + 10}', [acc[tier]![d]!]);
    }
    row('alle', acc[tier]!.values);
    b.writeln();
  }

  b
    ..writeln('## Liga 1: Tore pro Spiel, Meister, Pokalsieger je Saison')
    ..writeln()
    ..writeln('| Saison | Tore/Spiel | Meister (Klub-ID) | Pokalsieger (Klub-ID) |')
    ..writeln('| --- | --- | --- | --- |')
    ..write(seasonLines);

  final out = File('$root/data/langzeit_report.md');
  out.writeAsStringSync(b.toString());
  stdout.writeln('Wrote ${out.path} in ${watch.elapsed.inSeconds} s');
}
