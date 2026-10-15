import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'career.dart';
import 'loaded_world.dart';
import 'office.dart';

/// What the office shows now, or null while the career or the world is
/// still loading.
final officeViewProvider = Provider<OfficeView?>((ref) {
  final career = ref.watch(careerProvider);
  final loaded = ref.watch(loadedWorldProvider).value;
  if (career == null || loaded == null) return null;
  return OfficeView.of(career, loaded);
});
