import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/settings.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'adaptive.dart';
import 'screen_frame.dart';

/// Settings: help, ticker speed, vibration, sound, language, and (on a
/// computer) the keyboard shortcuts.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final speed = ref.watch(tickerSpeedProvider);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: Tokens.gapM, bottom: Tokens.gapS),
      child: Text(text, style: theme.textTheme.titleMedium),
    );
    return ScreenFrame(
      title: s.settingsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                heading(s.settingsGeneral),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const ValueKey('help-switch'),
                        title: Text(s.helpSettingTitle),
                        subtitle: Text(s.helpSettingText),
                        value: ref.watch(helpProvider),
                        onChanged: (on) =>
                            ref.read(helpProvider.notifier).set(on),
                      ),
                      ListTile(
                        minTileHeight: 56,
                        title: Text(s.settingsLanguage),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.languageName),
                            const SizedBox(width: 8),
                            const Icon(Icons.check, color: Tokens.green),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                heading(s.settingsMatch),
                Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Tokens.gapM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.settingsTicker,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.settingsTickerText,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: Tokens.gapS),
                            SegmentedButton<int>(
                              key: const ValueKey('settings-speed'),
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(
                                  value: 0,
                                  label: Text(s.matchSpeedSlow),
                                ),
                                ButtonSegment(
                                  value: 1,
                                  label: Text(s.matchSpeedNormal),
                                ),
                                ButtonSegment(
                                  value: 2,
                                  label: Text(s.matchSpeedFast),
                                ),
                              ],
                              selected: {speed},
                              onSelectionChanged: (v) => ref
                                  .read(tickerSpeedProvider.notifier)
                                  .set(v.first),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        key: const ValueKey('autolineup-switch'),
                        title: Text(s.settingsAutoLineup),
                        subtitle: Text(s.settingsAutoLineupText),
                        value: ref.watch(autoLineupProvider),
                        onChanged: (on) =>
                            ref.read(autoLineupProvider.notifier).set(on),
                      ),
                      SwitchListTile(
                        key: const ValueKey('vibration-switch'),
                        title: Text(s.settingsVibration),
                        subtitle: Text(s.settingsVibrationText),
                        value: ref.watch(vibrationProvider),
                        onChanged: (on) =>
                            ref.read(vibrationProvider.notifier).set(on),
                      ),
                      SwitchListTile(
                        key: const ValueKey('sound-switch'),
                        title: Text(s.settingsSound),
                        subtitle: Text(s.settingsSoundText),
                        value: ref.watch(soundProvider),
                        onChanged: (on) =>
                            ref.read(soundProvider.notifier).set(on),
                      ),
                    ],
                  ),
                ),
                if (!isNarrow(context)) ...[
                  heading(s.settingsShortcuts),
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
                heading(s.settingsAbout),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Tokens.gapM),
                    child: Text(s.settingsAboutText),
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
