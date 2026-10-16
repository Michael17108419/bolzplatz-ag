import 'package:flutter/material.dart';

/// Colours of the design rules ("Flutlicht auf Waldgrün"). All screens take
/// their colours from here, never from literals.
abstract final class Tokens {
  /// Background of every screen.
  static const Color ground = Color(0xFF12261A);

  /// Cards, panels and fields.
  static const Color panel = Color(0xFF1E3D28);

  /// Main accent: buttons and highlights.
  static const Color yellow = Color(0xFFFFC400);

  /// Warnings and negative numbers.
  static const Color orange = Color(0xFFFF7A1A);

  /// Positive numbers.
  static const Color green = Color(0xFF2ED47A);

  /// Text on dark ground.
  static const Color text = Color(0xFFF4F1E8);

  /// Text on yellow.
  static const Color ink = Color(0xFF1A1300);

  /// Cream used for crest outlines.
  static const Color cream = Color(0xFFF4EFE2);

  /// Neutral middle value (for example the middle level of a bar).
  /// Time off of the squad in the calendar.
  static const Color sky = Color(0xFF4FC3F7);

  static const Color beige = Color(0xFFE2CFA0);

  static const String headlineFont = 'SpaceGrotesk';
  static const String bodyFont = 'Figtree';

  /// Spacing steps; screens are airy, so the steps are generous.
  static const double gapS = 8;
  static const double gapM = 16;
  static const double gapL = 32;
  static const double radius = 16;
}
