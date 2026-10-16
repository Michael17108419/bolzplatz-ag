import 'package:flutter/material.dart';

/// The bottom row of a career start step: back on the left, next on the
/// right. A null [onNext] disables the button.
class StepButtons extends StatelessWidget {
  const StepButtons({
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    this.middle,
    super.key,
  });

  final String? backLabel;
  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  /// An extra widget left of the next button.
  final Widget? middle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (backLabel != null)
          Flexible(
            child: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(72, 48)),
              onPressed: onBack,
              child: Text(backLabel!, maxLines: 2, textAlign: TextAlign.center),
            ),
          ),
        const Spacer(),
        if (middle != null) ...[middle!, const SizedBox(width: 12)],
        Flexible(
          child: FilledButton(
            key: const ValueKey('step-next'),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: onNext,
            child: Text(nextLabel, maxLines: 2, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
