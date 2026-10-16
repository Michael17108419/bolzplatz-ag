import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game/saves.dart';
import 'l10n/app_strings.dart';
import 'theme/app_theme.dart';
import 'ui/main_menu_page.dart';

void main() {
  runApp(const ProviderScope(child: BolzplatzApp()));
}

class BolzplatzApp extends ConsumerStatefulWidget {
  const BolzplatzApp({super.key});

  @override
  ConsumerState<BolzplatzApp> createState() => _BolzplatzAppState();
}

/// Saves the game when the app goes to the background: on a phone the system
/// may end it there at any time, also in the middle of a match.
class _BolzplatzAppState extends ConsumerState<BolzplatzApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      ref.read(saveServiceProvider).autosave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return MaterialApp(
      title: s.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainMenuPage(),
    );
  }
}
