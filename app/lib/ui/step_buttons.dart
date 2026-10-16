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
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(72, 48)),
            onPressed: onBack,
            child: Text(backLabel!, maxLines: 1, softWrap: false),
          ),
        // The rest of the row belongs to the next button; a long label
        // wraps instead of overflowing on a phone.
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (middle != null) ...[middle!, const SizedBox(width: 8)],
                Flexible(
                  child: FilledButton(
                    key: const ValueKey('step-next'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 48),
                    ),
                    onPressed: onNext,
                    child: Text(
                      nextLabel,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
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
