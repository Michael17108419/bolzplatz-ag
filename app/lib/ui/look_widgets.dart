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

/// One row of the looks pages: a label and the choice, on a single line.
class LookRow extends StatelessWidget {
  const LookRow({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.gapS),
      child: LayoutBuilder(
        builder: (context, box) {
          // Narrow cells (a phone) get a short label column.
          final labelWidth = box.maxWidth < 360 ? 92.0 : 150.0;
          return SizedBox(
            height: 52,
            child: Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: child),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A choice with arrows: `◀ Kurzhaar ▶`. Tapping an arrow shows the next or
/// previous value (after the last comes the first); the portrait changes at
/// once. Give [labels] for text values or [colors] for colour values.
class LookPicker extends ConsumerWidget {
  const LookPicker({
    this.label,
    required this.optionKey,
    this.labels,
    this.colors,
    required this.value,
    required this.change,
    super.key,
  }) : assert((labels == null) != (colors == null));

  /// Replaces the standard label of the option.
  final String? label;
  final String optionKey;
  final List<String>? labels;
  final List<Color>? colors;
  final int value;
  final TrainerAppearance Function(TrainerAppearance, int) change;

  int get _count => labels?.length ?? colors!.length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final a = ref.watch(careerDraftProvider).appearance;
    void go(int step) => ref
        .read(careerDraftProvider.notifier)
        .setAppearance(change(a, (value + step + _count) % _count));
    final Widget shown = labels != null
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              labels![value],
              key: ValueKey('$optionKey-value'),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        : Container(
            key: ValueKey('$optionKey-value'),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors![value],
              border: Border.all(color: Tokens.yellow, width: 3),
            ),
          );
    return LookRow(
      label: label ?? s.lookLabel(optionKey),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Row(
          children: [
            _ArrowButton(
              key: ValueKey('$optionKey-prev'),
              forward: false,
              onTap: () => go(-1),
            ),
            Expanded(child: Center(child: shown)),
            _ArrowButton(
              key: ValueKey('$optionKey-next'),
              forward: true,
              onTap: () => go(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.forward, required this.onTap, super.key});

  final bool forward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: CustomPaint(painter: _ArrowPainter(forward)),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.forward);

  final bool forward;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final d = forward ? 1.0 : -1.0;
    final path = Path()
      ..moveTo(c.dx - 6 * d, c.dy - 9)
      ..lineTo(c.dx + 7 * d, c.dy)
      ..lineTo(c.dx - 6 * d, c.dy + 9)
      ..close();
    canvas.drawPath(path, Paint()..color = Tokens.yellow);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.forward != forward;
}

/// The portrait and the choices: side by side on a wide screen, the portrait
/// above the choices on a phone held upright. All rows fit without scrolling
/// on a phone; the list only scrolls on very small screens or when the
/// keyboard is open. On a phone on its side the rows form two columns.
class AvatarSplit extends StatelessWidget {
  const AvatarSplit({
    required this.loaded,
    required this.heading,
    required this.rows,
    super.key,
  });

  final LoadedWorld loaded;
  final String heading;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final title = Padding(
      padding: const EdgeInsets.only(bottom: Tokens.gapS),
      child: Text(heading, style: Theme.of(context).textTheme.titleLarge),
    );
    if (isNarrow(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AvatarPanel(loaded: loaded),
          const SizedBox(height: Tokens.gapS),
          Expanded(child: ListView(children: [title, ...rows])),
        ],
      );
    }
    final side = MediaQuery.sizeOf(context).height < 500;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarPanel(loaded: loaded),
        const SizedBox(width: Tokens.gapL),
        Expanded(
          child: side
              ? ListView(
                  children: [
                    LayoutBuilder(
                      builder: (context, box) {
                        final w = (box.maxWidth - Tokens.gapL) / 2;
                        return Wrap(
                          spacing: Tokens.gapL,
                          children: [
                            for (final r in rows) SizedBox(width: w, child: r),
                          ],
                        );
                      },
                    ),
                  ],
                )
              : ListView(children: [title, ...rows]),
        ),
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
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: dice),
          ),
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
