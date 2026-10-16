import '../model/ids.dart';
import '../season/timeline.dart';
import 'game_date.dart';
import 'holidays.dart';
import 'season.dart';

/// The kinds of appointments in the calendar of the manager.
enum AppointmentKind {
  /// The weekly meeting with the president on the first working day after
  /// the match (looks back at the match, looks ahead at the week).
  jourFix,

  /// The monthly talk with the president.
  presidentTalk,

  /// A press conference.
  pressTalk,

  /// A meeting with the sponsor.
  sponsorTalk,
}

/// One appointment of the manager on a day.
class Appointment {
  const Appointment({
    required this.kind,
    required this.date,
    required this.minuteOfDay,
    this.variant = 0,
    this.needsDecision = false,
  });

  final AppointmentKind kind;
  final GameDate date;

  /// Minutes after midnight.
  final int minuteOfDay;

  /// Tells apart appointments of one kind in a season (the press
  /// conference before the season and the one in winter).
  final int variant;

  /// True if the manager has to decide something. "Weiter" stops there.
  /// No appointment asks for a decision yet.
  final bool needsDecision;

  /// Stable id, for example for mails.
  String get id => '${kind.name}:$variant:${date.epochDay}';
}

/// Plans the appointments of a season. Everything depends only on the
/// calendar and the matches of the club, so a loaded game gets the same.
class AppointmentPlanner {
  AppointmentPlanner(this.holidays);

  final HolidayCalendar holidays;

  /// Appointments of [season] for [club], in date order. They never fall on
  /// a day with a match of the club, on a day before one or on a holiday.
  List<Appointment> build({
    required Season season,
    required SeasonTimeline timeline,
    required ClubId club,
  }) {
    final ownLeague = <int>[];
    final busy = <int>{};
    for (final day in timeline.days) {
      var own = false;
      for (final slot in day.leagueSlots) {
        for (final k in slot.kicks) {
          if (k.fixture.home == club || k.fixture.away == club) own = true;
        }
      }
      if (own) {
        ownLeague.add(day.date.epochDay);
        busy.add(day.date.epochDay);
      }
      // Cup days count as busy for every club: the draw is not known yet.
      if (day.cupWindows.isNotEmpty) busy.add(day.date.epochDay);
    }

    bool free(GameDate d) =>
        !busy.contains(d.epochDay) &&
        !holidays.isHoliday(d) &&
        !holidays.isNoFootballDay(d) &&
        d.weekday <= 5;

    /// The first free day on or after [from], looking at most [max] days on.
    GameDate? firstFree(GameDate from, {int max = 10, bool eve = false}) {
      var d = from;
      for (var i = 0; i < max; i++) {
        if (free(d) && (!eve || !busy.contains(d.epochDay + 1))) return d;
        d = d.plusDays(1);
      }
      return null;
    }

    GameDate? firstWeekdayFree(GameDate from, int weekday) {
      var d = from;
      while (d.weekday != weekday) {
        d = d.plusDays(1);
      }
      for (var i = 0; i < 4; i++) {
        final f = firstFree(d, max: 5, eve: true);
        if (f != null) return f;
        d = d.plusDays(7);
      }
      return null;
    }

    final out = <Appointment>[];
    void add(
      AppointmentKind kind,
      GameDate? date,
      int minute, {
      int variant = 0,
    }) {
      if (date == null || !season.contains(date)) return;
      out.add(
        Appointment(
          kind: kind,
          date: date,
          minuteOfDay: minute,
          variant: variant,
        ),
      );
    }

    // Jour Fix: every Monday after a week with a league match.
    var monday = season.start.plusDays((8 - season.start.weekday) % 7);
    while (!monday.isAfter(season.end)) {
      final from = monday.epochDay - 7;
      final played = ownLeague.any((e) => e >= from && e < monday.epochDay);
      if (played) {
        var d = monday;
        for (var i = 0; i < 4; i++) {
          if (free(d)) {
            add(AppointmentKind.jourFix, d, 10 * 60);
            break;
          }
          d = d.plusDays(1);
        }
      }
      monday = monday.plusDays(7);
    }

    // Talk with the president: once a month from August to May.
    for (var i = 0; i < 10; i++) {
      final month = ((7 + i) % 12) + 1;
      final year = month >= 7 ? season.startYear : season.startYear + 1;
      add(
        AppointmentKind.presidentTalk,
        firstWeekdayFree(GameDate(year, month, 12), 4),
        15 * 60,
      );
    }

    // Press conferences: before the first match and after the autumn round.
    if (ownLeague.isNotEmpty) {
      final first = GameDate.fromEpochDay(ownLeague.first);
      var d = first.plusDays(-3);
      for (var i = 0; i < 6; i++) {
        if (free(d)) break;
        d = d.plusDays(-1);
      }
      add(AppointmentKind.pressTalk, d, 11 * 60);
      final winterEdge = GameDate(season.startYear, 12, 22);
      final beforeWinter = ownLeague.where((e) => e <= winterEdge.epochDay);
      if (beforeWinter.isNotEmpty) {
        final last = GameDate.fromEpochDay(beforeWinter.last);
        add(
          AppointmentKind.pressTalk,
          firstFree(last.plusDays(2)),
          11 * 60,
          variant: 1,
        );
      }
    }

    // Sponsor: in July and in February.
    add(
      AppointmentKind.sponsorTalk,
      firstWeekdayFree(GameDate(season.startYear, 7, 10), 2),
      16 * 60,
    );
    add(
      AppointmentKind.sponsorTalk,
      firstWeekdayFree(GameDate(season.startYear + 1, 2, 10), 2),
      16 * 60,
      variant: 1,
    );

    out.sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.minuteOfDay.compareTo(b.minuteOfDay);
    });
    return List.unmodifiable(out);
  }
}
