/// The things on the office desk. One thing, one task, one button.
///
/// The order is the order of the number keys: 1 to 9 and then 0 (document
/// "Büro als Schreibtisch-Szene"). The door is "Weiter" and has no number.
enum DeskItem {
  post,
  press,
  tactics,
  files,
  calendar,
  stats,
  transfers,
  finance,
  grounds,
  saves,
  door;

  /// The number key that opens this item, null for the door.
  int? get digit => switch (this) {
    DeskItem.door => null,
    DeskItem.saves => 0,
    _ => index + 1,
  };

  /// The items that are reached from the quick bar (all but the door).
  static List<DeskItem> get rooms => [
    for (final i in DeskItem.values)
      if (i != DeskItem.door) i,
  ];
}
