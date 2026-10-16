import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'look_widgets.dart';
import 'step_buttons.dart';
import 'person_avatar.dart';

/// Step 2: glasses and clothes of the trainer.
class LookStep extends ConsumerWidget {
  const LookStep({
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
    final a = ref.watch(careerDraftProvider).appearance;
    final o = loaded.rules.career.appearanceOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AvatarSplit(
            loaded: loaded,
            heading: s.lookHeading,
            rows: [
              LookPicker(
                optionKey: 'glasses',
                labels: [
                  for (var i = 0; i < o['glasses']!; i++) s.glassesName(i),
                ],
                value: a.glasses,
                change: (a, i) => a.copyWith(glasses: i),
              ),
              LookPicker(
                optionKey: 'outfit',
                labels: [
                  for (var i = 0; i < o['outfit']!; i++) s.outfitName(i),
                ],
                value: a.outfit,
                change: (a, i) => a.copyWith(outfit: i),
              ),
              LookPicker(
                optionKey: 'outfit_colour',
                colors: PersonLooks.outfit,
                value: a.outfitColour,
                change: (a, i) => a.copyWith(outfitColour: i),
              ),
              if (const [4, 5, 7, 8].contains(a.outfit))
                LookPicker(
                  label: s.secondColourLabel(a.outfit),
                  optionKey: 'outfit_colour2',
                  colors: PersonLooks.outfit,
                  value: a.outfitColour2,
                  change: (a, i) => a.copyWith(outfitColour2: i),
                ),
            ],
          ),
        ),
        const SizedBox(height: Tokens.gapM),
        StepButtons(
          backLabel: s.back,
          nextLabel: s.next,
          onBack: onBack,
          onNext: onNext,
        ),
      ],
    );
  }
}
