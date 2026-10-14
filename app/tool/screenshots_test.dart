// Not part of the normal test run (it lives outside `test/`). The workflow
// `screenshots` runs it with `--update-goldens` to write PNG pictures of the
// screens into `tool/out/`, so the screens can be looked at without Windows.
import 'package:bolzplatz_app/main.dart';
import 'package:bolzplatz_app/ui/crest.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFont(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFont('SpaceGrotesk', 'assets/fonts/SpaceGrotesk.ttf');
    await _loadFont('Figtree', 'assets/fonts/Figtree.ttf');
  });

  testWidgets('screenshots', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: BolzplatzApp()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/01_hauptmenue.png'),
    );

    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/02_einstellungen.png'),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Neues Spiel'));
    await tester.pump();
    // The world loads in real time (files and parsing), outside fake time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 6)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/03_karrierestart.png'),
    );

    await tester.tap(find.byType(ClubCrest).at(2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Uschi Muster');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/04_karrierestart_gewaehlt.png'),
    );
  });
}
