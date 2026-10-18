import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10g4: shouts from the touchline.

late Rules rules;
late List<MatchTeam> tier1;

MatchTeam _coached(MatchTeam t, double charisma) => MatchTeam(
  clubId: t.clubId,
  name: t.name,
  squad: t.squad,
  sheet: t.sheet,
  coach: CoachProfile(charisma: charisma),
  autoManage: false,
);

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    final world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    final top = world.leagues.firstWhere((l) => l.level == 1).id;
    tier1 = [
      for (final club in world.clubs)
        if (club.leagueId == top)
          () {
            final squad = [
              for (final p in world.players)
                if (p.clubId == club.id) p,
            ];
            return MatchTeam(
              clubId: club.id,
              name: club.name,
              squad: squad,
              sheet: AutoManager(rules).build(squad)!,
            );
          }(),
    ];
  });

  test('three shouts per half, not in the break; they last a few minutes '
      'and replay the same', () {
    MatchSession make() => MatchSession(
      rules: rules,
      home: _coached(tier1[0], 80),
      away: tier1[1],
      seed: 31,
    );
    final s = make();
    expect(s.canShout(0), isFalse);
    s.advanceTo(10);
    expect(s.shoutOut(0, Shout.push), isNotNull);
    expect(s.activeShout(0), Shout.push);
    s.advanceTo(12);
    expect(s.shoutOut(0, Shout.wide), isNotNull);
    expect(s.shoutOut(0, Shout.shoot), isNotNull);
    expect(s.shoutsLeft(0), 0);
    expect(s.shoutOut(0, Shout.calm), isNull);
    s.advanceTo(30);
    expect(s.activeShout(0), isNull);
    while (!(s.inBreak && s.minute > 0)) {
      s.advanceTo(s.minute + 1);
    }
    expect(s.canShout(0), isFalse);
    s.advanceTo(s.minute + 1);
    expect(s.shoutsLeft(0), 3);
    expect(s.shoutOut(0, Shout.tight), isNotNull);
    final json = [for (final a in s.actions) a.toJson()];
    final r = s.finish();
    final again = make()
      ..replay([for (final j in json) SessionAction.fromJson(j)]);
    final r2 = again.finish();
    expect(r2.homeGoals, r.homeGoals);
    expect(r2.awayGoals, r.awayGoals);
    expect(
      r.events.where((e) => e.type == MatchEventType.shout),
      hasLength(4),
    );
  });

  test('a charismatic coach gets through more often than a dull one away '
      'in a full stadium; "Schieß doch" brings long shots (report)', () {
    var loud = 0;
    var dull = 0;
    var shotsWith = 0;
    var shotsWithout = 0;
    for (var i = 0; i < 60; i++) {
      final a = tier1[i % tier1.length];
      final b = tier1[(i * 7 + 3) % tier1.length];
      if (a.clubId == b.clubId) continue;
      const full = MatchSetting(capacity: 60000, attendance: 60000, derby: 2);
      final s1 = MatchSession(
        rules: rules,
        home: _coached(a, 95),
        away: b,
        seed: 4100 + i,
        setting: full,
      )..advanceTo(20);
      loud += s1.shoutOut(0, Shout.push)!;
      final s2 = MatchSession(
        rules: rules,
        home: a,
        away: _coached(b, 5),
        seed: 4100 + i,
        setting: full,
      )..advanceTo(20);
      dull += s2.shoutOut(1, Shout.push)!;
      int longShots(bool shout) {
        final s = MatchSession(
          rules: rules,
          home: _coached(a, 80),
          away: b,
          seed: 4300 + i,
        );
        for (final m in [5, 16, 27]) {
          s.advanceTo(m);
          if (shout) s.shoutOut(0, Shout.shoot);
        }
        s.advanceTo(40);
        return s.events
            .where((e) => e.side == 0 && e.shotType == 'long_shot')
            .length;
      }

      shotsWith += longShots(true);
      shotsWithout += longShots(false);
    }
    stdout.writeln(
      'SHOUT-REPORT landed loud coach=$loud dull coach away=$dull '
      'long shots in 40 minutes with shouts=$shotsWith without=$shotsWithout',
    );
    expect(loud, greaterThan(dull));
    expect(shotsWith, greaterThan(shotsWithout));
  });
}
