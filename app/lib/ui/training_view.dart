import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/lineup.dart';
import '../game/loaded_world.dart';
import '../game/season_game.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'info_button.dart';

/// The training of the own club (step 11a): the next seven days with up to
/// three units each, templates, the generator and the freshness of the
/// squad. Part of the player files ("Kader und Training").
class TrainingView extends ConsumerWidget {
  const TrainingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final game = ref.watch(seasonProvider);
    final loaded = ref.watch(loadedWorldProvider).value;
    if (game == null || loaded == null) {
      return Center(child: Text(s.trainingNone));
    }
    final runner = game.runner;
    final club = game.clubId;
    final today = game.today.epochDay;
    final matchDays = runner.matchDaysOf(club);
    final squad = runner.squadOf(club);
    final fresh = squad.isEmpty
        ? 100.0
        : squad
                  .map(
                    (p) =>
                        runner.freshnessOf(p.id, club: club, epochDay: today),
                  )
                  .reduce((a, b) => a + b) /
              squad.length;
    final days = [for (var d = today; d < today + 7; d++) d];
    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.trainingFreshness(fresh.round()),
                key: const ValueKey('training-fresh'),
                style: theme.textTheme.titleSmall,
              ),
            ),
            InfoButton(message: s.infoTraining),
          ],
        ),
        Builder(
          builder: (context) {
            final sheet = ref.watch(lineupProvider)?.sheet;
            final knowledge = runner.systemKnowledgeOf(club);
            final (att, def) = runner.setPiecesOf(club);
            final system = sheet?.systemId;
            return Text(
              s.trainingKnowledge(
                system == null ? null : s.systemName(system),
                system == null ? null : knowledge[system]!.round(),
                att.round(),
                def.round(),
              ),
              key: const ValueKey('training-knowledge'),
              style: theme.textTheme.bodySmall,
            );
          },
        ),
        const SizedBox(height: Tokens.gapS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('training-template'),
              onPressed: () => _pickTemplate(context, ref, days, matchDays),
              icon: const Icon(Icons.view_week_outlined),
              label: Text(s.trainingTemplate),
            ),
            OutlinedButton.icon(
              key: const ValueKey('training-generator'),
              onPressed: () => _generate(context, ref, days, matchDays),
              icon: const Icon(Icons.auto_fix_high),
              label: Text(s.trainingGenerator),
            ),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        for (final d in days)
          _DayCard(
            key: ValueKey('training-day-$d'),
            day: d,
            match: matchDays.contains(d),
            plan: runner.trainingDayOf(club, d),
            onTap: matchDays.contains(d)
                ? null
                : () => _editDay(context, ref, d),
          ),
        const SizedBox(height: Tokens.gapM),
        Row(
          children: [
            Expanded(
              child: Text(
                s.trainingIndividual,
                style: theme.textTheme.titleSmall,
              ),
            ),
            InfoButton(message: s.infoTrainingIndividual),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('individual-auto'),
            onPressed: () {
              final notifier = ref.read(seasonProvider.notifier);
              for (final p in squad) {
                if (runner.individualOf(p.id) != null) continue;
                final plan = runner.suggestIndividual(p);
                if (plan != null) notifier.setIndividual(p.id, plan);
              }
            },
            icon: const Icon(Icons.auto_fix_high, size: 18),
            label: Text(s.trainingIndividualAuto),
          ),
        ),
        for (final p in squad)
          ListTile(
            key: ValueKey('individual-${p.id.value}'),
            dense: true,
            title: Text(p.displayName),
            subtitle: Text(
              s.trainingIndividualLabel(
                runner.individualOf(p.id),
                runner.learntWeeks(p.id),
              ),
            ),
            trailing: Text(p.position.id),
            onTap: () => _editIndividual(context, ref, p),
          ),
      ],
    );
  }

  Future<void> _editIndividual(
    BuildContext context,
    WidgetRef ref,
    Player p,
  ) async {
    final s = ref.read(stringsProvider);
    final rules = ref.read(loadedWorldProvider).value!.rules;
    final roles = [
      for (final r in rules.tactics.roles)
        if (r.positions.contains(p.position)) r.id,
    ];
    final plan = await showModalBottomSheet<(IndividualPlan?,)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Tokens.panel,
      builder: (sheet) {
        final theme = Theme.of(sheet);
        Widget head(String t) => Padding(
          padding: const EdgeInsets.only(top: Tokens.gapS, bottom: 4),
          child: Text(t, style: theme.textTheme.titleSmall),
        );
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Tokens.gapM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.displayName, style: theme.textTheme.titleMedium),
                TextButton(
                  key: const ValueKey('individual-none'),
                  onPressed: () => Navigator.of(sheet).pop((null,)),
                  child: Text(s.trainingIndividualNone),
                ),
                head(s.trainingIndividualUnits),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final u in rules.season.training.units.values)
                      if (u.targets.isNotEmpty &&
                          (u.id != 'goalkeeping' || p.position.isGoalkeeper))
                        ActionChip(
                          key: ValueKey('individual-unit-${u.id}'),
                          label: Text(s.trainingUnitName(u.id)),
                          onPressed: () =>
                              Navigator.of(sheet)
                                  .pop((IndividualPlan.unit(u.id),)),
                        ),
                  ],
                ),
                if (!p.position.isGoalkeeper) ...[
                  head(s.trainingIndividualPosition),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final pos in Position.values)
                        if (!pos.isGoalkeeper && pos != p.position)
                          ActionChip(
                            key: ValueKey('individual-pos-${pos.id}'),
                            label: Text(pos.id),
                            onPressed: () =>
                                Navigator.of(sheet)
                                    .pop((IndividualPlan.position(pos),)),
                          ),
                    ],
                  ),
                ],
                if (roles.isNotEmpty) ...[
                  head(s.trainingIndividualRole),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in roles)
                        ActionChip(
                          key: ValueKey('individual-role-$r'),
                          label: Text(s.roleName(r)),
                          onPressed: () =>
                              Navigator.of(sheet)
                                  .pop((IndividualPlan.role(r),)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (plan == null) return;
    ref.read(seasonProvider.notifier).setIndividual(p.id, plan.$1);
  }

  Future<void> _pickTemplate(
    BuildContext context,
    WidgetRef ref,
    List<int> days,
    Set<int> matchDays,
  ) async {
    final s = ref.read(stringsProvider);
    final rules = ref.read(loadedWorldProvider).value!.rules.season.training;
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Tokens.panel,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final t in rules.templates.keys)
              ListTile(
                key: ValueKey('template-$t'),
                title: Text(s.trainingTemplateName(t)),
                subtitle: Text(s.trainingTemplateHint(t)),
                onTap: () => Navigator.of(sheet).pop(t),
              ),
          ],
        ),
      ),
    );
    if (id == null) return;
    final planner = TrainingPlanner(rules);
    final notifier = ref.read(seasonProvider.notifier);
    for (final d in days) {
      if (matchDays.contains(d)) continue;
      notifier.setTrainingDay(d, planner.fromTemplate(id, d, matchDays));
    }
  }

  Future<void> _generate(
    BuildContext context,
    WidgetRef ref,
    List<int> days,
    Set<int> matchDays,
  ) async {
    final s = ref.read(stringsProvider);
    final rules = ref.read(loadedWorldProvider).value!.rules.season.training;
    final goals = <String>[];
    var intensity = Intensity.normal;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Tokens.panel,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Tokens.gapM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.trainingGeneratorTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Tokens.gapS),
                for (final g in rules.groups.entries) ...[
                  Text(s.trainingGroupName(g.key)),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final u in g.value)
                        if (u.group != 'recovery')
                          FilterChip(
                            key: ValueKey('goal-${u.id}'),
                            label: Text(s.trainingUnitName(u.id)),
                            selected: goals.contains(u.id),
                            onSelected: (on) => setSheet(
                              () => on ? goals.add(u.id) : goals.remove(u.id),
                            ),
                          ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                SegmentedButton<Intensity>(
                  segments: [
                    for (final i in Intensity.values)
                      ButtonSegment(
                        value: i,
                        label: Text(s.trainingIntensityName(i)),
                      ),
                  ],
                  selected: {intensity},
                  onSelectionChanged: (v) =>
                      setSheet(() => intensity = v.first),
                ),
                const SizedBox(height: Tokens.gapM),
                FilledButton(
                  key: const ValueKey('generator-go'),
                  onPressed: goals.isEmpty
                      ? null
                      : () => Navigator.of(sheet).pop(true),
                  child: Text(s.trainingGeneratorGo),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final planner = TrainingPlanner(rules);
    final notifier = ref.read(seasonProvider.notifier);
    var index = 0;
    for (final d in days) {
      if (matchDays.contains(d)) continue;
      notifier.setTrainingDay(
        d,
        planner.fromGoals(goals, intensity, d, matchDays, index: index++),
      );
    }
  }

  Future<void> _editDay(BuildContext context, WidgetRef ref, int day) async {
    final s = ref.read(stringsProvider);
    final game = ref.read(seasonProvider)!;
    final rules = ref.read(loadedWorldProvider).value!.rules.season.training;
    final now = game.runner.trainingDayOf(game.clubId, day).sessions;
    final slots = <TrainingSession?>[
      for (var i = 0; i < TrainingDay.maxSessions; i++)
        i < now.length ? now[i] : null,
    ];
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Tokens.panel,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Tokens.gapM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.trainingDayTitle(GameDate.fromEpochDay(day)),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (var i = 0; i < slots.length; i++) ...[
                  const SizedBox(height: Tokens.gapS),
                  Text(s.trainingSlotName(i)),
                  DropdownButton<String?>(
                    key: ValueKey('slot-$i'),
                    isExpanded: true,
                    value: slots[i]?.unit,
                    items: [
                      DropdownMenuItem(child: Text(s.trainingNoUnit)),
                      for (final u in rules.units.values)
                        DropdownMenuItem(
                          value: u.id,
                          child: Text(
                            '${s.trainingGroupName(u.group)} · '
                            '${s.trainingUnitName(u.id)}',
                          ),
                        ),
                    ],
                    onChanged: (id) => setSheet(
                      () => slots[i] = id == null
                          ? null
                          : TrainingSession(
                              id,
                              slots[i]?.intensity ?? Intensity.normal,
                            ),
                    ),
                  ),
                  if (slots[i] != null)
                    SegmentedButton<Intensity>(
                      segments: [
                        for (final x in Intensity.values)
                          ButtonSegment(
                            value: x,
                            label: Text(s.trainingIntensityName(x)),
                          ),
                      ],
                      selected: {slots[i]!.intensity},
                      onSelectionChanged: (v) => setSheet(
                        () =>
                            slots[i] = TrainingSession(slots[i]!.unit, v.first),
                      ),
                    ),
                ],
                const SizedBox(height: Tokens.gapM),
                FilledButton(
                  key: const ValueKey('day-save'),
                  onPressed: () => Navigator.of(sheet).pop(true),
                  child: Text(s.trainingSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    ref
        .read(seasonProvider.notifier)
        .setTrainingDay(day, TrainingDay([...slots.nonNulls]));
  }
}

class _DayCard extends ConsumerWidget {
  const _DayCard({
    required this.day,
    required this.match,
    required this.plan,
    required this.onTap,
    super.key,
  });

  final int day;
  final bool match;
  final TrainingDay plan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final date = GameDate.fromEpochDay(day);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Tokens.gapS),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  '${s.weekdayShort(date.weekday)} ${date.day}.${date.month}.',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Expanded(
                child: match
                    ? Text(
                        s.trainingMatchDay,
                        style: theme.textTheme.bodyMedium,
                      )
                    : plan.sessions.isEmpty
                    ? Text(s.trainingRestDay, style: theme.textTheme.bodySmall)
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final x in plan.sessions)
                            Chip(
                              label: Text(
                                '${s.trainingUnitName(x.unit)} · '
                                '${s.trainingIntensityShort(x.intensity)}',
                              ),
                            ),
                        ],
                      ),
              ),
              if (onTap != null) const Icon(Icons.edit, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
