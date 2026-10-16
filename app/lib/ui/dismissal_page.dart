import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../game/season_game.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'career_start_page.dart';
import 'info_button.dart';
import 'screen_frame.dart';

/// The end of the job: the president lets the manager go. The player can
/// look for a new club with the same trainer.
class DismissalPage extends ConsumerWidget {
  const DismissalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final career = ref.watch(careerProvider);
    final end = ref.watch(seasonProvider.select((g) => g?.end));
    if (career == null || end == null) return const SizedBox.shrink();
    return ScreenFrame(
      title: s.dismissTitle,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.dismissTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  InfoButton(message: s.infoDismiss),
                ],
              ),
              const SizedBox(height: Tokens.gapM),
              Text(
                s.dismissBody(
                  career.offer.club.name,
                  end.startYear,
                  end.rank,
                  end.teams,
                ),
                key: const ValueKey('dismiss-text'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: Tokens.gapL),
              FilledButton(
                key: const ValueKey('dismiss-search'),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  ref.read(seasonProvider.notifier).startJobSearch();
                  await ref.read(loadedWorldProvider.future);
                  await navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CareerStartPage(jobSearch: true),
                    ),
                  );
                },
                child: Text(s.dismissSearch),
              ),
              const SizedBox(height: Tokens.gapS),
              TextButton(
                key: const ValueKey('dismiss-menu'),
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(s.dismissMenu),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
