import '../model/career.dart';
import '../rules/rules.dart';
import '../season/season_review.dart';

/// Numbers of `career.growth` in the rules file (step 11e): how the manager
/// grows with work and results, the licences and the courses.
class GrowthRules {
  const GrowthRules({
    this.gain = const {},
    this.diminishScale = 50,
    this.diminishMin = 0.2,
    this.diminishMax = 1.5,
    this.seasonCap = 5,
    this.standing = const {},
    this.stress = const {},
    this.required = const {},
    this.waiverTrust = 10,
    this.strawPress = 8,
    this.offerFactor = 0.5,
    this.courseDays = const {},
    this.courseStanding = const {},
    this.courseSeasons = const {},
    this.courseGain = 3,
  });

  factory GrowthRules.fromJson(Map<String, dynamic> m) {
    double n(Object? v) => (v! as num).toDouble();
    ManagerValue value(String id) => ManagerValue.values.firstWhere(
      (v) => v.id == id,
      orElse: () => throw RulesError('Unknown manager value $id in growth'),
    );
    Map<String, double> numbers(Object? raw) => {
      for (final e in (raw! as Map<String, dynamic>).entries) e.key: n(e.value),
    };
    Licence licence(String id) {
      try {
        return Licence.fromId(id);
      } on ArgumentError {
        throw RulesError('Unknown licence $id in growth');
      }
    }

    Map<Licence, double> byLicence(Object? raw) => {
      for (final e in (raw! as Map<String, dynamic>).entries)
        licence(e.key): n(e.value),
    };
    final course = m['course'] as Map<String, dynamic>;
    final rules = GrowthRules(
      gain: {
        for (final e in (m['gain'] as Map<String, dynamic>).entries)
          e.key: {
            for (final g in (e.value as Map<String, dynamic>).entries)
              value(g.key): n(g.value),
          },
      },
      diminishScale: n(m['diminish_scale']),
      diminishMin: n(m['diminish_min']),
      diminishMax: n(m['diminish_max']),
      seasonCap: n(m['season_cap']),
      standing: numbers(m['standing']),
      stress: numbers(m['stress']),
      required: {
        for (final e in (m['licence_required'] as Map<String, dynamic>).entries)
          int.parse(e.key): licence(e.value as String),
      },
      waiverTrust: n(m['waiver_trust']),
      strawPress: n(m['straw_press']),
      offerFactor: n(m['offer_factor']),
      courseDays: {
        for (final e in byLicence(course['days']).entries)
          e.key: e.value.round(),
      },
      courseStanding: byLicence(course['min_standing']),
      courseSeasons: {
        for (final e in byLicence(course['min_seasons']).entries)
          e.key: e.value.round(),
      },
      courseGain: n(course['value_gain']),
    );
    if (rules.diminishScale <= 0 || rules.diminishMin > rules.diminishMax) {
      throw const RulesError('career.growth diminish values are wrong');
    }
    for (final l in Licence.values.skip(1)) {
      if ((rules.courseDays[l] ?? 0) < 1) {
        throw RulesError('career.growth needs course days for ${l.id}');
      }
    }
    return rules;
  }

  /// Raw points per value for each kind of work (`team_talk`, `shout`,
  /// `plan_hit`, `plan_week`, `talk`).
  final Map<String, Map<ManagerValue, double>> gain;
  final double diminishScale;
  final double diminishMin;
  final double diminishMax;

  /// Most a value can grow in one season by work.
  final double seasonCap;

  /// Change of the standing at the end of a season.
  final Map<String, double> standing;

  /// Stress after results and in the holidays, and how much it costs the
  /// team talks.
  final Map<String, double> stress;

  /// The licence a league level asks for.
  final Map<int, Licence> required;

  /// What turning a blind eye costs the president's trust.
  final double waiverTrust;

  /// What a straw man on the bench costs the press image.
  final double strawPress;

  /// Offers from leagues above the licence come this much less often.
  final double offerFactor;
  final Map<Licence, int> courseDays;
  final Map<Licence, double> courseStanding;
  final Map<Licence, int> courseSeasons;

  /// What a course adds to the value of the manager's choice.
  final double courseGain;

  Licence requiredFor(int level) => required[level] ?? Licence.none;

  /// How much of a raw gain lands on a value of [v]: much at the start,
  /// little near the top.
  double factor(double v) =>
      ((100 - v) / diminishScale).clamp(diminishMin, diminishMax).toDouble();

  double _s(String key) => stress[key] ?? 0;
}

/// How the manager covers a missing licence (step 11e).
enum LicenceCover {
  /// The president turns a blind eye.
  waiver,

  /// A man with the licence sits on the bench, the manager "advises".
  strawMan,
}

/// A course for the next licence, in a holiday window (step 11e).
class Course {
  const Course({
    required this.start,
    required this.days,
    required this.licence,
    required this.value,
  });

  factory Course.fromJson(Map<String, dynamic> m) => Course(
    start: m['start'] as int,
    days: m['days'] as int,
    licence: Licence.fromId(m['licence'] as String),
    value: ManagerValue.values.firstWhere((v) => v.id == m['value']),
  );

  /// First day (epoch day).
  final int start;
  final int days;
  final Licence licence;

  /// The value the course trains besides the licence.
  final ManagerValue value;

  /// First day after the course.
  int get end => start + days;

  bool isOn(int epochDay) => epochDay >= start && epochDay < end;

  bool doneBy(int epochDay) => epochDay >= end;

  Map<String, dynamic> toJson() => {
    'start': start,
    'days': days,
    'licence': licence.id,
    'value': value.id,
  };
}

/// What the manager of a human club has done this season (step 11e).
/// Lives in the season runner, so a replayed season gives the same.
class TrainerProgress {
  TrainerProgress(this.base) : stress = base[ManagerValue.stress];

  /// The manager at the start of the season.
  final Trainer base;

  /// Raw points of work per value.
  final Map<ManagerValue, double> raw = {};

  /// Stress now, 1 to 100.
  double stress;

  /// Defeats in a row.
  int losses = 0;

  /// Training weeks the manager planned himself.
  final Set<int> plannedWeeks = {};

  LicenceCover? cover;
  final List<Course> courses = [];

  /// Cup ties won this season.
  int cupRounds = 0;

  void add(GrowthRules rules, String work, [double times = 1]) {
    for (final e in (rules.gain[work] ?? const {}).entries) {
      raw[e.key] = (raw[e.key] ?? 0) + e.value * times;
    }
  }

  /// The licence on [epochDay]: the one of the season start raised by the
  /// courses finished by then.
  Licence licenceOn(int epochDay) {
    var l = base.licence;
    for (final c in courses) {
      if (c.doneBy(epochDay) && c.licence.index > l.index) l = c.licence;
    }
    return l;
  }

  /// The course the manager is on at [epochDay], or null.
  Course? courseOn(int epochDay) {
    for (final c in courses) {
      if (c.isOn(epochDay)) return c;
    }
    return null;
  }
}

/// Turns the work of a season into the values of the manager (step 11e).
class TrainerGrowth {
  const TrainerGrowth(this.rules);

  final GrowthRules rules;

  /// Stress after a match of the own club.
  void afterMatch(TrainerProgress p, int goalsFor, int goalsAgainst) {
    final r = rules;
    var d = 0.0;
    if (goalsFor > goalsAgainst) {
      p.losses = 0;
      d = r._s('win');
    } else if (goalsFor == goalsAgainst) {
      p.losses = 0;
      d = r._s('draw');
    } else {
      p.losses++;
      d = r._s('loss');
      if (p.losses >= (r.stress['streak_from'] ?? 3)) d += r._s('streak_extra');
    }
    p.stress = (p.stress + d).clamp(1.0, 100.0);
  }

  /// A day of holiday without a course.
  void holiday(TrainerProgress p) =>
      p.stress = (p.stress + rules._s('vacation_day')).clamp(1.0, 100.0);

  /// Share of the team talks a manager under [stress] loses.
  double strain(double stress) {
    final from = rules.stress['talk_from'] ?? 60;
    if (stress <= from || from >= 100) return 0;
    return rules._s('talk_max') * (stress - from) / (100 - from);
  }

  /// The manager on [epochDay]: work, courses, stress and the price of a
  /// missing licence on top of the values of the season start. The
  /// standing moves only at the end of the season (see [close]).
  Trainer current(TrainerProgress p, int epochDay) {
    final base = p.base;
    final values = Map<ManagerValue, double>.of(base.values);
    for (final e in p.raw.entries) {
      final v = values[e.key]!;
      final grown = e.value * rules.factor(v);
      values[e.key] = v + (grown < rules.seasonCap ? grown : rules.seasonCap);
    }
    for (final c in p.courses) {
      if (c.doneBy(epochDay)) {
        values[c.value] = values[c.value]! + rules.courseGain;
      }
    }
    values[ManagerValue.stress] = p.stress;
    switch (p.cover) {
      case LicenceCover.waiver:
        values[ManagerValue.presidentTrust] =
            values[ManagerValue.presidentTrust]! - rules.waiverTrust;
      case LicenceCover.strawMan:
        values[ManagerValue.pressImage] =
            values[ManagerValue.pressImage]! - rules.strawPress;
      case null:
    }
    return base.copyWith(
      values: {
        for (final e in values.entries)
          e.key: (e.value.clamp(1.0, 100.0) * 10).round() / 10,
      },
      licence: p.licenceOn(epochDay),
    );
  }

  /// The manager for the next season: [current] at the end of the season,
  /// the standing moved by the verdict, promotion or relegation and the cup.
  Trainer close(
    TrainerProgress p, {
    required int epochDay,
    GoalVerdict? verdict,
    int levelChange = 0,
    bool cupWon = false,
  }) {
    final now = current(p, epochDay);
    final s = rules.standing;
    var d = verdict == null ? 0.0 : s[verdict.name] ?? 0;
    if (levelChange < 0) d += s['promoted'] ?? 0;
    if (levelChange > 0) d += s['relegated'] ?? 0;
    d += (s['cup_round'] ?? 0) * p.cupRounds;
    if (cupWon) d += s['cup_win'] ?? 0;
    final values = Map<ManagerValue, double>.of(now.values);
    values[ManagerValue.standing] =
        ((values[ManagerValue.standing]! + d).clamp(1.0, 100.0) * 10).round() /
        10;
    return now.copyWith(values: values, seasons: now.seasons + 1);
  }
}
