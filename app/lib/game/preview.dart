import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// True in the preview build (engine 2, step 10h3): built with
/// `--dart-define=PREVIEW=true`, served under /preview next to the web
/// version. Only there the app shows how long loading took.
const bool kPreview = bool.fromEnvironment('PREVIEW');

/// Shows "Geladen in … s" in the preview build; does nothing otherwise.
void showLoadTime(
  ScaffoldMessengerState messenger,
  AppStrings s,
  Stopwatch watch,
) {
  if (!kPreview) return;
  final seconds = (watch.elapsedMilliseconds / 1000)
      .toStringAsFixed(1)
      .replaceAll('.', ',');
  messenger.showSnackBar(
    SnackBar(
      key: const ValueKey('preview-load-time'),
      content: Text(s.loadedIn(seconds)),
    ),
  );
}
