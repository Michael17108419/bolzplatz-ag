import 'package:game_core/game_core.dart';

import '../l10n/app_strings.dart';

/// "Mi 01.07.2026": weekday, day, month and year.
String formatDate(AppStrings s, GameDate d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '${s.weekdayShort(d.weekday)} $dd.$mm.${d.year}';
}
