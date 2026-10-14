import 'package:bolzplatz_app/main.dart';
import 'package:bolzplatz_app/ui/logo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _start(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: BolzplatzApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the main menu shows the logo and four entries', (tester) async {
    await _start(tester);
    expect(find.byType(BolzplatzLogo), findsOneWidget);
    expect(find.text('Neues Spiel'), findsOneWidget);
    expect(find.text('Spiel laden'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Beenden'), findsOneWidget);
  });

  testWidgets('settings open and Esc goes back', (tester) async {
    await _start(tester);
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    expect(find.text('Tastaturkürzel'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Neues Spiel'), findsOneWidget);
  });

  testWidgets('new game shows the placeholder for step 2', (tester) async {
    await _start(tester);
    await tester.tap(find.text('Neues Spiel'));
    await tester.pumpAndSettle();
    expect(find.text('Kommt in Bauabschnitt 2.'), findsOneWidget);
  });
}
