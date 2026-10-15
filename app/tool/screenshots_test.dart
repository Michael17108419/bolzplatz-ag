// Not part of the normal test run (it lives outside `test/`). The workflow
// `screenshots` runs it with `--update-goldens` to write PNG pictures of the
// screens into `tool/out/`, so the screens can be looked at without Windows.
import 'package:bolzplatz_app/main.dart';
import 'package:bolzplatz_app/ui/info_button.dart';
import 'package:bolzplatz_app/ui/person_avatar.dart';
import 'package:bolzplatz_app/ui/president_look.dart';
import 'package:game_core/game_core.dart';
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
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/03_trainer_leer.png'),
    );

    final next = find.byKey(const ValueKey('step-next'));
    await tester.enterText(find.byType(TextField), 'Uschi Muster');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/04_trainer.png'),
    );
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('outfit-5')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/04b_kleidung.png'),
    );
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-pe_teacher')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/05_werdegang.png'),
    );
    await tester.tap(find.byType(InfoButton).at(6));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/05b_werdegang_info.png'),
    );
    await tester.tapAt(const Offset(10, 700));
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('wish-club-'),
          )
          .at(1),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/06_wunschverein.png'),
    );
    await tester.tap(find.byType(InfoButton).first);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/06b_wunschverein_info.png'),
    );
    await tester.tapAt(const Offset(10, 700));
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('offer-0')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/07_angebote.png'),
    );
    await tester.tap(find.byType(InfoButton).at(4));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/07b_angebote_info.png'),
    );
    await tester.tapAt(const Offset(10, 700));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('offer-accept')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/10_buero.png'),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('desk-tactics'))),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/10b_buero_hover.png'),
    );
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('desk-post'))),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/10c_buero_post.png'),
    );
    await tester.tap(find.byKey(const ValueKey('desk-post')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mail-jourfix')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BolzplatzApp),
      matchesGoldenFile('out/11_post.png'),
    );
  });

  testWidgets('trainer portraits', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const looks = [
      TrainerAppearance(skin: 1, hairStyle: 1, hairColour: 1, glasses: 3, outfit: 0, outfitColour: 6),
      TrainerAppearance(skin: 2, hairStyle: 2, hairColour: 0, beard: 1, outfit: 1, outfitColour: 7),
      TrainerAppearance(skin: 0, hairStyle: 3, hairColour: 3, glasses: 1, outfit: 2, outfitColour: 3),
      TrainerAppearance(skin: 3, hairStyle: 4, hairColour: 0, beard: 2, glasses: 3, outfit: 3, outfitColour: 2),
      TrainerAppearance(skin: 4, hairStyle: 5, hairColour: 2, beard: 3, outfit: 4, outfitColour: 4, outfitColour2: 7),
      TrainerAppearance(skin: 1, hairStyle: 2, hairColour: 4, glasses: 2, outfit: 5, outfitColour: 0, outfitColour2: 3),
      TrainerAppearance(skin: 0, hairStyle: 0, beard: 2, glasses: 1, outfit: 6, outfitColour: 5),
      TrainerAppearance(gender: 1, skin: 0, hairStyle: 4, hairColour: 2, outfit: 7, outfitColour: 7, outfitColour2: 1),
      TrainerAppearance(gender: 1, skin: 2, hairStyle: 3, hairColour: 0, glasses: 3, outfit: 8, outfitColour: 5, outfitColour2: 7),
      TrainerAppearance(gender: 1, skin: 4, hairStyle: 2, hairColour: 1, glasses: 1, outfit: 7, outfitColour: 3, outfitColour2: 2),
      TrainerAppearance(gender: 1, skin: 1, hairStyle: 1, hairColour: 3, outfit: 8, outfitColour: 6, outfitColour2: 4),
      TrainerAppearance(gender: 1, skin: 3, hairStyle: 5, hairColour: 4, outfit: 4, outfitColour: 3, outfitColour2: 1),
      TrainerAppearance(gender: 2, skin: 2, hairStyle: 1, hairColour: 0, glasses: 2, outfit: 5, outfitColour: 4, outfitColour2: 2),
      TrainerAppearance(gender: 2, skin: 0, hairStyle: 0, beard: 3, glasses: 3, outfit: 8, outfitColour: 0, outfitColour2: 1),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF12261A),
          body: Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final l in looks) PersonAvatar(appearance: l, size: 150),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/08_trainer_koepfe.png'),
    );
  });

  testWidgets('president portraits', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const types = [
      'construction_tycoon',
      'thrifty_butcher',
      'car_dealer',
      'savings_bank_director',
      'ex_pro',
      'rich_heir',
      'patron',
      'club_fixture',
    ];
    final looks = <PersonLook>[];
    for (var i = 0; i < 16; i++) {
      final type = types[i % 8];
      looks.add(
        PresidentLook.of(
          President(
            typeId: type,
            name: 'Person $i',
            traits: {
              for (final t in PresidentTrait.values)
                t: (i < 8 ? 50.0 : (i * 37 % 100) + 1.0),
            },
          ),
        ),
      );
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF12261A),
          body: Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final l in looks)
                  PersonAvatar(
                    appearance: l.appearance,
                    extras: l.extras,
                    size: 140,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/09_praesidenten.png'),
    );
  });
}
