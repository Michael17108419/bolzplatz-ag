import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/settings.dart';
import '../theme/tokens.dart';

/// A small "i" that explains a term (hidden when the helps are off): the explanation appears when the mouse
/// rests on it and also on a click or tap (and stays long enough to read).
class InfoButton extends ConsumerWidget {
  const InfoButton({required this.message, this.size = 14, super.key});

  final String message;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(helpProvider)) return const SizedBox.shrink();
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: const Duration(milliseconds: 150),
      showDuration: const Duration(seconds: 8),
      preferBelow: false,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(Tokens.gapM),
      margin: const EdgeInsets.symmetric(horizontal: Tokens.gapM),
      decoration: BoxDecoration(
        color: Tokens.ground,
        borderRadius: BorderRadius.circular(Tokens.radius),
        border: Border.all(color: Tokens.yellow, width: 1.5),
      ),
      textStyle: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Tokens.text),
      child: MouseRegion(
        cursor: SystemMouseCursors.help,
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Tokens.yellow,
          ),
          child: Text(
            'i',
            style: TextStyle(
              fontFamily: Tokens.headlineFont,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.68,
              height: 1,
              color: Tokens.ink,
            ),
          ),
        ),
      ),
    );
  }
}
