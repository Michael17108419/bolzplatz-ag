import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_strings.dart';
import 'theme/app_theme.dart';
import 'ui/main_menu_page.dart';

void main() {
  runApp(const ProviderScope(child: BolzplatzApp()));
}

class BolzplatzApp extends ConsumerWidget {
  const BolzplatzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return MaterialApp(
      title: s.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainMenuPage(),
    );
  }
}
