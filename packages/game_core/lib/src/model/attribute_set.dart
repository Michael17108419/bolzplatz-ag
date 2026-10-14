import 'dart:collection';

import 'attribute.dart';

/// Immutable values for all 42 attributes, stored by [Attribute.index].
class AttributeSet {
  AttributeSet._(List<double> values)
      : _values = UnmodifiableListView<double>(values);

  /// Builds a set from a complete map. Throws [ArgumentError] when an
  /// attribute is missing or a value is outside 1 to 100.
  factory AttributeSet.fromMap(Map<Attribute, double> map) {
    final values = List<double>.filled(Attribute.count, 0);
    for (final attribute in Attribute.values) {
      final value = map[attribute];
      if (value == null) {
        throw ArgumentError('Missing attribute ${attribute.id}');
      }
      values[attribute.index] = _check(attribute, value);
    }
    return AttributeSet._(values);
  }

  /// Every attribute set to [value].
  factory AttributeSet.filled(double value) {
    final checked = _check(Attribute.acceleration, value);
    return AttributeSet._(List<double>.filled(Attribute.count, checked));
  }

  final List<double> _values;

  double operator [](Attribute attribute) => _values[attribute.index];

  /// Copy with one attribute changed.
  AttributeSet withValue(Attribute attribute, double value) {
    final copy = List<double>.of(_values);
    copy[attribute.index] = _check(attribute, value);
    return AttributeSet._(copy);
  }

  /// Plain list in [Attribute.index] order, for persistence.
  List<double> toList() => List<double>.of(_values);

  static double _check(Attribute attribute, double value) {
    if (value.isNaN || value < Attribute.min || value > Attribute.max) {
      throw ArgumentError.value(
        value,
        attribute.id,
        'must be between ${Attribute.min} and ${Attribute.max}',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) {
    if (other is! AttributeSet) return false;
    for (var i = 0; i < Attribute.count; i++) {
      if (_values[i] != other._values[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_values);
}
