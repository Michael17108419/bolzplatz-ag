import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/mail_state.dart';
import '../game/planning.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'info_button.dart';
import 'office_mail.dart';
import 'office_pages.dart';

/// The inbox on the phone: a compact list (current, unread, archive); a tap
/// opens the mail on its own page, swipe goes to the next one.
class PostPhone extends ConsumerStatefulWidget {
  const PostPhone({
    required this.mails,
    required this.today,
    required this.matchday,
    super.key,
  });

  final List<OfficeMail> mails;
  final GameDate? today;
  final int matchday;

  @override
  ConsumerState<PostPhone> createState() => _PostPhoneState();
}

class _PostPhoneState extends ConsumerState<PostPhone> {
  /// 0 current, 1 unread, 2 archive.
  int _filter = 0;
  int? _open;
  PageController? _pages;

  /// The list as it was when a mail was opened: reading must not move the
  /// mails around under the swipe.
  List<OfficeMail>? _snap;

  /// Read mails of more than two weeks ago (about two match days) and the
  /// first mails of the career once the season is under way go to the
  /// archive. Unread mails stay in front.
  bool _archived(OfficeMail m, Set<String> read) {
    if (!read.contains(m.id)) return false;
    final d = m.date;
    if (d != null) {
      final today = widget.today;
      return today != null && today.epochDay - d.epochDay > 14;
    }
    const keep = {'jourfix', seasonEndId, vacationVerdictId};
    return !keep.contains(m.id) && widget.matchday > 2;
  }

  List<OfficeMail> _visible(Set<String> read) => [
    for (final m in widget.mails)
      if (switch (_filter) {
        0 => !_archived(m, read),
        1 => !read.contains(m.id),
        _ => _archived(m, read),
      })
        m,
  ];

  void _openAt(int i, List<OfficeMail> list) {
    ref.read(mailReadProvider.notifier).markRead(list[i].id);
    _pages?.dispose();
    _pages = PageController(initialPage: i);
    setState(() {
      _snap = list;
      _open = i;
    });
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  String _day(GameDate? d) => d == null ? '' : '${d.day}.${d.month}.';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final read = ref.watch(mailReadProvider);
    final list = _visible(read);
    final open = _open;
    final shown = _snap ?? list;

    return PopScope(
      canPop: open == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && open != null) {
          setState(() {
            _open = null;
            _snap = null;
          });
        }
      },
      child: open != null && shown.isNotEmpty
          ? _detail(s, theme, shown, open.clamp(0, shown.length - 1).toInt())
          : _list(s, theme, read, list),
    );
  }

  Widget _list(
    AppStrings s,
    ThemeData theme,
    Set<String> read,
    List<OfficeMail> list,
  ) {
    Widget chip(int i, String label) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        key: ValueKey('post-filter-$i'),
        label: Text(label),
        selected: _filter == i,
        onSelected: (_) => setState(() => _filter = i),
      ),
    );
    final anyUnread = widget.mails.any((m) => !read.contains(m.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    chip(0, s.postFilterCurrent),
                    chip(1, s.postFilterUnread),
                    chip(2, s.postFilterArchive),
                  ],
                ),
              ),
            ),
            if (anyUnread)
              IconButton(
                key: const ValueKey('post-mark-all'),
                tooltip: s.postMarkAllRead,
                onPressed: () => ref
                    .read(mailReadProvider.notifier)
                    .markAllRead([for (final m in widget.mails) m.id]),
                icon: const Icon(Icons.done_all),
              ),
            InfoButton(message: s.infoOfficeMail),
          ],
        ),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text(s.postEmpty))
              : ListView.builder(
                  key: const ValueKey('post-list'),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final m = list[i];
                    final unread = !read.contains(m.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: Tokens.panel,
                        borderRadius: BorderRadius.circular(Tokens.radius),
                        child: InkWell(
                          key: ValueKey('mail-${m.id}'),
                          borderRadius: BorderRadius.circular(Tokens.radius),
                          onTap: () => _openAt(i, list),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: FittedBox(child: m.portrait),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.sender,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      Text(
                                        m.subject,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: unread
                                                  ? Tokens.yellow
                                                  : null,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _day(m.date),
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (unread)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: Tokens.yellow,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _detail(
    AppStrings s,
    ThemeData theme,
    List<OfficeMail> list,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton.icon(
              key: const ValueKey('post-back'),
              onPressed: () => setState(() {
                _open = null;
                _snap = null;
              }),
              icon: const Icon(Icons.list),
              label: Text(s.officeMailTitle),
            ),
            const Spacer(),
            Text('${index + 1} / ${list.length}'),
            const SizedBox(width: 8),
          ],
        ),
        Expanded(
          child: PageView.builder(
            key: const ValueKey('post-pages'),
            controller: _pages,
            itemCount: list.length,
            onPageChanged: (i) {
              ref.read(mailReadProvider.notifier).markRead(list[i].id);
              setState(() => _open = i);
            },
            itemBuilder: (context, i) {
              final m = list[i];
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: FittedBox(child: m.portrait),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            m.sender,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(_day(m.date), style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: Tokens.gapS),
                    Text(
                      m.subject,
                      key: ValueKey('mail-subject-$i'),
                      style: theme.textTheme.titleMedium,
                    ),
                    if (m.actions.isNotEmpty) ...[
                      const SizedBox(height: Tokens.gapS),
                      Wrap(
                        spacing: Tokens.gapS,
                        runSpacing: Tokens.gapS,
                        children: [
                          for (final (label, item) in m.actions)
                            OutlinedButton(
                              key: ValueKey('mail-go-${item.name}'),
                              onPressed: () =>
                                  openDesk(context, ref, item, replace: true),
                              child: Text(label),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: Tokens.gapS),
                    Text(m.body, style: theme.textTheme.bodyLarge),
                    if (m.courtCase != null) ...[
                      const SizedBox(height: Tokens.gapS),
                      CourtButtons(caseId: m.courtCase!),
                    ],
                    const SizedBox(height: Tokens.gapL),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
