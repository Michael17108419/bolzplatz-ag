import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import 'career.dart';
import 'loaded_world.dart';
import 'season_game.dart';

/// The mail with the verdict on the vacation plan at the end of the season.
const String vacationVerdictId = 'vacation-verdict';

final holidayCalendarProvider = Provider<HolidayCalendar>(
  (ref) => HolidayCalendar(),
);

/// The appointments of the manager in the running season.
final appointmentsProvider = Provider<List<Appointment>>((ref) {
  final run = ref.watch(seasonProvider.select((g) => g?.run));
  final club = ref.watch(careerProvider.select((c) => c?.clubId));
  if (run == null || club == null) return const [];
  return AppointmentPlanner(ref.watch(holidayCalendarProvider))
      .build(season: run.timeline.season, timeline: run.timeline, club: club);
});

/// The appointments that are already due: their mails have arrived.
final dueAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final all = ref.watch(appointmentsProvider);
  final today = ref.watch(todayProvider);
  if (today == null) return const [];
  return [
    for (final a in all)
      if (!a.date.isAfter(today)) a,
  ];
});

/// The ids of the mails in the inbox: the three first mails and one mail
/// for every appointment that is due. Newest dynamic mails first.
final inboxIdsProvider = Provider<List<String>>((ref) {
  final due = ref.watch(dueAppointmentsProvider);
  final recent = due.reversed.take(12).map((a) => a.id).toList();
  final over = ref.watch(seasonProvider.select((g) => g?.isOver ?? false));
  return [
    if (over) vacationVerdictId,
    ...recent,
    'jourfix',
    'president',
    'advisor',
    'news',
  ];
});

final vacationPlannerProvider = Provider<VacationPlanner?>((ref) {
  final loaded = ref.watch(loadedWorldProvider).value;
  if (loaded == null) return null;
  return VacationPlanner(
    ref.watch(holidayCalendarProvider),
    minTotal: loaded.calendarRules.vacationWerktage,
    minBlock: loaded.calendarRules.vacationBlockWerktage,
  );
});

/// Working days on which the squad may be given time off: no match of the
/// own club and no cup day.
final vacationAllowedProvider = Provider<Set<int>>((ref) {
  final run = ref.watch(seasonProvider.select((g) => g?.run));
  final club = ref.watch(careerProvider.select((c) => c?.clubId));
  final planner = ref.watch(vacationPlannerProvider);
  if (run == null || club == null || planner == null) return const {};
  final blocked = <int>{};
  for (final day in run.timeline.days) {
    if (day.cupWindows.isNotEmpty) blocked.add(day.date.epochDay);
    for (final slot in day.leagueSlots) {
      for (final k in slot.kicks) {
        if (k.fixture.home == club || k.fixture.away == club) {
          blocked.add(day.date.epochDay);
        }
      }
    }
  }
  return planner.allowedDays(run.timeline.season, blocked);
});

/// The free days the manager has planned for the whole squad (epoch days).
/// Until he plans, the assistant's suggestion stands.
class VacationNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    final planner = ref.watch(vacationPlannerProvider);
    final run = ref.watch(seasonProvider.select((g) => g?.run));
    if (planner == null || run == null) return const {};
    return planner.suggest(
      run.timeline.season,
      ref.read(vacationAllowedProvider),
    );
  }

  bool _editable(GameDate d) {
    final today = ref.read(todayProvider);
    if (today != null && d.isBefore(today)) return false;
    return ref.read(vacationAllowedProvider).contains(d.epochDay);
  }

  /// Day on or off.
  void toggle(GameDate d) {
    if (!_editable(d)) return;
    final next = {...state};
    if (!next.remove(d.epochDay)) next.add(d.epochDay);
    state = next;
  }

  /// All free working days from [from] to [to] on (or off, if [from] is
  /// already planned).
  void setRange(GameDate from, GameDate to) {
    var a = from;
    var b = to;
    if (b.isBefore(a)) {
      a = to;
      b = from;
    }
    final add = !state.contains(from.epochDay);
    final next = {...state};
    for (var d = a; !d.isAfter(b); d = d.plusDays(1)) {
      if (!_editable(d)) continue;
      if (add) {
        next.add(d.epochDay);
      } else {
        next.remove(d.epochDay);
      }
    }
    state = next;
  }

  void clear() {
    final today = ref.read(todayProvider);
    state = {
      for (final e in state)
        if (today != null && e < today.epochDay) e,
    };
  }

  void useSuggestion() {
    final planner = ref.read(vacationPlannerProvider);
    final run = ref.read(seasonProvider)?.run;
    if (planner == null || run == null) return;
    state = planner.suggest(
      run.timeline.season,
      ref.read(vacationAllowedProvider),
    );
  }

  /// Takes over the plan of a saved game.
  void restore(Iterable<int> days) => state = Set.unmodifiable(days);
}

final vacationProvider = NotifierProvider<VacationNotifier, Set<int>>(
  VacationNotifier.new,
);

/// How the plan stands against the rule.
final vacationCheckProvider = Provider<VacationCheck?>((ref) {
  final planner = ref.watch(vacationPlannerProvider);
  final run = ref.watch(seasonProvider.select((g) => g?.run));
  if (planner == null || run == null) return null;
  return planner.check(run.timeline.season, ref.watch(vacationProvider));
});
