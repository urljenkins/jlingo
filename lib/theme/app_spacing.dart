/// Spacing scale. Values outside it are a smell — reach for the next step
/// up or down rather than inventing an in-between.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal inset shared by every scrollable screen body.
  static const double screenInset = 20;
}

/// Corner radii. Pills use [pill]; cards and buttons use [card].
abstract final class AppRadius {
  static const double sm = 8;
  static const double card = 16;
  static const double lg = 20;
  static const double pill = 999;
}
