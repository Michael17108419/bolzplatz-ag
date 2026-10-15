import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/desk.dart';
import '../game/loaded_world.dart';
import '../game/squad.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'info_button.dart';
import 'office_pages.dart';
import 'person_avatar.dart';
import 'player_look.dart';
import 'player_page.dart';
import 'player_widgets.dart';

const double _wPos = 52;
const double _wStrength = 92;
const double _wAge = 56;
const double _wContract = 84;
const double _wMedals = 62;

/// The squad of the own club: sortable and filterable, one click opens the
/// player profile.
class SquadPage extends ConsumerStatefulWidget {
  const SquadPage({super.key});

  @override
  ConsumerState<SquadPage> createState() => _SquadPageState();
}

class _SquadPageState extends ConsumerState<SquadPage> {
  SquadSort _sort = SquadSort.position;
  SquadFilter _filter = SquadFilter.all;
  bool _reversed = false;

  void _pick(SquadSort sort) => setState(() {
    if (_sort == sort) {
      _reversed = !_reversed;
    } else {
      _sort = sort;
      _reversed = false;
    }
  });

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return DeskFrame(
      item: DeskItem.files,
      child: WithCareer(
        builder: (context, career, loaded, view) {
          final all = squadOf(loaded, career.offer.club.id);
          final rows = arrangeSquad(
            all,
            sort: _sort,
            filter: _filter,
            reversed: _reversed,
          );
          final crestIndex = CrestSpec.forClub(career.offer.club.id.value)
              .color;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Toolbar(
                filter: _filter,
                count: rows.length,
                onFilter: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: Tokens.gapS),
              _HeaderRow(sort: _sort, reversed: _reversed, onSort: _pick),
              const SizedBox(height: 4),
              Expanded(
                child: rows.isEmpty
                    ? Center(
                        child: Text(
                          s.squadEmpty,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, i) => _SquadTile(
                          key: ValueKey('squad-${rows[i].player.id.value}'),
                          row: rows[i],
                          crestIndex: crestIndex,
                          today: loaded.today,
                          loaded: loaded,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.filter,
    required this.count,
    required this.onFilter,
  });

  final SquadFilter filter;
  final int count;
  final ValueChanged<SquadFilter> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in SquadFilter.values)
                ChoiceChip(
                  key: ValueKey('squad-filter-${f.name}'),
                  label: Text(s.squadFilterName(f)),
                  selected: f == filter,
                  onSelected: (_) => onFilter(f),
                ),
            ],
          ),
        ),
        Text(
          count == 0 ? s.squadCount0 : s.squadCount(count),
          key: const ValueKey('squad-count'),
          style: theme.textTheme.bodyMedium,
        ),
        InfoButton(message: s.infoSquadList),
      ],
    );
  }
}

class _HeaderRow extends ConsumerWidget {
  const _HeaderRow({
    required this.sort,
    required this.reversed,
    required this.onSort,
  });

  final SquadSort sort;
  final bool reversed;
  final ValueChanged<SquadSort> onSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    Widget cell(
      SquadSort key,
      String label, {
      double? width,
      String? info,
      Alignment align = Alignment.centerLeft,
    }) {
      final active = sort == key;
      final text = InkWell(
        key: ValueKey('squad-sort-${key.name}'),
        onTap: () => onSort(key),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: active ? Tokens.yellow : Tokens.beige),
                ),
              ),
              if (active) ...[
                const SizedBox(width: 4),
                SortCaret(up: reversed),
              ],
              if (info != null) InfoButton(message: info),
            ],
          ),
        ),
      );
      final aligned = Align(alignment: align, child: text);
      return width == null
          ? Expanded(child: aligned)
          : SizedBox(width: width, child: aligned);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gapS),
      child: Row(
        children: [
          const SizedBox(width: 48),
          cell(SquadSort.name, s.squadColName),
          cell(
            SquadSort.position,
            s.squadColPos,
            width: _wPos,
            info: s.infoSquadPos,
            align: Alignment.center,
          ),
          cell(
            SquadSort.strength,
            s.squadColStrength,
            width: _wStrength,
            info: s.infoSquadStrength,
            align: Alignment.center,
          ),
          cell(
            SquadSort.age,
            s.squadColAge,
            width: _wAge,
            align: Alignment.center,
          ),
          cell(
            SquadSort.contract,
            s.squadColContract,
            width: _wContract,
            info: s.infoSquadContract,
            align: Alignment.center,
          ),
          const SizedBox(width: _wMedals),
        ],
      ),
    );
  }
}

class _SquadTile extends ConsumerWidget {
  const _SquadTile({
    required this.row,
    required this.crestIndex,
    required this.today,
    required this.loaded,
    super.key,
  });

  final SquadRow row;
  final int crestIndex;
  final GameDate today;
  final LoadedWorld loaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final p = row.player;
    final look = PlayerLook.of(p, age: row.age, crestColour: crestIndex);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Tokens.panel,
        borderRadius: BorderRadius.circular(Tokens.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(Tokens.radius),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PlayerPage(playerId: p.id.value),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.gapS,
              vertical: 4,
            ),
            child: Row(
              children: [
                PersonAvatar(
                  appearance: look.appearance,
                  extras: look.extras,
                  size: 40,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        s.nationName(p.nationality),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: _wPos,
                  child: Center(child: PositionChip(p.position)),
                ),
                SizedBox(
                  width: _wStrength,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        row.overall.round().toString(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: valueColor(row.overall),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ValueBar(row.overall, height: 6),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: _wAge,
                  child: Center(
                    child: Text('${row.age}', style: theme.textTheme.bodyLarge),
                  ),
                ),
                SizedBox(
                  width: _wContract,
                  child: Center(
                    child: Text(
                      p.contract == null ? '–' : '${p.contract!.end.year}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                SizedBox(
                  width: _wMedals,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final a in p.abilities)
                        Tooltip(
                          message:
                              '${s.abilityName(a.type)} · '
                              '${s.abilityTierName(a.tier)}',
                          child: Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Medal(a.tier, size: 11),
                          ),
                        ),
                    ],
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
