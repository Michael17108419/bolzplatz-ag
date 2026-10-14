/// Clamping that keeps the static type (num.clamp returns num).
extension DoubleLimit on double {
  double limit(double low, double high) =>
      this < low ? low : (this > high ? high : this);
}

extension IntLimit on int {
  int limit(int low, int high) =>
      this < low ? low : (this > high ? high : this);
}
