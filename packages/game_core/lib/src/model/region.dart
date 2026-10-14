/// The five regions of the fourth league tier.
enum Region {
  nord('nord'),
  nordost('nordost'),
  west('west'),
  suedwest('suedwest'),
  bayern('bayern');

  const Region(this.id);

  /// Stable string id, also the key for language files and rules.
  final String id;
}
