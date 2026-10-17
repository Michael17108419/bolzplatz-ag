import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

// Rules of the game from IFAB Law 3 and the DFB (see the project document
// "Regelwerk_Abgleich"): five substitutions in three windows plus breaks,
// one more of each in extra time, a yellow card of a player sent off in the
// same match does not count.

late Rules rules;
late MatchTeam home;
late MatchTeam away;

MatchTeam _team(Club club, List<Player> squad) => MatchTeam(
  clubId: club.id,
  name: club.name,
  squad: squad,
  sheet: AutoManager(rules).build(squad)!,
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
    List<Player> squad(Club c) => [
      for (final p in world.players)
        if (p.clubId == c.id) p,
    ];
    home = _team(world.clubs[0], squad(world.clubs[0]));
    away = _team(world.clubs[1], squad(world.clubs[1]));
  });

  bool isKeeper(PlayerId id) =>
      home.squad.firstWhere((p) => p.id == id).position.isGoalkeeper;

  /// Brings the first outfield substitute on for the first outfield player.
  bool subOne(MatchSession s) {
    final off = s.onPitch(0).where((id) => !isKeeper(id));
    final on = s.benchOf(0).where((id) => !isKeeper(id));
    if (off.isEmpty || on.isEmpty) return false;
    return s.substitute(0, off.first, on.first);
  }

  test('the rules know five changes in three windows', () {
    expect(rules.tactics.maxSubstitutions, 5);
    expect(rules.tactics.substitutionWindows, 3);
    expect(rules.tactics.extraTimeExtraSubstitutions, 1);
    expect(rules.tactics.extraTimeExtraWindows, 1);
    expect(rules.season.straightRedBanMatches, 1);
  });

  test('windows: same stoppage is one window, half time is free', () {
    final s = MatchSession(rules: rules, home: home, away: away, seed: 11)
      ..advanceTo(20);
    final w0 = s.windowsLeft(0);
    expect(subOne(s), isTrue);
    expect(s.windowsLeft(0), w0 - 1);
    // A second change in the same stoppage uses no new window.
    expect(subOne(s), isTrue);
    expect(s.windowsLeft(0), w0 - 1);
    s.advanceTo(rules.match.halfTimeMinute);
    expect(s.inBreak, isTrue);
    final w1 = s.windowsLeft(0);
    expect(subOne(s), isTrue);
    expect(s.windowsLeft(0), w1);
  });

  test('without a window no change, even with changes left', () {
    final s = MatchSession(rules: rules, home: home, away: away, seed: 12);
    var minute = 10;
    // Use every window with one change each.
    while (s.windowsLeft(0) > 0 && s.substitutionsLeft(0) > 1) {
      s.advanceTo(minute);
      if (s.inBreak) {
        minute++;
        continue;
      }
      expect(subOne(s), isTrue);
      minute += 10;
    }
    s.advanceTo(minute + 5);
    if (s.windowsLeft(0) == 0 && s.substitutionsLeft(0) > 0 && !s.inBreak) {
      expect(s.canSubstitute(0), isFalse);
      expect(subOne(s), isFalse);
    }
  });

  test('extra time gives one more change and one more window', () {
    final s = MatchSession(rules: rules, home: home, away: away, seed: 13)
      ..advanceTo(rules.match.minutes);
    final subsBefore = s.substitutionsLeft(0);
    final windowsBefore = s.windowsLeft(0);
    s.startExtraTime();
    expect(s.inExtraTime, isTrue);
    expect(s.substitutionsLeft(0), subsBefore + 1);
    expect(s.windowsLeft(0), windowsBefore + 1);
    // Before extra time starts the change is free of windows.
    expect(s.inBreak, isTrue);
    expect(subOne(s), isTrue);
    expect(s.windowsLeft(0), windowsBefore + 1);
  });

  test('a yellow before a sending-off is used up (DFB § 43 Nr. 4)', () {
    MatchEvent card(MatchEventType type, int player) => MatchEvent(
      minute: 10,
      type: type,
      side: 0,
      homeGoals: 0,
      awayGoals: 0,
      player: PlayerId(player),
    );
    final events = [
      card(MatchEventType.yellowCard, 1),
      card(MatchEventType.yellowCard, 2),
      card(MatchEventType.secondYellow, 2),
      card(MatchEventType.yellowCard, 3),
      card(MatchEventType.redCard, 3),
      card(MatchEventType.redCard, 4),
    ];
    expect(countedYellowCards(events), [const PlayerId(1)]);
  });
}
