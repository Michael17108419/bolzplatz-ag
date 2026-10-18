import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/dates.dart';
import '../game/season_game.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'info_button.dart';
import 'person_avatar.dart';
import 'screen_frame.dart';

/// The profile of the manager (step 11e): values with arrows since the
/// start of the season, licence, the licence question and the courses.
class TrainerPage extends ConsumerWidget {
  const TrainerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final career = ref.watch(careerProvider);
    final game = ref.watch(seasonProvider);
    if (career == null) return const SizedBox.shrink();
    final base = career.trainer;
    final runner = game?.runner;
    final club = career.clubId;
    final now =
        runner?.trainerOf(club, epochDay: game!.today.epochDay) ?? base;
    final missing = runner?.licenceMissing(club);
    final progress = runner?.progressOf(club);
    return ScreenFrame(
      title: s.officeTrainerProfile,
      child: ListView(
        key: const ValueKey('trainer-page'),
        children: [
          Row(
            children: [
              PersonAvatar(appearance: base.appearance, size: 64),
              const SizedBox(width: Tokens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(base.name, style: theme.textTheme.headlineSmall),
                    Text(
                      s.backstoryName(base.backstoryId),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      s.trainerLicenceLine(
                        s.trainerLicenceName(now.licence),
                        now.seasons,
                      ),
                      key: const ValueKey('trainer-licence'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              InfoButton(message: s.infoTrainer),
            ],
          ),
          if (missing != null) ...[
            const SizedBox(height: Tokens.gapM),
            _LicenceCard(
              missing: missing,
              cover: progress?.cover,
              growth: runner?.rules.career.growth,
            ),
          ],
          if (runner != null && progress != null) ...[
            const SizedBox(height: Tokens.gapM),
            _CourseCard(game: game!, now: now, progress: progress),
          ],
          const SizedBox(height: Tokens.gapM),
          Text(s.trainerValuesHeading, style: theme.textTheme.titleMedium),
          for (final v in ManagerValue.values)
            ListTile(
              key: ValueKey('trainer-value-${v.id}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(s.managerValueName(v)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    now[v].round().toString(),
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      _arrow(now[v] - base[v]),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  InfoButton(message: s.managerValueInfo(v)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _arrow(double d) {
    if (d >= 0.5) return '▲ ${d.toStringAsFixed(1)}';
    if (d <= -0.5) return '▼ ${(-d).toStringAsFixed(1)}';
    return '';
  }
}

class _LicenceCard extends ConsumerWidget {
  const _LicenceCard({
    required this.missing,
    required this.cover,
    required this.growth,
  });

  final Licence missing;
  final LicenceCover? cover;
  final GrowthRules? growth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final chosen = cover;
    return Card(
      key: const ValueKey('trainer-licence-card'),
      child: Padding(
        padding: const EdgeInsets.all(Tokens.gapM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.trainerLicenceMissing(s.trainerLicenceName(missing))),
            const SizedBox(height: Tokens.gapS),
            if (chosen != null)
              Text(s.trainerCoverChosen(chosen))
            else ...[
              Text(
                s.trainerCoverHint(
                  (growth?.waiverTrust ?? 0).round(),
                  (growth?.strawPress ?? 0).round(),
                ),
              ),
              const SizedBox(height: Tokens.gapS),
              FilledButton(
                key: const ValueKey('trainer-cover-waiver'),
                onPressed: () => ref
                    .read(seasonProvider.notifier)
                    .setLicenceCover(LicenceCover.waiver),
                child: Text(s.trainerCoverName(LicenceCover.waiver)),
              ),
              const SizedBox(height: Tokens.gapS),
              OutlinedButton(
                key: const ValueKey('trainer-cover-straw'),
                onPressed: () => ref
                    .read(seasonProvider.notifier)
                    .setLicenceCover(LicenceCover.strawMan),
                child: Text(s.trainerCoverName(LicenceCover.strawMan)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({
    required this.game,
    required this.now,
    required this.progress,
  });

  final SeasonGame game;
  final Trainer now;
  final TrainerProgress progress;

  /// Days a course could start on, with the first reason against one when
  /// there is none.
  (List<int>, String) _options() {
    final runner = game.runner;
    final club = game.clubId;
    final from = game.today.epochDay + 1;
    final days = <int>[];
    String? reason;
    for (final w in runner.courseWindowsOf(club)) {
      for (var d = w.$1 < from ? from : w.$1; d <= w.$2; d++) {
        final block = runner.courseBlock(club, d);
        if (block == null) {
          days.add(d);
        } else {
          reason ??= block;
        }
      }
    }
    return (days, reason ?? 'window');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final growth = game.runner.rules.career.growth;
    final next = now.licence.next;
    final (days, reason) = _options();
    return Card(
      key: const ValueKey('trainer-course-card'),
      child: Padding(
        padding: const EdgeInsets.all(Tokens.gapM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.trainerCourseHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: Tokens.gapS),
            for (final c in progress.courses)
              Text(
                s.trainerCourseBooked(
                  s.trainerLicenceName(c.licence),
                  formatDate(s, GameDate.fromEpochDay(c.start)),
                  c.days,
                  s.managerValueName(c.value),
                ),
              ),
            if (next == null)
              Text(s.trainerCourseNone)
            else ...[
              Text(
                s.trainerCourseNext(
                  s.trainerLicenceName(next),
                  growth.courseDays[next] ?? 0,
                ),
              ),
              const SizedBox(height: Tokens.gapS),
              if (days.isEmpty)
                Text(
                  s.trainerCourseBlocked(reason),
                  key: const ValueKey('trainer-course-blocked'),
                )
              else
                FilledButton(
                  key: const ValueKey('trainer-course-book'),
                  onPressed: () => _book(context, ref, days),
                  child: Text(s.trainerCourseBook),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _book(BuildContext context, WidgetRef ref, List<int> days) {
    final s = ref.read(stringsProvider);
    var day = days.first;
    var value = ManagerValue.tacticalKnowledge;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Tokens.gapM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.trainerCourseBook,
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
                const SizedBox(height: Tokens.gapS),
                DropdownButton<int>(
                  key: const ValueKey('trainer-course-day'),
                  isExpanded: true,
                  value: day,
                  items: [
                    for (final d in days)
                      DropdownMenuItem(
                        value: d,
                        child: Text(
                          '${s.trainerCourseStart}: '
                          '${formatDate(s, GameDate.fromEpochDay(d))}',
                        ),
                      ),
                  ],
                  onChanged: (d) => setState(() => day = d ?? day),
                ),
                const SizedBox(height: Tokens.gapS),
                Text(s.trainerCourseValue),
                Wrap(
                  spacing: Tokens.gapS,
                  children: [
                    for (final v in ManagerValue.values)
                      if (v.isSkill)
                        ChoiceChip(
                          key: ValueKey('trainer-course-value-${v.id}'),
                          label: Text(s.managerValueName(v)),
                          selected: value == v,
                          onSelected: (_) => setState(() => value = v),
                        ),
                  ],
                ),
                const SizedBox(height: Tokens.gapM),
                FilledButton(
                  key: const ValueKey('trainer-course-confirm'),
                  onPressed: () {
                    final ok = ref
                        .read(seasonProvider.notifier)
                        .bookCourse(day, value);
                    Navigator.of(sheet).pop();
                    if (ok) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(s.trainerCourseDone)));
                    }
                  },
                  child: Text(s.trainerCourseConfirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
