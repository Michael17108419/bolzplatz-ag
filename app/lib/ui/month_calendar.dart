import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/planning.dart';
import '../game/season_game.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'info_button.dart';

/// What happens on one day of the month view.
class _DayInfo {
  _DayInfo({required this.holiday, required this.breakDay});

  final bool holiday;
  final bool breakDay;
  bool ownMatch = false;
  bool leagueDay = false;
  bool cup = false;
  bool rest = false;
}

/// The month view of the season: matches, cups, holidays and breaks.
class MonthCalendar extends ConsumerStatefulWidget {
  const MonthCalendar({super.key});

  @override
  ConsumerState<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends ConsumerState<MonthCalendar> {
  int? _offset;
  bool _edit = false;
  bool _range = false;
  GameDate? _rangeStart;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final game = ref.watch(seasonProvider);
    final today = ref.watch(todayProvider);
    if (game == null || today == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final season = Season.containing(today);
    // Month index counted from July of the season: 0 to 11.
    final todayIndex = (today.year - season.startYear) * 12 + today.month - 7;
    final index = (_offset ?? todayIndex).clamp(0, 11).toInt();
    final month = (index + 6) % 12 + 1;
    final year = month >= 7 ? season.startYear : season.startYear + 1;

    final vacation = ref.watch(vacationProvider);
    final allowed = ref.watch(vacationAllowedProvider);
    final check = ref.watch(vacationCheckProvider);
    final appointments = {
      for (final a in ref.watch(appointmentsProvider)) a.date.epochDay,
    };
    final timeline = game.run.timeline;
    final holidays = HolidayCalendar();
    final group = timeline.leagueGroup[game.ownLeague];
    final cal = group == null ? null : timeline.calendars[group];
    final breakDays = <int>{
      if (cal != null)
        for (final sat in cal.internationalBreakSaturdays) ...[
          sat.epochDay,
          sat.plusDays(1).epochDay,
        ],
    };

    _DayInfo infoOf(GameDate d) {
      final info = _DayInfo(
        holiday: holidays.isHoliday(d),
        breakDay: breakDays.contains(d.epochDay),
      );
      final plan = timeline.planOn(d);
      if (plan != null) {
        info.leagueDay = plan.hasLeagueMatches;
        info.cup = plan.cupWindows.isNotEmpty;
        for (final slot in plan.leagueSlots) {
          for (final k in slot.kicks) {
            if (k.fixture.home == game.clubId ||
                k.fixture.away == game.clubId) {
              info.ownMatch = true;
            }
          }
        }
      }
      final v = cal?.vacation;
      if (v != null) {
        info.rest =
            (!d.isBefore(v.summerStart) && !d.isAfter(v.summerEnd)) ||
            (!d.isBefore(v.winterStart) && !d.isAfter(v.winterEnd));
      }
      return info;
    }

    final first = GameDate(year, month, 1);
    final days = GameDate.daysInMonth(year, month);
    final lead = first.weekday - 1;
    final cells = <Widget>[];
    for (var i = 0; i < lead; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= days; day++) {
      final d = GameDate(year, month, day);
      final info = infoOf(d);
      final isToday = d == today;
      final off = vacation.contains(d.epochDay);
      final canEdit =
          _edit && allowed.contains(d.epochDay) && !d.isBefore(today);
      final Color? fill = off
          ? Tokens.sky.withValues(alpha: 0.7)
          : info.ownMatch
          ? Tokens.yellow
          : info.leagueDay
          ? Tokens.green.withValues(alpha: 0.35)
          : info.cup
          ? Tokens.orange.withValues(alpha: 0.5)
          : info.breakDay
          ? Tokens.beige.withValues(alpha: 0.3)
          : info.rest
          ? Tokens.panel
          : null;
      Widget cell = Container(
        key: ValueKey('cal-day-$day'),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: Tokens.text, width: 2)
              : info.holiday
              ? Border.all(color: Tokens.orange)
              : null,
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: info.ownMatch || off ? Tokens.ink : null,
                fontWeight: info.ownMatch || isToday ? FontWeight.bold : null,
              ),
            ),
            if (appointments.contains(d.epochDay))
              Positioned(
                bottom: 2,
                child: Container(
                  key: ValueKey('cal-appt-$day'),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: info.ownMatch || off ? Tokens.ink : Tokens.yellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      );
      if (canEdit || (_edit && _range && _rangeStart != null)) {
        cell = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final notifier = ref.read(vacationProvider.notifier);
            if (!_range) {
              notifier.toggle(d);
            } else if (_rangeStart == null) {
              if (canEdit) setState(() => _rangeStart = d);
            } else {
              notifier.setRange(_rangeStart!, d);
              setState(() => _rangeStart = null);
            }
          },
          child: cell,
        );
      }
      cells.add(cell);
    }

    Widget legend(Color? color, String text, {bool outline = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: outline ? null : color,
            border: outline ? Border.all(color: color ?? Tokens.text) : null,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.gapM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('cal-prev'),
                  onPressed: index > 0
                      ? () => setState(() => _offset = index - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${s.monthName(month)} $year',
                    key: const ValueKey('cal-title'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const ValueKey('cal-next'),
                  onPressed: index < 11
                      ? () => setState(() => _offset = index + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                InfoButton(message: s.infoCalendarMonth),
              ],
            ),
            Row(
              children: [
                for (var w = 1; w <= 7; w++)
                  Expanded(
                    child: Center(
                      child: Text(
                        s.weekdayShort(w),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
              ],
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              childAspectRatio: 1.4,
              children: cells,
            ),
            const SizedBox(height: Tokens.gapS),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                legend(Tokens.yellow, s.calLegendMatch),
                legend(Tokens.green.withValues(alpha: 0.5), s.calLegendLeague),
                legend(Tokens.orange.withValues(alpha: 0.6), s.calLegendCup),
                legend(Tokens.orange, s.calLegendHoliday, outline: true),
                legend(Tokens.beige.withValues(alpha: 0.5), s.calLegendBreak),
                legend(Tokens.panel, s.calLegendRest),
                legend(Tokens.sky.withValues(alpha: 0.7), s.calLegendVacation),
                legend(Tokens.yellow, s.calLegendAppointment),
                legend(Tokens.text, s.calToday, outline: true),
              ],
            ),
            if (check != null) ...[
              const Divider(height: Tokens.gapL),
              Row(
                children: [
                  Expanded(
                    child: Text(s.vacTitle, style: theme.textTheme.titleMedium),
                  ),
                  InfoButton(message: s.infoVacation),
                ],
              ),
              Text(
                s.vacCounter(
                  check.total,
                  check.minTotal,
                  check.longestBlock,
                  check.minBlock,
                ),
                key: const ValueKey('vac-counter'),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                s.vacStatus(check.level, check.blockKept, check.minBlock),
                key: const ValueKey('vac-status'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: Tokens.gapS),
              Wrap(
                spacing: Tokens.gapS,
                runSpacing: Tokens.gapS,
                children: [
                  FilterChip(
                    key: const ValueKey('vac-edit'),
                    label: Text(s.vacEdit),
                    selected: _edit,
                    onSelected: (v) => setState(() {
                      _edit = v;
                      _rangeStart = null;
                    }),
                  ),
                  if (_edit) ...[
                    ChoiceChip(
                      key: const ValueKey('vac-mode-days'),
                      label: Text(s.vacModeDays),
                      selected: !_range,
                      onSelected: (_) => setState(() {
                        _range = false;
                        _rangeStart = null;
                      }),
                    ),
                    ChoiceChip(
                      key: const ValueKey('vac-mode-range'),
                      label: Text(s.vacModeRange),
                      selected: _range,
                      onSelected: (_) => setState(() => _range = true),
                    ),
                  ],
                  OutlinedButton(
                    key: const ValueKey('vac-suggest'),
                    onPressed: () =>
                        ref.read(vacationProvider.notifier).useSuggestion(),
                    child: Text(s.vacSuggest),
                  ),
                  OutlinedButton(
                    key: const ValueKey('vac-clear'),
                    onPressed: () =>
                        ref.read(vacationProvider.notifier).clear(),
                    child: Text(s.vacClear),
                  ),
                ],
              ),
              if (_edit && _range)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(s.vacRangeHint, style: theme.textTheme.bodySmall),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
