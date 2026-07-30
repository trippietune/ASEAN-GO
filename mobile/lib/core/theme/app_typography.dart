import 'package:flutter/material.dart';

/// Named text styles matching the design spec's scale exactly, for call
/// sites that want a specific weight/size pairing rather than the ambient
/// Material TextTheme role names (which ThemeData.textTheme.bodyLarge etc.
/// still cover for general use — this is for spots that need the literal
/// spec values, e.g. a hero headline or a stat label).
abstract final class AppTypography {
  static const headlineLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2);
  static const headlineMedium = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3);
  static const headlineSmall = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4);
  static const bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 1.5);
  static const bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.6);
  static const bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.6);
  static const labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);
  static const labelSmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4);
}
