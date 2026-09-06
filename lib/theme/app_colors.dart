import 'package:flutter/material.dart';

/// Monochrome palette.
///
/// Hierarchy comes from contrast and weight, not hue. White is the accent:
/// it marks the single primary action on a screen and nothing else.
abstract final class AppColors {
  // Grounds, darkest to lightest.
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceRaised = Color(0xFF161616);
  static const Color surfaceSunken = Color(0xFF080808);

  // Hairlines. [borderStrong] outlines the focused item in a list.
  static const Color border = Color(0xFF1F1F1F);
  static const Color borderStrong = Color(0xFFFFFFFF);

  // Text. [textMuted] is the floor for anything that must stay readable;
  // [textDisabled] is for locked rows, which are deliberately recessive.
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textMuted = Color(0xFF7A7A7A);
  static const Color textDisabled = Color(0xFF5C5C5C);

  // Inverted, for content sitting on a white fill.
  static const Color onAccent = Color(0xFF000000);
  static const Color accent = Color(0xFFFFFFFF);

  /// Answer feedback is the one place hue survives, because correctness
  /// cannot be encoded in a greyscale ramp alone.
  static const Color correct = Color(0xFF4ADE80);
  static const Color incorrect = Color(0xFFF87171);
}
