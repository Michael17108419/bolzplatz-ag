import '../model/attribute.dart';
import '../model/development.dart';
import '../model/ids.dart';
import '../model/player.dart';
import '../model/position.dart';
import '../model/special_ability.dart';
import '../rules/rules.dart';
import 'world.dart';

/// A readable distribution report of a world (Markdown). Shows per tier the
/// ages, strength, potential, special abilities and money, so the draft
/// numbers of the generator can be judged by eye.
class WorldReport {
  const WorldReport._();

  /// Position overall (draft): mean of the attributes that matter for the
  /// position, taken from the position profile of the rules.
  static double overall(Player p, Rules rules) {
    final Iterable<Attribute> keys;
    if (p.position.isGoalkeeper) {
      keys = Attribute.values.where((a) => a.isGoalkeeping);
    } else {
      final profile = rules.generator.positionProfiles[p.position]!;
      keys = profile.entries.where((e) => e.value > 0).map((e) => e.key);
    }
    var sum = 0.0;
    var n = 0;
    for (final a in keys) {
      sum += p.attributes[a];
      n++;
    }
    return n == 0 ? 0 : sum / n;
  }

  static String build(World world, Rules rules) {
    final tierOfClub = <ClubId, int>{};
    final leagueLevel = {for (final l in world.leagues) l.id: l.level};
    for (final c in world.clubs) {
      tierOfClub[c.id] = c.leagueId == null ? 5 : leagueLevel[c.leagueId]!;
    }
    final byTier = <int, List<Player>>{};
    for (final p in world.players) {
      (byTier[tierOfClub[p.clubId]!] ??= []).add(p);
    }
    final today = world.season.start;

    final out = StringBuffer()
      ..writeln('# Verteilungsbericht Startwelt ${world.season.label}')
      ..writeln()
      ..writeln(
        'Seed ${world.seed}, ${world.clubs.length} Vereine, '
        '${world.players.length} Spieler, ${world.coaches.length} Trainer. '
        'Alle Zahlen sind Entwürfe.',
      )
      ..writeln()
      ..writeln('## Je Ebene')
      ..writeln()
      ..writeln(
        '| Ebene | Spieler | Alter Ø | Alter min–max | Overall Ø | '
        'Overall P10–P90 | Potenzial Ø | dyn. Anteil Ø | Fähigkeiten Ø | '
        'mit Gold | Gehalt Ø | Restlaufzeit Ø |',
      )
      ..writeln('|---|---|---|---|---|---|---|---|---|---|---|---|');

    String f1(double v) => v.toStringAsFixed(1);
    double mean(Iterable<double> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
    double percentile(List<double> sorted, double q) =>
        sorted[((sorted.length - 1) * q).round()];

    for (final tier in byTier.keys.toList()..sort()) {
      final players = byTier[tier]!;
      final ages = players.map((p) => p.ageOn(today)).toList()..sort();
      final overalls = players.map((p) => overall(p, rules)).toList()..sort();
      final gold = players
          .where((p) => p.abilities.any((a) => a.tier == AbilityTier.gold))
          .length;
      out.writeln(
        '| ${tier == 5 ? 'Pool' : tier} | ${players.length} '
        '| ${f1(mean(ages.map((a) => a.toDouble())))} '
        '| ${ages.first}–${ages.last} '
        '| ${f1(mean(overalls))} '
        '| ${f1(percentile(overalls, 0.1))}–${f1(percentile(overalls, 0.9))} '
        '| ${f1(mean(players.map((p) => p.potentialCore)))} '
        '| ${f1(mean(players.map((p) => p.potentialDynamic)))} '
        '| ${f1(mean(players.map((p) => p.abilities.length.toDouble())))} '
        '| $gold '
        '| ${mean(players.map((p) => p.contract!.baseSalaryPerYear.toDouble())).round()} '
        '| ${f1(mean(players.map((p) => (p.contract!.end.year - today.year).toDouble())))} |',
      );
    }

    out
      ..writeln()
      ..writeln('## Altersverteilung (Anteil je Ebene in Prozent)')
      ..writeln()
      ..writeln('| Ebene | bis 20 | 21–24 | 25–29 | 30 und älter |')
      ..writeln('|---|---|---|---|---|');
    for (final tier in byTier.keys.toList()..sort()) {
      final players = byTier[tier]!;
      double share(bool Function(int) test) =>
          100 *
          players.where((p) => test(p.ageOn(today))).length /
          players.length;
      out.writeln(
        '| ${tier == 5 ? 'Pool' : tier} | ${f1(share((a) => a <= 20))} '
        '| ${f1(share((a) => a >= 21 && a <= 24))} '
        '| ${f1(share((a) => a >= 25 && a <= 29))} '
        '| ${f1(share((a) => a >= 30))} |',
      );
    }

    out
      ..writeln()
      ..writeln('## Positionen und Overall')
      ..writeln()
      ..writeln('| Position | Anzahl | Overall Ø | Alter Ø |')
      ..writeln('|---|---|---|---|');
    for (final pos in Position.values) {
      final list = world.players.where((p) => p.position == pos).toList();
      out.writeln(
        '| ${pos.id} | ${list.length} '
        '| ${f1(mean(list.map((p) => overall(p, rules))))} '
        '| ${f1(mean(list.map((p) => p.ageOn(today).toDouble())))} |',
      );
    }

    out
      ..writeln()
      ..writeln('## Entwicklungstypen')
      ..writeln();
    for (final d in DevelopmentType.values) {
      final share =
          100 *
          world.players.where((p) => p.developmentType == d).length /
          world.players.length;
      out.writeln('- ${d.id}: ${f1(share)} %');
    }

    out
      ..writeln()
      ..writeln('## Spezialfähigkeiten')
      ..writeln()
      ..writeln('| Fähigkeit | Bronze | Silber | Gold |')
      ..writeln('|---|---|---|---|');
    for (final type in SpecialAbilityType.values) {
      int count(AbilityTier t) => world.players
          .where((p) => p.abilities.any((a) => a.type == type && a.tier == t))
          .length;
      out.writeln(
        '| ${type.id} | ${count(AbilityTier.bronze)} '
        '| ${count(AbilityTier.silver)} | ${count(AbilityTier.gold)} |',
      );
    }

    final best = [...world.players]
      ..sort((a, b) => overall(b, rules).compareTo(overall(a, rules)));
    out
      ..writeln()
      ..writeln('## Die zehn besten Spieler')
      ..writeln()
      ..writeln('| Name | Position | Alter | Overall | Potenzial | Verein |')
      ..writeln('|---|---|---|---|---|---|');
    final clubName = {for (final c in world.clubs) c.id: c.name};
    for (final p in best.take(10)) {
      out.writeln(
        '| ${p.displayName} | ${p.position.id} | ${p.ageOn(today)} '
        '| ${f1(overall(p, rules))} | ${f1(p.potentialCore)} '
        '| ${clubName[p.clubId]} |',
      );
    }

    final overlap = <String>[];
    for (var t = 1; t < 5; t++) {
      final upper = byTier[t]!.map((p) => overall(p, rules)).toList()..sort();
      final lower = byTier[t + 1]!.map((p) => overall(p, rules)).toList()
        ..sort();
      final upperLow = percentile(upper, 0.1);
      final lowerHigh = percentile(lower, 0.9);
      overlap.add(
        'Ebene ${t == 5 ? 'Pool' : t} (P10 ${f1(upperLow)}) gegen '
        'Ebene ${t + 1 == 5 ? 'Pool' : t + 1} (P90 ${f1(lowerHigh)}): '
        '${upperLow < lowerHigh ? 'Bänder überlappen' : 'Bänder überlappen nicht'}',
      );
    }
    out
      ..writeln()
      ..writeln('## Überlappung der Ebenen')
      ..writeln();
    for (final line in overlap) {
      out.writeln('- $line');
    }
    return out.toString();
  }
}
