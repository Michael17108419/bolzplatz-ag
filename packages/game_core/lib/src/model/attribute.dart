/// Groups of attributes as shown in the interface.
enum AttributeGroup {
  physique,
  shooting,
  setPieces,
  passing,
  intelligence,
  dribbling,
  defending,
  goalkeeping,
}

/// The 42 player attributes (34 outfield in seven groups, 8 goalkeeping).
///
/// The declaration order is part of the save format: [AttributeSet] stores
/// values by [index]. Only append at the end, never reorder.
enum Attribute {
  // Physique
  acceleration('acceleration', AttributeGroup.physique),
  sprintSpeed('sprint_speed', AttributeGroup.physique),
  stamina('stamina', AttributeGroup.physique),
  strength('strength', AttributeGroup.physique),
  jumping('jumping', AttributeGroup.physique),
  recovery('recovery', AttributeGroup.physique),
  // Shooting
  goalInstinct('goal_instinct', AttributeGroup.shooting),
  finishing('finishing', AttributeGroup.shooting),
  shotPower('shot_power', AttributeGroup.shooting),
  longShots('long_shots', AttributeGroup.shooting),
  volleys('volleys', AttributeGroup.shooting),
  // Set pieces
  penalties('penalties', AttributeGroup.setPieces),
  freeKicks('free_kicks', AttributeGroup.setPieces),
  corners('corners', AttributeGroup.setPieces),
  // Passing
  shortPassing('short_passing', AttributeGroup.passing),
  longPassing('long_passing', AttributeGroup.passing),
  crossing('crossing', AttributeGroup.passing),
  curve('curve', AttributeGroup.passing),
  // Intelligence
  vision('vision', AttributeGroup.intelligence),
  composure('composure', AttributeGroup.intelligence),
  reactions('reactions', AttributeGroup.intelligence),
  anticipation('anticipation', AttributeGroup.intelligence),
  decisionMaking('decision_making', AttributeGroup.intelligence),
  tacticalSense('tactical_sense', AttributeGroup.intelligence),
  concentration('concentration', AttributeGroup.intelligence),
  // Dribbling
  agility('agility', AttributeGroup.dribbling),
  balance('balance', AttributeGroup.dribbling),
  ballControl('ball_control', AttributeGroup.dribbling),
  dribbling('dribbling', AttributeGroup.dribbling),
  // Defending
  interceptions('interceptions', AttributeGroup.defending),
  heading('heading', AttributeGroup.defending),
  defensiveAwareness('defensive_awareness', AttributeGroup.defending),
  standingTackle('standing_tackle', AttributeGroup.defending),
  slidingTackle('sliding_tackle', AttributeGroup.defending),
  // Goalkeeping
  gkReflexes('gk_reflexes', AttributeGroup.goalkeeping),
  gkDiving('gk_diving', AttributeGroup.goalkeeping),
  gkHandling('gk_handling', AttributeGroup.goalkeeping),
  gkPositioning('gk_positioning', AttributeGroup.goalkeeping),
  gkKicking('gk_kicking', AttributeGroup.goalkeeping),
  gkCommandOfArea('gk_command_of_area', AttributeGroup.goalkeeping),
  gkDistribution('gk_distribution', AttributeGroup.goalkeeping),
  gkOneOnOne('gk_one_on_one', AttributeGroup.goalkeeping);

  const Attribute(this.id, this.group);

  final String id;
  final AttributeGroup group;

  bool get isGoalkeeping => group == AttributeGroup.goalkeeping;

  static const int count = 42;
  static const double min = 1;
  static const double max = 100;
}
