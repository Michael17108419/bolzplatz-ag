import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/lineup.dart';
import '../game/loaded_world.dart';
import '../game/office_provider.dart';
import '../game/reporter.dart';
import '../game/saves.dart';
import '../game/settings.dart';
import '../game/season_game.dart';
import '../game/ticker.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'adaptive.dart';
import 'conference_view.dart';
import 'crest.dart';
import 'info_button.dart';
import 'player_widgets.dart';
import 'round_play_button.dart';
import 'screen_frame.dart';
import 'stats_page.dart';
import 'step_buttons.dart';

/// The short name of a player for the ticker (last name).
String _shortName(LoadedWorld loaded, PlayerId? id) {
  if (id == null) return '';
  return loaded.player(id)?.lastName ?? '';
}

/// "F. Lastname" for lists.
String _listName(LoadedWorld loaded, PlayerId id) {
  final p = loaded.player(id);
  if (p == null) return '';
  return '${p.firstName.isEmpty ? '' : '${p.firstName[0]}. '}${p.lastName}';
}

String _clubName(LoadedWorld loaded, ClubId id) => loaded.club(id).name;

/// True for a cup tie (extra time and shoot-out are possible).
bool _isCup(OwnMatch own) => own.competition != Competition.league;

/// "Spieltag 5" or "Bolzplatzpokal, Runde 2".
String _matchTitle(
  AppStrings s,
  LoadedWorld loaded,
  OwnMatch own,
  SeasonGame game,
) {
  if (!_isCup(own)) return s.officeMatchday(game.matchday);
  final cups = loaded.rules.season.cups;
  final rounds = own.competition == Competition.pott
      ? cups.pottAfterMatchday.length
      : cups.bolzplatzAfterMatchday.length;
  return '${s.cupName(own.competition)}, '
      '${s.cupRoundName(own.round == rounds - 1, own.round)}';
}

/// Preview before the kick-off: opponent, strength, line-up, absences.
class MatchPreviewPage extends ConsumerWidget {
  const MatchPreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final game = ref.watch(seasonProvider);
    final loaded = ref.watch(loadedWorldProvider).value;
    final view = ref.watch(officeViewProvider);
    final lineup = ref.watch(lineupProvider);
    final theme = Theme.of(context);
    final own = game?.next;
    if (game == null || loaded == null || view == null || own == null) {
      return ScreenFrame(
        title: s.officeMatchday(game?.matchday ?? 1),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final fixture = own.fixture;
    final home = fixture.home;
    final away = fixture.away;
    final atHome = home == game.clubId;
    final opponentStrength = _isCup(own)
        ? (loaded.strengths[atHome ? away : home] ?? 0)
        : view.opponentStrength;
    final absent = game.runner.absences(game.run, game.clubId);
    final sheet = lineup?.sheet;

    Widget team(ClubId id) => Expanded(
      child: Column(
        children: [
          ClubCrest(clubId: id.value, size: 64),
          const SizedBox(height: Tokens.gapS),
          Text(
            _clubName(loaded, id),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );

    return ScreenFrame(
      title: _matchTitle(s, loaded, own, game),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              team(home),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text('–', style: theme.textTheme.headlineMedium),
              ),
              team(away),
            ],
          ),
          const SizedBox(height: Tokens.gapM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '${atHome ? s.officeHome : s.officeAway} · '
                  '${_isCup(own) ? s.cupName(own.competition) : s.leagueName(ref.watch(careerProvider)!.league.name)}',
                  key: const ValueKey('match-preview-kind'),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              InfoButton(message: s.infoMatchPreview),
            ],
          ),
          const SizedBox(height: Tokens.gapM),
          Text(
            s.matchPreviewStrength,
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            s.officeStrengthCompare(
              view.ownStrength.toStringAsFixed(1),
              opponentStrength.toStringAsFixed(1),
            ),
            key: const ValueKey('match-preview-strength'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Tokens.gapM),
          if (sheet != null)
            Text(
              s.matchPreviewLineup(
                sheet.formationId,
                s.systemName(sheet.systemId),
              ),
              key: const ValueKey('match-preview-lineup'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: Tokens.gapM),
          Text(s.matchPreviewAbsent, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          if (absent.isEmpty)
            Text(
              s.matchNoAbsent,
              key: const ValueKey('match-preview-none'),
              style: theme.textTheme.bodyMedium,
            )
          else
            for (final e in absent.entries)
              Text(
                '${_listName(loaded, e.key)} – ${s.matchAbsence(e.value)}',
                key: ValueKey('match-absent-${e.key.value}'),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
          if (own.sheetReplaced)
            Padding(
              padding: const EdgeInsets.only(top: Tokens.gapM),
              child: Text(
                s.matchSheetReplaced,
                key: const ValueKey('match-sheet-replaced'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Tokens.orange,
                ),
              ),
            ),
          const Spacer(),
          StepButtons(
            backLabel: s.back,
            nextLabel: s.matchKickOff,
            onBack: () => Navigator.of(context).maybePop(),
            onNext: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const LiveMatchPage()),
            ),
          ),
        ],
      ),
    );
  }
}

/// The live match: score, ticker, speed, pause, substitutions, tactics.
class LiveMatchPage extends ConsumerStatefulWidget {
  const LiveMatchPage({super.key});

  @override
  ConsumerState<LiveMatchPage> createState() => _LiveMatchPageState();
}

class _LiveMatchPageState extends ConsumerState<LiveMatchPage> {
  static const _speeds = [
    Duration(milliseconds: 700),
    Duration(milliseconds: 350),
    Duration(milliseconds: 100),
  ];

  late final OwnMatch _own;
  late final ConferenceDay _day;
  int _view = 0;
  late final LoadedWorld _loaded;
  late final int _ownSide;
  late final Reporter _reporter;
  final List<TickerLine> _lines = [];

  /// Lines of the reporter still to be shown, one after the other with a
  /// pause each (a scene: build-up, shot, the end).
  final List<TickerLine> _queue = [];

  /// An event that stops the match came in: stop once its lines are shown.
  bool _stopAfterQueue = false;

  /// The score of the newest line shown: while a scene is told the board
  /// does not give the goal away.
  int _shownHome = 0;
  int _shownAway = 0;
  int _seen = 0;
  // Slow is the default: the ticker should be readable.
  int _speed = 0;
  // False while old events are read in (no buzzing for those).
  bool _live = false;
  bool _running = true;
  bool _pausedByEvent = false;
  bool _done = false;

  /// The match is over and the reporter has said everything.
  bool get _over => _done && _queue.isEmpty;
  bool _shootoutShown = false;
  Timer? _timer;

  MatchSession get _session => _own.session!;

  bool get _cup => _isCup(_own);

  @override
  void initState() {
    super.initState();
    final game = ref.read(seasonProvider)!;
    _own = game.next!;
    _day = game.day!;
    _loaded = ref.read(loadedWorldProvider).value!;
    _ownSide = _own.fixture.home == game.clubId ? 0 : 1;
    _speed = ref.read(tickerSpeedProvider);
    final home = _loaded.club(_own.fixture.home);
    final league = _loaded.world.leagues
        .where((l) => l.id == home.leagueId)
        .firstOrNull;
    _reporter = Reporter(
      strings: ref.read(stringsProvider).reporter,
      ownSide: _ownSide,
      home: home.name,
      away: _clubName(_loaded, _own.fixture.away),
      playerName: (id) => _shortName(_loaded, id),
      player: _loaded.player,
      captainOf: _session.captainOf,
      tier: league?.level ?? 1,
    );
    // A saved match that was under way waits paused, so nothing happens
    // before the player is back.
    final notifier = ref.read(seasonProvider.notifier);
    if (notifier.resumeLive) {
      notifier.resumeLive = false;
      _running = false;
    }
    _ingest();
    _live = true;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer([Duration? wait]) {
    _timer?.cancel();
    if (!_running || _over) return;
    _timer = Timer(wait ?? _speeds[_speed], _tick);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Turns new events of the session into ticker lines. Returns true if one
  /// of them should stop the match. A cup tie that is level after full time
  /// goes into extra time and then to the shoot-out.
  bool _ingest() {
    var stop = false;
    while (true) {
      if (_readEvents()) stop = true;
      if (!_session.isFinished) break;
      if (_cup && _session.startExtraTimeIfLevel()) continue;
      _done = true;
      break;
    }
    if (_done && _cup && _session.isLevel) {
      final winner = _session.playShootout();
      if (!_shootoutShown) {
        _shootoutShown = true;
        final s = ref.read(stringsProvider);
        final score = _session.shootoutScore();
        final fixture = _own.fixture;
        _show(
          TickerLine(
            minute: _session.clock,
            kind: TickerKind.shootout,
            side: -1,
            homeGoals: score[0],
            awayGoals: score[1],
            text: s.matchShootoutLine(
              _clubName(_loaded, winner == 0 ? fixture.home : fixture.away),
              winner == 0 ? score[0] : score[1],
              winner == 0 ? score[1] : score[0],
            ),
          ),
        );
      }
    }
    return stop;
  }

  bool _readEvents() {
    final events = _session.events;
    var stop = false;
    for (; _seen < events.length; _seen++) {
      final e = events[_seen];
      for (final line in _reporter.linesOf(e, _seen)) {
        _show(line);
      }
      if (pausesMatch(e)) stop = true;
    }
    return stop;
  }

  /// A line of the reporter: while the match runs live it waits in the
  /// queue for its turn, otherwise (reading in, paused, skipped) it goes
  /// straight to the top of the ticker.
  void _show(TickerLine line) {
    if (_live && _running) {
      _queue.add(line);
    } else {
      _put(line);
    }
  }

  /// Puts a line on top of the ticker (newest first); a goal of the own
  /// club buzzes.
  void _put(TickerLine line) {
    _lines.insert(0, line);
    if (line.kind != TickerKind.shootout) {
      _shownHome = line.homeGoals;
      _shownAway = line.awayGoals;
    }
    if (_live &&
        line.isGoal &&
        line.side == _ownSide &&
        ref.read(vibrationProvider)) {
      unawaited(buzz());
    }
  }

  /// Shows the waiting lines at once (pause, skip, a change).
  void _flush() {
    for (final line in _queue) {
      _put(line);
    }
    _queue.clear();
  }

  /// One beat of the live match: the next waiting line of the reporter,
  /// or, with none waiting, the next minute.
  void _tick() {
    if (_queue.isEmpty && !_done) {
      _session.advanceTo(_session.minute + 1);
      if (_ingest()) _stopAfterQueue = true;
      final quiet = _reporter.quiet(
        _session.minute,
        _session.clock,
        _session.clockLabel,
      );
      if (quiet != null) _queue.add(quiet);
      // Every quarter of an hour of the match the game is saved.
      if (_session.minute % 15 == 0) {
        unawaited(ref.read(saveServiceProvider).autosave());
      }
    }
    var wait = _speeds[_speed];
    if (_queue.isNotEmpty) {
      final line = _queue.removeAt(0);
      _put(line);
      wait += readingTime(line, _speed);
    }
    if (_queue.isEmpty && _stopAfterQueue) {
      _stopAfterQueue = false;
      _running = false;
      _pausedByEvent = true;
      _stopTimer();
    } else if (_queue.isEmpty && _done) {
      _stopTimer();
    } else {
      _startTimer(wait);
    }
    setState(() {});
  }

  void _pause() {
    _running = false;
    _stopAfterQueue = false;
    _flush();
    _stopTimer();
    setState(() {});
  }

  void _resume() {
    if (_over) return;
    _running = true;
    _pausedByEvent = false;
    _startTimer();
    setState(() {});
  }

  void _skip() {
    _stopTimer();
    _flush();
    _live = false;
    if (_cup) {
      _session.finishKnockout();
    } else {
      _session.finish();
    }
    _ingest();
    _running = false;
    setState(() {});
  }

  void _setSpeed(int speed) {
    _speed = speed;
    if (_running) _startTimer();
    setState(() {});
  }

  void _toReport() {
    final KnockoutResult? knockout = _cup ? _session.finishKnockout() : null;
    final result = knockout?.match ?? _session.finish();
    ref.read(seasonProvider.notifier).complete(result, knockout: knockout);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            MatchReportPage(result: result, own: _own, knockout: knockout),
      ),
    );
  }

  Future<void> _openSubs() async {
    _pause();
    if (isNarrow(context)) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Tokens.ground,
        builder: (_) => _SubsSheet(
          session: _session,
          side: _ownSide,
          loaded: _loaded,
          onDone: () {
            _ingest();
            setState(() {});
          },
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _SubsDialog(
        session: _session,
        side: _ownSide,
        loaded: _loaded,
        onDone: () {
          _ingest();
          setState(() {});
        },
      ),
    );
  }

  Future<void> _openTactics() async {
    _pause();
    if (isNarrow(context)) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Tokens.ground,
        builder: (_) => _TacticsDialog(
          asSheet: true,
          session: _session,
          side: _ownSide,
          rules: _loaded.rules,
          onChanged: () {
            _ingest();
            setState(() {});
          },
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _TacticsDialog(
        session: _session,
        side: _ownSide,
        rules: _loaded.rules,
        onChanged: () {
          _ingest();
          setState(() {});
        },
      ),
    );
  }

  void _openMore() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Tokens.panel,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) {
          final s = ref.read(stringsProvider);
          final theme = Theme.of(context);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Tokens.gapM),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        s.settingsTicker,
                        style: theme.textTheme.titleMedium,
                      ),
                      InfoButton(message: s.infoMatchSpeed),
                    ],
                  ),
                  const SizedBox(height: Tokens.gapS),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < 3; i++)
                        ChoiceChip(
                          key: ValueKey('match-speed-$i'),
                          label: Text(
                            [
                              s.matchSpeedSlow,
                              s.matchSpeedNormal,
                              s.matchSpeedFast,
                            ][i],
                          ),
                          selected: _speed == i,
                          onSelected: (_) {
                            _setSpeed(i);
                            setSheet(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: Tokens.gapM),
                  OutlinedButton(
                    key: const ValueKey('match-skip'),
                    onPressed: () {
                      Navigator.of(sheet).pop();
                      _skip();
                    },
                    child: Text(s.matchSkip),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final home = _own.fixture.home;
    final away = _own.fixture.away;
    final game = ref.watch(seasonProvider);
    final phone = isNarrow(context);

    Widget team(ClubId id, {required bool right}) => phone
        ? Expanded(
            child: Column(
              children: [
                ClubCrest(clubId: id.value, size: 44),
                const SizedBox(height: 4),
                Text(
                  _clubName(_loaded, id),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          )
        : Expanded(
      child: Row(
        mainAxisAlignment: right
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (!right) ...[
            Flexible(
              child: Text(
                _clubName(_loaded, id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: Tokens.gapS),
          ],
          ClubCrest(clubId: id.value, size: 40),
          if (right) ...[
            const SizedBox(width: Tokens.gapS),
            Flexible(
              child: Text(
                _clubName(_loaded, id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ],
      ),
    );

    final subsLeft = _session.substitutionsLeft(_ownSide);

    return PopScope(
      canPop: _over,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(s.matchLeaveBlocked)));
      },
      child: ScreenFrame(
        showBack: false,
        title: game == null
            ? s.officeMatchday(1)
            : _matchTitle(s, _loaded, _own, game),
        maxWidth: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                team(home, right: false),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Tokens.gapM),
                  child: Text(
                    _queue.isEmpty
                        ? '${_session.homeGoals} : ${_session.awayGoals}'
                        : '$_shownHome : $_shownAway',
                    key: const ValueKey('match-score'),
                    style: phone
                        ? theme.textTheme.displaySmall
                        : theme.textTheme.headlineMedium,
                  ),
                ),
                team(away, right: true),
              ],
            ),
            const SizedBox(height: Tokens.gapS),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _over
                      ? s.matchFinal
                      : _pausedByEvent
                      ? s.matchPaused
                      : '${_session.clockLabel}\'',
                  key: const ValueKey('match-minute'),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            if (phone) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  key: const ValueKey('match-progress'),
                  minHeight: 6,
                  value: (_over ? 90 : _session.clock.clamp(0, 90)) / 90,
                  color: Tokens.yellow,
                  backgroundColor: Tokens.panel,
                ),
              ),
            ],
            const SizedBox(height: Tokens.gapS),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const ValueKey('match-view-own'),
                  label: Text(s.matchViewOwn),
                  selected: _view == 0,
                  onSelected: (_) => setState(() => _view = 0),
                ),
                ChoiceChip(
                  key: const ValueKey('match-view-conference'),
                  label: Text(s.matchViewConference),
                  selected: _view == 1,
                  onSelected: (_) => setState(() => _view = 1),
                ),
              ],
            ),
            const SizedBox(height: Tokens.gapS),
            Expanded(
              child: _view == 1 && game != null
                  ? ConferenceView(
                      day: _day,
                      run: game.run,
                      loaded: _loaded,
                      strings: s,
                      ownLeague: game.ownLeague,
                      ownClub: game.clubId,
                      ownDone: _over,
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: Tokens.panel,
                        borderRadius: BorderRadius.circular(Tokens.radius),
                      ),
                      child: ListView.builder(
                        key: const ValueKey('match-ticker'),
                        padding: const EdgeInsets.all(Tokens.gapM),
                        itemCount: _lines.length,
                        itemBuilder: (context, i) => _TickerRow(
                          key: ValueKey('match-line-${_lines.length - 1 - i}'),
                          line: _lines[i],
                          crestId: switch (_lines[i].side) {
                            0 => home.value,
                            1 => away.value,
                            _ => null,
                          },
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: Tokens.gapS),
            if (_over)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const ValueKey('match-report'),
                  onPressed: _toReport,
                  child: Text(s.matchToReport),
                ),
              )
            else if (phone)
              Row(
                children: [
                  RoundPlayButton(
                    key: const ValueKey('match-pause'),
                    pause: _running,
                    semanticLabel: _running ? s.matchPause : s.matchResume,
                    onTap: _running ? _pause : _resume,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('match-subs'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: _openSubs,
                      child: Text(
                        '${s.matchSubs} ($subsLeft)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('match-tactics'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: _openTactics,
                      child: Text(s.matchTactics, maxLines: 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.outlined(
                    key: const ValueKey('match-more'),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                    ),
                    onPressed: _openMore,
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    ChoiceChip(
                      key: ValueKey('match-speed-$i'),
                      label: Text(
                        [
                          s.matchSpeedSlow,
                          s.matchSpeedNormal,
                          s.matchSpeedFast,
                        ][i],
                      ),
                      selected: _speed == i,
                      onSelected: (_) => _setSpeed(i),
                    ),
                  InfoButton(message: s.infoMatchSpeed),
                  RoundPlayButton(
                    key: const ValueKey('match-pause'),
                    pause: _running,
                    semanticLabel: _running ? s.matchPause : s.matchResume,
                    onTap: _running ? _pause : _resume,
                  ),
                  OutlinedButton(
                    key: const ValueKey('match-subs'),
                    onPressed: _openSubs,
                    child: Text('${s.matchSubs} ($subsLeft)'),
                  ),
                  InfoButton(message: s.infoMatchSubs),
                  OutlinedButton(
                    key: const ValueKey('match-tactics'),
                    onPressed: _openTactics,
                    child: Text(s.matchTactics),
                  ),
                  InfoButton(message: s.infoMatchTactics),
                  TextButton(
                    key: const ValueKey('match-skip'),
                    onPressed: _skip,
                    child: Text(s.matchSkip),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TickerRow extends StatelessWidget {
  const _TickerRow({required this.line, this.crestId, super.key});

  final TickerLine line;

  /// The club the line is about: its crest stands before the text.
  final int? crestId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (line.kind) {
      TickerKind.goal ||
      TickerKind.goalAssist ||
      TickerKind.scorer ||
      TickerKind.assist => Tokens.yellow,
      TickerKind.red || TickerKind.secondYellow => Tokens.orange,
      TickerKind.injury => Tokens.orange,
      _ => null,
    };
    final bold = line.isGoal || line.kind == TickerKind.fullTime;
    final symbol = line.symbol;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '${line.clockLabel}\'',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Tokens.text.withValues(alpha: 0.6),
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: crestId == null
                ? null
                : Align(
                    alignment: Alignment.centerLeft,
                    child: ClubCrest(clubId: crestId!, size: 22),
                  ),
          ),
          SizedBox(
            width: 24,
            child: symbol == null
                ? null
                : Align(
                    alignment: Alignment.topLeft,
                    child: TickerSymbolView(
                      symbol,
                      key: ValueKey('ticker-symbol-${symbol.name}'),
                    ),
                  ),
          ),
          Expanded(
            child: Text(
              line.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: bold ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The symbol of a highlight in the ticker: ball, cards, whistle, clock.
class TickerSymbolView extends StatelessWidget {
  const TickerSymbolView(this.symbol, {super.key});

  final TickerSymbol symbol;

  static Widget _card(Color color) => Container(
    width: 10,
    height: 14,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: Tokens.ink, width: 0.8),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF2C94C);
    const red = Color(0xFFD64545);
    return switch (symbol) {
      TickerSymbol.goal => const Icon(
        Icons.sports_soccer,
        size: 18,
        color: Tokens.yellow,
      ),
      TickerSymbol.yellow => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: _card(yellow),
      ),
      TickerSymbol.red => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: _card(red),
      ),
      TickerSymbol.yellowRed => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: SizedBox(
          width: 18,
          height: 16,
          child: Stack(
            children: [
              _card(yellow),
              Positioned(left: 6, top: 2, child: _card(red)),
            ],
          ),
        ),
      ),
      TickerSymbol.injury => const Icon(
        Icons.local_hospital,
        size: 17,
        color: Tokens.orange,
      ),
      TickerSymbol.sub => const Icon(
        Icons.swap_horiz,
        size: 18,
        color: Tokens.green,
      ),
      TickerSymbol.time => const Icon(
        Icons.timer_outlined,
        size: 17,
        color: Tokens.text,
      ),
      TickerSymbol.whistle => const Icon(
        Icons.sports,
        size: 17,
        color: Tokens.text,
      ),
      TickerSymbol.bigChance => const Icon(
        Icons.priority_high,
        size: 18,
        color: Tokens.orange,
      ),
    };
  }
}

/// One player in the substitution list: position, name, role, energy and
/// form, and the strength on the right.
class _SubRow extends StatelessWidget {
  const _SubRow({
    required this.player,
    required this.position,
    required this.strength,
    required this.energy,
    required this.form,
    required this.strings,
    required this.onTap,
    this.role,
    this.fits = false,
    this.selected = false,
    this.captain = false,
    super.key,
  });

  final Player player;

  /// The position shown in the chip: the place on the pitch, or his own.
  final Position position;
  final double strength;
  final double energy;
  final double form;
  final AppStrings strings;
  final VoidCallback onTap;
  final String? role;
  final bool fits;
  final bool selected;

  /// Wears the armband.
  final bool captain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = player.firstName.isEmpty ? '' : '${player.firstName[0]}. ';
    final low = energy < 50;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? Tokens.panel : Tokens.panel.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Tokens.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(Tokens.radius),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Tokens.radius),
              border: selected
                  ? Border.all(color: Tokens.yellow, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                PositionChip(position, width: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$first${player.lastName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          if (captain) ...[
                            const SizedBox(width: 6),
                            CaptainBadge(
                              key: ValueKey('match-sub-captain-${player.id.value}'),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        [
                          if (role != null) strings.roleName(role!),
                          strings.matchSubStats(energy.round(), form.round()),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: low ? Tokens.orange : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (fits)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      strings.matchSubFits,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Tokens.green,
                      ),
                    ),
                  ),
                Text(
                  strength.round().toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: valueColor(strength),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The list rows of the substitution: [off] true for the pitch, false for
/// the bench (then [offId] is the one who goes and decides what "fits").
List<Widget> _subRows({
  required MatchSession session,
  required int side,
  required LoadedWorld loaded,
  required AppStrings s,
  required bool off,
  required PlayerId? offId,
  required void Function(PlayerId id) onTap,
}) {
  final ids = off ? session.onPitch(side) : session.benchOf(side);
  final want = offId == null ? null : session.slotPositionOf(side, offId);
  final entries = <(PlayerId, Player)>[
    for (final id in ids)
      if (loaded.player(id) != null) (id, loaded.player(id)!),
  ];
  if (!off) {
    entries.sort((a, b) {
      final fa = want != null && a.$2.position == want ? 0 : 1;
      final fb = want != null && b.$2.position == want ? 0 : 1;
      if (fa != fb) return fa - fb;
      return loaded.overall(b.$2).compareTo(loaded.overall(a.$2));
    });
  }
  return [
    for (final (id, p) in entries)
      _SubRow(
        key: ValueKey('match-sub-${off ? 'off' : 'on'}-${id.value}'),
        player: p,
        position: off ? (session.slotPositionOf(side, id) ?? p.position) : p.position,
        strength: loaded.overall(p),
        energy: session.energyOf(side, id),
        form: session.formOf(side, id),
        role: off ? session.roleOf(side, id) : null,
        fits: !off && want != null && p.position == want,
        selected: off && offId == id,
        captain: off && session.captainOf(side) == id,
        strings: s,
        onTap: () => onTap(id),
      ),
  ];
}

/// Substitution: first who goes, then who comes.
class _SubsDialog extends ConsumerStatefulWidget {
  const _SubsDialog({
    required this.session,
    required this.side,
    required this.loaded,
    required this.onDone,
  });

  final MatchSession session;
  final int side;
  final LoadedWorld loaded;
  final VoidCallback onDone;

  @override
  ConsumerState<_SubsDialog> createState() => _SubsDialogState();
}

class _SubsDialogState extends ConsumerState<_SubsDialog> {
  PlayerId? _off;
  String? _note;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final session = widget.session;
    final left = session.substitutionsLeft(widget.side);
    final bench = session.benchOf(widget.side);
    final loaded = widget.loaded;

    final String title;
    final List<Widget> body;
    if (left <= 0 || !session.canSubstitute(widget.side)) {
      title = s.matchSubs;
      body = [Text(left <= 0 ? s.matchSubNone : s.matchSubNoWindow)];
    } else if (_off == null) {
      title = s.matchSubPickOff;
      body = _subRows(
        session: session,
        side: widget.side,
        loaded: loaded,
        s: s,
        off: true,
        offId: null,
        onTap: (id) => setState(() => _off = id),
      );
    } else if (bench.isEmpty) {
      title = s.matchSubPickOn;
      body = [Text(s.matchSubBenchEmpty)];
    } else {
      title = s.matchSubPickOn;
      body = _subRows(
        session: session,
        side: widget.side,
        loaded: loaded,
        s: s,
        off: false,
        offId: _off,
        onTap: (id) {
          final ok = session.substitute(widget.side, _off!, id);
          if (ok) {
            widget.onDone();
            Navigator.of(context).pop();
          } else {
            setState(() => _note = s.matchSubKeeperOnly);
          }
        },
      );
    }

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.matchSubsAndWindows(
                  left,
                  session.windowsLeft(widget.side),
                  breakNow: session.inBreak,
                ),
              ),
              if (_note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _note!,
                    style: const TextStyle(color: Tokens.orange),
                  ),
                ),
              ...body,
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('match-dialog-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.matchClose),
        ),
      ],
    );
  }
}

/// Phone: the substitution as one sheet. Who goes off and who comes on are
/// both on screen, so there is no scrolling from step to step.
class _SubsSheet extends ConsumerStatefulWidget {
  const _SubsSheet({
    required this.session,
    required this.side,
    required this.loaded,
    required this.onDone,
  });

  final MatchSession session;
  final int side;
  final LoadedWorld loaded;
  final VoidCallback onDone;

  @override
  ConsumerState<_SubsSheet> createState() => _SubsSheetState();
}

class _SubsSheetState extends ConsumerState<_SubsSheet> {
  PlayerId? _off;
  String? _note;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final session = widget.session;
    final left = session.substitutionsLeft(widget.side);
    final bench = session.benchOf(widget.side);
    final loaded = widget.loaded;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Tokens.gapM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.matchSubs,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    s.matchSubsAndWindows(
                      left,
                      session.windowsLeft(widget.side),
                      breakNow: session.inBreak,
                    ),
                  ),
                ],
              ),
              if (left <= 0 || !session.canSubstitute(widget.side))
                Padding(
                  padding: const EdgeInsets.only(top: Tokens.gapS),
                  child: Text(
                    left <= 0 ? s.matchSubNone : s.matchSubNoWindow,
                  ),
                )
              else ...[
                const SizedBox(height: Tokens.gapS),
                if (_off == null) ...[
                  Text(s.matchSubPickOff, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  ..._subRows(
                    session: session,
                    side: widget.side,
                    loaded: loaded,
                    s: s,
                    off: true,
                    offId: null,
                    onTap: (id) => setState(() {
                      _off = id;
                      _note = null;
                    }),
                  ),
                ] else ...[
                  Text(s.matchSubPickOn, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  _SubRow(
                    key: const ValueKey('match-sub-off-chosen'),
                    player: loaded.player(_off!)!,
                    position:
                        session.slotPositionOf(widget.side, _off!) ??
                        loaded.player(_off!)!.position,
                    strength: loaded.overall(loaded.player(_off!)!),
                    energy: session.energyOf(widget.side, _off!),
                    form: session.formOf(widget.side, _off!),
                    role: session.roleOf(widget.side, _off!),
                    selected: true,
                    strings: s,
                    onTap: () => setState(() {
                      _off = null;
                      _note = null;
                    }),
                  ),
                  const SizedBox(height: 4),
                  if (bench.isEmpty)
                    Text(s.matchSubBenchEmpty)
                  else
                    ..._subRows(
                      session: session,
                      side: widget.side,
                      loaded: loaded,
                      s: s,
                      off: false,
                      offId: _off,
                      onTap: (id) {
                        if (session.substitute(widget.side, _off!, id)) {
                          widget.onDone();
                          Navigator.of(context).pop();
                        } else {
                          setState(() => _note = s.matchSubKeeperOnly);
                        }
                      },
                    ),
                ],
                if (_note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _note!,
                      style: const TextStyle(color: Tokens.orange),
                    ),
                  ),
              ],
              const SizedBox(height: Tokens.gapM),
              FilledButton(
                key: const ValueKey('match-dialog-close'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(s.matchClose),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One option of the tactics sheet: same height and look everywhere, the
/// chosen one is filled.
class _TacticOption extends StatelessWidget {
  const _TacticOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Tokens.yellow : Tokens.panel,
      borderRadius: BorderRadius.circular(Tokens.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Tokens.radius),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Tokens.ground : Tokens.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// System and sliders during the match.
class _TacticsDialog extends ConsumerStatefulWidget {
  const _TacticsDialog({
    required this.session,
    required this.side,
    required this.rules,
    required this.onChanged,
    this.asSheet = false,
  });

  final MatchSession session;
  final int side;
  final Rules rules;
  final VoidCallback onChanged;

  /// Phone: shown as a sheet from the bottom instead of a dialog.
  final bool asSheet;

  @override
  ConsumerState<_TacticsDialog> createState() => _TacticsDialogState();
}

class _TacticsDialogState extends ConsumerState<_TacticsDialog> {
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final sheet = widget.session.sheetOf(widget.side);
    final tactics = widget.rules.tactics;
    final levels = {
      'pressing': sheet.pressing,
      'tempo': sheet.tempo,
      'defensive_line': sheet.defensiveLine,
    };

    void change({String? system, String? slider, int? level}) {
      widget.session.changeTactics(
        widget.side,
        systemId: system,
        pressing: slider == 'pressing' ? level : null,
        tempo: slider == 'tempo' ? level : null,
        defensiveLine: slider == 'defensive_line' ? level : null,
      );
      widget.onChanged();
      setState(() {});
    }

    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.lineupSystem, style: titleStyle),
        const SizedBox(height: 6),
        for (var i = 0; i < tactics.systems.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
            child: Row(
              children: [
                for (var j = i; j < i + 2; j++) ...[
                  if (j > i) const SizedBox(width: 8),
                  Expanded(
                    child: j < tactics.systems.length
                        ? _TacticOption(
                            key: ValueKey(
                              'match-system-${tactics.systems[j].id}',
                            ),
                            label: s.systemName(tactics.systems[j].id),
                            selected:
                                tactics.systems[j].id == sheet.systemId,
                            onTap: () {
                              final id = tactics.systems[j].id;
                              if (id != sheet.systemId) change(system: id);
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        for (final slider in tactics.sliders) ...[
          const SizedBox(height: Tokens.gapM),
          Text(s.sliderName(slider.id), style: titleStyle),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var l = 0; l < slider.levels.length; l++) ...[
                if (l > 0) const SizedBox(width: 8),
                Expanded(
                  child: _TacticOption(
                    key: ValueKey('match-slider-${slider.id}-$l'),
                    label: s.sliderLevelName(slider.id, l),
                    selected: levels[slider.id] == l,
                    onTap: () {
                      if (levels[slider.id] != l) {
                        change(slider: slider.id, level: l);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
    if (widget.asSheet) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Tokens.gapM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.matchTactics,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Tokens.gapS),
              content,
              const SizedBox(height: Tokens.gapM),
              FilledButton(
                key: const ValueKey('match-dialog-close'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(s.matchClose),
              ),
            ],
          ),
        ),
      );
    }
    return AlertDialog(
      title: Text(s.matchTactics),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: content,
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('match-dialog-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.matchClose),
        ),
      ],
    );
  }
}

/// The report after the final whistle.
class MatchReportPage extends ConsumerWidget {
  const MatchReportPage({
    required this.result,
    required this.own,
    this.knockout,
    super.key,
  });

  final MatchResult result;
  final OwnMatch own;

  /// Set for a cup tie: extra time and shoot-out.
  final KnockoutResult? knockout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final loaded = ref.watch(loadedWorldProvider).value;
    final game = ref.watch(seasonProvider);
    final career = ref.watch(careerProvider);
    final theme = Theme.of(context);
    if (loaded == null || game == null || career == null) {
      return ScreenFrame(
        title: s.matchReportTitle,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final home = own.fixture.home;
    final away = own.fixture.away;
    final ownHome = home == career.clubId;
    final mine = ownHome ? result.homeGoals : result.awayGoals;
    final theirs = ownHome ? result.awayGoals : result.homeGoals;
    String teamOf(int side) => _clubName(loaded, side == 0 ? home : away);

    final goals = [
      for (final e in result.events)
        if (e.isGoal) e,
    ];
    final cards = [
      for (final e in result.events)
        if (e.type == MatchEventType.yellowCard ||
            e.type == MatchEventType.secondYellow ||
            e.type == MatchEventType.redCard)
          e,
    ];
    final h = result.homeStats;
    final a = result.awayStats;
    final stats = [
      ('shots', h.shots, a.shots),
      ('shotsOnTarget', h.shotsOnTarget, a.shotsOnTarget),
      ('corners', h.corners, a.corners),
      ('freeKicks', h.freeKicks, a.freeKicks),
      ('yellow', h.yellowCards, a.yellowCards),
      ('red', h.redCards, a.redCards),
      ('subs', h.substitutions, a.substitutions),
    ];

    Widget head(String text) => Padding(
      padding: const EdgeInsets.only(top: Tokens.gapM, bottom: 4),
      child: Text(text, style: theme.textTheme.titleSmall),
    );

    return ScreenFrame(
      title: s.matchReportTitle,
      maxWidth: 800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isNarrow(context))
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final side in [0, 1]) ...[
                  if (side == 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${result.homeGoals} : ${result.awayGoals}',
                        key: const ValueKey('report-score'),
                        style: theme.textTheme.displaySmall,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        ClubCrest(
                          clubId: (side == 0 ? home : away).value,
                          size: 44,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teamOf(side),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ],
                InfoButton(message: s.infoMatchReport),
              ],
            )
          else
          Row(
            children: [
              ClubCrest(clubId: home.value, size: 40),
              const SizedBox(width: Tokens.gapS),
              Expanded(
                child: Text(
                  '${teamOf(0)}  ${result.homeGoals} : ${result.awayGoals}  '
                  '${teamOf(1)}',
                  key: const ValueKey('report-score'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: Tokens.gapS),
              ClubCrest(clubId: away.value, size: 40),
              InfoButton(message: s.infoMatchReport),
            ],
          ),
          const SizedBox(height: Tokens.gapS),
          Text(
            s.matchReportVerdict(mine, theirs),
            key: const ValueKey('report-verdict'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (knockout != null) ...[
            if (knockout!.extraTime || knockout!.decidedByShootout)
              Text(
                [
                  if (knockout!.extraTime) s.matchReportExtraTime,
                  if (knockout!.decidedByShootout)
                    s.matchReportShootout(
                      knockout!.shootoutHome!,
                      knockout!.shootoutAway!,
                    ),
                ].join(', '),
                key: const ValueKey('report-extra'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            Text(
              (knockout!.winnerSide == 0) == ownHome
                  ? s.matchReportThrough
                  : s.matchReportOut,
              key: const ValueKey('report-cup'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: Tokens.yellow),
            ),
          ],
          Expanded(
            child: ListView(
              children: [
                head(s.matchReportGoals),
                if (goals.isEmpty)
                  Text(
                    s.matchReportNoGoals,
                    key: const ValueKey('report-no-goals'),
                  )
                else
                  for (final e in goals)
                    Text(
                      "${e.clockLabel}'  ${_listName(loaded, e.player!)} "
                      '(${teamOf(e.side)}) ${e.homeGoals}:${e.awayGoals}',
                      overflow: TextOverflow.ellipsis,
                    ),
                if (cards.isNotEmpty) head(s.matchReportCards),
                for (final e in cards)
                  Text(
                    "${e.clockLabel}'  ${_listName(loaded, e.player!)} "
                    '(${teamOf(e.side)}) – ${s.matchCardLine(tickerKindOf(e)!)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                if (result.injuries.isNotEmpty) head(s.matchReportInjuries),
                for (final inj in result.injuries)
                  Text(
                    "${inj.minute}'  ${_listName(loaded, inj.player)} – "
                    '${s.matchInjuryLine(inj.days)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                head(s.matchReportStats),
                for (final row in stats)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(width: 40, child: Text('${row.$2}')),
                        Expanded(
                          child: Text(
                            s.matchStatName(row.$1),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text('${row.$3}', textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Tokens.gapS),
          Row(
            children: [
              TextButton(
                key: const ValueKey('report-table'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const StatsPage()),
                ),
                child: Text(s.matchReportToTable),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('report-office'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(s.matchReportToOffice),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
