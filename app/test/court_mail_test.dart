import 'package:bolzplatz_app/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

// Step 10e3: the post of the control committee after a red card.

void main() {
  const s = AppStringsDe();

  test('every kind and status has a letter that names the player and the '
      'ban', () {
    for (final status in CourtStatus.values) {
      for (final kind in ['dogso', 'rough', 'violent', 'insult', 'other']) {
        for (final weeks in [true, false]) {
          final body = s.courtBody(
            player: 'Krüger',
            kind: kind,
            competition: null,
            motion: 3,
            weeks: weeks,
            status: status,
            verdict: status == CourtStatus.appealed ? 2 : null,
          );
          expect(body, contains('Krüger'));
          expect(body, isNot(contains(r'$')));
          if (status != CourtStatus.stopped) {
            expect(body, contains(weeks ? 'Woche' : 'Spiel'));
          }
          expect(s.courtSubject('Krüger', status), contains('Krüger'));
        }
      }
    }
    final harder = s.courtBody(
      player: 'Krüger',
      kind: 'violent',
      competition: 'Bolzplatzpokal',
      motion: 3,
      weeks: false,
      status: CourtStatus.appealed,
      verdict: 4,
    );
    expect(harder, contains('erhöht'));
    expect(harder, contains('Bolzplatzpokal'));
  });
}
