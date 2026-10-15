import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/desk.dart';
import '../game/loaded_world.dart';
import '../game/stats.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'info_button.dart';
import 'office_pages.dart';
import 'player_page.dart';

const double _wPlace = 40;
const double _wNumber = 36;
const double _wGoals = 62;
const double _wDiff = 44;
const double _wPoints = 44;

/// Colour of the stripe in front of a table place.
Color zoneColor(TableZone zone) => switch (zone) {
  TableZone.none => Colors.transparent,
  TableZone.promotion => Tokens.green,
  TableZone.chance => Tokens.beige,
  TableZone.playoffUp => Tokens.yellow,
  TableZone.playoffDown => const Color(0xFFFFA84D),
  TableZone.relegation => Tokens.orange,
};

/// Tables of all leagues, the two cups and the scorer lists.
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  int _tab = 0;
  int? _leagueId;
  bool _assists = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final stats = ref.watch(seasonStatsProvider);
    return DeskFrame(
      item: DeskItem.stats,
      child: WithCareer(
        builder: (context, career, loaded, view) {
          if (stats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final tabs = [s.statsTabTables, s.statsTabCups, s.statsTabScorers];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        key: ValueKey('stats-tab-$i'),
                        label: Text(tabs[i]),
                        selected: _tab == i,
                        onSelected: (_) => setState(() => _tab = i),
                      ),
                    ),
                  InfoButton(message: s.infoStatsPage),
                ],
              ),
              const SizedBox(height: Tokens.gapS),
              Expanded(
                child: switch (_tab) {
                  0 => _TablesTab(
                    stats: stats,
                    loaded: loaded,
                    ownClub: career.clubId,
                    ownLeague: career.offer.league.id.value,
                    selected: _leagueId ?? career.offer.league.id.value,
                    onSelect: (id) => setState(() => _leagueId = id),
                  ),
                  1 => _CupsTab(stats: stats, loaded: loaded),
                  _ => _ScorersTab(
                    stats: stats,
                    loaded: loaded,
                    assists: _assists,
                    onMode: (a) => setState(() => _assists = a),
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- tables ---

class _TablesTab extends ConsumerWidget {
  const _TablesTab({
    required this.stats,
    required this.loaded,
    required this.ownClub,
    required this.ownLeague,
    required this.selected,
    required this.onSelect,
  });

  final SeasonStats stats;
  final LoadedWorld loaded;
  final ClubId ownClub;
  final int ownLeague;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final leagues = [
      ...stats.leagues.where((l) => l.id.value == ownLeague),
      ...stats.leagues.where((l) => l.id.value != ownLeague),
    ];
    final league = leagues.firstWhere(
      (l) => l.id.value == selected,
      orElse: () => leagues.first,
    );
    final rows = stats.tables[league.id] ?? const <TableEntry>[];
    final zones = [
      for (var i = 0; i < rows.length; i++)
        zoneOf(level: league.level, teamCount: rows.length, place: i + 1),
    ];
    final used = <TableZone>[
      for (final z in TableZone.values)
        if (z != TableZone.none && zones.contains(z)) z,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final l in leagues)
              ChoiceChip(
                key: ValueKey('stats-league-${l.id.value}'),
                avatar: l.id.value == ownLeague
                    ? const Icon(Icons.star, size: 14)
                    : null,
                label: Text(s.leagueName(l.name)),
                selected: l.id == league.id,
                onSelected: (_) => onSelect(l.id.value),
              ),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        _TableHeader(info: s.infoStatsColumns),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('stats-table'),
            itemCount: rows.length,
            itemBuilder: (context, i) => _TableTile(
              key: ValueKey('stats-row-${rows[i].club.value}'),
              place: i + 1,
              entry: rows[i],
              zone: zones[i],
              club: loaded.club(rows[i].club),
              own: rows[i].club == ownClub,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (stats.isForecast)
          Text(
            s.statsForecastNote,
            key: const ValueKey('stats-forecast'),
            style: theme.textTheme.bodySmall,
          ),
        if (used.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              key: const ValueKey('stats-legend'),
              spacing: Tokens.gapM,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final z in used)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, color: zoneColor(z)),
                      const SizedBox(width: 6),
                      Text(s.statsZoneName(z), style: theme.textTheme.bodySmall),
                    ],
                  ),
                InfoButton(message: s.infoStatsZones),
              ],
            ),
          ),
      ],
    );
  }
}

class _TableHeader extends ConsumerWidget {
  const _TableHeader({required this.info});

  final String info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: Tokens.beige);
    Widget cell(String text, double width) => SizedBox(
      width: width,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gapS),
      child: Row(
        children: [
          const SizedBox(width: 4 + 8),
          cell(s.statsColPlace, _wPlace),
          const SizedBox(width: 28),
          Expanded(child: Text(s.statsColClub, style: style)),
          cell(s.statsColPlayed, _wNumber),
          cell(s.statsColWon, _wNumber),
          cell(s.statsColDrawn, _wNumber),
          cell(s.statsColLost, _wNumber),
          cell(s.statsColGoals, _wGoals),
          cell(s.statsColDiff, _wDiff),
          cell(s.statsColPoints, _wPoints),
          InfoButton(message: info),
        ],
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({
    required this.place,
    required this.entry,
    required this.zone,
    required this.club,
    required this.own,
    super.key,
  });

  final int place;
  final TableEntry entry;
  final TableZone zone;
  final Club club;
  final bool own;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plain = theme.textTheme.bodyMedium;
    Widget cell(String text, double width, {TextStyle? style}) => SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: style ?? plain,
      ),
    );
    final diff = entry.goalDifference;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: own ? Tokens.yellow.withAlpha(46) : Tokens.panel,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: own ? Border.all(color: Tokens.yellow, width: 1) : null,
          ),
          padding: const EdgeInsets.fromLTRB(0, 4, Tokens.gapS, 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                margin: const EdgeInsets.only(right: 8),
                color: zoneColor(zone),
              ),
              cell('$place', _wPlace, style: theme.textTheme.titleSmall),
              ClubCrest(clubId: club.id.value, size: 24),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  club.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: own
                      ? theme.textTheme.titleSmall?.copyWith(
                          color: Tokens.yellow,
                        )
                      : theme.textTheme.titleSmall,
                ),
              ),
              cell('${entry.played}', _wNumber),
              cell('${entry.won}', _wNumber),
              cell('${entry.drawn}', _wNumber),
              cell('${entry.lost}', _wNumber),
              cell('${entry.goalsFor}:${entry.goalsAgainst}', _wGoals),
              cell(diff > 0 ? '+$diff' : '$diff', _wDiff),
              cell(
                '${entry.points}',
                _wPoints,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Tokens.yellow,
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// --- cups ---

class _CupsTab extends ConsumerWidget {
  const _CupsTab({required this.stats, required this.loaded});

  final SeasonStats stats;
  final LoadedWorld loaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final cups = loaded.rules.season.cups;
    final bolz = stats.bolzplatz;
    final fieldSize = cups.bolzplatzFieldSize;
    final bolzRounds = cups.bolzplatzAfterMatchday.length;
    final pottRounds = cups.pottAfterMatchday.length;
    final pottField = cups.pottBracketSize;

    Widget heading(String text, String info) => Row(
      children: [
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(color: Tokens.orange),
          ),
        ),
        InfoButton(message: info),
      ],
    );

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Tokens.gapM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading(s.statsCupBolzplatz, s.infoStatsCupBolzplatz),
                const SizedBox(height: Tokens.gapS),
                for (var i = 0; i < bolzRounds; i++)
                  _CupRound(
                    keyName: 'stats-bolz-round-$i',
                    name: s.statsCupRoundName(fieldSize >> i),
                    afterMatchday: cups.bolzplatzAfterMatchday[i],
                    ties: bolz != null && i < bolz.rounds.length
                        ? bolz.rounds[i]
                        : null,
                    loaded: loaded,
                  ),
                const SizedBox(height: 4),
                Text(
                  bolz?.winner != null
                      ? s.statsCupWinner(loaded.club(bolz!.winner!).name)
                      : s.statsCupNoWinner,
                  key: const ValueKey('stats-bolz-winner'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Tokens.yellow,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Tokens.gapS),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Tokens.gapM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading(s.statsCupPott, s.infoStatsCupPott),
                const SizedBox(height: 4),
                Text(
                  [
                    for (var i = 0; i < pottRounds; i++)
                      '${s.statsCupRoundName(pottField >> i)} '
                          '(${s.statsCupAfterMatchday(cups.pottAfterMatchday[i])})',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Tokens.gapS),
                for (final region in Region.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      key: ValueKey('stats-pott-${region.id}'),
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            s.regionName(region),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Tokens.beige,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            stats.pottWinners[region] != null
                                ? s.statsCupWinner(
                                    loaded.club(stats.pottWinners[region]!).name,
                                  )
                                : s.statsCupNoWinner,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
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
}

class _CupRound extends ConsumerWidget {
  const _CupRound({
    required this.keyName,
    required this.name,
    required this.afterMatchday,
    required this.ties,
    required this.loaded,
  });

  final String keyName;
  final String name;
  final int afterMatchday;
  final List<CupTie>? ties;
  final LoadedWorld loaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final head = Row(
      children: [
        Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
        Text(
          s.statsCupAfterMatchday(afterMatchday),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
    final played = ties;
    if (played == null) {
      return Padding(
        key: ValueKey(keyName),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            head,
            Text(s.statsCupNotDrawn, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey(keyName),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 8, bottom: 6),
        title: head,
        children: [
          for (final t in played)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      loaded.club(t.home).name,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: t.winner == t.home
                          ? theme.textTheme.titleSmall?.copyWith(
                              color: Tokens.yellow,
                            )
                          : theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–'),
                  ),
                  Expanded(
                    child: Text(
                      loaded.club(t.away).name,
                      overflow: TextOverflow.ellipsis,
                      style: t.winner == t.away
                          ? theme.textTheme.titleSmall?.copyWith(
                              color: Tokens.yellow,
                            )
                          : theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// --- scorers ---

class _ScorersTab extends ConsumerWidget {
  const _ScorersTab({
    required this.stats,
    required this.loaded,
    required this.assists,
    required this.onMode,
  });

  final SeasonStats stats;
  final LoadedWorld loaded;
  final bool assists;
  final ValueChanged<bool> onMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final rows = assists ? stats.assists : stats.goals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ChoiceChip(
              key: const ValueKey('stats-scorers-goals'),
              label: Text(s.statsGoals),
              selected: !assists,
              onSelected: (_) => onMode(false),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              key: const ValueKey('stats-scorers-assists'),
              label: Text(s.statsAssists),
              selected: assists,
              onSelected: (_) => onMode(true),
            ),
            InfoButton(message: s.infoStatsScorers),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    assists ? s.statsAssistsEmpty : s.statsScorersEmpty,
                    key: const ValueKey('stats-scorers-empty'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    final club = loaded.club(r.player.clubId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Material(
                        color: Tokens.panel,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          key: ValueKey('stats-scorer-${r.player.id.value}'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PlayerPage(playerId: r.player.id.value),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Tokens.gapS,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: _wPlace,
                                  child: Text(
                                    '${i + 1}',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                                ClubCrest(clubId: club.id.value, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.player.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      Text(
                                        club.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${r.count}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Tokens.yellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
