import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'step_buttons.dart';
import 'trainer_avatar.dart';

/// Step 1: name and looks of the trainer.
class TrainerStep extends ConsumerStatefulWidget {
  const TrainerStep({required this.loaded, required this.onNext, super.key});

  final LoadedWorld loaded;
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

  void _look(TrainerAppearance a) =>
      ref.read(careerDraftProvider.notifier).setAppearance(a);

  void _randomLook() {
    final r = Random();
    final o = widget.loaded.rules.career.appearanceOptions;
    _look(
      TrainerAppearance(
        skin: r.nextInt(o['skin']!),
        hairStyle: r.nextInt(o['hair_style']!),
        hairColour: r.nextInt(o['hair_colour']!),
        beard: r.nextInt(o['beard']!),
        glasses: r.nextInt(o['glasses']!),
        jacket: r.nextInt(o['jacket']!),
      ),
    );
  }

  void _next() {
    if (_name.text.trim().isEmpty) return;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final draft = ref.watch(careerDraftProvider);
    final a = draft.appearance;
    final o = widget.loaded.rules.career.appearanceOptions;

    Widget swatches(String key, List<Color> colors, int value, int count) {
      return _LookRow(
        label: s.lookLabel(key),
        child: Wrap(
          spacing: Tokens.gapS,
          runSpacing: Tokens.gapS,
          children: [
            for (var i = 0; i < count; i++)
              _Swatch(
                key: ValueKey('$key-$i'),
                color: colors[i],
                selected: i == value,
                onTap: () => _look(switch (key) {
                  'skin' => a.copyWith(skin: i),
                  'hair_colour' => a.copyWith(hairColour: i),
                  _ => a.copyWith(jacket: i),
                }),
              ),
          ],
        ),
      );
    }

    Widget chips(
      String key,
      List<String> labels,
      int value,
      TrainerAppearance Function(int) change,
    ) {
      return _LookRow(
        label: s.lookLabel(key),
        child: Wrap(
          spacing: Tokens.gapS,
          runSpacing: Tokens.gapS,
          children: [
            for (var i = 0; i < labels.length; i++)
              ChoiceChip(
                key: ValueKey('$key-$i'),
                label: Text(labels[i]),
                selected: i == value,
                onSelected: (_) => _look(change(i)),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 240,
                child: Column(
                  children: [
                    TrainerAvatar(appearance: a, size: 220),
                    const SizedBox(height: Tokens.gapM),
                    TextButton(
                      onPressed: _randomLook,
                      child: Text(s.trainerRandomLook),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Tokens.gapL),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      s.trainerHeading,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: Tokens.gapM),
                    TextField(
                      controller: _name,
                      autofocus: true,
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
                    swatches('skin', TrainerLooks.skin, a.skin, o['skin']!),
                    chips(
                      'hair_style',
                      [
                        for (var i = 0; i < o['hair_style']!; i++)
                          s.hairStyleName(i),
                      ],
                      a.hairStyle,
                      (i) => a.copyWith(hairStyle: i),
                    ),
                    swatches(
                      'hair_colour',
                      TrainerLooks.hair,
                      a.hairColour,
                      o['hair_colour']!,
                    ),
                    chips(
                      'beard',
                      [
                        for (var i = 0; i < o['beard']!; i++) s.beardName(i),
                      ],
                      a.beard,
                      (i) => a.copyWith(beard: i),
                    ),
                    chips(
                      'glasses',
                      [
                        for (var i = 0; i < o['glasses']!; i++)
                          s.glassesName(i),
                      ],
                      a.glasses,
                      (i) => a.copyWith(glasses: i),
                    ),
                    swatches(
                      'jacket',
                      TrainerLooks.jacket,
                      a.jacket,
                      o['jacket']!,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Tokens.gapM),
        StepButtons(
          backLabel: null,
          nextLabel: s.next,
          onBack: null,
          onNext: _name.text.trim().isEmpty ? null : _next,
        ),
      ],
    );
  }
}

class _LookRow extends StatelessWidget {
  const _LookRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.gapM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? Tokens.yellow : Tokens.panel,
            width: 3,
          ),
        ),
      ),
    );
  }
}
