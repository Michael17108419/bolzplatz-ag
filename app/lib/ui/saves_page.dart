import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/career.dart';
import '../game/dates.dart';
import '../game/saves.dart';
import '../game/season_game.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'info_button.dart';
import 'match_pages.dart';
import 'office_page.dart';
import 'screen_frame.dart';
import 'settings_page.dart';

/// The saved games: the automatic slot and three of the player's own. Opened
/// from the desk (save and load) and from the main menu (load only).
class SavesPage extends ConsumerStatefulWidget {
  const SavesPage({this.fromMenu = false, super.key});

  /// True when opened from the main menu: there is nothing to save yet.
  final bool fromMenu;

  @override
  ConsumerState<SavesPage> createState() => _SavesPageState();
}

class _SavesPageState extends ConsumerState<SavesPage> {
  List<SaveSlotView>? _slots;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final slots = await ref.read(saveServiceProvider).slots();
    if (!mounted) return;
    setState(() => _slots = slots);
  }

  Future<bool> _confirm(String title, String text, String confirmLabel) async {
    final s = ref.read(stringsProvider);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            key: const ValueKey('confirm-no'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.savesCancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-yes'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  Future<void> _save(SaveSlotView view) async {
    final s = ref.read(stringsProvider);
    if (!view.isEmpty &&
        !await _confirm(
          s.savesOverwriteTitle,
          s.savesOverwriteText,
          s.savesSave,
        )) {
      return;
    }
    final ok = await ref.read(saveServiceProvider).save(view.slot);
    if (!mounted) return;
    setState(() => _message = ok ? s.savesDone : null);
    await _reload();
  }

  Future<void> _delete(SaveSlotView view) async {
    final s = ref.read(stringsProvider);
    if (!await _confirm(s.savesDeleteTitle, s.savesDeleteText, s.savesDelete)) {
      return;
    }
    await ref.read(saveServiceProvider).delete(view.slot);
    if (!mounted) return;
    setState(() => _message = null);
    await _reload();
  }

  Future<void> _load(SaveSlotView view) async {
    final data = view.data;
    if (data == null) return;
    final s = ref.read(stringsProvider);
    setState(() {
      _busy = true;
      _message = null;
    });
    // Let the hint draw once before the replay blocks the thread.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final ok = await ref.read(saveServiceProvider).load(data);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _message = s.savesLoadFailed;
      });
      return;
    }
    final nav = Navigator.of(context);
    // A match that was under way is picked up where it stopped.
    final resume = ref.read(seasonProvider.notifier).resumeLive;
    unawaited(
      nav.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const OfficePage()),
        (route) => route.isFirst,
      ),
    );
    if (resume) {
      unawaited(
        nav.push(MaterialPageRoute<void>(builder: (_) => const LiveMatchPage())),
      );
    }
  }

  String _stamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}';
  }

  String _title(AppStrings s, String slot) =>
      slot == 'auto' ? s.savesAuto : s.savesSlot(slot);

  Widget _card(AppStrings s, ThemeData theme, SaveSlotView view, bool canSave) {
    final data = view.data;
    final isAuto = view.slot == 'auto';
    return Card(
      key: ValueKey('save-slot-${view.slot}'),
      child: Padding(
        padding: const EdgeInsets.all(Tokens.gapM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title(s, view.slot), style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            if (data != null) ...[
              Text(s.savesLine1(data.trainerName, data.clubName)),
              Text(
                s.savesLine2(
                  data.leagueName,
                  formatDate(s, data.date),
                  data.matchday,
                  data.matchdays,
                ),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                s.savesSavedAt(_stamp(data.savedAt)),
                style: theme.textTheme.bodySmall,
              ),
            ] else
              Text(view.unreadable ? s.savesUnreadable : s.savesEmpty),
            const SizedBox(height: Tokens.gapS),
            Wrap(
              spacing: Tokens.gapS,
              runSpacing: Tokens.gapS,
              children: [
                if (canSave && !isAuto)
                  FilledButton(
                    key: ValueKey('save-btn-${view.slot}'),
                    onPressed: _busy ? null : () => _save(view),
                    child: Text(s.savesSave),
                  ),
                if (data != null)
                  FilledButton.tonal(
                    key: ValueKey('load-btn-${view.slot}'),
                    onPressed: _busy ? null : () => _load(view),
                    child: Text(s.savesLoad),
                  ),
                if (!view.isEmpty)
                  TextButton(
                    key: ValueKey('delete-btn-${view.slot}'),
                    onPressed: _busy ? null : () => _delete(view),
                    child: Text(s.savesDelete),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final canSave = !widget.fromMenu && ref.watch(careerProvider) != null;
    final slots = _slots;
    final anything = slots?.any((v) => !v.isEmpty) ?? false;
    return ScreenFrame(
      title: s.savesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(s.savesTitle, style: theme.textTheme.headlineSmall),
              InfoButton(message: s.infoSaves),
            ],
          ),
          const SizedBox(height: Tokens.gapM),
          if (_busy)
            Padding(
              padding: const EdgeInsets.only(bottom: Tokens.gapM),
              child: Row(
                key: const ValueKey('saves-loading'),
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: Tokens.gapS),
                  Text(s.savesLoading),
                ],
              ),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Tokens.gapM),
              child: Text(
                _message!,
                key: const ValueKey('saves-message'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Tokens.yellow,
                ),
              ),
            ),
          Expanded(
            child: slots == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      if (widget.fromMenu && !anything)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Tokens.gapM),
                          child: Text(s.savesNothingToLoad),
                        ),
                      for (final v in slots) _card(s, theme, v, canSave),
                      if (!widget.fromMenu) ...[
                        const SizedBox(height: Tokens.gapM),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonal(
                            key: const ValueKey('saves-settings'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SettingsPage(),
                              ),
                            ),
                            child: Text(s.savesSettings),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: Tokens.gapM),
          Row(
            children: [
              TextButton(
                key: const ValueKey('saves-back'),
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).maybePop(),
                child: Text(s.back),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
