import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'screen_frame.dart';

/// Stands in for a screen that a later building step delivers.
class PlaceholderPage extends ConsumerWidget {
  const PlaceholderPage({required this.title, required this.step, super.key});

  final String title;
  final int step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return ScreenFrame(
      title: title,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            s.comingInStep(step),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Tokens.gapL),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(s.back),
          ),
        ],
      ),
    );
  }
}
