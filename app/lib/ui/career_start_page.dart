import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'backstory_step.dart';
import 'look_step.dart';
import 'offers_step.dart';
import 'placeholder_page.dart';
import 'screen_frame.dart';
import 'trainer_step.dart';
import 'wish_step.dart';

/// The career start (document 16): trainer, backstory, wish club, offers.
class CareerStartPage extends ConsumerWidget {
  const CareerStartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final world = ref.watch(loadedWorldProvider);
    return ScreenFrame(
      title: s.careerTitle,
      maxWidth: 1100,
      child: world.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: Tokens.gapM),
              Text(s.careerLoading),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text(s.careerLoadFailed)),
        data: (loaded) => _CareerWizard(loaded: loaded),
      ),
    );
  }
}

class _CareerWizard extends ConsumerStatefulWidget {
  const _CareerWizard({required this.loaded});

  final LoadedWorld loaded;

  @override
  ConsumerState<_CareerWizard> createState() => _CareerWizardState();
}

class _CareerWizardState extends ConsumerState<_CareerWizard> {
  int _step = 0;

  void _go(int step) => setState(() => _step = step);

  void _accept(Trainer trainer, JobOffer offer) {
    ref.read(careerProvider.notifier).start(trainer: trainer, offer: offer);
    final s = ref.read(stringsProvider);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PlaceholderPage(title: s.homeTitle, step: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final loaded = widget.loaded;
    final titles = [
      s.careerStepTrainer,
      s.careerStepLook,
      s.careerStepBackstory,
      s.careerStepWish,
      s.careerStepOffers,
    ];
    final Widget body = switch (_step) {
      0 => TrainerStep(
        loaded: loaded,
        onBack: () => Navigator.of(context).maybePop(),
        onNext: () => _go(1),
      ),
      1 => LookStep(loaded: loaded, onBack: () => _go(0), onNext: () => _go(2)),
      2 => BackstoryStep(
        loaded: loaded,
        onBack: () => _go(1),
        onNext: () => _go(3),
      ),
      3 => WishStep(loaded: loaded, onBack: () => _go(2), onNext: () => _go(4)),
      _ => OffersStep(loaded: loaded, onBack: () => _go(3), onAccept: _accept),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepBar(titles: titles, current: _step),
        const SizedBox(height: Tokens.gapL),
        Expanded(child: body),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.titles, required this.current});

  final List<String> titles;
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < titles.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: Tokens.gapS),
                color: i <= current ? Tokens.yellow : Tokens.panel,
              ),
            ),
          Container(
            key: ValueKey('step-$i'),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= current ? Tokens.yellow : Tokens.panel,
            ),
            child: Text(
              '${i + 1}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: i <= current ? Tokens.ink : Tokens.text,
              ),
            ),
          ),
          const SizedBox(width: Tokens.gapS),
          Text(
            titles[i],
            style: theme.textTheme.bodyLarge?.copyWith(
              color: i == current ? Tokens.yellow : Tokens.text,
              fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
