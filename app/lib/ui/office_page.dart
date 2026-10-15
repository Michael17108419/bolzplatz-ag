import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/career.dart';
import '../game/desk.dart';
import '../game/lineup.dart';
import '../game/mail_state.dart';
import '../game/office.dart';
import '../game/office_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'info_button.dart';
import 'office_mail.dart';
import 'office_pages.dart';
import 'office_scene.dart';
import 'person_avatar.dart';
import 'screen_frame.dart';
import 'step_buttons.dart';

/// The home screen of a career: the office as a desk scene. Every thing on
/// the desk opens one screen, the door is "Weiter".
class OfficePage extends ConsumerWidget {
  const OfficePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final career = ref.watch(careerProvider);
    final view = ref.watch(officeViewProvider);
    return ScreenFrame(
      title: s.homeTitle,
      maxWidth: 1800,
      padding: const EdgeInsets.fromLTRB(
        Tokens.gapM,
        Tokens.gapS,
        Tokens.gapM,
        Tokens.gapM,
      ),
      extraBindings: deskBindings(context, ref),
      child: career == null || view == null
          ? const Center(child: CircularProgressIndicator())
          : _Office(career: career, view: view),
    );
  }
}

class _Office extends ConsumerWidget {
  const _Office({required this.career, required this.view});

  final Career career;
  final OfficeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final offer = career.offer;
    final read = ref.watch(mailReadProvider);
    final lineup = ref.watch(lineupProvider);
    final unread = officeMailIds.where((id) => !read.contains(id)).length;

    final labels = {
      for (final item in DeskItem.values)
        item: DeskLabel(
          title: item == DeskItem.door
              ? s.deskNext(view.matchday)
              : s.deskName(item),
          hint: item == DeskItem.press
              ? '${s.deskHint(item)}\n\n'
                    '„${s.officeMailSubjectNews(offer.situation)}“'
              : item == DeskItem.post && unread > 0
              ? '${s.deskHint(item)}\n\n${s.deskBadgePost(unread)}.'
              : s.deskHint(item),
          keyText: item.digit == null ? s.deskKeyDoor : s.deskKey(item.digit!),
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ClubCrest(clubId: offer.club.id.value, size: 40),
            const SizedBox(width: Tokens.gapM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.club.name,
                    key: const ValueKey('office-club'),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    '${offer.club.place} · ${s.leagueName(offer.league.name)} '
                    '· ${s.officeSeason(view.startYear)}',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            InfoButton(message: s.infoDesk),
            const SizedBox(width: Tokens.gapM),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                career.trainer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: Tokens.gapS),
            PersonAvatar(
              key: const ValueKey('office-trainer'),
              appearance: career.trainer.appearance,
              size: 40,
            ),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        Expanded(
          child: OfficeScene(
            clubId: offer.club.id.value,
            labels: labels,
            badges: {
              if (unread > 0) DeskItem.post: '$unread',
              if (lineup == null || !lineup.reviewed) DeskItem.tactics: '!',
            },
            onOpen: (item) => openDesk(context, ref, item),
            portrait: (size) =>
                PersonAvatar(appearance: career.trainer.appearance, size: size),
            leagueLabel: s.leagueName(offer.league.name),
          ),
        ),
        const SizedBox(height: Tokens.gapS),
        StepButtons(
          backLabel: s.officeToMenu,
          nextLabel: s.deskNext(view.matchday),
          onBack: () => Navigator.of(context).maybePop(),
          onNext: () => goNext(context, ref),
        ),
      ],
    );
  }
}
