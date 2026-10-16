import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
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
    if (leagues.isEmpty) {
      return Center(child: Text(s.confNoLeagues));
    }
    final league = leagues.contains(_selected) ? _selected! : leagues.first;
    final lines = [for (final m in widget.day.ofLeague(league)) _lineOf(m)];
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
    final standing = table.standing;

    String statusText(_Line l) => switch (l.status) {
      _Status.notStarted => s.confNotStarted,
      _Status.running => s.confRunning(l.minute),
      _Status.finished => s.confFinished,
    };

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
            for (final l in leagues)
              ChoiceChip(
                key: ValueKey('conf-tab-${l.value}'),
                label: Text(_leagueTitle(l)),
                selected: l == league,
                onSelected: (_) => setState(() => _selected = l),
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
                const SizedBox(height: Tokens.gapM),
                Text(s.confTable, style: theme.textTheme.titleMedium),
                const SizedBox(height: Tokens.gapS),
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

  TextStyle? _own(ThemeData theme, ClubId club) => club == widget.ownClub
      ? theme.textTheme.bodyMedium?.copyWith(
          color: Tokens.yellow,
          fontWeight: FontWeight.bold,
        )
      : theme.textTheme.bodyMedium;
}
