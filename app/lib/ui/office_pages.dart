import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/career.dart';
import '../game/desk.dart';
import '../game/lineup.dart';
import '../game/loaded_world.dart';
import '../game/mail_state.dart';
import '../game/office.dart';
import '../game/office_provider.dart';
import '../game/season_game.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'info_button.dart';
import 'office_mail.dart';
import 'match_pages.dart';
import 'month_calendar.dart';
import 'screen_frame.dart';
import 'settings_page.dart';
import 'lineup_page.dart';
import 'stats_page.dart';
import 'squad_page.dart';

const List<LogicalKeyboardKey> _digitKeys = [
  LogicalKeyboardKey.digit0,
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

/// The number keys 1 to 9 and 0 open the desk items; space and Enter are
/// "Weiter". [current] is the item whose screen is open (its number does
/// nothing); [replace] swaps the open screen instead of stacking a new one.
Map<ShortcutActivator, VoidCallback> deskBindings(
  BuildContext context,
  WidgetRef ref, {
  DeskItem? current,
  bool replace = false,
}) {
  return {
    for (final item in DeskItem.rooms)
      if (item != current)
        SingleActivator(_digitKeys[item.digit!]): () =>
            openDesk(context, ref, item, replace: replace),
    const SingleActivator(LogicalKeyboardKey.space): () => goNext(context, ref),
    const SingleActivator(LogicalKeyboardKey.enter): () => goNext(context, ref),
  };
}

/// Opens the screen behind a desk item. The door is "Weiter".
void openDesk(
  BuildContext context,
  WidgetRef ref,
  DeskItem item, {
  bool replace = false,
}) {
  if (item == DeskItem.door) {
    goNext(context, ref);
    return;
  }
  final route = MaterialPageRoute<void>(builder: (_) => _pageFor(item));
  final nav = Navigator.of(context);
  if (replace) {
    nav.pushReplacement(route);
  } else {
    nav.push(route);
  }
}

/// "Weiter": on to the next match day.
void goNext(BuildContext context, WidgetRef ref) {
  final s = ref.read(stringsProvider);
  final view = ref.read(officeViewProvider);
  final problem = lineupProblemOf(ref);
  if (problem != LineupProblem.none) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.lineupProblemText(problem))));
    return;
  }
  if (view?.seasonOver ?? false) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.officeMatchdayOver)));
    return;
  }
  final own = ref.read(seasonProvider.notifier).openNext();
  if (own == null) return;
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const MatchPreviewPage()));
}

/// "Einen Tag weiter": the clock runs one day.
void goNextDay(BuildContext context, WidgetRef ref) {
  final s = ref.read(stringsProvider);
  switch (ref.read(seasonProvider.notifier).advanceDay()) {
    case DayStep.played:
      break;
    case DayStep.ownMatch:
      goNext(context, ref);
    case DayStep.seasonOver:
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.officeMatchdayOver)));
  }
}

Widget _pageFor(DeskItem item) => switch (item) {
  DeskItem.post => const PostPage(),
  DeskItem.calendar => const CalendarPage(),
  DeskItem.stats => const StatsPage(),
  DeskItem.finance => const FinancePage(),
  DeskItem.saves => const SettingsPage(),
  DeskItem.tactics => const LineupPage(),
  DeskItem.files => const SquadPage(),
  _ => _LaterPage(item),
};

/// The frame of every screen behind a desk item: title, the number keys and
/// the quick bar at the bottom.
class DeskFrame extends ConsumerWidget {
  const DeskFrame({
    required this.item,
    required this.child,
    this.title,
    super.key,
  });

  final DeskItem item;
  final Widget child;

  /// The title of the screen; the name of the desk item when null.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return ScreenFrame(
      title: title ?? s.deskName(item),
      maxWidth: 1100,
      extraBindings: deskBindings(context, ref, current: item, replace: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: child),
          const SizedBox(height: Tokens.gapS),
          QuickBar(current: item),
        ],
      ),
    );
  }
}

/// The bar at the bottom of every screen behind a desk item: back to the
/// office, one chip per desk item (with its number key) and "Weiter".
class QuickBar extends ConsumerWidget {
  const QuickBar({required this.current, super.key});

  final DeskItem current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final view = ref.watch(officeViewProvider);
    final read = ref.watch(mailReadProvider);
    final unread = officeMailIds.where((id) => !read.contains(id)).length;
    return Row(
      children: [
        TextButton(
          key: const ValueKey('quick-office'),
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(s.homeTitle),
        ),
        const SizedBox(width: Tokens.gapS),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final item in DeskItem.rooms)
                _QuickChip(
                  item: item,
                  selected: item == current,
                  count: item == DeskItem.post ? unread : 0,
                  onTap: () {
                    if (item != current) {
                      openDesk(context, ref, item, replace: true);
                    }
                  },
                ),
            ],
          ),
        ),
        const SizedBox(width: Tokens.gapS),
        FilledButton(
          key: const ValueKey('quick-next'),
          onPressed: () => goNext(context, ref),
          child: Text(s.deskNext(view?.matchday ?? 1)),
        ),
      ],
    );
  }
}

class _QuickChip extends ConsumerWidget {
  const _QuickChip({
    required this.item,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final DeskItem item;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final fg = selected ? Tokens.ink : Tokens.text;
    return Tooltip(
      message: s.deskName(item),
      child: Material(
        color: selected ? Tokens.yellow : Tokens.panel,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: ValueKey('quick-${item.name}'),
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.digit}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? Tokens.ink : Tokens.yellow,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  s.deskShort(item),
                  style: theme.textTheme.labelLarge?.copyWith(color: fg),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected ? Tokens.ink : Tokens.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// For the desk items that a later building step delivers.
class _LaterPage extends ConsumerWidget {
  const _LaterPage(this.item);

  final DeskItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    return DeskFrame(
      item: item,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.comingLater, style: theme.textTheme.titleMedium),
            const SizedBox(height: Tokens.gapS),
            Text(
              s.deskHint(item),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds a page body once the career and the world are there.
class WithCareer extends ConsumerWidget {
  const WithCareer({required this.builder, super.key});

  final Widget Function(
    BuildContext context,
    Career career,
    LoadedWorld loaded,
    OfficeView view,
  )
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final career = ref.watch(careerProvider);
    final loaded = ref.watch(loadedWorldProvider).value;
    final view = ref.watch(officeViewProvider);
    if (career == null || loaded == null || view == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return builder(context, career, loaded, view);
  }
}

Widget _card(Widget child) => Card(
  child: Padding(padding: const EdgeInsets.all(Tokens.gapM), child: child),
);

Widget _heading(ThemeData theme, String text, String info) => Row(
  children: [
    Flexible(
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(color: Tokens.orange),
      ),
    ),
    InfoButton(message: info),
  ],
);

/// One card, centred and not too wide.
Widget _single(Widget card) => SingleChildScrollView(
  child: Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: card,
    ),
  ),
);

String _num(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// The inbox: mails from the president, the advisor, the news and the
/// weekly "Jour Fix".
class PostPage extends ConsumerStatefulWidget {
  const PostPage({super.key});

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  String? _open;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final read = ref.watch(mailReadProvider);
    return DeskFrame(
      item: DeskItem.post,
      child: WithCareer(
        builder: (context, career, loaded, view) {
          final mails = buildMails(s, career, loaded, view);
          final opened = mails.where((m) => m.id == _open).firstOrNull;
          return SingleChildScrollView(
            child: _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading(theme, s.officeMailTitle, s.infoOfficeMail),
                  const SizedBox(height: Tokens.gapS),
                  for (final m in mails)
                    _MailRow(
                      key: ValueKey('mail-${m.id}'),
                      mail: m,
                      unread: !read.contains(m.id),
                      selected: m.id == _open,
                      onTap: () {
                        setState(() => _open = m.id);
                        ref.read(mailReadProvider.notifier).markRead(m.id);
                      },
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
                    if (opened.actions.isNotEmpty) ...[
                      const SizedBox(height: Tokens.gapS),
                      Wrap(
                        spacing: Tokens.gapS,
                        children: [
                          for (final (label, item) in opened.actions)
                            OutlinedButton(
                              key: ValueKey('mail-go-${item.name}'),
                              onPressed: () =>
                                  openDesk(context, ref, item, replace: true),
                              child: Text(label),
                            ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MailRow extends StatelessWidget {
  const _MailRow({
    required this.mail,
    required this.unread,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final OfficeMail mail;
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

/// The calendar: for now the next match.
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    return DeskFrame(
      item: DeskItem.calendar,
      child: WithCareer(
        builder: (context, career, loaded, view) => _single(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heading(theme, s.officeNextTitle, s.infoOfficeNext),
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
              ),
              const SizedBox(height: Tokens.gapM),
              const MonthCalendar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Finances: for now budget, goal and squad size.
class FinancePage extends ConsumerWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
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
    return DeskFrame(
      item: DeskItem.finance,
      child: WithCareer(
        builder: (context, career, loaded, view) {
          final offer = career.offer;
          return _single(
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.officeCashTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Tokens.orange,
                    ),
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
            ),
          );
        },
      ),
    );
  }
}
