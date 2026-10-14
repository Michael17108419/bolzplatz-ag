import '../model/attribute.dart';
import '../model/position.dart';
import '../model/special_ability.dart';
import 'rules.dart';

Position _position(String id) {
  for (final p in Position.values) {
    if (p.id == id) return p;
  }
  throw RulesError('Unknown position $id');
}

Attribute _attribute(String id) {
  for (final a in Attribute.values) {
    if (a.id == id) return a;
  }
  throw RulesError('Unknown attribute $id');
}

List<Attribute> _attributes(Object? raw) => List.unmodifiable([
  for (final id in raw! as List<dynamic>) _attribute(id as String),
]);

/// One role (what a player does on his position).
class RoleRule {
  const RoleRule({
    required this.id,
    required this.positions,
    required this.keyAttributes,
    required this.fitsSystems,
    required this.onlyWithBackThreeOrFive,
  });

  final String id;
  final List<Position> positions;
  final List<Attribute> keyAttributes;
  final List<String> fitsSystems;

  /// True for roles that exist only in a back three or back five.
  final bool onlyWithBackThreeOrFive;
}

/// One formation: eleven slots, goalkeeper first.
class FormationRule {
  const FormationRule({
    required this.id,
    required this.slots,
    required this.backLine,
    required this.wingBackSlots,
  });

  final String id;
  final List<Position> slots;

  /// Number of defenders in the back line (3, 4 or 5).
  final int backLine;

  /// True if LV and RV are wing-back slots (back three).
  final bool wingBackSlots;
}

/// A playing system and the attributes and abilities it asks for.
class SystemRule {
  const SystemRule({
    required this.id,
    required this.keyAttributes,
    required this.abilities,
  });

  final String id;
  final List<Attribute> keyAttributes;
  final List<SpecialAbilityType> abilities;
}

/// A tactic slider with ordered levels (lowest first).
class SliderRule {
  const SliderRule({
    required this.id,
    required this.levels,
    required this.keyAttributes,
  });

  final String id;
  final List<String> levels;
  final List<Attribute> keyAttributes;
}

/// Numbers for tactics, roles and fit. Read from the `tactics` section.
class TacticsRules {
  const TacticsRules({
    required this.positionDistance,
    required this.trainedPointsMax,
    required this.practisedFactor,
    required this.unfamiliarFactor,
    required this.roleFamiliarityFactor,
    required this.maxPlusRoles,
    required this.maxPlusPlusRoles,
    required this.weakFootPenalty,
    required this.roles,
    required this.formations,
    required this.systems,
    required this.sliders,
    required this.fitBonusMax,
    required this.warmupMinutes,
    required this.freeChanges,
    required this.penaltyPerExtraChange,
    required this.talks,
  });

  factory TacticsRules.fromJson(Map<String, dynamic> m) {
    final order = [
      for (final id in m['positions'] as List<dynamic>) _position(id as String),
    ];
    if (order.length != Position.values.length ||
        order.toSet().length != order.length) {
      throw const RulesError('tactics.positions must list every position once');
    }
    final matrixRaw = m['position_distance'] as Map<String, dynamic>;
    final distance = <Position, Map<Position, double>>{};
    for (final from in order) {
      final row = matrixRaw[from.id] as List<dynamic>?;
      if (row == null || row.length != order.length) {
        throw RulesError('Bad position_distance row ${from.id}');
      }
      distance[from] = {
        for (var i = 0; i < order.length; i++)
          order[i]: (row[i] as num).toDouble(),
      };
    }
    for (final a in order) {
      if (distance[a]![a] != 0) {
        throw RulesError('position_distance diagonal must be 0 (${a.id})');
      }
    }

    final fam = m['position_familiarity'] as Map<String, dynamic>;
    final roleFam = m['role_familiarity_factor'] as Map<String, dynamic>;
    final limits = m['role_familiarity_limits'] as Map<String, dynamic>;
    final foot = m['weak_foot_penalty'] as Map<String, dynamic>;
    final weakFoot = <int, double>{
      for (var star = 1; star <= 5; star++)
        star: (foot['$star'] as num).toDouble(),
    };
    for (var star = 1; star < 5; star++) {
      if (weakFoot[star]! < weakFoot[star + 1]!) {
        throw const RulesError('weak_foot_penalty must fall with more stars');
      }
    }

    final systems = [
      for (final raw in m['systems'] as List<dynamic>)
        _system(raw as Map<String, dynamic>),
    ];
    final systemIds = systems.map((s) => s.id).toSet();
    if (systemIds.length != systems.length) {
      throw const RulesError('Duplicate system id');
    }

    final roles = [
      for (final raw in m['roles'] as List<dynamic>)
        _role(raw as Map<String, dynamic>),
    ];
    if (roles.map((r) => r.id).toSet().length != roles.length) {
      throw const RulesError('Duplicate role id');
    }
    for (final role in roles) {
      for (final s in role.fitsSystems) {
        if (!systemIds.contains(s)) {
          throw RulesError('Role ${role.id} fits unknown system $s');
        }
      }
      if (role.positions.isEmpty || role.keyAttributes.isEmpty) {
        throw RulesError('Role ${role.id} is incomplete');
      }
    }

    final formations = [
      for (final raw in m['formations'] as List<dynamic>)
        _formation(raw as Map<String, dynamic>),
    ];
    if (formations.map((f) => f.id).toSet().length != formations.length) {
      throw const RulesError('Duplicate formation id');
    }

    final sliders = [
      for (final raw in m['sliders'] as List<dynamic>)
        _slider(raw as Map<String, dynamic>),
    ];

    final live = m['live_changes'] as Map<String, dynamic>;
    return TacticsRules(
      positionDistance: Map.unmodifiable(distance),
      trainedPointsMax: (fam['trained_points_max'] as num).toDouble(),
      practisedFactor: (fam['practised_factor'] as num).toDouble(),
      unfamiliarFactor: (fam['unfamiliar_factor'] as num).toDouble(),
      roleFamiliarityFactor: Map.unmodifiable({
        for (final e in roleFam.entries) e.key: (e.value as num).toDouble(),
      }),
      maxPlusRoles: limits['max_plus'] as int,
      maxPlusPlusRoles: limits['max_plus_plus'] as int,
      weakFootPenalty: Map.unmodifiable(weakFoot),
      roles: List.unmodifiable(roles),
      formations: List.unmodifiable(formations),
      systems: List.unmodifiable(systems),
      sliders: List.unmodifiable(sliders),
      fitBonusMax: (m['fit_bonus_max'] as num).toDouble(),
      warmupMinutes: live['warmup_minutes'] as int,
      freeChanges: live['free_changes'] as int,
      penaltyPerExtraChange: (live['penalty_per_extra_change'] as num)
          .toDouble(),
      talks: List.unmodifiable((m['talks'] as List<dynamic>).cast<String>()),
    );
  }

  static SystemRule _system(Map<String, dynamic> m) {
    final abilities = <SpecialAbilityType>[];
    for (final id in m['abilities'] as List<dynamic>) {
      final matches = SpecialAbilityType.values.where(
        (SpecialAbilityType a) => a.id == id,
      );
      if (matches.isEmpty) throw RulesError('Unknown ability $id');
      abilities.add(matches.first);
    }
    return SystemRule(
      id: m['id'] as String,
      keyAttributes: _attributes(m['key_attributes']),
      abilities: List.unmodifiable(abilities),
    );
  }

  static RoleRule _role(Map<String, dynamic> m) => RoleRule(
    id: m['id'] as String,
    positions: List.unmodifiable([
      for (final id in m['positions'] as List<dynamic>) _position(id as String),
    ]),
    keyAttributes: _attributes(m['key_attributes']),
    fitsSystems: List.unmodifiable(
      (m['fits_systems'] as List<dynamic>).cast<String>(),
    ),
    onlyWithBackThreeOrFive:
        (m['only_with_back_three_or_five'] as bool?) ?? false,
  );

  static FormationRule _formation(Map<String, dynamic> m) {
    final slots = [
      for (final id in m['slots'] as List<dynamic>) _position(id as String),
    ];
    if (slots.length != 11 || slots.first != Position.tw) {
      throw RulesError('Formation ${m['id']} needs 11 slots, goalkeeper first');
    }
    if (slots.where((p) => p == Position.tw).length != 1) {
      throw RulesError('Formation ${m['id']} needs exactly one goalkeeper');
    }
    return FormationRule(
      id: m['id'] as String,
      slots: List.unmodifiable(slots),
      backLine: m['back_line'] as int,
      wingBackSlots: m['wing_back_slots'] as bool,
    );
  }

  static SliderRule _slider(Map<String, dynamic> m) {
    final levels = (m['levels'] as List<dynamic>).cast<String>();
    if (levels.length != 3) {
      throw RulesError('Slider ${m['id']} needs three levels');
    }
    return SliderRule(
      id: m['id'] as String,
      levels: List.unmodifiable(levels),
      keyAttributes: _attributes(m['key_attributes']),
    );
  }

  /// Deduction in points when a player of the row position plays the column
  /// position, before familiarity is applied.
  final Map<Position, Map<Position, double>> positionDistance;

  /// Largest deduction in points for a trained secondary position.
  final double trainedPointsMax;

  /// Share of the distance deduction for a practised position.
  final double practisedFactor;

  /// Share of the distance deduction for an unfamiliar position.
  final double unfamiliarFactor;

  /// Change of the role key values per familiarity level
  /// (`minus`, `zero`, `plus`, `plus_plus`).
  final Map<String, double> roleFamiliarityFactor;
  final int maxPlusRoles;
  final int maxPlusPlusRoles;

  /// Share lost on pass, shot and cross per weak-foot star (1 to 5).
  final Map<int, double> weakFootPenalty;

  final List<RoleRule> roles;
  final List<FormationRule> formations;
  final List<SystemRule> systems;
  final List<SliderRule> sliders;

  /// Largest bonus of the team fit on team performance (0.04 = 4 percent).
  final double fitBonusMax;
  final int warmupMinutes;

  /// Counting tactic changes allowed per match before the team is unsettled.
  final int freeChanges;
  final double penaltyPerExtraChange;

  /// Ids of the half-time talks.
  final List<String> talks;

  RoleRule role(String id) => roles.firstWhere((r) => r.id == id);
  FormationRule formation(String id) =>
      formations.firstWhere((f) => f.id == id);
  SystemRule system(String id) => systems.firstWhere((s) => s.id == id);
}
