import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/desk.dart';
import '../game/lineup.dart';
import '../game/season_game.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'adaptive.dart';
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

  void _openPicker(
    BuildContext context,
    LoadedWorld loaded,
    Map<PlayerId, Player> squad,
    Map<PlayerId, int> numbers,
    int crest,
    int slot,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Tokens.ground,
      builder: (sheet) => _SlotPicker(
        slotIndex: slot,
        loaded: loaded,
        squad: squad,
        numbers: numbers,
        crestColour: crest,
        onDone: () {
          Navigator.of(sheet).pop();
          setState(() => _slot = null);
        },
      ),
    );
  }

  void _openTactics(
    BuildContext context,
    LoadedWorld loaded,
    Map<PlayerId, Player> squad,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Tokens.ground,
      builder: (sheet) => Consumer(
        builder: (context, ref, _) {
          final lineup = ref.watch(lineupProvider);
          if (lineup == null) return const SizedBox.shrink();
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: SingleChildScrollView(
                key: const ValueKey('lineup-tactics-sheet'),
                padding: const EdgeInsets.all(Tokens.gapM),
                child: _TacticsTab(
                  loaded: loaded,
                  squad: squad,
                  lineup: lineup,
                  onFormation: () => setState(() => _slot = null),
                ),
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
          final phone = isNarrow(context);
          final absent = ref.watch(ownAbsencesProvider);
          final numbers = shirtNumbers(squad.values);
          final strengths = {
            for (final p in squad.values) p.id: loaded.overall(p),
          };
          final pitch = _Pitch(
            clubId: career.clubId.value,
            absent: absent,
            numbers: numbers,
            strengths: strengths,
            onFormationTap: () => _openTactics(context, loaded, squad),
            formation: formation,
            sheet: lineup.sheet,
            squad: squad,
            preview: preview,
            selected: _slot,
            crestColour: crest,
            today: loaded.today,
            onSelect: (i) {
              final lineup = ref.read(lineupProvider);
              if (_slot != null && _slot != i && lineup != null) {
                // Two players on the pitch: they swap places.
                final other = lineup.sheet.startingXi[i];
                final ok = ref
                    .read(lineupProvider.notifier)
                    .assign(_slot!, other);
                setState(() => _slot = null);
                if (!ok) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(s.lineupSwapKeeper)));
                }
                return;
              }
              setState(() {
                _slot = _slot == i ? null : i;
                if (_slot != null) _tab = 1;
              });
              if (phone && _slot != null) {
                _openPicker(context, loaded, squad, numbers, crest, i);
              }
            },
          );
          final side = _Side(
            phone: phone,
            strengths: strengths,
            absent: absent,
            numbers: numbers,
            places: benchPlaces(rules, career),
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
                  if (phone) ...[
                    _PhoneStrip(preview: preview),
                    const SizedBox(height: Tokens.gapS),
                  ],
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
    required this.clubId,
    required this.absent,
    required this.numbers,
    required this.strengths,
    required this.onFormationTap,
    required this.formation,
    required this.sheet,
    required this.squad,
    required this.preview,
    required this.selected,
    required this.crestColour,
    required this.today,
    required this.onSelect,
  });

  final int clubId;
  final Map<PlayerId, Absence> absent;
  final Map<PlayerId, int> numbers;
  final Map<PlayerId, double> strengths;
  final VoidCallback onFormationTap;
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
    final captain = captainOf(sheet, squad);
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
                  left: spots[i].dx * w - 40,
                  top: spots[i].dy * h - 38,
                  width: 80,
                  height: 84,
                  child: _SlotView(
                    key: ValueKey('slot-$i'),
                    player: squad[sheet.startingXi[i]]!,
                    absence: absent[sheet.startingXi[i]],
                    number: numbers[sheet.startingXi[i]],
                    strength: strengths[sheet.startingXi[i]] ?? 0,
                    slot: formation.slots[i],
                    fit: preview.slotFits[i],
                    selected: selected == i,
                    captain: captain == sheet.startingXi[i],
                    crestColour: crestColour,
                    today: today,
                    onTap: () => onSelect(i),
                  ),
                ),
              Positioned(
                right: 10,
                bottom: 8,
                child: GestureDetector(
                  key: const ValueKey('lineup-formation-button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onFormationTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formation.id,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: Tokens.text),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.tune, size: 18, color: Tokens.yellow),
                      const SizedBox(width: 8),
                      ClubCrest(clubId: clubId, size: 30),
                    ],
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

class _SlotView extends StatelessWidget {
  const _SlotView({
    required this.player,
    required this.absence,
    required this.number,
    required this.strength,
    required this.slot,
    required this.fit,
    required this.selected,
    required this.crestColour,
    required this.today,
    required this.onTap,
    this.captain = false,
    super.key,
  });

  final Player player;
  final Absence? absence;
  final int? number;
  final double strength;
  final Position slot;
  final double fit;
  final bool selected;
  final int crestColour;
  final GameDate today;
  final VoidCallback onTap;

  /// Wears the armband: a yellow "C" at the head.
  final bool captain;

  @override
  Widget build(BuildContext context) {
    final look = PlayerLook.of(
      player,
      age: player.ageOn(today),
      crestColour: crestColour,
    );
    final off = player.position != slot;
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
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Tokens.yellow : Tokens.ink,
                  ),
                  child: absence == null
                      ? PersonAvatar(
                          appearance: look.appearance,
                          extras: look.extras,
                          size: 44,
                        )
                      : ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            0.33, 0.33, 0.33, 0, 0, //
                            0.33, 0.33, 0.33, 0, 0,
                            0.33, 0.33, 0.33, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                          child: PersonAvatar(
                            appearance: look.appearance,
                            extras: look.extras,
                            size: 44,
                          ),
                        ),
                ),
                if (absence != null)
                  Positioned(
                    left: -8,
                    bottom: 0,
                    child: Container(
                      key: ValueKey('slot-absent-${player.id.value}'),
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD64545),
                        border: Border.all(color: Tokens.ink, width: 1.5),
                      ),
                      child: Icon(
                        absence == Absence.injured
                            ? Icons.add
                            : Icons.square_rounded,
                        size: absence == Absence.injured ? 16 : 10,
                        color: absence == Absence.injured
                            ? Colors.white
                            : Tokens.yellow,
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -5,
                  child: Center(
                    child: Container(
                      key: ValueKey('slot-pos-${player.id.value}'),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Tokens.ink,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: positionColor(slot),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        slot.id,
                        style: TextStyle(
                          fontFamily: Tokens.headlineFont,
                          fontSize: 10,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: positionColor(slot),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -10,
                  top: -4,
                  child: Container(
                    key: ValueKey('slot-strength-${player.id.value}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: valueColor(strength),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Tokens.ink, width: 1.5),
                    ),
                    child: Text(
                      strength.round().toString(),
                      style: const TextStyle(
                        fontFamily: Tokens.bodyFont,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Tokens.ink,
                      ),
                    ),
                  ),
                ),
                if (captain)
                  Positioned(
                    right: -8,
                    bottom: 8,
                    child: CaptainBadge(
                      key: ValueKey('slot-captain-${player.id.value}'),
                    ),
                  ),
                if (off)
                  Positioned(
                    left: -8,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Tokens.orange,
                        border: Border.all(color: Tokens.ink, width: 1.5),
                      ),
                      child: const Text(
                        '!',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: Tokens.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: const Color(0xB31A1300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                number == null ? player.lastName : '$number ${player.lastName}',
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1F5A36),
    );
    final centre = Offset(w / 2, h * 0.04);
    const rings = 9;
    for (var i = rings; i >= 1; i--) {
      canvas.drawCircle(
        centre,
        h * 1.05 * i / rings,
        Paint()
          ..color = i.isEven
              ? const Color(0xFF256238)
              : const Color(0xFF2A6B3E),
      );
    }
    final line = Paint()
      ..color = const Color(0x80F4EFE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
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
    required this.phone,
    required this.strengths,
    required this.absent,
    required this.numbers,
    required this.places,
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

  final bool phone;
  final Map<PlayerId, double> strengths;
  final Map<PlayerId, Absence> absent;
  final Map<PlayerId, int> numbers;
  final int places;
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
        if (absent.isNotEmpty &&
            [
              ...lineup.sheet.startingXi,
              ...lineup.sheet.bench,
            ].any(absent.containsKey))
          Padding(
            padding: const EdgeInsets.only(bottom: Tokens.gapS),
            child: Text(
              s.lineupAbsentWarning(
                [
                  ...lineup.sheet.startingXi,
                  ...lineup.sheet.bench,
                ].where(absent.containsKey).length,
              ),
              key: const ValueKey('lineup-absent-warning'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFFD64545),
              ),
            ),
          ),
        _BenchStrip(
          sheet: lineup.sheet,
          squad: squad,
          numbers: numbers,
          strengths: strengths,
          absent: absent,
          places: places,
          crestColour: crestColour,
          today: loaded.today,
        ),
        const SizedBox(height: Tokens.gapS),
        if (!phone) ...[
          _PreviewCard(
            preview: preview,
            sheet: lineup.sheet,
            squad: squad,
            places: places,
          ),
          const SizedBox(height: Tokens.gapS),
        ],
        Row(
          children: [
            Expanded(
              child: Text(s.lineupHint, style: theme.textTheme.bodySmall),
            ),
            InfoButton(message: s.infoLineupPitch),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        if (slot != null && !phone)
          _SlotCard(
            slotIndex: slot!,
            formation: formation,
            sheet: lineup.sheet,
            squad: squad,
            loaded: loaded,
          ),
        Row(
          children: [
            for (var i = 0; i < (phone ? 0 : 2); i++)
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
        if (phone)
          const SizedBox.shrink()
        else if (tab == 0)
          _TacticsTab(
            loaded: loaded,
            squad: squad,
            lineup: lineup,
            onFormation: onFormation,
          )
        else
          _SquadTab(
            numbers: numbers,
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
  const _PreviewCard({
    required this.preview,
    required this.sheet,
    required this.squad,
    required this.places,
  });

  final LineupPreview preview;
  final TeamSheet sheet;
  final Map<PlayerId, Player> squad;
  final int places;

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
            Text(
              s.lineupBenchCount(sheet.bench.length, places),
              key: const ValueKey('lineup-benchcount'),
              style: theme.textTheme.bodySmall?.copyWith(color: Tokens.beige),
            ),
            if (!sheet.bench.any((id) => squad[id]!.position.isGoalkeeper))
              Text(
                s.lineupNoBenchKeeper,
                key: const ValueKey('lineup-nobenchkeeper'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Tokens.orange,
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
    final named =
        sheet.captain != null && sheet.startingXi.contains(sheet.captain);
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
        head(s.lineupCaptain, s.infoLineupCaptain),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              key: const ValueKey('lineup-captain-auto'),
              label: Text(s.lineupCaptainAuto),
              selected: !named,
              onSelected: (_) => notifier.setCaptain(null),
            ),
            for (final p in eleven)
              ChoiceChip(
                key: ValueKey('lineup-captain-${p.id.value}'),
                label: Text(p.lastName),
                selected: named && sheet.captain == p.id,
                onSelected: (_) => notifier.setCaptain(p.id),
              ),
          ],
        ),
        if (!named && eleven.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              s.lineupCaptainAutoIs(_leader(eleven).lastName),
              style: theme.textTheme.bodySmall,
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

/// The player of [eleven] with the most leadership: the captain when the
/// manager names none (the match engine picks the same one).
Player _leader(List<Player> eleven) {
  var best = eleven.first;
  for (final p in eleven) {
    if ((p.traits[CharacterTrait.leadership] ?? 0) >
        (best.traits[CharacterTrait.leadership] ?? 0)) {
      best = p;
    }
  }
  return best;
}

/// Who wears the armband with [sheet]: the named captain if he starts,
/// else the leader of the eleven.
PlayerId? captainOf(TeamSheet sheet, Map<PlayerId, Player> squad) {
  final named = sheet.captain;
  if (named != null && sheet.startingXi.contains(named)) return named;
  final eleven = [
    for (final id in sheet.startingXi)
      if (squad[id] != null) squad[id]!,
  ];
  return eleven.isEmpty ? null : _leader(eleven).id;
}


class _SquadTab extends ConsumerWidget {
  const _SquadTab({
    required this.numbers,
    required this.loaded,
    required this.squad,
    required this.lineup,
    required this.formation,
    required this.crestColour,
    required this.slot,
    required this.onSlot,
  });

  final Map<PlayerId, int> numbers;
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
    final absent = ref.watch(ownAbsencesProvider);

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
      final reason = absent[p.id];
      // A player who is out can always be taken off the bench or the pitch;
      // he just cannot be put on.
      final already = xi.contains(p.id) || sheet.bench.contains(p.id);
      if (reason != null && (slot != null || !already)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(s.lineupAbsentBlocked(s.matchAbsence(reason))),
            ),
          );
        return;
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.lineupBenchFull(sheet.bench.length))),
        );
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
                              numbers[p.id] == null
                                  ? p.displayName
                                  : '${numbers[p.id]}  ${p.displayName}',
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
                              absent[p.id] != null
                                  ? s.matchAbsence(absent[p.id]!)
                                  : inXi
                                  ? s.lineupStartXi
                                  : onBench
                                  ? s.lineupBench
                                  : s.lineupStand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: absent[p.id] != null
                                    ? Tokens.orange
                                    : inXi
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

/// Phone: strength, role fit and system fit in one slim strip above the pitch.
class _PhoneStrip extends ConsumerWidget {
  const _PhoneStrip({required this.preview});

  final LineupPreview preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final roleFit = preview.roleFit * 100;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.gapM,
        vertical: Tokens.gapS,
      ),
      decoration: BoxDecoration(
        color: Tokens.panel,
        borderRadius: BorderRadius.circular(Tokens.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                preview.strength.round().toString(),
                key: const ValueKey('lineup-strength'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: valueColor(preview.strength),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.lineupStrength, style: theme.textTheme.bodySmall),
                    Text(
                      '${s.lineupRoleFit} ${roleFit.round()} %',
                      key: const ValueKey('lineup-rolefit'),
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      s.lineupSystemFitName(preview.systemFit),
                      key: const ValueKey('lineup-systemfit'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              InfoButton(message: s.infoLineupPreview),
            ],
          ),
          if (preview.outOfPosition > 0)
            Text(
              s.lineupOutOfPosition(preview.outOfPosition),
              key: const ValueKey('lineup-outofposition'),
              style: theme.textTheme.bodySmall?.copyWith(color: Tokens.orange),
            ),
        ],
      ),
    );
  }
}

/// The bench as a row of heads under the pitch, with free places.
class _BenchStrip extends ConsumerWidget {
  const _BenchStrip({
    required this.sheet,
    required this.squad,
    required this.numbers,
    required this.strengths,
    required this.absent,
    required this.places,
    required this.crestColour,
    required this.today,
  });

  final TeamSheet sheet;
  final Map<PlayerId, Player> squad;
  final Map<PlayerId, int> numbers;
  final Map<PlayerId, double> strengths;
  final Map<PlayerId, Absence> absent;
  final int places;
  final int crestColour;
  final GameDate today;

  void _openPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Tokens.ground,
      builder: (sheet) => _BenchPicker(
        squad: squad,
        numbers: numbers,
        strengths: strengths,
        places: places,
        crestColour: crestColour,
        today: today,
        onDone: () => Navigator.of(sheet).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final bench = sheet.bench;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${s.lineupBenchTitle} (${bench.length}/$places)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        SizedBox(
          key: const ValueKey('lineup-bench-strip'),
          height: 82,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < places; i++)
                if (i < bench.length && squad[bench[i]] != null)
                  _benchSlot(context, ref, squad[bench[i]]!)
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => _openPicker(context, ref),
                      child: SizedBox(
                        width: 56,
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Tokens.beige.withAlpha(120),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(Icons.add, color: Tokens.beige),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _benchSlot(BuildContext context, WidgetRef ref, Player p) {
    final look = PlayerLook.of(
      p,
      age: p.ageOn(today),
      crestColour: crestColour,
    );
    final out = absent[p.id];
    Widget avatar = PersonAvatar(
      appearance: look.appearance,
      extras: look.extras,
      size: 44,
    );
    if (out != null) {
      avatar = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: avatar,
      );
    }
    final strength = strengths[p.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        key: ValueKey('bench-${p.id.value}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _openPicker(context, ref),
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Tokens.ink,
                    ),
                    child: avatar,
                  ),
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: valueColor(strength),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Tokens.ink, width: 1.5),
                      ),
                      child: Text(
                        strength.round().toString(),
                        style: const TextStyle(
                          fontFamily: Tokens.bodyFont,
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Tokens.ink,
                        ),
                      ),
                    ),
                  ),
                  if (out != null)
                    Positioned(
                      left: -6,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFD64545),
                          border: Border.all(color: Tokens.ink, width: 1.5),
                        ),
                        child: Icon(
                          out == Absence.injured
                              ? Icons.add
                              : Icons.square_rounded,
                          size: out == Absence.injured ? 14 : 9,
                          color: out == Absence.injured
                              ? Colors.white
                              : Tokens.yellow,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                numbers[p.id] == null
                    ? p.lastName
                    : '${numbers[p.id]} ${p.lastName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sheet for one place on the pitch: the roles of the place and the
/// players who can play there, best fit first. One tap puts a player there
/// (a player of the eleven swaps places with him).
class _SlotPicker extends ConsumerStatefulWidget {
  const _SlotPicker({
    required this.slotIndex,
    required this.loaded,
    required this.squad,
    required this.numbers,
    required this.crestColour,
    required this.onDone,
  });

  final int slotIndex;
  final LoadedWorld loaded;
  final Map<PlayerId, Player> squad;
  final Map<PlayerId, int> numbers;
  final int crestColour;
  final VoidCallback onDone;

  @override
  ConsumerState<_SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends ConsumerState<_SlotPicker> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final lineup = ref.watch(lineupProvider);
    final absent = ref.watch(ownAbsencesProvider);
    if (lineup == null) return const SizedBox.shrink();
    final rules = widget.loaded.rules;
    final sheet = lineup.sheet;
    final formation = rules.tactics.formation(sheet.formationId);
    final target = formation.slots[widget.slotIndex];
    final fit = Fit(rules);
    final xi = sheet.startingXi;
    final notifier = ref.read(lineupProvider.notifier);
    final current = widget.squad[xi[widget.slotIndex]]!;

    final players =
        [
          for (final p in widget.squad.values)
            if (p.position.isGoalkeeper == target.isGoalkeeper &&
                (_all ||
                    p.id == current.id ||
                    fit.positionMultiplier(p, target) >= 0.9))
              p,
        ]..sort(
          (a, b) =>
              fit.slotScore(b, target).compareTo(fit.slotScore(a, target)),
        );

    void pick(Player p) {
      final reason = absent[p.id];
      if (reason != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(s.lineupAbsentBlocked(s.matchAbsence(reason))),
            ),
          );
        return;
      }
      notifier.assign(widget.slotIndex, p.id);
      widget.onDone();
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Tokens.gapM,
                Tokens.gapM,
                Tokens.gapM,
                0,
              ),
              child: Row(
                children: [
                  PositionChip(target),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${s.positionName(target)} · ${current.lastName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  ChoiceChip(
                    key: const ValueKey('picker-fit'),
                    label: Text(s.lineupPickerFit),
                    selected: !_all,
                    onSelected: (_) => setState(() => _all = false),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    key: const ValueKey('picker-all'),
                    label: Text(s.lineupPickerAll),
                    selected: _all,
                    onSelected: (_) => setState(() => _all = true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Tokens.gapM),
                children: [
                  _SlotCard(
                    slotIndex: widget.slotIndex,
                    formation: formation,
                    sheet: sheet,
                    squad: widget.squad,
                    loaded: widget.loaded,
                  ),
                  for (final p in players)
                    _pickRow(context, p, xi, sheet, absent, fit, target, pick),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickRow(
    BuildContext context,
    Player p,
    List<PlayerId> xi,
    TeamSheet sheet,
    Map<PlayerId, Absence> absent,
    Fit fit,
    Position target,
    void Function(Player) pick,
  ) {
    final s = ref.read(stringsProvider);
    final theme = Theme.of(context);
    final look = PlayerLook.of(
      p,
      age: p.ageOn(widget.loaded.today),
      crestColour: widget.crestColour,
    );
    final at = xi.indexOf(p.id);
    final isCurrent = at == widget.slotIndex;
    final formation = widget.loaded.rules.tactics.formation(sheet.formationId);
    final reason = absent[p.id];
    final value = fit.slotScore(p, target);
    final number = widget.numbers[p.id];
    final status = reason != null
        ? s.matchAbsence(reason)
        : isCurrent
        ? s.lineupPickerHere
        : at >= 0
        ? s.lineupPickerPlaysOn(formation.slots[at].id)
        : sheet.bench.contains(p.id)
        ? s.lineupBench
        : s.lineupStand;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isCurrent
            ? const Color(0xFF28503A)
            : at >= 0
            ? const Color(0xFF223F2F)
            : Tokens.panel,
        borderRadius: BorderRadius.circular(Tokens.radius),
        child: InkWell(
          key: ValueKey('pick-${p.id.value}'),
          borderRadius: BorderRadius.circular(Tokens.radius),
          onTap: isCurrent ? widget.onDone : () => pick(p),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
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
                          number == null
                              ? p.displayName
                              : '$number  ${p.displayName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: reason != null
                                ? const Color(0xFFD64545)
                                : at >= 0
                                ? Tokens.yellow
                                : Tokens.beige,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PositionChip(p.position),
                  SizedBox(
                    width: 44,
                    child: Text(
                      value.round().toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: valueColor(value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet for the bench: everybody who is not in the eleven, one tap puts
/// a player on the bench or takes him off. A player who is out can always be
/// taken off but not put on.
class _BenchPicker extends ConsumerWidget {
  const _BenchPicker({
    required this.squad,
    required this.numbers,
    required this.strengths,
    required this.places,
    required this.crestColour,
    required this.today,
    required this.onDone,
  });

  final Map<PlayerId, Player> squad;
  final Map<PlayerId, int> numbers;
  final Map<PlayerId, double> strengths;
  final int places;
  final int crestColour;
  final GameDate today;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final lineup = ref.watch(lineupProvider);
    final absent = ref.watch(ownAbsencesProvider);
    if (lineup == null) return const SizedBox.shrink();
    final sheet = lineup.sheet;
    final notifier = ref.read(lineupProvider.notifier);
    final players =
        [
          for (final p in squad.values)
            if (!sheet.startingXi.contains(p.id)) p,
        ]..sort((a, b) {
          final ab = sheet.bench.contains(a.id) ? 0 : 1;
          final bb = sheet.bench.contains(b.id) ? 0 : 1;
          if (ab != bb) return ab.compareTo(bb);
          return (strengths[b.id] ?? 0).compareTo(strengths[a.id] ?? 0);
        });
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Tokens.gapM),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${s.lineupBenchTitle} (${sheet.bench.length}/$places)',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  FilledButton(
                    key: const ValueKey('bench-done'),
                    onPressed: onDone,
                    child: Text(s.lineupBenchDone),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.gapM,
                  0,
                  Tokens.gapM,
                  Tokens.gapM,
                ),
                children: [
                  for (final p in players)
                    Builder(
                      builder: (context) {
                        final on = sheet.bench.contains(p.id);
                        final reason = absent[p.id];
                        final look = PlayerLook.of(
                          p,
                          age: p.ageOn(today),
                          crestColour: crestColour,
                        );
                        final strength = strengths[p.id] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Material(
                            color: on ? const Color(0xFF28503A) : Tokens.panel,
                            borderRadius: BorderRadius.circular(Tokens.radius),
                            child: InkWell(
                              key: ValueKey('benchpick-${p.id.value}'),
                              borderRadius: BorderRadius.circular(
                                Tokens.radius,
                              ),
                              onTap: () {
                                if (reason != null && !on) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          s.lineupAbsentBlocked(
                                            s.matchAbsence(reason),
                                          ),
                                        ),
                                      ),
                                    );
                                  return;
                                }
                                if (!notifier.toggleBench(p.id)) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          s.lineupBenchFull(sheet.bench.length),
                                        ),
                                      ),
                                    );
                                }
                              },
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 56,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              numbers[p.id] == null
                                                  ? p.displayName
                                                  : '${numbers[p.id]}  ${p.displayName}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall,
                                            ),
                                            Text(
                                              reason != null
                                                  ? s.matchAbsence(reason)
                                                  : on
                                                  ? s.lineupBench
                                                  : s.lineupStand,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: reason != null
                                                        ? const Color(
                                                            0xFFD64545,
                                                          )
                                                        : on
                                                        ? Tokens.green
                                                        : Tokens.beige,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PositionChip(p.position),
                                      SizedBox(
                                        width: 44,
                                        child: Text(
                                          strength.round().toString(),
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: valueColor(strength),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
