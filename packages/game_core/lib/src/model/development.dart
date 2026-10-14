/// Shifts the age curves of a player (see rules).
enum DevelopmentType {
  earlyBloomer('early_bloomer'),
  normal('normal'),
  lateBloomer('late_bloomer');

  const DevelopmentType(this.id);

  final String id;
}

/// How well a player knows a role (four levels).
enum RoleFamiliarity {
  unfamiliar,
  basic,
  comfortable,
  expert,
}
