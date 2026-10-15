import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../game/office.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'info_button.dart';
import 'person_avatar.dart';
import 'placeholder_page.dart';
import 'president_look.dart';
import 'screen_frame.dart';
import 'step_buttons.dart';

/// The home screen of a career: next match, table, cash, mail, and the button
/// that leads to the match day.
class OfficePage extends ConsumerWidget {
  const OfficePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final career = ref.watch(careerProvider);
    final loaded = ref.watch(loadedWorldProvider).value;
    return ScreenFrame(
      title: s.homeTitle,
      maxWidth: 1100,
      child: career == null || loaded == null
          ? const Center(child: CircularProgressIndicator())
          : _Office(career: career, loaded: loaded),
    );
  }
}

class _Office extends ConsumerStatefulWidget {
  const _Office({required this.career, required this.loaded});

  final Career career;
  final LoadedWorld loaded;

  @override
  ConsumerState<_Office> createState() => _OfficeState();
}

class _Mail {
  const _Mail({
    required this.id,
    required this.sender,
    required this.subject,
    required this.body,
    required this.portrait,
  });

  final String id;
  final String sender;
  final String subject;
  final String body;
  final Widget portrait;
}

class _OfficeState extends ConsumerState<_Office> {
  String? _open;
  final Set<String> _read = {};

  List<_Mail> _mails(AppStrings s, OfficeView view) {
    final career = widget.career;
    final offer = career.offer;
    final look = PresidentLook.of(offer.president);
    final trainer = career.trainer;
    final story = widget.loaded.rules.career.backstory(trainer.backstoryId);
    return [
      _Mail(
        id: 'president',
        sender: '${s.officeSenderPresident} ${offer.president.name}',
        subject: s.officeMailSubjectPresident(offer.club.name),
        body: s.officeMailBodyPresident(
          offer.president.typeId,
          trainer.name,
        ),
        portrait: PersonAvatar(
          appearance: look.appearance,
          extras: look.extras,
          size: 72,
        ),
      ),
      _Mail(
        id: 'advisor',
        sender: s.officeSenderAdvisor,
        subject: s.officeMailSubjectAdvisor,
        body: s.officeMailBodyAdvisor(
          goal: s.seasonGoalText(offer.goal),
          budget: s.money(offer.budget),
          squad: view.squadSize,
          opponent: view.opponent.name,
          home: view.atHome,
        ),
        portrait: const _Initial('B'),
      ),
      _Mail(
        id: 'news',
        sender: s.officeSenderNews,
        subject: s.officeMailSubjectNews(offer.situation),
        body: s.officeMailBodyNews(
          name: trainer.name,
          club: offer.club.name,
          backstory: s.backstoryName(trainer.backstoryId),
          hook: s.backstoryHook(story.hook),
        ),
        portrait: const _Initial('E'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final career = widget.career;
    final offer = career.offer;
    final view = OfficeView.of(career, widget.loaded);
    final mails = _mails(s, view);
    final opened = mails.where((m) => m.id == _open).firstOrNull;

    Widget card(Widget child) => Card(
      child: Padding(padding: const EdgeInsets.all(Tokens.gapM), child: child),
    );
    Widget heading(String text, String info) => Row(
      children: [
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Tokens.orange,
            ),
          ),
        ),
        InfoButton(message: info),
      ],
    );

    final header = card(
      Row(
        children: [
          ClubCrest(clubId: offer.club.id.value, size: 64),
          const SizedBox(width: Tokens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.club.name,
                  key: const ValueKey('office-club'),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  '${offer.club.place} · ${s.leagueName(offer.league.name)} · '
                  '${s.officeSeason(view.startYear)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: Tokens.gapM),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        career.trainer.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        s.backstoryName(career.trainer.backstoryId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.gapS),
                PersonAvatar(
                  key: const ValueKey('office-trainer'),
                  appearance: career.trainer.appearance,
                  size: 64,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final next = card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(s.officeNextTitle, s.infoOfficeNext),
          const SizedBox(height: Tokens.gapS),
          Row(
            children: [
              ClubCrest(clubId: view.opponent.id.value, size: 44),
              const SizedBox(width: Tokens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      view.opponent.name,
                      key: const ValueKey('office-opponent'),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      '${s.officeMatchday(view.matchday)} · '
                      '${view.atHome ? s.officeHome : s.officeAway}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.gapS),
          Row(
            children: [
              Flexible(
                child: Text(
                  s.officeStrengthCompare(
                    _num(view.ownStrength),
                    _num(view.opponentStrength),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              InfoButton(message: s.infoStrength),
            ],
          ),
        ],
      ),
    );

    final table = card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(s.officeTableTitle, s.infoOfficeTable),
          const SizedBox(height: Tokens.gapS),
          Text(s.officeTableEmpty, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Tokens.gapS),
          Text(
            s.officeTableForecast(offer.strengthRank, view.leagueSize),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Tokens.yellow,
            ),
          ),
        ],
      ),
    );

    Widget line(String label, String value, String info) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Tokens.orange,
                    ),
                  ),
                ),
                InfoButton(message: info),
              ],
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
    final cash = card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.officeCashTitle,
            style: theme.textTheme.titleMedium?.copyWith(color: Tokens.orange),
          ),
          const SizedBox(height: Tokens.gapS),
          line(s.offerBudget, s.money(offer.budget), s.infoBudget),
          line(s.offerGoal, s.seasonGoalText(offer.goal), s.infoGoal),
          const SizedBox(height: 2),
          Text(
            s.officeSquad(view.squadSize),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );

    final mailList = card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(s.officeMailTitle, s.infoOfficeMail),
          const SizedBox(height: Tokens.gapS),
          for (final m in mails)
            _MailRow(
              key: ValueKey('mail-${m.id}'),
              mail: m,
              unread: !_read.contains(m.id),
              selected: m.id == _open,
              onTap: () => setState(() {
                _open = m.id;
                _read.add(m.id);
              }),
            ),
          const Divider(height: Tokens.gapL),
          if (opened == null)
            Text(s.officeMailPick, style: theme.textTheme.bodyMedium)
          else ...[
            Text(
              opened.subject,
              key: const ValueKey('mail-subject'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Tokens.gapS),
            Text(opened.body, style: theme.textTheme.bodyLarge),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: Tokens.gapS),
        Expanded(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth > 760;
                if (!wide) {
                  return Column(children: [next, table, cash, mailList]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(children: [next, table, cash]),
                    ),
                    const SizedBox(width: Tokens.gapS),
                    Expanded(flex: 6, child: mailList),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: Tokens.gapS),
        StepButtons(
          backLabel: s.officeToMenu,
          nextLabel: s.officeGo,
          onBack: () => Navigator.of(context).maybePop(),
          onNext: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PlaceholderPage(
                title: s.officeMatchday(view.matchday),
                step: 7,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _num(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
}

class _MailRow extends StatelessWidget {
  const _MailRow({
    required this.mail,
    required this.unread,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final _Mail mail;
  final bool unread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Tokens.ground,
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
            padding: const EdgeInsets.all(Tokens.gapS),
            child: Row(
              children: [
                SizedBox(width: 48, child: Center(child: mail.portrait)),
                const SizedBox(width: Tokens.gapS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mail.sender,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        mail.subject,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: unread ? Tokens.yellow : null,
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

/// A round letter badge for senders without a portrait.
class _Initial extends StatelessWidget {
  const _Initial(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Tokens.panel,
      child: Text(
        letter,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Tokens.yellow,
        ),
      ),
    );
  }
}
