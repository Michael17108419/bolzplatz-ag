/// Level of a start value: the scale of document 16 (-, 0, +, ++).
enum TraitLevel {
  low('-'),
  middle('0'),
  high('+'),
  veryHigh('++');

  const TraitLevel(this.symbol);

  final String symbol;

  static TraitLevel fromSymbol(String symbol) => TraitLevel.values.firstWhere(
    (l) => l.symbol == symbol,
    orElse: () => throw ArgumentError('Unknown level $symbol'),
  );
}

/// The nine values of the manager (document 01 and 16). Four of them are
/// skills that grow ([tacticalKnowledge], [charisma], [negotiation],
/// [talentEye]), [standing] is the reputation, the rest are states.
enum ManagerValue {
  standing('standing'),
  charisma('charisma'),
  stress('stress'),
  presidentTrust('president_trust'),
  pressImage('press_image'),
  contacts('contacts'),
  tacticalKnowledge('tactical_knowledge'),
  negotiation('negotiation'),
  talentEye('talent_eye');

  const ManagerValue(this.id);

  final String id;

  bool get isSkill =>
      this == charisma ||
      this == tacticalKnowledge ||
      this == negotiation ||
      this == talentEye;
}

/// The seven traits of a club president (document 01). For [thrift], a low
/// level is generous and a high level is stingy.
enum PresidentTrait {
  patience('patience'),
  meddling('meddling'),
  thrift('thrift'),
  ambition('ambition'),
  vanity('vanity'),
  loyalty('loyalty'),
  pressCraving('press_craving');

  const PresidentTrait(this.id);

  final String id;
}

/// Starting situation of a club in a job offer.
enum Situation {
  favourite('favourite'),
  midTable('mid_table'),
  relegation('relegation'),
  bankrupt('bankrupt');

  const Situation(this.id);

  final String id;
}

/// What the president expects for the season.
enum SeasonGoal {
  /// Win the title (favourite in the top league).
  title,

  /// Promotion (favourite below the top league).
  promotion,

  /// Mid table without a target.
  noTarget,

  /// Avoid relegation.
  survival,

  /// Avoid relegation and keep the licence.
  licence,
}

/// A feature of the club shown in the job offer.
enum ClubQuirk {
  none('none'),
  debtMountain('debt_mountain'),
  talentFactory('talent_factory'),
  feudingSquad('feuding_squad'),
  loyalFans('loyal_fans'),
  crumblingStadium('crumbling_stadium');

  const ClubQuirk(this.id);

  final String id;
}

/// How the manager looks: indices into the options of the rules.
class TrainerAppearance {
  const TrainerAppearance({
    this.skin = 0,
    this.hairStyle = 0,
    this.hairColour = 0,
    this.beard = 0,
    this.glasses = 0,
    this.jacket = 0,
  });

  final int skin;
  final int hairStyle;
  final int hairColour;
  final int beard;
  final int glasses;
  final int jacket;

  TrainerAppearance copyWith({
    int? skin,
    int? hairStyle,
    int? hairColour,
    int? beard,
    int? glasses,
    int? jacket,
  }) => TrainerAppearance(
    skin: skin ?? this.skin,
    hairStyle: hairStyle ?? this.hairStyle,
    hairColour: hairColour ?? this.hairColour,
    beard: beard ?? this.beard,
    glasses: glasses ?? this.glasses,
    jacket: jacket ?? this.jacket,
  );

  Map<String, int> toJson() => {
    'skin': skin,
    'hair_style': hairStyle,
    'hair_colour': hairColour,
    'beard': beard,
    'glasses': glasses,
    'jacket': jacket,
  };

  factory TrainerAppearance.fromJson(Map<String, dynamic> m) =>
      TrainerAppearance(
        skin: m['skin'] as int,
        hairStyle: m['hair_style'] as int,
        hairColour: m['hair_colour'] as int,
        beard: m['beard'] as int,
        glasses: m['glasses'] as int,
        jacket: m['jacket'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is TrainerAppearance &&
      other.skin == skin &&
      other.hairStyle == hairStyle &&
      other.hairColour == hairColour &&
      other.beard == beard &&
      other.glasses == glasses &&
      other.jacket == jacket;

  @override
  int get hashCode =>
      Object.hash(skin, hairStyle, hairColour, beard, glasses, jacket);
}

/// The player's manager: name, looks, backstory and the nine values.
class Trainer {
  Trainer({
    required this.name,
    required this.appearance,
    required this.backstoryId,
    required Map<ManagerValue, double> values,
  }) : values = Map.unmodifiable(values) {
    for (final v in ManagerValue.values) {
      final x = values[v];
      if (x == null || x < 1 || x > 100) {
        throw ArgumentError('Manager value ${v.id} missing or outside 1-100');
      }
    }
    if (name.trim().isEmpty) throw ArgumentError('Trainer needs a name');
  }

  factory Trainer.fromJson(Map<String, dynamic> m) => Trainer(
    name: m['name'] as String,
    appearance: TrainerAppearance.fromJson(
      m['appearance'] as Map<String, dynamic>,
    ),
    backstoryId: m['backstory'] as String,
    values: {
      for (final v in ManagerValue.values)
        v: ((m['values'] as Map<String, dynamic>)[v.id] as num).toDouble(),
    },
  );

  final String name;
  final TrainerAppearance appearance;
  final String backstoryId;
  final Map<ManagerValue, double> values;

  double operator [](ManagerValue v) => values[v]!;

  Map<String, dynamic> toJson() => {
    'name': name,
    'appearance': appearance.toJson(),
    'backstory': backstoryId,
    'values': {for (final e in values.entries) e.key.id: e.value},
  };
}

/// The president of a club.
class President {
  President({
    required this.typeId,
    required this.name,
    required Map<PresidentTrait, double> traits,
  }) : traits = Map.unmodifiable(traits) {
    for (final t in PresidentTrait.values) {
      final x = traits[t];
      if (x == null || x < 1 || x > 100) {
        throw ArgumentError('President trait ${t.id} missing or outside 1-100');
      }
    }
  }

  /// Id of the president type (for example `car_dealer`).
  final String typeId;
  final String name;
  final Map<PresidentTrait, double> traits;

  double operator [](PresidentTrait t) => traits[t]!;
}
