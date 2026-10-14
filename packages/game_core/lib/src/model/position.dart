/// The ten playing positions.
enum Position {
  tw('TW'),
  iv('IV'),
  lv('LV'),
  rv('RV'),
  zdm('ZDM'),
  zm('ZM'),
  zom('ZOM'),
  la('LA'),
  ra('RA'),
  st('ST');

  const Position(this.id);

  final String id;

  bool get isGoalkeeper => this == Position.tw;

  /// Side of the pitch for wide positions, null for central ones.
  Foot? get wideSide {
    switch (this) {
      case Position.lv:
      case Position.la:
        return Foot.left;
      case Position.rv:
      case Position.ra:
        return Foot.right;
      default:
        return null;
    }
  }
}

/// Preferred foot of a player, and the side of a wide position.
enum Foot {
  left('L'),
  right('R');

  const Foot(this.id);

  final String id;
}

/// How well a player knows a secondary position. A position that is neither
/// the main nor a secondary position counts as foreign (full deduction).
enum PositionFamiliarity {
  /// "Eingespielt": 0 to 2 points of deduction.
  trained,

  /// "Geübt": half of the distance deduction.
  practised,
}
