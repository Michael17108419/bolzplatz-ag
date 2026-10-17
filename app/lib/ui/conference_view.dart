import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'adaptive.dart';
import 'crest.dart';
import 'info_button.dart';

enum _Status { notStarted, running, finished }

class _Line {
  const _Line(this.match, this.home, this.away, this.status, this.minute);

  final ConferenceMatch match;
  final int home;
  final int away;
  final _Status status;
  final int minute;
}

/// The conference of one day: all league matches that run now, with live
/// score and status, a tab per league that plays and the live table.
class ConferenceView extends StatefulWidget {
  const ConferenceView({
    required this.day,
    required this.run,
    required this.loaded,
    required this.strings,
    required this.ownLeague,
    required this.ownClub,
    required this.ownDone,
    super.key,
  });

  final ConferenceDay day;
  final SeasonRun run;
  final LoadedWorld loaded;
  final AppStrings strings;
  final LeagueId ownLeague;
  final ClubId ownClub;

  /// True once the own match is over: the whole day counts as finished.
  final bool ownDone;

  @override
  State<ConferenceView> createState() => _ConferenceViewState();
}

class _ConferenceViewState extends State<ConferenceView> {
  LeagueId? _selected;
  bool _cupTab = false;

  /// Phone: 0 live, 1 results, 2 table.
  int _tab = 0;

  int get _now {
    final own = widget.day.own;
    if (widget.ownDone || own == null) return 24 * 60;
    return own.minuteOfDay + own.session!.minute;
  }

  _Line _lineOf(ConferenceMatch m) {
    final session = m.session;
    if (session != null) {
      final status = widget.ownDone || session.isFinished
          ? _Status.finished
          : session.minute <= 0
          ? _Status.notStarted
          : _Status.running;
      return _Line(
        m,
        session.homeGoals,
        session.awayGoals,
        status,
        session.minute,
      );
    }
    final elapsed = _now - m.minuteOfDay;
    if (elapsed < 0) return _Line(m, 0, 0, _Status.notStarted, 0);
    final r = m.finalResult!;
    if (elapsed >= m.lengthMinutes) {
      return _Line(m, r.homeGoals, r.awayGoals, _Status.finished, elapsed);
    }
    final (h, a) = m.scoreAt(elapsed);
    return _Line(m, h, a, _Status.running, elapsed);
  }

  String _leagueTitle(LeagueId id) {
    final s = widget.strings;
    for (final ls in widget.loaded.world.leagueSeasons) {
      if (ls.league.id == id) return s.leagueName(ls.league.name);
    }
    return '';
  }

  String _clock() {
    final s = widget.strings;
    final d = widget.day.date;
    final minutes = _now >= 24 * 60 ? widget.day.kickoffs.last : _now;
    final hh = (minutes ~/ 60).toString().padLeft(2, '0');
    final mm = (minutes % 60).toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '${s.weekdayShort(d.weekday)} $dd.$mo.${d.year} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final theme = Theme.of(context);
    final leagues = [...widget.day.leagues];
    leagues.sort((a, b) {
      if (a == widget.ownLeague) return -1;
      if (b == widget.ownLeague) return 1;
      return a.value.compareTo(b.value);
    });
    final cupMatches = [
      for (final m in widget.day.matches)
        if (!m.isLeague) m,
    ];
    if (leagues.isEmpty && cupMatches.isEmpty) {
      return Center(child: Text(s.confNoLeagues));
    }
    // A day with only cup ties, or a cup tie of the own club, starts on the
    // cup tab.
    final ownIsCup = widget.day.own != null && !widget.day.own!.isLeague;
    final showCup =
        cupMatches.isNotEmpty &&
        (leagues.isEmpty || (_cupTab || (ownIsCup && _selected == null)));
    final league = showCup
        ? null
        : (leagues.contains(_selected) ? _selected! : leagues.first);
    final lines = showCup
        ? [for (final m in cupMatches) _lineOf(m)]
        : [for (final m in widget.day.ofLeague(league!)) _lineOf(m)];
    final standing = <TableEntry>[];
    if (league != null) {
      final table = widget.run.tables[league]!.copy();
      for (final l in lines) {
        if (l.status != _Status.notStarted) {
          table.record(
            l.match.fixture.home,
            l.match.fixture.away,
            l.home,
            l.away,
          );
        }
      }
      standing.addAll(table.standing);
    }

    String statusText(_Line l) => switch (l.status) {
      _Status.notStarted => s.confNotStarted,
      _Status.running => s.confRunning(l.minute),
      _Status.finished => s.confFinished,
    };

    if (isNarrow(context)) {
      return _phone(
        leagues: leagues,
        hasCup: cupMatches.isNotEmpty,
        showCup: showCup,
        league: league,
        lines: lines,
        standing: standing,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              _clock(),
              key: const ValueKey('conf-clock'),
              style: theme.textTheme.titleMedium,
            ),
            InfoButton(message: s.infoConference),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (cupMatches.isNotEmpty)
              ChoiceChip(
                key: const ValueKey('conf-tab-cup'),
                label: Text(s.confCupTab),
                selected: showCup,
                onSelected: (_) => setState(() => _cupTab = true),
              ),
            for (final l in leagues)
              ChoiceChip(
                key: ValueKey('conf-tab-${l.value}'),
                label: Text(_leagueTitle(l)),
                selected: l == league,
                onSelected: (_) => setState(() {
                  _selected = l;
                  _cupTab = false;
                }),
              ),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Tokens.panel,
              borderRadius: BorderRadius.circular(Tokens.radius),
            ),
            child: ListView(
              key: const ValueKey('conf-list'),
              padding: const EdgeInsets.all(Tokens.gapM),
              children: [
                for (final l in lines)
                  Padding(
                    key: ValueKey('conf-match-${l.match.fixture.home.value}'),
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.loaded.club(l.match.fixture.home).name,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: _own(theme, l.match.fixture.home),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            l.status == _Status.notStarted
                                ? '– : –'
                                : '${l.home} : ${l.away}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.loaded.club(l.match.fixture.away).name,
                            overflow: TextOverflow.ellipsis,
                            style: _own(theme, l.match.fixture.away),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: Text(
                            statusText(l),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Tokens.text.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (league != null) ...[
                  const SizedBox(height: Tokens.gapM),
                  Text(s.confTable, style: theme.textTheme.titleMedium),
                  const SizedBox(height: Tokens.gapS),
                ],
                for (var i = 0; i < standing.length; i++)
                  Padding(
                    key: ValueKey('conf-table-$i'),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(width: 28, child: Text('${i + 1}.')),
                        ClubCrest(clubId: standing[i].club.value, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.loaded.club(standing[i].club).name,
                            overflow: TextOverflow.ellipsis,
                            style: _own(theme, standing[i].club),
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text(
                            '${s.confPlayedShort} ${standing[i].played}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text(
                            '${s.confPointsShort} ${standing[i].points}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _kickoff(_Line l) {
    final m = l.match.minuteOfDay;
    return '${(m ~/ 60).toString().padLeft(2, '0')}:'
        '${(m % 60).toString().padLeft(2, '0')}';
  }

  /// Phone: league chips in one swipeable row, then three tabs: live games,
  /// results and the live table.
  Widget _phone({
    required List<LeagueId> leagues,
    required bool hasCup,
    required bool showCup,
    required LeagueId? league,
    required List<_Line> lines,
    required List<TableEntry> standing,
  }) {
    final s = widget.strings;
    final theme = Theme.of(context);

    Widget crestName(ClubId id, {required bool right}) {
      final name = Text(
        widget.loaded.club(id).name,
        maxLines: 2,
        textAlign: right ? TextAlign.start : TextAlign.end,
        overflow: TextOverflow.ellipsis,
        style: _own(theme, id),
      );
      final crest = ClubCrest(clubId: id.value, size: 26);
      return Expanded(
        child: Row(
          mainAxisAlignment: right
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: right
              ? [crest, const SizedBox(width: 6), Flexible(child: name)]
              : [Flexible(child: name), const SizedBox(width: 6), crest],
        ),
      );
    }

    Widget matchRow(_Line l, {required String note}) {
      final own =
          l.match.fixture.home == widget.ownClub ||
          l.match.fixture.away == widget.ownClub;
      return Container(
        key: ValueKey('conf-match-${l.match.fixture.home.value}'),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Tokens.ground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Tokens.radius),
          border: own ? Border.all(color: Tokens.yellow, width: 2) : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                crestName(l.match.fixture.home, right: false),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    l.status == _Status.notStarted
                        ? '– : –'
                        : '${l.home} : ${l.away}',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                crestName(l.match.fixture.away, right: true),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Tokens.text.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    final open = [
      for (final l in lines)
        if (l.status != _Status.finished) l,
    ];
    open.sort((a, b) {
      final ra = a.status == _Status.running ? 0 : 1;
      final rb = b.status == _Status.running ? 0 : 1;
      return ra != rb ? ra - rb : a.match.minuteOfDay - b.match.minuteOfDay;
    });
    final done = [
      for (final l in lines)
        if (l.status == _Status.finished) l,
    ];

    final Widget body;
    if (_tab == 0) {
      body = open.isEmpty
          ? Center(child: Text(s.confNoLive))
          : ListView(
              key: const ValueKey('conf-list'),
              padding: const EdgeInsets.all(Tokens.gapS),
              children: [
                for (final l in open)
                  matchRow(
                    l,
                    note: l.status == _Status.running
                        ? s.confRunning(l.minute)
                        : s.confKickoffAt(_kickoff(l)),
                  ),
              ],
            );
    } else if (_tab == 1) {
      body = done.isEmpty
          ? Center(child: Text(s.confNoResults))
          : ListView(
              key: const ValueKey('conf-list'),
              padding: const EdgeInsets.all(Tokens.gapS),
              children: [
                for (final l in done) matchRow(l, note: s.confFinished),
              ],
            );
    } else if (league == null) {
      body = Center(child: Text(s.confNoLive));
    } else {
      Widget cell(String t, double w, {bool bold = false}) => SizedBox(
        width: w,
        child: Text(
          t,
          textAlign: TextAlign.end,
          maxLines: 1,
          style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
      );
      body = ListView(
        key: const ValueKey('conf-list'),
        padding: const EdgeInsets.all(Tokens.gapS),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 34),
                const SizedBox(width: 30),
                const Expanded(child: SizedBox.shrink()),
                cell(s.confPlayedShort, 30),
                cell(s.confGoalsShort, 46),
                cell(s.confDiffShort, 38),
                cell(s.confPointsShort, 34, bold: true),
              ],
            ),
          ),
          for (var i = 0; i < standing.length; i++)
            Container(
              key: ValueKey('conf-table-$i'),
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(
                children: [
                  SizedBox(width: 34, child: Text('${i + 1}.')),
                  ClubCrest(clubId: standing[i].club.value, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.loaded.club(standing[i].club).name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _own(theme, standing[i].club),
                    ),
                  ),
                  cell('${standing[i].played}', 30),
                  cell(
                    '${standing[i].goalsFor}:${standing[i].goalsAgainst}',
                    46,
                  ),
                  cell('${standing[i].goalDifference}', 38),
                  cell('${standing[i].points}', 34, bold: true),
                ],
              ),
            ),
        ],
      );
    }

    Widget tabButton(int i, String label) => Expanded(
      child: InkWell(
        key: ValueKey('conf-subtab-$i'),
        onTap: () => setState(() => _tab = i),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _tab == i ? Tokens.yellow : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _tab == i ? Tokens.yellow : Tokens.text,
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              _clock(),
              key: const ValueKey('conf-clock'),
              style: theme.textTheme.titleSmall,
            ),
            InfoButton(message: s.infoConference),
          ],
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (hasCup)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: const ValueKey('conf-tab-cup'),
                    visualDensity: VisualDensity.compact,
                    label: Text(s.confCupTab),
                    selected: showCup,
                    onSelected: (_) => setState(() => _cupTab = true),
                  ),
                ),
              for (final l in leagues)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: ValueKey('conf-tab-${l.value}'),
                    visualDensity: VisualDensity.compact,
                    label: Text(_leagueTitle(l)),
                    selected: l == league,
                    onSelected: (_) => setState(() {
                      _selected = l;
                      _cupTab = false;
                    }),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            tabButton(0, s.confTabLive),
            tabButton(1, s.confTabResults),
            if (!showCup) tabButton(2, s.confTabTable),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Tokens.panel,
              borderRadius: BorderRadius.circular(Tokens.radius),
            ),
            child: body,
          ),
        ),
      ],
    );
  }

  TextStyle? _own(ThemeData theme, ClubId club) => club == widget.ownClub
      ? theme.textTheme.bodyMedium?.copyWith(
          color: Tokens.yellow,
          fontWeight: FontWeight.bold,
        )
      : theme.textTheme.bodyMedium;
}
