import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Engine 2, step 10e4: places, stadiums, crowd, derbies and travel.

late Rules rules;
late World world;
late VenueData venues;
late List<MatchTeam> tier1;

void main() {
  setUpAll(() {
    rules = Rules.parse(
      File('../../rules/rules_2026_27.json').readAsStringSync(),
    ).valueOrNull!;
    world = WorldJson.decode(
      File('../../data/world_2026_27.json').readAsStringSync(),
    );
    venues = VenueData.fromJson(
      File('../../data/venues_de.json').readAsStringSync(),
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

  test('every club has a place and a stadium, distances make sense', () {
    for (final c in world.clubs) {
      expect(venues.places[c.place], isNotNull, reason: c.place);
      final s = venues.stadiums[c.id];
      expect(s, isNotNull, reason: c.name);
      expect(s!.capacity, greaterThan(300));
      expect(s.pitch, inInclusiveRange(1, 100));
    }
    // München to Hamburg is about 610 km as the crow flies.
    expect(venues.distanceKm('München', 'Hamburg'), inInclusiveRange(570, 650));
    expect(venues.distanceKm('Köln', 'Köln'), 0);
  });

  test('derbies: same place, near, rivalries; never against the own second '
      'team', () {
    Club byPlace(String place) => world.clubs.firstWhere(
      (c) => c.place == place && c.parentClubId == null,
    );
    final dortmund = byPlace('Dortmund');
    final gelsenkirchen = byPlace('Gelsenkirchen');
    expect(venues.derbyLevel(dortmund, gelsenkirchen), 3);
    expect(venues.derbyName(dortmund, gelsenkirchen), isNotNull);
    final far = venues.derbyLevel(byPlace('Kiel'), byPlace('Freiburg im Breisgau'));
    expect(far, 0);
    for (final c in world.clubs.where((c) => c.parentClubId != null)) {
      final parent = world.clubs.firstWhere((p) => p.id == c.parentClubId);
      expect(venues.derbyLevel(c, parent), 0);
    }
  });

  test('a full ground helps the home team more than an empty one', () {
    final crowd = rules.match.crowd;
    final full = crowd.homeFactor(75000, 1, 0);
    final empty = crowd.homeFactor(800, 0.1, 0);
    expect(full, greaterThan(empty));
    expect(full, closeTo(rules.match.homeAdvantage, 0.01));
    expect(crowd.homeFactor(75000, 1, 3), greaterThan(full));
    expect(crowd.travelLoss(100, shortRest: false), 0);
    expect(crowd.travelLoss(650, shortRest: false), greaterThan(0));
    expect(
      crowd.travelLoss(650, shortRest: true),
      greaterThan(crowd.travelLoss(650, shortRest: false)),
    );
  });

  test('crowd, derby and travel move the results (report)', () {
    const games = 300;
    (double, double) run(MatchSetting setting) {
      var home = 0;
      var yellows = 0;
      for (var i = 0; i < games; i++) {
        final r = MatchEngine(rules).simulate(
          tier1[i % tier1.length],
          tier1[(i * 5 + 1) % tier1.length],
          seed: 7000 + i,
          setting: setting,
        );
        if (r.homeGoals > r.awayGoals) home++;
        yellows += r.homeStats.yellowCards + r.awayStats.yellowCards;
      }
      return (home / games, yellows / games);
    }

    final full = run(
      const MatchSetting(capacity: 75000, attendance: 75000, travel: 0.06),
    );
    final empty = run(const MatchSetting(capacity: 20000, attendance: 2000));
    final derby = run(
      const MatchSetting(capacity: 50000, attendance: 50000, derby: 3),
    );
    stdout.writeln(
      'VENUE-REPORT home wins full+travel=${full.$1.toStringAsFixed(2)} '
      'empty=${empty.$1.toStringAsFixed(2)} derby=${derby.$1.toStringAsFixed(2)} '
      'yellows plain=${full.$2.toStringAsFixed(2)} derby=${derby.$2.toStringAsFixed(2)}',
    );
    expect(full.$1, greaterThan(empty.$1));
    expect(derby.$2, greaterThan(full.$2));
  });

  test('a season with grounds and referees stays balanced (report)', () {
    final runner = SeasonRunner(
      rules,
      calendarRules: CalendarRules.fromJsonString(
        File('../../rules/calendar_rules.json').readAsStringSync(),
      ),
      referees: RefereePool.fromJson(
        File('../../data/referees_de.json').readAsStringSync(),
      ),
      venues: venues,
    );
    final o = runner.play(SeasonState.fromWorld(world), seed: 31);
    final n = o.matchesPlayed;
    stdout.writeln(
      'VENUE-REPORT season H/D/A='
      '${(o.homeWins / n).toStringAsFixed(2)}/'
      '${(o.draws / n).toStringAsFixed(2)}/'
      '${(o.awayWins / n).toStringAsFixed(2)} '
      'goals/game=${(o.goalsScored / n).toStringAsFixed(2)} '
      'reds=${o.redCards}',
    );
    expect(o.homeWins / n, inInclusiveRange(0.33, 0.5));
  });

  test('weather and ground: by month and region, the same every time, '
      'good grass keeps the ground better (report)', () {
    final runner = SeasonRunner(
      rules,
      calendarRules: CalendarRules.fromJsonString(
        File('../../rules/calendar_rules.json').readAsStringSync(),
      ),
      venues: venues,
    );
    runner.begin(SeasonState.fromWorld(world), seed: 41);
    final good = world.clubs.reduce(
      (a, b) =>
          venues.stadiums[a.id]!.pitch > venues.stadiums[b.id]!.pitch ? a : b,
    );
    final bad = world.clubs.reduce(
      (a, b) =>
          venues.stadiums[a.id]!.pitch < venues.stadiums[b.id]!.pitch ? a : b,
    );
    final kinds = <String, int>{};
    var heavyGood = 0;
    var heavyBad = 0;
    var snowSummer = 0;
    var rightForecasts = 0;
    final start = GameDate(2026, 8, 1).epochDay;
    for (var d = 0; d < 300; d++) {
      final day = start + d;
      final (w, g) = runner.conditionsOn(good.id, day);
      expect(runner.conditionsOn(good.id, day), (w, g));
      kinds[w] = (kinds[w] ?? 0) + 1;
      if (g == 'heavy' || g == 'frozen') heavyGood++;
      final (_, g2) = runner.conditionsOn(bad.id, day);
      if (g2 == 'heavy' || g2 == 'frozen') heavyBad++;
      final month = GameDate.fromEpochDay(day).month;
      if (w == 'snow' && month >= 5 && month <= 9) snowSummer++;
      if (runner.forecastOn(good.id, day) == w) rightForecasts++;
    }
    stdout.writeln(
      'WEATHER-REPORT kinds=$kinds heavy good=$heavyGood bad=$heavyBad '
      'forecast right=$rightForecasts/300',
    );
    expect(snowSummer, 0);
    expect(heavyBad, greaterThan(heavyGood));
    expect(rightForecasts, inInclusiveRange(150, 260));
  });
}
