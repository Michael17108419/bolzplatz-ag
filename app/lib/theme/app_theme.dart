import 'package:flutter/material.dart';

import 'tokens.dart';

/// The one dark theme of the app.
ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: Tokens.yellow,
    onPrimary: Tokens.ink,
    secondary: Tokens.orange,
    onSecondary: Tokens.ink,
    tertiary: Tokens.green,
    onTertiary: Tokens.ink,
    surface: Tokens.panel,
    onSurface: Tokens.text,
    secondaryContainer: Tokens.panel,
    onSecondaryContainer: Tokens.text,
    error: Tokens.orange,
    onError: Tokens.ink,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Tokens.ground,
    fontFamily: Tokens.bodyFont,
  );
  final text = base.textTheme.apply(
    fontFamily: Tokens.bodyFont,
    bodyColor: Tokens.text,
    displayColor: Tokens.text,
  );
  // The fonts are variable fonts: the weight axis is set explicitly, so
  // bold is drawn by the font and not faked by the engine.
  TextStyle? head(TextStyle? s) => s?.copyWith(
    fontFamily: Tokens.headlineFont,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation.weight(700)],
  );
  final textTheme = text.copyWith(
    displayLarge: head(text.displayLarge),
    displayMedium: head(text.displayMedium),
    displaySmall: head(text.displaySmall),
    headlineLarge: head(text.headlineLarge),
    headlineMedium: head(text.headlineMedium),
    headlineSmall: head(text.headlineSmall),
    titleLarge: head(text.titleLarge),
    titleMedium: head(text.titleMedium),
    labelLarge: head(text.labelLarge),
  );
  // Buttons use the body font in bold; it reads better at small sizes.
  TextStyle buttonText(double size) => TextStyle(
    fontFamily: Tokens.bodyFont,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation.weight(700)],
    fontSize: size,
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Tokens.radius),
  );
  const padding = EdgeInsets.symmetric(horizontal: 28, vertical: 20);
  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Tokens.ground,
      foregroundColor: Tokens.text,
      elevation: 0,
    ),
    cardTheme: CardThemeData(color: Tokens.panel, elevation: 0, shape: shape),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: shape,
        padding: padding,
        textStyle: buttonText(18),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Tokens.text,
        shape: shape,
        padding: padding,
        textStyle: buttonText(16),
      ),
    ),
  );
}
