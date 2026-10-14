import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/career.dart';
import '../game/loaded_world.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'placeholder_page.dart';
import 'screen_frame.dart';

/// Choose a league, a club and a manager name, then start the career.
class CareerStartPage extends ConsumerWidget {
  const CareerStartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final world = ref.watch(loadedWorldProvider);
    return ScreenFrame(
      title: s.careerTitle,
      maxWidth: 1100,
      child: world.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: Tokens.gapM),
              Text(s.careerLoading),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text(s.careerLoadFailed)),
        data: (loaded) => _CareerBody(loaded: loaded),
      ),
    );
  }
}

class _CareerBody extends ConsumerStatefulWidget {
  const _CareerBody({required this.loaded});

  final LoadedWorld loaded;

  @override
  ConsumerState<_CareerBody> createState() => _CareerBodyState();
}

class _CareerBodyState extends ConsumerState<_CareerBody> {
  late League _league = widget.loaded.world.leagues.firstWhere(
    (l) => l.level == 1,
  );
  Club? _club;
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _start() {
    final club = _club;
    if (club == null || _name.text.trim().isEmpty) return;
    ref
        .read(careerProvider.notifier)
        .start(managerName: _name.text, clubId: club.id);
    final s = ref.read(stringsProvider);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PlaceholderPage(title: s.homeTitle, step: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final loaded = widget.loaded;
    final leagues = [...loaded.world.leagues]
      ..sort((a, b) {
        final l = a.level.compareTo(b.level);
        return l != 0 ? l : a.id.value.compareTo(b.id.value);
      });
    final clubs = loaded.clubsOf(_league);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.careerChooseClub, style: theme.textTheme.headlineSmall),
        const SizedBox(height: Tokens.gapM),
        Wrap(
          spacing: Tokens.gapS,
          runSpacing: Tokens.gapS,
          children: [
            for (final l in leagues)
              ChoiceChip(
                label: Text(s.leagueName(l.name)),
                selected: l.id == _league.id,
                onSelected: (_) => setState(() {
                  _league = l;
                  _club = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: Tokens.gapL),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ListView.separated(
                  itemCount: clubs.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Tokens.gapS),
                  itemBuilder: (context, i) {
                    final club = clubs[i];
                    final selected = club.id == _club?.id;
                    return _ClubRow(
                      club: club,
                      strength: loaded.strength[club.id.value] ?? 0,
                      selected: selected,
                      onTap: () => setState(() => _club = club),
                    );
                  },
                ),
              ),
              const SizedBox(width: Tokens.gapL),
              Expanded(
                flex: 2,
                child: _DetailCard(
                  club: _club,
                  league: _league,
                  clubs: clubs,
                  loaded: loaded,
                  nameController: _name,
                  onChanged: () => setState(() {}),
                  onStart: _start,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({
    required this.club,
    required this.strength,
    required this.selected,
    required this.onTap,
  });

  final Club club;
  final double strength;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: ValueKey('club-${club.id.value}'),
      color: Tokens.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radius),
        side: BorderSide(
          color: selected ? Tokens.yellow : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Tokens.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.gapM,
            vertical: Tokens.gapS + 2,
          ),
          child: Row(
            children: [
              ClubCrest(clubId: club.id.value, size: 48),
              const SizedBox(width: Tokens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club.name, style: theme.textTheme.titleMedium),
                    Text(club.place, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Text(
                strength.toStringAsFixed(1),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Tokens.yellow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends ConsumerWidget {
  const _DetailCard({
    required this.club,
    required this.league,
    required this.clubs,
    required this.loaded,
    required this.nameController,
    required this.onChanged,
    required this.onStart,
  });

  final Club? club;
  final League league;
  final List<Club> clubs;
  final LoadedWorld loaded;
  final TextEditingController nameController;
  final VoidCallback onChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final chosen = club;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.gapL),
        child: chosen == null
            ? Center(
                child: Text(
                  s.careerNoClubChosen,
                  style: theme.textTheme.bodyLarge,
                ),
              )
            : ListView(
                children: [
                  Center(child: ClubCrest(clubId: chosen.id.value, size: 140)),
                  const SizedBox(height: Tokens.gapM),
                  Text(
                    chosen.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    chosen.place,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: Tokens.gapS),
                  Text(
                    s.leagueName(league.name),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Tokens.gapM),
                  Text(
                    '${s.careerStrength((loaded.strength[chosen.id.value] ?? 0).toStringAsFixed(1))}'
                    ' · '
                    '${s.careerRank(clubs.indexWhere((c) => c.id == chosen.id) + 1, clubs.length)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Tokens.yellow,
                    ),
                  ),
                  const SizedBox(height: Tokens.gapL),
                  TextField(
                    controller: nameController,
                    onChanged: (_) => onChanged(),
                    onSubmitted: (_) => onStart(),
                    decoration: InputDecoration(
                      labelText: s.careerManagerName,
                      filled: true,
                      fillColor: Tokens.ground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Tokens.radius),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: Tokens.gapM),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: nameController.text.trim().isEmpty
                          ? null
                          : onStart,
                      child: Text(s.careerStart),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
