import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'info_button.dart';
import 'step_buttons.dart';

/// Step 2: choose one of the twelve backstories.
class BackstoryStep extends ConsumerWidget {
  const BackstoryStep({
    required this.loaded,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final LoadedWorld loaded;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final draft = ref.watch(careerDraftProvider);
    final stories = loaded.rules.career.backstories;
    final chosen = draft.backstoryId == null
        ? null
        : loaded.rules.career.backstory(draft.backstoryId!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(s.backstoryHeading, style: theme.textTheme.headlineSmall),
            InfoButton(message: s.infoBackstory),
          ],
        ),
        const SizedBox(height: Tokens.gapM),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: Tokens.gapS,
                  crossAxisSpacing: Tokens.gapS,
                  childAspectRatio: 4.2,
                  children: [
                    for (final b in stories)
                      _StoryCard(
                        key: ValueKey('story-${b.id}'),
                        label: s.backstoryName(b.id),
                        selected: b.id == draft.backstoryId,
                        onTap: () => ref
                            .read(careerDraftProvider.notifier)
                            .setBackstory(b.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Tokens.gapL),
              Expanded(
                flex: 4,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Tokens.gapL),
                    child: chosen == null
                        ? Center(
                            child: Text(
                              s.backstoryPick,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        : _StoryDetail(story: chosen),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Tokens.gapM),
        StepButtons(
          backLabel: s.back,
          nextLabel: s.next,
          onBack: onBack,
          onNext: chosen == null ? null : onNext,
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Tokens.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radius),
        side: BorderSide(
          color: selected ? Tokens.yellow : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Tokens.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gapM),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryDetail extends ConsumerWidget {
  const _StoryDetail({required this.story});

  final Backstory story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    return ListView(
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                s.backstoryName(story.id),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            InfoButton(message: s.backstoryPast(story.id)),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        Text(s.backstoryStrengths(story.id), style: theme.textTheme.bodyMedium),
        const SizedBox(height: Tokens.gapM),
        for (final v in ManagerValue.values)
          _LevelRow(
            label: s.managerValueName(v),
            level: story.levels[v]!,
            goodWhenHigh: v != ManagerValue.stress,
            levelText: s.levelName(story.levels[v]!),
            info: s.managerValueInfo(v),
          ),
        const SizedBox(height: Tokens.gapM),
        Row(
          children: [
            Text(
              s.hookLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Tokens.orange,
              ),
            ),
            InfoButton(message: s.hookInfo),
          ],
        ),
        const SizedBox(height: 4),
        Text(s.backstoryHook(story.hook), style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.label,
    required this.level,
    required this.goodWhenHigh,
    required this.levelText,
    required this.info,
  });

  final String label;
  final TraitLevel level;
  final bool goodWhenHigh;
  final String levelText;
  final String info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = level.index + 1;
    final high = level.index >= 2;
    final low = level.index == 0;
    final Color color;
    if (high) {
      color = goodWhenHigh ? Tokens.green : Tokens.orange;
    } else if (low) {
      color = goodWhenHigh ? Tokens.orange : Tokens.green;
    } else {
      color = Tokens.beige;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                InfoButton(message: info),
              ],
            ),
          ),
          for (var i = 0; i < 4; i++)
            Container(
              width: 14,
              height: 8,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i < filled ? color : Tokens.ground,
              ),
            ),
          SizedBox(
            width: 84,
            child: Text(
              levelText,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
