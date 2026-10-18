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

/// The values of the manager (document 01 and 16). Four of them are
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
  talentEye('talent_eye'),

  /// Engine 2, step 10f3: how well the manager fires up a team.
  motivation('motivation'),

  /// Engine 2, step 10f3: how well he keeps players happy.
  manManagement('man_management');

  const ManagerValue(this.id);

  final String id;

  bool get isSkill =>
      this == charisma ||
      this == tacticalKnowledge ||
      this == negotiation ||
      this == talentEye ||
      this == motivation ||
      this == manManagement;
}

/// Coaching licence of the manager (step 11e): none, C, B, A, Pro.
enum Licence {
  none('none'),
  c('c'),
  b('b'),
  a('a'),
  pro('pro');

  const Licence(this.id);

  final String id;

  static Licence fromId(String id) => Licence.values.firstWhere(
    (l) => l.id == id,
    orElse: () => throw ArgumentError('Unknown licence $id'),
  );

  /// The next step, null after Pro.
  Licence? get next => index + 1 < Licence.values.length
      ? Licence.values[index + 1]
      : null;

  bool covers(Licence required) => index >= required.index;
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
    this.gender = 0,
    this.skin = 0,
    this.hairStyle = 0,
    this.hairColour = 0,
    this.beard = 0,
    this.glasses = 0,
    this.outfit = 0,
    this.outfitColour = 0,
    this.outfitColour2 = 1,
  });

  /// 0 man, 1 woman, 2 diverse.
  final int gender;
  final int skin;
  final int hairStyle;
  final int hairColour;
  final int beard;
  final int glasses;

  /// Kind of clothing (tracksuit jacket, T-shirt, hoodie, polo, suit with
  /// tie, lumberjack shirt, tank top).
  final int outfit;
  final int outfitColour;

  /// Second colour: tie, plaid pattern, belt or bow, depending on the outfit.
  final int outfitColour2;

  TrainerAppearance copyWith({
    int? gender,
    int? skin,
    int? hairStyle,
    int? hairColour,
    int? beard,
    int? glasses,
    int? outfit,
    int? outfitColour,
    int? outfitColour2,
  }) => TrainerAppearance(
    gender: gender ?? this.gender,
    skin: skin ?? this.skin,
    hairStyle: hairStyle ?? this.hairStyle,
    hairColour: hairColour ?? this.hairColour,
    beard: beard ?? this.beard,
    glasses: glasses ?? this.glasses,
    outfit: outfit ?? this.outfit,
    outfitColour: outfitColour ?? this.outfitColour,
    outfitColour2: outfitColour2 ?? this.outfitColour2,
  );

  Map<String, int> toJson() => {
    'gender': gender,
    'skin': skin,
    'hair_style': hairStyle,
    'hair_colour': hairColour,
    'beard': beard,
    'glasses': glasses,
    'outfit': outfit,
    'outfit_colour': outfitColour,
    'outfit_colour2': outfitColour2,
  };

  factory TrainerAppearance.fromJson(Map<String, dynamic> m) =>
      TrainerAppearance(
        gender: m['gender'] as int,
        skin: m['skin'] as int,
        hairStyle: m['hair_style'] as int,
        hairColour: m['hair_colour'] as int,
        beard: m['beard'] as int,
        glasses: m['glasses'] as int,
        outfit: m['outfit'] as int,
        outfitColour: m['outfit_colour'] as int,
        outfitColour2: m['outfit_colour2'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is TrainerAppearance &&
      other.skin == skin &&
      other.hairStyle == hairStyle &&
      other.hairColour == hairColour &&
      other.beard == beard &&
      other.glasses == glasses &&
      other.gender == gender &&
      other.outfit == outfit &&
      other.outfitColour == outfitColour &&
      other.outfitColour2 == outfitColour2;

  @override
  int get hashCode => Object.hash(
    gender,
    skin,
    hairStyle,
    hairColour,
    beard,
    glasses,
    outfit,
    outfitColour,
    outfitColour2,
  );
}

/// The player's manager: name, looks, backstory and the values.
class Trainer {
  Trainer({
    required this.name,
    required this.appearance,
    required this.backstoryId,
    required Map<ManagerValue, double> values,
    this.licence = Licence.none,
    this.seasons = 0,
  }) : values = Map.unmodifiable(values) {
    for (final v in ManagerValue.values) {
      final x = values[v];
      if (x == null || x < 1 || x > 100) {
        throw ArgumentError('Manager value ${v.id} missing or outside 1-100');
      }
    }
    if (name.trim().isEmpty) throw ArgumentError('Trainer needs a name');
  }

  /// [licence] stands in for saves from before step 11e (the start
  /// licence of the backstory).
  factory Trainer.fromJson(
    Map<String, dynamic> m, {
    Licence licence = Licence.none,
  }) => Trainer(
    name: m['name'] as String,
    appearance: TrainerAppearance.fromJson(
      m['appearance'] as Map<String, dynamic>,
    ),
    backstoryId: m['backstory'] as String,
    values: _values(m['values'] as Map<String, dynamic>),
    licence: m['licence'] == null
        ? licence
        : Licence.fromId(m['licence'] as String),
    seasons: m['seasons'] as int? ?? 0,
  );

  /// Values of a saved trainer. Saves from before step 10f3 know no
  /// motivation and man management: both start at the charisma.
  static Map<ManagerValue, double> _values(Map<String, dynamic> m) {
    final charisma = (m[ManagerValue.charisma.id] as num).toDouble();
    return {
      for (final v in ManagerValue.values)
        v: (m[v.id] as num?)?.toDouble() ?? charisma,
    };
  }

  final String name;
  final TrainerAppearance appearance;
  final String backstoryId;
  final Map<ManagerValue, double> values;

  /// Coaching licence (step 11e).
  final Licence licence;

  /// Seasons finished as a manager (step 11e).
  final int seasons;

  double operator [](ManagerValue v) => values[v]!;

  Trainer copyWith({
    Map<ManagerValue, double>? values,
    Licence? licence,
    int? seasons,
  }) => Trainer(
    name: name,
    appearance: appearance,
    backstoryId: backstoryId,
    values: values ?? this.values,
    licence: licence ?? this.licence,
    seasons: seasons ?? this.seasons,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'appearance': appearance.toJson(),
    'backstory': backstoryId,
    'values': {for (final e in values.entries) e.key.id: e.value},
    'licence': licence.id,
    'seasons': seasons,
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
