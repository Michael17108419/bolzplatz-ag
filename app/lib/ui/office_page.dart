import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/dates.dart';
import '../game/desk.dart';
import '../game/lineup.dart';
import '../game/mail_state.dart';
import '../game/office.dart';
import '../game/office_provider.dart';
import '../game/planning.dart';
import '../game/season_game.dart';
import '../game/settings.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'office_pages.dart';
import 'office_scene.dart';
import 'person_avatar.dart';

/// The home screen of a career: the office as a picture filling the screen.
/// Every thing in it opens one screen, the door and the round play button
/// are "Weiter". The menu (three bars, top left) holds the rest.
class OfficePage extends ConsumerWidget {
  const OfficePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final career = ref.watch(careerProvider);
    final view = ref.watch(officeViewProvider);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
        ...deskBindings(context, ref),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Tokens.ground,
          body: SafeArea(
            child: career == null || view == null
                ? const Center(child: CircularProgressIndicator())
                : _Office(career: career, view: view),
          ),
        ),
      ),
    );
  }
}

class _Office extends ConsumerWidget {
  const _Office({required this.career, required this.view});

  final Career career;
  final OfficeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final offer = career.offer;
    final read = ref.watch(mailReadProvider);
    final lineup = ref.watch(lineupProvider);
    final today = ref.watch(todayProvider);
    final game = ref.watch(seasonProvider);
    // ignore: prefer_null_aware_operators
    final nextMatch = game == null
        ? null
        : game.runner.nextMatchOf(game.run, game.clubId);
    final nextText = game != null && game.isOver
        ? s.deskNextSeason
        : nextMatch != null && nextMatch.$2 != Competition.league
        ? s.deskNextCup(s.cupName(nextMatch.$2))
        : s.deskNext(view.matchday);
    final unread = ref
        .watch(inboxIdsProvider)
        .where((id) => !read.contains(id))
        .length;

    final labels = {
      for (final item in DeskItem.values)
        item: DeskLabel(
          title: item == DeskItem.door ? nextText : s.deskName(item),
          hint: item == DeskItem.press
              ? '${s.deskHint(item)}\n\n'
                    '„${s.officeMailSubjectNews(offer.situation)}“'
              : item == DeskItem.post && unread > 0
              ? '${s.deskHint(item)}\n\n${s.deskBadgePost(unread)}.'
              : s.deskHint(item),
          keyText: item.digit == null ? s.deskKeyDoor : s.deskKey(item.digit!),
        ),
    };

    return Stack(
      children: [
        Positioned.fill(
          child: OfficeScene(
            clubId: offer.club.id.value,
            labels: labels,
            badges: {
              if (unread > 0) DeskItem.post: '$unread',
              if (lineup == null || !lineup.reviewed) DeskItem.tactics: '!',
            },
            onOpen: (item) => openDesk(context, ref, item),
            portrait: (size) =>
                PersonAvatar(appearance: career.trainer.appearance, size: size),
            leagueLabel: s.leagueName(career.league.name),
            calendarTop: today == null
                ? ''
                : '${s.weekdayShort(today.weekday)} · '
                      '${s.monthName(today.month).substring(0, 3)}',
            calendarDay: today == null ? '' : '${today.day}',
          ),
        ),
        Positioned(
          left: 6,
          top: 6,
          child: _MenuButton(
            semanticLabel: s.officeMenuLabel,
            onTap: () => _openMenu(context, ref, today),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 6,
          child: _PlayButton(
            semanticLabel: nextText,
            onTap: () => goNext(context, ref),
          ),
        ),
      ],
    );
  }

  /// The menu: who and where you are, then the way back to the main menu
  /// and to the saves.
  void _openMenu(BuildContext context, WidgetRef ref, GameDate? today) {
    final s = ref.read(stringsProvider);
    final theme = Theme.of(context);
    final offer = career.offer;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Tokens.ground,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.gapM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClubCrest(clubId: offer.club.id.value, size: 48),
                  const SizedBox(width: Tokens.gapM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.club.name,
                          key: const ValueKey('office-club'),
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          '${offer.club.place} · '
                          '${s.leagueName(career.league.name)} · '
                          '${s.officeSeason(view.startYear)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (today != null)
                          Text(
                            formatDate(s, today),
                            key: const ValueKey('office-date'),
                            style: theme.textTheme.titleSmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Tokens.gapS),
                  PersonAvatar(
                    key: const ValueKey('office-trainer'),
                    appearance: career.trainer.appearance,
                    size: 48,
                  ),
                ],
              ),
              const SizedBox(height: Tokens.gapS),
              ListTile(
                key: const ValueKey('menu-saves'),
                title: Text(s.deskName(DeskItem.saves)),
                onTap: () {
                  Navigator.of(sheet).pop();
                  openDesk(context, ref, DeskItem.saves);
                },
              ),
              ListTile(
                key: const ValueKey('menu-main'),
                title: Text(s.officeToMenu),
                onTap: () {
                  Navigator.of(sheet).pop();
                  Navigator.of(context).maybePop();
                },
              ),
              if (ref.read(helpProvider))
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Tokens.gapM,
                    Tokens.gapS,
                    Tokens.gapM,
                    0,
                  ),
                  child: Text(s.infoDesk, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three bars in the green of the club house, drawn like part of the picture
/// (no background).
class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.semanticLabel, required this.onTap});

  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        key: const ValueKey('office-menu'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(painter: _MenuPainter()),
        ),
      ),
    );
  }
}

class _MenuPainter extends CustomPainter {
  const _MenuPainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final bar = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2 + (i - 1) * 11),
          width: 30,
          height: 7,
        ),
        const Radius.circular(3.5),
      );
      canvas.drawRRect(
        bar,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF2B1B12),
      );
      canvas.drawRRect(bar, Paint()..color = const Color(0xFF2E8B57));
    }
  }

  @override
  bool shouldRepaint(_MenuPainter old) => false;
}

/// The round yellow play button: on to the next day. A shadow, an outline and
/// a plain triangle, like the rest of the room.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.semanticLabel, required this.onTap});

  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        key: const ValueKey('office-play'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(painter: _PlayPainter()),
        ),
      ),
    );
  }
}

class _PlayPainter extends CustomPainter {
  const _PlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 - 2);
    const ink = Color(0xFF2B1B12);
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 25), width: 40, height: 8),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawCircle(c, 24, Paint()..color = Tokens.yellow);
    canvas.drawCircle(
      c,
      24,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ink,
    );
    final tri = Path()
      ..moveTo(c.dx - 7, c.dy - 12)
      ..lineTo(c.dx + 13, c.dy)
      ..lineTo(c.dx - 7, c.dy + 12)
      ..close();
    canvas.drawPath(tri, Paint()..color = ink);
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = ink,
    );
  }

  @override
  bool shouldRepaint(_PlayPainter old) => false;
}
