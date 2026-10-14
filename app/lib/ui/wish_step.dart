import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'step_buttons.dart';

/// Step 3: an optional wish club.
class WishStep extends ConsumerStatefulWidget {
  const WishStep({
    required this.loaded,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final LoadedWorld loaded;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  ConsumerState<WishStep> createState() => _WishStepState();
}

class _WishStepState extends ConsumerState<WishStep> {
  late League _league;

  List<League> get _leagues => [
    for (final ls in widget.loaded.world.leagueSeasons) ls.league,
  ];

  @override
  void initState() {
    super.initState();
    _league = _leagues.first;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final draft = ref.watch(careerDraftProvider);
    final loaded = widget.loaded;
    final clubs = loaded.clubsOf(_league);
    final wish = draft.wishClubId == null
        ? null
        : loaded.club(draft.wishClubId!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.wishHeading, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(s.wishHint, style: theme.textTheme.bodyMedium),
        const SizedBox(height: Tokens.gapM),
        Wrap(
          spacing: Tokens.gapS,
          runSpacing: Tokens.gapS,
          children: [
            for (final l in _leagues)
              ChoiceChip(
                key: ValueKey('wish-league-${l.id.value}'),
                label: Text(s.leagueName(l.name)),
                selected: l.id == _league.id,
                onSelected: (_) => setState(() => _league = l),
              ),
          ],
        ),
        const SizedBox(height: Tokens.gapM),
        Expanded(
          child: ListView(
            children: [
              for (final c in clubs)
                _ClubTile(
                  key: ValueKey('wish-club-${c.id.value}'),
                  club: c,
                  selected: c.id == draft.wishClubId,
                  onTap: () =>
                      ref.read(careerDraftProvider.notifier).setWish(c.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: Tokens.gapS),
        Row(
          children: [
            Expanded(
              child: Text(
                wish == null ? s.wishNone : s.wishChosen(wish.name),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: wish == null ? Tokens.text : Tokens.yellow,
                ),
              ),
            ),
            if (wish != null)
              TextButton(
                key: const ValueKey('wish-clear'),
                onPressed: () =>
                    ref.read(careerDraftProvider.notifier).setWish(null),
                child: Text(s.wishNone),
              ),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        StepButtons(
          backLabel: s.back,
          nextLabel: s.next,
          onBack: widget.onBack,
          onNext: widget.onNext,
        ),
      ],
    );
  }
}

class _ClubTile extends StatelessWidget {
  const _ClubTile({
    required this.club,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Club club;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
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
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.gapM,
              vertical: 8,
            ),
            child: Row(
              children: [
                ClubCrest(clubId: club.id.value, size: 36),
                const SizedBox(width: Tokens.gapM),
                Expanded(
                  child: Text(club.name, style: theme.textTheme.titleMedium),
                ),
                Text(club.place, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
