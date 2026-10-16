import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'adaptive.dart';
import 'person_avatar.dart';

/// One row of the looks pages: a label and the choices.
class LookRow extends StatelessWidget {
  const LookRow({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, style: Theme.of(context).textTheme.bodyLarge);
    // On a phone the label stands above its choices.
    if (isNarrow(context)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Tokens.gapM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [text, const SizedBox(height: Tokens.gapS), child],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.gapL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Padding(padding: const EdgeInsets.only(top: 8), child: text),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A row of text choices (one is selected).
class LookChips extends ConsumerWidget {
  const LookChips({
    required this.optionKey,
    required this.labels,
    required this.value,
    required this.change,
    super.key,
  });

  final String optionKey;
  final List<String> labels;
  final int value;
  final TrainerAppearance Function(TrainerAppearance, int) change;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final a = ref.watch(careerDraftProvider).appearance;
    return LookRow(
      label: s.lookLabel(optionKey),
      child: Wrap(
        spacing: Tokens.gapS,
        runSpacing: Tokens.gapS,
        children: [
          for (var i = 0; i < labels.length; i++)
            ChoiceChip(
              key: ValueKey('$optionKey-$i'),
              label: Text(labels[i]),
              selected: i == value,
              onSelected: (_) => ref
                  .read(careerDraftProvider.notifier)
                  .setAppearance(change(a, i)),
            ),
        ],
      ),
    );
  }
}

/// A row of colour choices (one is selected).
class LookSwatches extends ConsumerWidget {
  const LookSwatches({
    this.label,
    required this.optionKey,
    required this.colors,
    required this.value,
    required this.change,
    super.key,
  });

  /// Replaces the standard label of the option.
  final String? label;
  final String optionKey;
  final List<Color> colors;
  final int value;
  final TrainerAppearance Function(TrainerAppearance, int) change;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final a = ref.watch(careerDraftProvider).appearance;
    return LookRow(
      label: label ?? s.lookLabel(optionKey),
      child: Wrap(
        spacing: Tokens.gapS,
        runSpacing: Tokens.gapS,
        children: [
          for (var i = 0; i < colors.length; i++)
            _Swatch(
              key: ValueKey('$optionKey-$i'),
              color: colors[i],
              selected: i == value,
              onTap: () => ref
                  .read(careerDraftProvider.notifier)
                  .setAppearance(change(a, i)),
            ),
        ],
      ),
    );
  }
}

/// The portrait and the choices: side by side on a wide screen, the portrait
/// above the choices on a phone held upright.
class AvatarSplit extends StatelessWidget {
  const AvatarSplit({required this.loaded, required this.children, super.key});

  final LoadedWorld loaded;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final list = ListView(children: children);
    if (isNarrow(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AvatarPanel(loaded: loaded),
          const SizedBox(height: Tokens.gapM),
          Expanded(child: list),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarPanel(loaded: loaded),
        const SizedBox(width: Tokens.gapL),
        Expanded(child: list),
      ],
    );
  }
}

/// The portrait with the dice button, left of the choices.
class AvatarPanel extends ConsumerWidget {
  const AvatarPanel({required this.loaded, super.key});

  final LoadedWorld loaded;

  void _randomLook(WidgetRef ref) {
    final r = Random();
    final o = loaded.rules.career.appearanceOptions;
    final a = ref.read(careerDraftProvider).appearance;
    ref
        .read(careerDraftProvider.notifier)
        .setAppearance(
          TrainerAppearance(
            gender: a.gender,
            skin: r.nextInt(o['skin']!),
            hairStyle: r.nextInt(o['hair_style']!),
            hairColour: r.nextInt(o['hair_colour']!),
            beard: a.gender == 1 ? 0 : r.nextInt(o['beard']!),
            glasses: r.nextInt(o['glasses']!),
            outfit: r.nextInt(o['outfit']!),
            outfitColour: r.nextInt(o['outfit_colour']!),
            outfitColour2: r.nextInt(o['outfit_colour2']!),
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final a = ref.watch(careerDraftProvider).appearance;
    final dice = TextButton.icon(
      key: const ValueKey('random-look'),
      style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: () => _randomLook(ref),
      icon: const DiceIcon(),
      label: Text(s.trainerRandomLook),
    );
    // On a phone upright the portrait sits above the choices, small, with
    // the dice beside it.
    if (isNarrow(context)) {
      return Row(
        children: [
          PersonAvatar(appearance: a, size: 120),
          const SizedBox(width: Tokens.gapM),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: dice)),
        ],
      );
    }
    return SizedBox(
      width: 240,
      child: LayoutBuilder(
        builder: (context, box) {
          // On a phone on its side there is little height: shrink the portrait.
          final size = (box.maxHeight - 64).clamp(96.0, 220.0);
          return Column(
            children: [
              PersonAvatar(appearance: a, size: size),
              const SizedBox(height: Tokens.gapS),
              dice,
            ],
          );
        },
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? Tokens.yellow : Tokens.panel,
            width: 3,
          ),
        ),
      ),
    );
  }
}

/// A small die, drawn by hand (the icon font is not always available).
class DiceIcon extends StatelessWidget {
  const DiceIcon({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 24,
    height: 24,
    child: CustomPaint(painter: _DicePainter()),
  );
}

class _DicePainter extends CustomPainter {
  const _DicePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(box, Paint()..color = Tokens.yellow);
    final dot = Paint()..color = Tokens.ink;
    final r = size.width * 0.085;
    for (final p in const [
      Offset(0.28, 0.28),
      Offset(0.72, 0.28),
      Offset(0.5, 0.5),
      Offset(0.28, 0.72),
      Offset(0.72, 0.72),
    ]) {
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), r, dot);
    }
  }

  @override
  bool shouldRepaint(_DicePainter old) => false;
}
