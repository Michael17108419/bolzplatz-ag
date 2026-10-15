import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'info_button.dart';
import 'person_avatar.dart';
import 'president_look.dart';

/// Step 4: the random job offers; the player takes one.
class OffersStep extends ConsumerStatefulWidget {
  const OffersStep({
    required this.loaded,
    required this.onBack,
    required this.onAccept,
    super.key,
  });

  final LoadedWorld loaded;
  final VoidCallback onBack;
  final void Function(Trainer trainer, JobOffer offer) onAccept;

  @override
  ConsumerState<OffersStep> createState() => _OffersStepState();
}

class _OffersStepState extends ConsumerState<OffersStep> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final draft = ref.watch(careerDraftProvider);
    final loaded = widget.loaded;
    final trainer = TrainerFactory.create(
      rules: loaded.rules,
      name: draft.name,
      appearance: draft.appearance,
      backstoryId: draft.backstoryId!,
      seed: draft.seed,
    );
    final set = loaded.offerGenerator.generate(
      trainer: trainer,
      seed: draft.seed,
      wishClubId: draft.wishClubId,
    );
    final wish = set.wish;
    String? notice;
    if (wish != null) {
      notice = wish.offered
          ? s.offersWishOffered(wish.club.name)
          : s.offersWishMissing(
              wish.club.name,
              s.levelName(wish.requiredLevel!),
            );
    }
    final offers = set.offers;
    final selected = _selected == null ? null : offers[_selected!];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.offersHeading, style: theme.textTheme.headlineSmall),
        if (notice != null) ...[
          const SizedBox(height: 4),
          Text(
            notice,
            key: const ValueKey('offers-notice'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: wish!.offered ? Tokens.green : Tokens.orange,
            ),
          ),
        ],
        const SizedBox(height: Tokens.gapM),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: ListView(
                  children: [
                    for (var i = 0; i < offers.length; i++)
                      _OfferTile(
                        key: ValueKey('offer-$i'),
                        offer: offers[i],
                        selected: i == _selected,
                        onTap: () => setState(() => _selected = i),
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
                    child: selected == null
                        ? Center(
                            child: Text(
                              s.offerNoneChosen,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        : _OfferDetail(offer: selected),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Tokens.gapM),
        Row(
          children: [
            TextButton(onPressed: widget.onBack, child: Text(s.back)),
            const Spacer(),
            FilledButton(
              key: const ValueKey('offer-accept'),
              onPressed: selected == null
                  ? null
                  : () => widget.onAccept(trainer, selected),
              child: Text(s.offerAccept),
            ),
          ],
        ),
      ],
    );
  }
}

class _OfferTile extends ConsumerWidget {
  const _OfferTile({
    required this.offer,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final JobOffer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.gapS),
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
            padding: const EdgeInsets.all(Tokens.gapM),
            child: Row(
              children: [
                ClubCrest(clubId: offer.club.id.value, size: 52),
                const SizedBox(width: Tokens.gapM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.club.name, style: theme.textTheme.titleMedium),
                      Text(
                        '${offer.club.place} · '
                        '${s.leagueName(offer.league.name)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.situationName(offer.situation),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Tokens.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferDetail extends ConsumerWidget {
  const _OfferDetail({required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final total = offer.league.teamCount;
    // The two most extreme president traits, described in words.
    final traits = PresidentTrait.values.toList()
      ..sort(
        (a, b) => (offer.president[b] - 50).abs().compareTo(
          (offer.president[a] - 50).abs(),
        ),
      );
    final words = [
      for (final t in traits.take(2))
        s.presidentTraitWord(t, offer.president[t] >= 50),
    ];
    final look = PresidentLook.of(offer.president);
    Widget row(String label, String value, {String? info}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Tokens.orange,
                  ),
                ),
                if (info != null) InfoButton(message: info),
              ],
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
    return ListView(
      children: [
        Text(offer.club.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: Tokens.gapM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PersonAvatar(
              key: const ValueKey('president-portrait'),
              appearance: look.appearance,
              extras: look.extras,
              size: 104,
            ),
            const SizedBox(width: Tokens.gapM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s.offerPresident,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Tokens.orange,
                        ),
                      ),
                      InfoButton(message: s.infoPresident),
                    ],
                  ),
                  Text(
                    offer.president.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    s.presidentTypeName(offer.president.typeId),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Tokens.yellow,
                    ),
                  ),
                  Text(words.join(', '), style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Tokens.gapM),
        row(
          s.offerSituation,
          s.situationName(offer.situation),
          info: s.infoSituation,
        ),
        row(s.offerGoal, s.seasonGoalText(offer.goal), info: s.infoGoal),
        row(s.offerBudget, s.money(offer.budget), info: s.infoBudget),
        row(
          s.offerLastSeason,
          s.lastSeasonRank(offer.lastSeasonRank),
          info: s.infoLastSeason,
        ),
        row(
          s.offerSquad,
          s.squadText(
            offer.strength.toStringAsFixed(1),
            offer.strengthRank,
            total,
          ),
          info: s.infoSquad,
        ),
        row(
          s.offerQuirk,
          s.quirkName(offer.quirk),
          info: s.infoQuirkKind(offer.quirk),
        ),
      ],
    );
  }
}
