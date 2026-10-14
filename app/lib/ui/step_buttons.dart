import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The bottom row of a career start step: back on the left, next on the
/// right. A null [onNext] disables the button.
class StepButtons extends StatelessWidget {
  const StepButtons({
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final String? backLabel;
  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (backLabel != null)
          TextButton(onPressed: onBack, child: Text(backLabel!)),
        const Spacer(),
        FilledButton(
          key: const ValueKey('step-next'),
          onPressed: onNext,
          child: Text(nextLabel),
        ),
      ],
    );
  }
}
