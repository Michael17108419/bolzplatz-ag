@Timeout(Duration(minutes: 10))
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

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

void main() {
  test('balance over several seasons', () {
    final rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    final world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    final names = NameLists.fromJson(
      File('../../data/names_de.json').readAsStringSync(),
    );
    const seasons = 8;
    var state = SeasonState.fromWorld(world);
    final runner = SeasonRunner(rules);
    final tierOf = {for (final l in rules.leagues) LeagueId(l.id): l.level};

    final goals = <int, int>{};
    final games = <int, int>{};
    final zero = <int, int>{};
    var hw = 0;
    var dr = 0;
    var aw = 0;
    final topPpg = <int, List<double>>{};
    final botPpg = <int, List<double>>{};
    final corrs = <int, List<double>>{};
    var champStrongest = 0;
    var champTop3 = 0;
    var leagueCount = 0;
    final ageSum = <int, double>{};
    final ageN = <int, int>{};
    final strengthByTier = <int, List<double>>{};

    for (var year = 0; year < seasons; year++) {
      final outcome = runner.play(state, seed: 500 + year);
      for (final e in outcome.tables.entries) {
        final tier = tierOf[e.key]!;
        final table = e.value;
        final n = table.length;
        final played = table.first.played;
        for (final t in table) {
          goals[tier] = (goals[tier] ?? 0) + t.goalsFor;
          games[tier] = (games[tier] ?? 0) + t.played;
        }
        final s = [
          for (final t in table) _strength(state.squads[t.club]!, rules),
        ];
        final pts = [for (final t in table) t.points.toDouble()];
        (corrs[tier] ??= []).add(_corr(s, pts));
        final top = table.take(3).map((t) => t.points).fold(0, (a, b) => a + b);
        final bot = table
            .skip(n - 3)
            .map((t) => t.points)
            .fold(0, (a, b) => a + b);
        (topPpg[tier] ??= []).add(top / 3 / played);
        (botPpg[tier] ??= []).add(bot / 3 / played);
        var best = 0;
        for (var i = 1; i < n; i++) {
          if (s[i] > s[best]) best = i;
        }
        final champ = table.first.club;
        leagueCount++;
        if (table[0].club == table.firstWhere((t) => true).club &&
            table.indexWhere((t) => t.club == table[best].club) == 0) {
          champStrongest++;
        }
        if (table.indexWhere((t) => t.club == table[best].club) < 3) {
          champTop3++;
        }
        expect(champ, isNotNull);
      }
      hw += outcome.homeWins;
      dr += outcome.draws;
      aw += outcome.awayWins;
      for (final squad in state.squads.values) {
        for (final p in squad) {
          final tier =
              tierOf[state.members.entries
                  .firstWhere(
                    (m) => m.value.contains(p.clubId),
                    orElse: () => state.members.entries.first,
                  )
                  .key] ??
              1;
          ageSum[tier] =
              (ageSum[tier] ?? 0) + p.ageOn(GameDate(state.startYear, 7, 1));
          ageN[tier] = (ageN[tier] ?? 0) + 1;
        }
      }
      for (final e in state.members.entries) {
        final t = tierOf[e.key]!;
        for (final c in e.value) {
          (strengthByTier[t] ??= []).add(_strength(state.squads[c]!, rules));
        }
      }
      final next = runner.nextSeason(
        state,
        outcome,
        seed: 900 + year,
        names: names,
      );
      expect(next.errorOrNull, isNull);
      state = next.valueOrNull!;
    }
    String f(double v) => v.toStringAsFixed(2);
    double mean(List<double> l) => l.fold(0.0, (a, b) => a + b) / l.length;
    final total = hw + dr + aw;
    stdout.writeln(
      'BALANCE-REPORT H/D/A=${f(hw / total)}/${f(dr / total)}/${f(aw / total)}'
      ' strongestChampion=${f(champStrongest / leagueCount)}'
      ' strongestTop3=${f(champTop3 / leagueCount)}',
    );
    for (final tier in goals.keys.toList()..sort()) {
      stdout.writeln(
        'BALANCE-REPORT tier$tier goals/team/game=${f(goals[tier]! / games[tier]!)}'
        ' topPpg=${f(mean(topPpg[tier]!))} botPpg=${f(mean(botPpg[tier]!))}'
        ' corr=${f(mean(corrs[tier]!))}'
        ' meanAge=${f(ageSum[tier]! / ageN[tier]!)}'
        ' meanStrength=${f(mean(strengthByTier[tier]!))}',
      );
    }
  });
}
