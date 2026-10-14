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
}
