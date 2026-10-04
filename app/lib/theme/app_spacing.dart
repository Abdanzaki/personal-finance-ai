import 'package:flutter/material.dart';

/// Exact spacing and corner radii from Stitch DESIGN.md
class AppSpacing {
  AppSpacing._();

  // Spacing Discipline
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  // Grid Gutters & Margins
  static const double gutterSm = 12.0;
  static const double gutter = 16.0;
  static const double margin = 16.0;
  static const double marginTablet = 24.0;
  static const double marginDesktop = 32.0;

  // Max layout container width
  static const double maxContentWidth = 1200.0;
}

class AppRadii {
  AppRadii._();

  static const double sm = 4.0;
  static const double defaultRadius = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0; // Standard 16px card radius
  static const double xl = 24.0;
  static const double full = 9999.0;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderDefault = BorderRadius.all(Radius.circular(defaultRadius));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(full));
}
