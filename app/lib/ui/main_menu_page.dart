import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'logo.dart';
import 'career_start_page.dart';
import 'saves_page.dart';
import 'settings_page.dart';

/// First screen: new game, load, settings, quit.
class MainMenuPage extends ConsumerWidget {
  const MainMenuPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  FilledButton(
                    onPressed: () => _open(context, const CareerStartPage()),
                    child: Text(s.menuNewGame),
                  ),
                  const SizedBox(height: Tokens.gapM),
                  FilledButton.tonal(
                    onPressed: () => _open(
                      context,
                      const SavesPage(fromMenu: true),
                    ),
                    child: Text(s.menuLoadGame),
                  ),
                  const SizedBox(height: Tokens.gapM),
                  FilledButton.tonal(
                    onPressed: () => _open(context, const SettingsPage()),
                    child: Text(s.menuSettings),
                  ),
                  const SizedBox(height: Tokens.gapM),
                  TextButton(onPressed: () => exit(0), child: Text(s.menuQuit)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
