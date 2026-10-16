import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'adaptive.dart';
import 'look_widgets.dart';
import 'step_buttons.dart';
import 'person_avatar.dart';

/// Step 1: name, gender, skin, hair and beard of the trainer.
class TrainerStep extends ConsumerStatefulWidget {
  const TrainerStep({
    required this.loaded,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final LoadedWorld loaded;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  ConsumerState<TrainerStep> createState() => _TrainerStepState();
}

class _TrainerStepState extends ConsumerState<TrainerStep> {
  late final TextEditingController _name = TextEditingController(
    text: ref.read(careerDraftProvider).name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_name.text.trim().isEmpty) return;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final a = ref.watch(careerDraftProvider).appearance;
    final o = widget.loaded.rules.career.appearanceOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AvatarSplit(
            loaded: widget.loaded,
            children: [
                    Text(
                      s.trainerHeading,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: Tokens.gapM),
                    TextField(
                      controller: _name,
                      autofocus: !isNarrow(context),
                      onChanged: (v) {
                        ref.read(careerDraftProvider.notifier).setName(v);
                        setState(() {});
                      },
                      onSubmitted: (_) => _next(),
                      decoration: InputDecoration(
                        labelText: s.trainerNameLabel,
                        filled: true,
                        fillColor: Tokens.panel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Tokens.radius),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: Tokens.gapL),
                    LookChips(
                      optionKey: 'gender',
                      labels: [
                        for (var i = 0; i < o['gender']!; i++) s.genderName(i),
                      ],
                      value: a.gender,
                      change: (a, i) =>
                          a.copyWith(gender: i, beard: i == 1 ? 0 : a.beard),
                    ),
                    LookSwatches(
                      optionKey: 'skin',
                      colors: PersonLooks.skin,
                      value: a.skin,
                      change: (a, i) => a.copyWith(skin: i),
                    ),
                    LookChips(
                      optionKey: 'hair_style',
                      labels: [
                        for (var i = 0; i < o['hair_style']!; i++)
                          s.hairStyleName(i),
                      ],
                      value: a.hairStyle,
                      change: (a, i) => a.copyWith(hairStyle: i),
                    ),
                    LookSwatches(
                      optionKey: 'hair_colour',
                      colors: PersonLooks.hair,
                      value: a.hairColour,
                      change: (a, i) => a.copyWith(hairColour: i),
                    ),
                    if (a.gender != 1)
                      LookChips(
                        optionKey: 'beard',
                        labels: [
                          for (var i = 0; i < o['beard']!; i++) s.beardName(i),
                        ],
                        value: a.beard,
                        change: (a, i) => a.copyWith(beard: i),
                      ),
            ],
          ),
        ),
        const SizedBox(height: Tokens.gapM),
        StepButtons(
          backLabel: s.back,
          nextLabel: s.next,
          onBack: widget.onBack,
          onNext: _name.text.trim().isEmpty ? null : _next,
        ),
      ],
    );
  }
}
