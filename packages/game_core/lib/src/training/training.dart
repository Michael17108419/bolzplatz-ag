import '../rules/rules.dart';

/// How hard a training unit is (step 11a).
enum Intensity { light, normal, hard }

/// One unit of a training day: what is trained and how hard.
class TrainingSession {
  const TrainingSession(this.unit, this.intensity);

  factory TrainingSession.fromJson(List<dynamic> j) => TrainingSession(
    j[0] as String,
    Intensity.values.byName(j[1] as String),
  );

  /// Id of the unit in the rules (`endurance`, `pressing` …).
  final String unit;
  final Intensity intensity;

  List<dynamic> toJson() => [unit, intensity.name];

  @override
  bool operator ==(Object other) =>
      other is TrainingSession &&
      other.unit == unit &&
      other.intensity == intensity;

  @override
  int get hashCode => Object.hash(unit, intensity);
}

/// The units of one day, three at most (morning, afternoon, evening).
class TrainingDay {
  TrainingDay(List<TrainingSession> sessions)
    : sessions = List.unmodifiable(sessions.take(maxSessions));

  factory TrainingDay.fromJson(List<dynamic> j) => TrainingDay([
    for (final s in j) TrainingSession.fromJson(s as List<dynamic>),
  ]);

  static const int maxSessions = 3;

  /// A day without units.
  static final TrainingDay rest = TrainingDay(const []);

  final List<TrainingSession> sessions;

  List<dynamic> toJson() => [for (final s in sessions) s.toJson()];
}

/// One training unit of the rules: its group, what it costs in freshness
/// per intensity (negative: it refreshes), the load it adds, and what it
/// works on (attribute groups, the system, set pieces; used from step 11b).
class UnitRule {
  const UnitRule({
    required this.id,
    required this.group,
    required this.cost,
    required this.load,
    required this.targets,
  });

  factory UnitRule.fromJson(String id, Map<String, dynamic> m) {
    List<double> numbers(Object? v) => [
      for (final x in (v as List<dynamic>? ?? const [0, 0, 0]))
        (x as num).toDouble(),
    ];
    final targets = (m['targets'] as List<dynamic>? ?? const []);
    return UnitRule(
      id: id,
      group: m['group'] as String,
      cost: numbers(m['cost']),
      load: numbers(m['load']),
      targets: targets.cast<String>(),
    );
  }

  final String id;
  final String group;
  final List<double> cost;
  final List<double> load;
  final List<String> targets;

  double costOf(Intensity i) => cost[i.index];
  double loadOf(Intensity i) => load[i.index];
}

/// A ready week: units by the distance of a day to the next or last own
/// match. Keys: `-1` (the day before a match), `-2`, `+1` (the day after),
/// `+2`, `other`.
class TemplateRule {
  const TemplateRule(this.id, this.days);

  factory TemplateRule.fromJson(String id, Map<String, dynamic> m) =>
      TemplateRule(id, {
        for (final e in m.entries)
          e.key: TrainingDay.fromJson(e.value as List<dynamic>),
      });

  final String id;
  final Map<String, TrainingDay> days;

  /// The day for a distance key; `other` when the key is missing.
  TrainingDay dayFor(String key) =>
      days[key] ?? days['other'] ?? TrainingDay.rest;
}

/// The training of step 11a: units, templates and how freshness moves.
class TrainingRules {
  const TrainingRules({
    required this.units,
    required this.templates,
    required this.values,
    this.devPoints = const [0.5, 1.0, 1.6],
  });

  factory TrainingRules.fromJson(Map<String, dynamic>? m) {
    if (m == null) {
      return const TrainingRules(units: {}, templates: {}, values: {});
    }
    final units = <String, UnitRule>{
      for (final e in (m['units'] as Map<String, dynamic>).entries)
        e.key: UnitRule.fromJson(e.key, e.value as Map<String, dynamic>),
    };
    final templates = <String, TemplateRule>{
      for (final e in (m['templates'] as Map<String, dynamic>).entries)
        e.key: TemplateRule.fromJson(e.key, e.value as Map<String, dynamic>),
    };
    for (final t in templates.values) {
      for (final d in t.days.values) {
        for (final s in d.sessions) {
          if (!units.containsKey(s.unit)) {
            throw RulesError('Template ${t.id} uses unknown unit ${s.unit}');
          }
        }
      }
    }
    final values = <String, double>{
      for (final e in m.entries)
        if (e.value is num) e.key: (e.value as num).toDouble(),
    };
    final points = m['dev_points'] as List<dynamic>?;
    return TrainingRules(
      units: units,
      templates: templates,
      values: values,
      devPoints: points == null
          ? const [0.5, 1.0, 1.6]
          : [for (final x in points) (x as num).toDouble()],
    );
  }

  final Map<String, UnitRule> units;
  final Map<String, TemplateRule> templates;
  final Map<String, double> values;

  double operator [](String key) => values[key] ?? 0;

  /// Development points of one unit by intensity (step 11b).
  double pointsOf(Intensity i) {
    final list = devPoints;
    return i.index < list.length ? list[i.index] : 1;
  }

  /// Points per intensity, read from `dev_points`.
  final List<double> devPoints;

  /// The groups in the order of the rules, with their units.
  Map<String, List<UnitRule>> get groups {
    final out = <String, List<UnitRule>>{};
    for (final u in units.values) {
      (out[u.group] ??= []).add(u);
    }
    return out;
  }
}

/// Builds training weeks (step 11a): from a template, or from goals.
class TrainingPlanner {
  const TrainingPlanner(this.rules);

  final TrainingRules rules;

  /// The distance key of [day] to the matches in [matchDays] (epoch days):
  /// `match`, `-1`, `-2`, `+1`, `+2` or `other`.
  static String distanceKey(int day, Iterable<int> matchDays) {
    if (matchDays.contains(day)) return 'match';
    if (matchDays.contains(day + 1)) return '-1';
    if (matchDays.contains(day - 1)) return '+1';
    if (matchDays.contains(day + 2)) return '-2';
    if (matchDays.contains(day - 2)) return '+2';
    return 'other';
  }

  /// The day of [template] for [day]; match days stay empty.
  TrainingDay fromTemplate(String template, int day, Iterable<int> matchDays) {
    final key = distanceKey(day, matchDays);
    if (key == 'match') return TrainingDay.rest;
    final t = rules.templates[template];
    return t?.dayFor(key) ?? TrainingDay.rest;
  }

  /// A day built from [goals] (unit ids) at [intensity]: the day after a
  /// match is for recovery, the day before is light (video and set
  /// pieces), the other days work on the goals in turn, two units a day
  /// (three when hard). [index] turns the goals round from day to day.
  TrainingDay fromGoals(
    List<String> goals,
    Intensity intensity,
    int day,
    Iterable<int> matchDays, {
    int index = 0,
  }) {
    final key = distanceKey(day, matchDays);
    switch (key) {
      case 'match':
        return TrainingDay.rest;
      case '+1':
        return TrainingDay(const [
          TrainingSession('regeneration', Intensity.light),
        ]);
      case '-1':
        return TrainingDay(const [
          TrainingSession('video', Intensity.light),
          TrainingSession('set_pieces_attack', Intensity.light),
        ]);
    }
    final valid = [
      for (final g in goals)
        if (rules.units.containsKey(g)) g,
    ];
    if (valid.isEmpty) return TrainingDay.rest;
    final count = intensity == Intensity.hard ? 3 : 2;
    return TrainingDay([
      for (var i = 0; i < count; i++)
        TrainingSession(valid[(index * count + i) % valid.length], intensity),
    ]);
  }
}
