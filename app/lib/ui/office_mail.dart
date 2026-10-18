import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/desk.dart';
import '../game/loaded_world.dart';
import '../game/office.dart';
import '../game/planning.dart';
import '../game/season_game.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'person_avatar.dart';
import 'president_look.dart';

/// A mail in the inbox, with the buttons that jump to the desk items it
/// talks about.
class OfficeMail {
  const OfficeMail({
    required this.id,
    required this.sender,
    required this.subject,
    required this.body,
    required this.portrait,
    this.actions = const [],
    this.date,
    this.courtCase,
  });

  final String id;
  final String sender;
  final String subject;
  final String body;
  final Widget portrait;
  final List<(String, DeskItem)> actions;

  /// The day of the mail, null for the first mails of the career.
  final GameDate? date;

  /// An open case of the sports court this mail asks about: the mail then
  /// shows "Annehmen" and "Einspruch" (step 10e3).
  final String? courtCase;
}

/// The two answers to a motion of the control committee.
class CourtButtons extends ConsumerWidget {
  const CourtButtons({required this.caseId, super.key});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Wrap(
      spacing: Tokens.gapS,
      runSpacing: Tokens.gapS,
      children: [
        OutlinedButton(
          key: ValueKey('court-accept-$caseId'),
          onPressed: () => ref
              .read(seasonProvider.notifier)
              .decideCase(caseId, appeal: false),
          child: Text(s.courtAccept),
        ),
        FilledButton(
          key: ValueKey('court-appeal-$caseId'),
          onPressed: () => ref
              .read(seasonProvider.notifier)
              .decideCase(caseId, appeal: true),
          child: Text(s.courtAppeal),
        ),
      ],
    );
  }
}

/// The inbox of the career: the "Jour Fix" before the match day, then the
/// president, the advisor and the news.
List<OfficeMail> buildMails(
  AppStrings s,
  Career career,
  LoadedWorld loaded,
  OfficeView view, {
  List<Appointment> due = const [],
  SeasonGame? game,
  VacationCheck? vacation,
  List<Appointment> all = const [],
  int absent = 0,
}) {
  final offer = career.offer;
  final look = PresidentLook.of(offer.president);
  final trainer = career.trainer;
  final story = loaded.rules.career.backstory(trainer.backstoryId);
  final president = '${s.officeSenderPresident} ${offer.president.name}';
  final presidentPortrait = PersonAvatar(
    appearance: look.appearance,
    extras: look.extras,
    size: 72,
  );
  String jourFix(Appointment a) {
    final lines = <String>[s.jourFixGreeting];
    final past = game?.history.where((r) => !r.date.isAfter(a.date)).toList();
    if (past == null || past.isEmpty) {
      lines.add(s.jourFixNoMatch);
    } else {
      final r = past.last;
      lines.add(
        s.jourFixReview(
          opponent: loaded.club(r.opponent).name,
          home: r.home,
          goalsFor: r.goalsFor,
          goalsAgainst: r.goalsAgainst,
          seed: a.date.epochDay + r.goalsFor * 7 + r.goalsAgainst,
          cup: r.competition == Competition.league
              ? null
              : s.cupName(r.competition),
          wentThrough: r.wentThrough,
        ),
      );
    }
    if (game != null) {
      final table = game.run.tables[game.ownLeague];
      if (table != null && game.played > 0) {
        final standing = table.standing;
        final place = standing.indexWhere((e) => e.club == game.clubId) + 1;
        if (place > 0) lines.add(s.jourFixTable(place, standing.length));
      }
      lines.add(s.jourFixAbsent(absent));
    }
    lines.add(s.jourFixNext(view.matchday, view.opponent.name, view.atHome));
    final others = all
        .where(
          (x) =>
              x.id != a.id &&
              x.kind != AppointmentKind.jourFix &&
              !x.date.isBefore(a.date) &&
              x.date.epochDay < a.date.epochDay + 7,
        )
        .toList();
    if (others.isNotEmpty) {
      lines.add(
        s.jourFixAppointments(
          others
              .map(
                (x) =>
                    '${s.apptName(x.kind, x.variant)} '
                    '(${s.weekdayShort(x.date.weekday)} ${x.date.day}.'
                    '${x.date.month}.)',
              )
              .join(', '),
        ),
      );
    }
    if (vacation != null && !vacation.kept) {
      lines.add(s.jourFixVacation(vacation.total, vacation.minTotal));
    }
    final g = game;
    if (g != null) {
      final next = g.runner.nextMatchOf(g.run, g.clubId);
      if (next != null) {
        final home = view.atHome ? g.clubId : view.opponent.id;
        lines.add(
          s.jourFixForecast(g.runner.forecastOn(home, next.$1.epochDay)),
        );
      }
    }
    lines.add(s.jourFixSign);
    return lines.join('\n\n');
  }

  final appointmentMails = <OfficeMail>[
    for (final a in due)
      OfficeMail(
        id: a.id,
        sender: president,
        subject: s.apptMailSubject(a.kind, a.variant, 0),
        body: a.kind == AppointmentKind.jourFix
            ? jourFix(a)
            : s.apptMailBody(
                a.kind,
                a.variant,
                manager: trainer.name,
                goal: s.seasonGoalText(career.goal),
                club: offer.club.name,
              ),
        portrait: presidentPortrait,
        date: a.date,
        actions: a.kind == AppointmentKind.jourFix
            ? [
                (s.jourFixToTactics, DeskItem.tactics),
                (s.jourFixToCalendar, DeskItem.calendar),
              ]
            : const [],
      ),
  ];
  final verdict = game != null && game.end != null && vacation != null
      ? OfficeMail(
          id: vacationVerdictId,
          sender: s.officeSenderAdvisor,
          subject: s.vacVerdictSubject(vacation.kept),
          body: s.vacVerdictBody(
            vacation.total,
            vacation.minTotal,
            vacation.longestBlock,
            vacation.minBlock,
          ),
          portrait: const _Initial('B'),
          actions: [(s.jourFixToCalendar, DeskItem.calendar)],
        )
      : null;
  final end = game?.end;
  OfficeMail? seasonEnd;
  if (end != null) {
    final leagues = {for (final l in loaded.world.leagues) l.id: l};
    seasonEnd = OfficeMail(
      id: seasonEndId,
      sender: president,
      subject: s.seasonEndSubject(end.startYear, end.review.dismissed),
      body: s.seasonEndBody(
        startYear: end.startYear,
        league: career.league.name,
        rank: end.rank,
        teams: end.teams,
        champion: loaded.club(end.champion).name,
        cupWinner: end.cupWinner == null
            ? null
            : loaded.club(end.cupWinner!).name,
        levelChange: end.levelChange,
        nextLeague: end.nextLeague == null
            ? null
            : leagues[end.nextLeague]!.name,
        verdict: end.review.verdict,
        gap: end.review.gap,
        goal: end.review.goal,
        dismissed: end.review.dismissed,
      ),
      portrait: presidentPortrait,
    );
  }
  String playerName(PlayerId id) => loaded.player(id)?.lastName ?? '?';
  final courtMails = <OfficeMail>[
    if (game != null)
      for (final c in game.runner.casesOf(game.clubId).reversed)
        OfficeMail(
          id: 'court:${c.id}',
          sender: s.courtSender,
          subject: s.courtSubject(playerName(c.player), c.status),
          body: s.courtBody(
            player: playerName(c.player),
            kind: c.kind,
            competition: c.competition == Competition.league
                ? null
                : s.cupName(c.competition),
            motion: c.motion,
            weeks: c.weeks,
            status: c.status,
            verdict: c.verdict,
          ),
          portrait: const _Initial('§'),
          date: c.date.plusDays(1),
          courtCase: c.status == CourtStatus.open ? c.id : null,
        ),
  ];
  return [
    ?seasonEnd,
    ?verdict,
    ...courtMails,
    ...appointmentMails,
    OfficeMail(
      id: 'jourfix',
      sender: president,
      subject: s.jourFixSubject(view.matchday),
      body: s.jourFixBody(
        // At the start of the week all other mails are still unread.
        unread: 3,
        matchday: view.matchday,
        opponent: view.opponent.name,
        home: view.atHome,
      ),
      portrait: presidentPortrait,
      actions: [
        (s.jourFixToPost, DeskItem.post),
        (s.jourFixToTactics, DeskItem.tactics),
        (s.jourFixToCalendar, DeskItem.calendar),
      ],
    ),
    OfficeMail(
      id: 'president',
      sender: '${s.officeSenderPresident} ${offer.president.name}',
      subject: s.officeMailSubjectPresident(offer.club.name),
      body: s.officeMailBodyPresident(offer.president.typeId, trainer.name),
      portrait: presidentPortrait,
    ),
    OfficeMail(
      id: 'advisor',
      sender: s.officeSenderAdvisor,
      subject: s.officeMailSubjectAdvisor,
      body: s.officeMailBodyAdvisor(
        goal: s.seasonGoalText(career.goal),
        budget: s.money(offer.budget),
        squad: view.squadSize,
        opponent: view.opponent.name,
        home: view.atHome,
      ),
      portrait: const _Initial('B'),
    ),
    OfficeMail(
      id: 'news',
      sender: s.officeSenderNews,
      subject: s.officeMailSubjectNews(offer.situation),
      body: s.officeMailBodyNews(
        name: trainer.name,
        club: offer.club.name,
        backstory: s.backstoryName(trainer.backstoryId),
        hook: s.backstoryHook(story.hook),
      ),
      portrait: const _Initial('E'),
    ),
  ];
}

/// A round letter badge for senders without a portrait.
class _Initial extends StatelessWidget {
  const _Initial(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Tokens.panel,
      child: Text(
        letter,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: Tokens.yellow),
      ),
    );
  }
}
