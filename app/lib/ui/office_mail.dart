import 'package:flutter/material.dart';

import '../game/career.dart';
import '../game/desk.dart';
import '../game/loaded_world.dart';
import '../game/office.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'person_avatar.dart';
import 'president_look.dart';

/// The ids of all mails in the inbox, newest first.
const List<String> officeMailIds = ['jourfix', 'president', 'advisor', 'news'];

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
  OfficeView view,
) {
  final offer = career.offer;
  final look = PresidentLook.of(offer.president);
  final trainer = career.trainer;
  final story = loaded.rules.career.backstory(trainer.backstoryId);
  return [
    OfficeMail(
      id: 'jourfix',
      sender: s.officeSenderJourFix,
      subject: s.jourFixSubject(view.matchday),
      body: s.jourFixBody(
        // At the start of the week all other mails are still unread.
        unread: officeMailIds.length - 1,
        matchday: view.matchday,
        opponent: view.opponent.name,
        home: view.atHome,
      ),
      portrait: const _Initial('J'),
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
      portrait: PersonAvatar(
        appearance: look.appearance,
        extras: look.extras,
        size: 72,
      ),
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
