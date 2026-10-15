import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/desk.dart';
import '../game/lineup.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'info_button.dart';
import 'office_pages.dart';
import 'person_avatar.dart';
import 'player_look.dart';
import 'player_widgets.dart';

/// The rows of every formation on the pitch, back to front, each from left
/// to right. The numbers are slot indices of the formation.
const Map<String, List<List<int>>> _rows = {
  '4-4-2': [
    [0],
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10],
  ],
  '4-3-3': [
    [0],
    [1, 2, 3, 4],
    [5],
    [6, 7],
    [8, 9, 10],
  ],
  '4-2-3-1': [
    [0],
    [1, 2, 3, 4],
    [5, 6],
    [7, 8, 9],
    [10],
  ],
  '4-1-4-1': [
    [0],
    [1, 2, 3, 4],
    [5],
    [6, 7, 8, 9],
    [10],
  ],
  '4-3-1-2': [
    [0],
    [1, 2, 3, 4],
    [5],
    [6, 7],
    [8],
    [9, 10],
  ],
  '3-5-2': [
    [0],
    [1, 2, 3],
    [6],
    [4, 7, 8, 5],
    [9, 10],
  ],
  '3-4-3': [
    [0],
    [1, 2, 3],
    [4, 6, 7, 5],
    [8, 9, 10],
  ],
  '5-3-2': [
    [0],
    [1, 2, 3, 4, 5],
    [6, 7, 8],
    [9, 10],
  ],
  '5-4-1': [
    [0],
    [1, 2, 3, 4, 5],
    [6, 7, 8, 9],
    [10],
  ],
};

/// Where the slots of a formation stand on the pitch: x and y from 0 to 1,
/// y = 1 is the own goal line.
List<Offset> slotPositions(FormationRule formation) {
  final rows =
      _rows[formation.id] ??
      [
        [for (var i = 0; i < formation.slots.length; i++) i],
      ];
  final out = List<Offset>.filled(formation.slots.length, Offset.zero);
  for (var r = 0; r < rows.length; r++) {
    final y = rows.length == 1 ? 0.5 : 0.9 - r * (0.78 / (rows.length - 1));
    final row = rows[r];
    for (var i = 0; i < row.length; i++) {
      final n = row.length;
      final x = n == 1
          ? 0.5
          : n == 2
          ? (i == 0 ? 0.34 : 0.66)
          : 0.1 + 0.8 * i / (n - 1);
      out[row[i]] = Offset(x, y);
    }
  }
  return out;
}

/// The tactics board: formation, roles, bench and a preview of the team.
class LineupPage extends ConsumerStatefulWidget {
  const LineupPage({super.key});

  @override
  ConsumerState<LineupPage> createState() => _LineupPageState();
}

class _LineupPageState extends ConsumerState<LineupPage> {
  int? _slot;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lineup = ref.watch(lineupProvider);
    return DeskFrame(
      item: DeskItem.tactics,
      child: WithCareer(
        builder: (context, career, loaded, view) {
          if (lineup == null) {
            return Center(
              child: Text(
                s.lineupNoSheet,
                key: const ValueKey('lineup-none'),
                textAlign: TextAlign.center,
              ),
            );
          }
          final squad = clubPlayers(loaded, career.clubId);
          final rules = loaded.rules;
          final formation = rules.tactics.formation(lineup.sheet.formationId);
          final preview = previewLineup(lineup.sheet, squad, rules);
          final crest = CrestSpec.forClub(career.clubId.value).color;
          final pitch = _Pitch(
            formation: formation,
            sheet: lineup.sheet,
            squad: squad,
            preview: preview,
            selected: _slot,
            crestColour: crest,
            today: loaded.today,
            onSelect: (i) => setState(() {
              _slot = _slot == i ? null : i;
              if (_slot != null) _tab = 1;
            }),
          );
          final side = _Side(
            loaded: loaded,
            squad: squad,
            lineup: lineup,
            formation: formation,
            preview: preview,
            crestColour: crest,
            slot: _slot,
            tab: _tab,
            onTab: (t) => setState(() => _tab = t),
            onSlot: (i) => setState(() => _slot = i),
            onFormation: () => setState(() => _slot = null),
          );
          return LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: LayoutBuilder(
                        builder: (context, pc) {
                          final w = math.min(pc.maxWidth, pc.maxHeight * 0.8);
                          return Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: w,
                              height: w / 0.8,
                              child: pitch,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: Tokens.gapM),
                    Expanded(flex: 6, child: ListView(children: [side])),
                  ],
                );
              }
              final w = math.min(c.maxWidth, 520.0);
              return ListView(
                children: [
                  Center(
                    child: SizedBox(width: w, height: w / 0.8, child: pitch),
                  ),
                  const SizedBox(height: Tokens.gapM),
                  side,
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch({
    required this.formation,
    required this.sheet,
    required this.squad,
    required this.preview,
    required this.selected,
    required this.crestColour,
    required this.today,
    required this.onSelect,
  });

  final FormationRule formation;
  final TeamSheet sheet;
  final Map<PlayerId, Player> squad;
  final LineupPreview preview;
  final int? selected;
  final int crestColour;
  final GameDate today;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final spots = slotPositions(formation);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Tokens.radius),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: const ValueKey('lineup-pitch'),
                  painter: const _PitchPainter(),
                ),
              ),
              for (var i = 0; i < formation.slots.length; i++)
                Positioned(
                  left: spots[i].dx * w - 38,
                  top: spots[i].dy * h - 34,
                  width: 76,
                  height: 68,
                  child: _SlotView(
                    key: ValueKey('slot-$i'),
                    player: squad[sheet.startingXi[i]]!,
                    slot: formation.slots[i],
                    fit: preview.slotFits[i],
                    selected: selected == i,
                    crestColour: crestColour,
                    today: today,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SlotView extends StatelessWidget {
  const _SlotView({
    required this.player,
    required this.slot,
    required this.fit,
    required this.selected,
    required this.crestColour,
    required this.today,
    required this.onTap,
    super.key,
  });

  final Player player;
  final Position slot;
  final double fit;
  final bool selected;
  final int crestColour;
  final GameDate today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = PlayerLook.of(
      player,
      age: player.ageOn(today),
      crestColour: crestColour,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Tokens.yellow : Colors.transparent,
                  ),
                  child: PersonAvatar(
                    appearance: look.appearance,
                    extras: look.extras,
                    size: 38,
                  ),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: valueColor(fit * 100),
                      border: Border.all(color: Tokens.ink, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xB31A1300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                player.lastName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: Tokens.bodyFont,
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Tokens.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const stripes = 8;
    for (var i = 0; i < stripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, h / stripes * i, w, h / stripes + 1),
        Paint()
          ..color = i.isEven
              ? const Color(0xFF2A6B3E)
              : const Color(0xFF256238),
      );
    }
    final line = Paint()
      ..color = const Color(0xB3F4EFE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final m = w * 0.04;
    canvas.drawRect(Rect.fromLTRB(m, m, w - m, h - m), line);
    canvas.drawLine(Offset(m, h / 2), Offset(w - m, h / 2), line);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.12, line);
    // Penalty areas: own goal at the bottom, the other one at the top.
    final boxW = w * 0.54;
    final boxH = h * 0.15;
    canvas.drawRect(
      Rect.fromLTWH((w - boxW) / 2, h - m - boxH, boxW, boxH),
      line,
    );
    canvas.drawRect(Rect.fromLTWH((w - boxW) / 2, m, boxW, boxH), line);
    final sixW = w * 0.26;
    final sixH = h * 0.06;
    canvas.drawRect(
      Rect.fromLTWH((w - sixW) / 2, h - m - sixH, sixW, sixH),
      line,
    );
    canvas.drawRect(Rect.fromLTWH((w - sixW) / 2, m, sixW, sixH), line);
  }

  @override
  bool shouldRepaint(_PitchPainter old) => false;
}

class _Side extends ConsumerWidget {
  const _Side({
    required this.loaded,
    required this.squad,
    required this.lineup,
    required this.formation,
    required this.preview,
    required this.crestColour,
    required this.slot,
    required this.tab,
    required this.onTab,
    required this.onSlot,
    required this.onFormation,
  });

  final LoadedWorld loaded;
  final Map<PlayerId, Player> squad;
  final LineupState lineup;
  final FormationRule formation;
  final LineupPreview preview;
  final int crestColour;
  final int? slot;
  final int tab;
  final ValueChanged<int> onTab;
  final ValueChanged<int?> onSlot;
  final VoidCallback onFormation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final notifier = ref.read(lineupProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreviewCard(preview: preview, sheet: lineup.sheet),
        const SizedBox(height: Tokens.gapS),
        Row(
          children: [
            Expanded(
              child: Text(s.lineupHint, style: theme.textTheme.bodySmall),
            ),
            InfoButton(message: s.infoLineupPitch),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        if (slot != null)
          _SlotCard(
            slotIndex: slot!,
            formation: formation,
            sheet: lineup.sheet,
            squad: squad,
            loaded: loaded,
          ),
        Row(
          children: [
            for (var i = 0; i < 2; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: ValueKey('lineup-tab-$i'),
                  label: Text(i == 0 ? s.lineupTabTactics : s.lineupTabSquad),
                  selected: tab == i,
                  onSelected: (_) => onTab(i),
                ),
              ),
            const Spacer(),
            if (lineup.reviewed)
              Text(
                s.lineupConfirmed,
                key: const ValueKey('lineup-confirmed'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Tokens.green,
                ),
              )
            else
              FilledButton(
                key: const ValueKey('lineup-confirm'),
                onPressed: notifier.review,
                child: Text(s.lineupConfirm),
              ),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        if (tab == 0)
          _TacticsTab(
            loaded: loaded,
            squad: squad,
            lineup: lineup,
            onFormation: onFormation,
          )
        else
          _SquadTab(
            loaded: loaded,
            squad: squad,
            lineup: lineup,
            formation: formation,
            crestColour: crestColour,
            slot: slot,
            onSlot: onSlot,
          ),
      ],
    );
  }
}

class _PreviewCard extends ConsumerWidget {
  const _PreviewCard({required this.preview, required this.sheet});

  final LineupPreview preview;
  final TeamSheet sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    Widget line(String label, Widget value, {Widget? bar}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(flex: 4, child: bar ?? const SizedBox.shrink()),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
    final roleFit = preview.roleFit * 100;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.gapM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    s.lineupPreview,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                InfoButton(message: s.infoLineupPreview),
              ],
            ),
            line(
              s.lineupStrength,
              Text(
                preview.strength.round().toString(),
                key: const ValueKey('lineup-strength'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: valueColor(preview.strength),
                ),
              ),
              bar: ValueBar(preview.strength),
            ),
            line(
              s.lineupRoleFit,
              Text(
                '${roleFit.round()} %',
                key: const ValueKey('lineup-rolefit'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: valueColor(roleFit),
                ),
              ),
              bar: ValueBar(roleFit),
            ),
            line(
              s.lineupSystemFit,
              Text(
                s.lineupSystemFitName(preview.systemFit),
                key: const ValueKey('lineup-systemfit'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              s.lineupOutOfPosition(preview.outOfPosition),
              key: const ValueKey('lineup-outofposition'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: preview.outOfPosition == 0
                    ? Tokens.beige
                    : Tokens.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotCard extends ConsumerWidget {
  const _SlotCard({
    required this.slotIndex,
    required this.formation,
    required this.sheet,
    required this.squad,
    required this.loaded,
  });

  final int slotIndex;
  final FormationRule formation;
  final TeamSheet sheet;
  final Map<PlayerId, Player> squad;
  final LoadedWorld loaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final rules = loaded.rules;
    final slot = formation.slots[slotIndex];
    final player = squad[sheet.startingXi[slotIndex]]!;
    final fit = Fit(rules);
    final current = sheet.slotRoles[slotIndex];
    final roles = [
      for (final r in rules.tactics.roles)
        if (r.positions.contains(slot) &&
            !(r.onlyWithBackThreeOrFive && formation.backLine == 4))
          r,
    ];
    final notifier = ref.read(lineupProvider.notifier);
    return Card(
      key: const ValueKey('lineup-slotcard'),
      child: Padding(
        padding: const EdgeInsets.all(Tokens.gapM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PositionChip(slot),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                InfoButton(message: s.infoLineupSlot),
              ],
            ),
            if (player.position != slot)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  s.lineupOutOfPositionHint(
                    s.positionName(player.position),
                    s.positionName(slot),
                    (fit.positionMultiplier(player, slot) * 100).round(),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Tokens.orange,
                  ),
                ),
              ),
            const SizedBox(height: Tokens.gapS),
            Text(s.lineupSlotRole, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  key: const ValueKey('lineup-role-none'),
                  label: Text(s.lineupNoRole),
                  selected: current == null,
                  onSelected: (_) => notifier.setRole(slotIndex, null),
                ),
                for (final r in roles)
                  ChoiceChip(
                    key: ValueKey('lineup-role-${r.id}'),
                    label: Text(
                      '${s.roleName(r.id)} '
                      '${s.roleFamiliaritySymbol(player.roles[r.id] ?? RoleFamiliarity.basic)} · '
                      '${s.lineupRolePercent((fit.playerFit(player, slot, r.id) * 100).round())}',
                    ),
                    selected: current == r.id,
                    onSelected: (_) => notifier.setRole(slotIndex, r.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TacticsTab extends ConsumerWidget {
  const _TacticsTab({
    required this.loaded,
    required this.squad,
    required this.lineup,
    required this.onFormation,
  });

  final LoadedWorld loaded;
  final Map<PlayerId, Player> squad;
  final LineupState lineup;
  final VoidCallback onFormation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final tactics = loaded.rules.tactics;
    final sheet = lineup.sheet;
    final notifier = ref.read(lineupProvider.notifier);
    final eleven = [for (final id in sheet.startingXi) squad[id]!];
    final systemFit = SystemFit(loaded.rules);
    final levels = {
      'pressing': sheet.pressing,
      'tempo': sheet.tempo,
      'defensive_line': sheet.defensiveLine,
    };
    Widget head(String title, String info) => Padding(
      padding: const EdgeInsets.only(top: Tokens.gapS, bottom: 4),
      child: Row(
        children: [
          Flexible(child: Text(title, style: theme.textTheme.titleSmall)),
          InfoButton(message: info),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head(s.lineupFormation, s.infoLineupFormation),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final f in tactics.formations)
              ChoiceChip(
                key: ValueKey('lineup-formation-${f.id}'),
                label: Text(f.id),
                selected: f.id == sheet.formationId,
                onSelected: (_) {
                  notifier.setFormation(f.id);
                  onFormation();
                },
              ),
          ],
        ),
        head(s.lineupSystem, s.infoLineupSystem),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final sys in tactics.systems)
              ChoiceChip(
                key: ValueKey('lineup-system-${sys.id}'),
                label: Text(
                  '${s.systemName(sys.id)} · '
                  '${s.lineupSystemFitName(systemFit.fit(eleven, sys.id))}',
                ),
                selected: sys.id == sheet.systemId,
                onSelected: (_) => notifier.setSystem(sys.id),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            s.systemHint(sheet.systemId),
            style: theme.textTheme.bodySmall,
          ),
        ),
        head(s.lineupSliders, s.infoLineupSliders),
        for (final slider in tactics.sliders)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    s.sliderName(slider.id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (var l = 0; l < slider.levels.length; l++)
                  ChoiceChip(
                    key: ValueKey('lineup-slider-${slider.id}-$l'),
                    label: Text(s.sliderLevelName(slider.id, l)),
                    selected: levels[slider.id] == l,
                    onSelected: (_) => notifier.setSlider(slider.id, l),
                  ),
              ],
            ),
          ),
        const SizedBox(height: Tokens.gapM),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const ValueKey('lineup-auto'),
            onPressed: () {
              notifier.autoPick();
              onFormation();
            },
            child: Text(s.lineupAuto),
          ),
        ),
      ],
    );
  }
}

class _SquadTab extends ConsumerWidget {
  const _SquadTab({
    required this.loaded,
    required this.squad,
    required this.lineup,
    required this.formation,
    required this.crestColour,
    required this.slot,
    required this.onSlot,
  });

  final LoadedWorld loaded;
  final Map<PlayerId, Player> squad;
  final LineupState lineup;
  final FormationRule formation;
  final int crestColour;
  final int? slot;
  final ValueChanged<int?> onSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final sheet = lineup.sheet;
    final notifier = ref.read(lineupProvider.notifier);
    final fit = Fit(loaded.rules);
    final xi = sheet.startingXi;

    int order(Player p) {
      final x = xi.indexOf(p.id);
      if (x >= 0) return x;
      final b = sheet.bench.indexOf(p.id);
      if (b >= 0) return 100 + b;
      return 1000;
    }

    var players = squad.values.toList();
    if (slot != null) {
      final target = formation.slots[slot!];
      players =
          [
            for (final p in players)
              if (p.position.isGoalkeeper == target.isGoalkeeper) p,
          ]..sort(
            (a, b) =>
                fit.slotScore(b, target).compareTo(fit.slotScore(a, target)),
          );
    } else {
      players.sort((a, b) {
        final c = order(a).compareTo(order(b));
        return c != 0 ? c : loaded.overall(b).compareTo(loaded.overall(a));
      });
    }

    void tap(Player p) {
      if (slot != null) {
        notifier.assign(slot!, p.id);
        onSlot(null);
        return;
      }
      final at = xi.indexOf(p.id);
      if (at >= 0) {
        onSlot(at);
        return;
      }
      if (!notifier.toggleBench(p.id)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.lineupBenchFull(sheet.bench.length))));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in players)
          Builder(
            builder: (context) {
              final look = PlayerLook.of(
                p,
                age: p.ageOn(loaded.today),
                crestColour: crestColour,
              );
              final inXi = xi.contains(p.id);
              final onBench = sheet.bench.contains(p.id);
              final value = slot == null
                  ? loaded.overall(p)
                  : fit.slotScore(p, formation.slots[slot!]);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: inXi ? const Color(0xFF28503A) : Tokens.panel,
                  borderRadius: BorderRadius.circular(Tokens.radius),
                  child: InkWell(
                    key: ValueKey('lineup-player-${p.id.value}'),
                    borderRadius: BorderRadius.circular(Tokens.radius),
                    onTap: () => tap(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Tokens.gapS,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          PersonAvatar(
                            appearance: look.appearance,
                            extras: look.extras,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          PositionChip(p.position),
                          SizedBox(
                            width: 40,
                            child: Text(
                              value.round().toString(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: valueColor(value),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 76,
                            child: Text(
                              inXi
                                  ? s.lineupStartXi
                                  : onBench
                                  ? s.lineupBench
                                  : s.lineupStand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: inXi
                                    ? Tokens.yellow
                                    : onBench
                                    ? Tokens.green
                                    : Tokens.beige,
                              ),
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
      ],
    );
  }
}
