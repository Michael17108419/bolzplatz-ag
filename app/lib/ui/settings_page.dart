import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/settings.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'screen_frame.dart';

/// Settings: language and the list of keyboard shortcuts.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    return ScreenFrame(
      title: s.settingsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                Text(s.settingsLanguage, style: theme.textTheme.titleMedium),
                const SizedBox(height: Tokens.gapS),
                Card(
                  child: ListTile(
                    title: Text(s.languageName),
                    trailing: const Icon(Icons.check, color: Tokens.green),
                  ),
                ),
                const SizedBox(height: Tokens.gapL),
                Text(s.helpSettingTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: Tokens.gapS),
                Card(
                  child: SwitchListTile(
                    key: const ValueKey('help-switch'),
                    title: Text(s.helpSettingTitle),
                    subtitle: Text(s.helpSettingText),
                    value: ref.watch(helpProvider),
                    onChanged: (on) => ref.read(helpProvider.notifier).set(on),
                  ),
                ),
                const SizedBox(height: Tokens.gapL),
                Text(s.settingsShortcuts, style: theme.textTheme.titleMedium),
                const SizedBox(height: Tokens.gapS),
                Card(
                  child: ListTile(
                    title: Text(s.shortcutBack),
                    trailing: Text(
                      s.shortcutBackKey,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Tokens.yellow,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Tokens.gapM),
          Row(
            children: [
              TextButton(
                key: const ValueKey('settings-back'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(s.back),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
