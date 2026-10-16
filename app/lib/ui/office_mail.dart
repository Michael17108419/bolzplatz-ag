import 'package:flutter/material.dart';
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
  });

  final String id;
  final String sender;
  final String subject;
  final String body;
  final Widget portrait;
  final List<(String, DeskItem)> actions;
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
              .map((x) => '${s.apptName(x.kind, x.variant)} '
                  '(${s.weekdayShort(x.date.weekday)} ${x.date.day}.'
                  '${x.date.month}.)')
              .join(', '),
        ),
      );
    }
    if (vacation != null && !vacation.kept) {
      lines.add(s.jourFixVacation(vacation.total, vacation.minTotal));
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
                goal: s.seasonGoalText(offer.goal),
                club: offer.club.name,
              ),
        portrait: presidentPortrait,
        actions: a.kind == AppointmentKind.jourFix
            ? [
                (s.jourFixToTactics, DeskItem.tactics),
                (s.jourFixToCalendar, DeskItem.calendar),
              ]
            : const [],
      ),
  ];
  final verdict = game != null && game.isOver && vacation != null
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
  return [
    ?verdict,
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
        goal: s.seasonGoalText(offer.goal),
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
