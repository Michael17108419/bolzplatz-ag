import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game/desk.dart';
import '../game/loaded_world.dart';
import '../game/squad.dart';
import '../l10n/app_strings.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'info_button.dart';
import 'office_pages.dart';
import 'person_avatar.dart';
import 'player_look.dart';
import 'player_widgets.dart';

/// The profile of one player (own or foreign) in five tabs.
class PlayerPage extends ConsumerWidget {
  const PlayerPage({required this.playerId, super.key});

  final int playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return WithCareer(
      builder: (context, career, loaded, view) {
        final p = loaded.player(PlayerId(playerId));
        if (p == null) {
          return DeskFrame(
            item: DeskItem.files,
            child: Center(child: Text(s.squadEmpty)),
          );
        }
        return DeskFrame(
          item: DeskItem.files,
          title: p.displayName,
          child: _Profile(
            player: p,
            loaded: loaded,
            ownClub: career.offer.club.id,
          ),
        );
      },
    );
  }
}

class _Profile extends ConsumerWidget {
  const _Profile({
    required this.player,
    required this.loaded,
    required this.ownClub,
  });

  final Player player;
  final LoadedWorld loaded;
  final ClubId ownClub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final p = player;
    final age = p.ageOn(loaded.today);
    final overall = loaded.overall(p);
    final club = p.clubId == null ? null : loaded.club(p.clubId!);
    final look = PlayerLook.of(
      p,
      age: age,
      crestColour: CrestSpec.forClub(club?.id.value ?? 0).color,
    );
    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PersonAvatar(
                key: const ValueKey('profile-portrait'),
                appearance: look.appearance,
                extras: look.extras,
                size: 96,
              ),
              const SizedBox(width: Tokens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.displayName,
                      key: const ValueKey('profile-name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      club == null ? s.profileNoContract : club.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      s.profileAgeNation(age, s.nationName(p.nationality)),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              PositionChip(p.position),
              const SizedBox(width: Tokens.gapM),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    overall.round().toString(),
                    key: const ValueKey('profile-overall'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: valueColor(overall),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.profileOverall, style: theme.textTheme.bodySmall),
                      InfoButton(message: s.infoProfileOverall),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Tokens.gapS),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (var i = 0; i < 5; i++)
                Tab(key: ValueKey('profile-tab-$i'), text: s.profileTab(i)),
            ],
          ),
          const SizedBox(height: Tokens.gapS),
          Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(player: p, loaded: loaded),
                _ValuesTab(player: p),
                _RolesTab(player: p, loaded: loaded),
                _HeadTab(player: p),
                _CareerTab(player: p, loaded: loaded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _section(ThemeData theme, String title, String? info, Widget body) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(Tokens.gapM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: Text(title, style: theme.textTheme.titleMedium)),
              if (info != null) InfoButton(message: info),
            ],
          ),
          const SizedBox(height: Tokens.gapS),
          body,
        ],
      ),
    ),
  );
}

String _euro(int amount) {
  final digits = amount.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return '$out €';
}

String _date(GameDate d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.player, required this.loaded});

  final Player player;
  final LoadedWorld loaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final p = player;
    final role = mainRoleOf(p, loaded.rules);
    final familiarity = role == null
        ? RoleFamiliarity.basic
        : (p.roles[role.id] ?? RoleFamiliarity.basic);
    final c = p.contract;
    return ListView(
      children: [
        _section(
          theme,
          s.profileMainRole,
          s.infoProfileRole,
          Text(
            role == null
                ? s.profileNoRole
                : '${s.roleName(role.id)}  ${s.roleFamiliaritySymbol(familiarity)}',
            key: const ValueKey('profile-role'),
            style: theme.textTheme.titleMedium?.copyWith(color: Tokens.yellow),
          ),
        ),
        _section(
          theme,
          s.profileAbilities,
          s.infoProfileAbilities,
          p.abilities.isEmpty
              ? Text(s.profileNoAbilities)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final a in p.abilities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3, right: 8),
                              child: Medal(a.tier),
                            ),
                            Expanded(
                              child: Text(
                                '${s.abilityName(a.type)} (${s.abilityTierName(a.tier)}): '
                                '${s.abilityInfo(a.type)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        _section(
          theme,
          s.profileContract,
          null,
          c == null
              ? Text(s.profileNoContract)
              : Text(
                  '${s.profileContractUntil(_date(c.end))} · '
                  '${s.profileSalary(_euro(c.baseSalaryPerYear))}',
                  key: const ValueKey('profile-contract'),
                ),
        ),
        _section(
          theme,
          s.profileForm,
          s.infoProfileForm,
          Text(s.profileFormNone),
        ),
      ],
    );
  }
}

class _ValuesTab extends ConsumerWidget {
  const _ValuesTab({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final groups = [
      for (final g in AttributeGroup.values)
        if (g != AttributeGroup.goalkeeping || player.position.isGoalkeeper) g,
    ];
    return ListView(
      children: [
        Row(
          children: [
            Text(s.valuesHint, style: theme.textTheme.bodyMedium),
            InfoButton(message: s.infoValues),
          ],
        ),
        const SizedBox(height: Tokens.gapS),
        for (final g in groups)
          Card(
            child: ExpansionTile(
              key: ValueKey('values-${g.name}'),
              initiallyExpanded: true,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                s.attributeGroupName(g),
                style: theme.textTheme.titleSmall,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                Tokens.gapM,
                0,
                Tokens.gapM,
                Tokens.gapS,
              ),
              children: [
                for (final a in Attribute.values)
                  if (a.group == g)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              s.attributeName(a),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: ValueBar(player.attributes[a]),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              player.attributes[a].round().toString(),
                              textAlign: TextAlign.right,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: valueColor(player.attributes[a]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RolesTab extends ConsumerWidget {
  const _RolesTab({required this.player, required this.loaded});

  final Player player;
  final LoadedWorld loaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final p = player;
    final side = p.position.wideSide;
    return ListView(
      children: [
        _section(
          theme,
          s.rolesPositions,
          s.infoPositions,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${s.rolesMainPosition}: '),
                  PositionChip(p.position),
                  const SizedBox(width: 6),
                  Text(s.positionName(p.position)),
                ],
              ),
              const SizedBox(height: 6),
              if (p.secondaryPositions.isEmpty)
                Text(s.rolesSecondaryNone)
              else
                for (final e in p.secondaryPositions.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        PositionChip(e.key),
                        const SizedBox(width: 6),
                        Text(
                          '${s.positionName(e.key)} · '
                          '${s.positionFamiliarityName(e.value)}',
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('${s.rolesFoot}: ${s.footName(p.foot)}'),
                  const SizedBox(width: Tokens.gapM),
                  Text('${s.rolesWeakFoot}: '),
                  Dots(p.weakFoot),
                ],
              ),
            ],
          ),
        ),
        _section(
          theme,
          s.rolesList,
          s.infoRoles,
          Column(
            children: [
              for (final r in rolesOf(p, loaded.rules))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    key: ValueKey('role-${r.id}'),
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          s.roleFamiliaritySymbol(
                            p.roles[r.id] ?? RoleFamiliarity.basic,
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Tokens.yellow,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s.roleName(r.id) +
                              (r.onlyWithBackThreeOrFive
                                  ? ' (${s.rolesBackThree})'
                                  : ''),
                        ),
                      ),
                      if (r.side != null && side != null)
                        Text(
                          s.roleSideHint(
                            (r.side == 'natural') == (p.foot == side),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: InfoButton(message: s.infoRolesSymbols),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeadTab extends ConsumerWidget {
  const _HeadTab({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final p = player;
    return ListView(
      children: [
        _section(
          theme,
          s.headTraits,
          s.infoTraits,
          Column(
            children: [
              for (final t in CharacterTrait.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(s.traitName(t))),
                      Expanded(
                        flex: 4,
                        child: LevelBar(displayLevel(p.traits[t]!)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          s.traitLevelName(displayLevel(p.traits[t]!)),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _section(
          theme,
          s.headInjury,
          null,
          Row(
            children: [
              Expanded(child: LevelBar(displayLevel(p.injuryProneness))),
              const SizedBox(width: Tokens.gapM),
              Text(s.traitLevelName(displayLevel(p.injuryProneness))),
            ],
          ),
        ),
        _section(
          theme,
          s.headPotential,
          s.infoPotential,
          Dots(potentialStars(p)),
        ),
        _section(
          theme,
          s.headDevelopment,
          s.infoDevelopment,
          Text(s.developmentTypeName(p.developmentType)),
        ),
        _section(
          theme,
          s.headCircumstances,
          s.infoCircumstances,
          Text(s.headCircumstancesText),
        ),
      ],
    );
  }
}

class _CareerTab extends ConsumerWidget {
  const _CareerTab({required this.player, required this.loaded});

  final Player player;
  final LoadedWorld loaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final c = player.contract;
    return ListView(
      children: [
        _section(
          theme,
          s.profileTab(4),
          s.infoCareer,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c != null) Text(s.careerSince(_date(c.start))),
              const SizedBox(height: 6),
              Text(s.careerNoSeason),
            ],
          ),
        ),
      ],
    );
  }
}
