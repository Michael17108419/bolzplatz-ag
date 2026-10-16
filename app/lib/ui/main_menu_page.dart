import 'dart:io' show exit;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/loaded_world.dart';
import '../game/saves.dart';
import '../game/season_game.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'logo.dart';
import 'career_start_page.dart';
import 'saves_page.dart';
import 'settings_page.dart';

/// First screen: new game, load, settings, quit.
class MainMenuPage extends ConsumerStatefulWidget {
  const MainMenuPage({super.key});

  @override
  ConsumerState<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends ConsumerState<MainMenuPage> {
  /// The automatic save, if there is one: "Weiterspielen" loads it.
  SaveData? _auto;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _findAuto();
  }

  Future<void> _findAuto() async {
    final slots = await ref.read(saveServiceProvider).slots();
    if (!mounted) return;
    setState(() {
      _auto = slots.where((v) => v.slot == 'auto').firstOrNull?.data;
    });
  }

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) await _findAuto();
  }

  Future<void> _continue() async {
    final data = _auto;
    if (data == null || _busy) return;
    setState(() => _busy = true);
    // Let the button draw once before the replay blocks the thread.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    final ok = await loadAndEnter(context, ref, data);
    if (mounted) setState(() => _busy = false);
    if (!ok && mounted) await _findAuto();
  }

  Widget _newGameButton(AppStrings s) {
    void start() {
      ref.read(worldStateProvider.notifier).set(null);
      ref.read(seasonHistoryProvider.notifier).reset();
      _open(context, const CareerStartPage());
    }

    final label = Text(s.menuNewGame);
    // With a game to go on with, "Weiterspielen" is the main button.
    return _auto == null
        ? FilledButton(onPressed: start, child: label)
        : FilledButton.tonal(onPressed: start, child: label);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(Tokens.gapL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BolzplatzLogo(height: 200),
                  const SizedBox(height: Tokens.gapM),
                  Text(
                    s.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: Tokens.gapL * 1.5),
                  if (_auto != null) ...[
                    FilledButton(
                      key: const ValueKey('menu-continue'),
                      onPressed: _busy ? null : _continue,
                      child: Text(s.menuContinue),
                    ),
                    const SizedBox(height: Tokens.gapM),
                  ],
                  _newGameButton(s),
                  const SizedBox(height: Tokens.gapM),
                  FilledButton.tonal(
                    onPressed: () =>
                        _open(context, const SavesPage(fromMenu: true)),
                    child: Text(s.menuLoadGame),
                  ),
                  const SizedBox(height: Tokens.gapM),
                  FilledButton.tonal(
                    onPressed: () => _open(context, const SettingsPage()),
                    child: Text(s.menuSettings),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: Tokens.gapM),
                    TextButton(
                      onPressed: () => exit(0),
                      child: Text(s.menuQuit),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
