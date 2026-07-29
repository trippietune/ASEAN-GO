import 'package:flutter/material.dart';

/// Warm, pastel palette: soft pink as the primary accent, cream/soft-yellow
/// as the secondary — chosen to read as friendly and human rather than
/// high-tech. Field names are kept stable (pink/yellow/etc.) even though the
/// values are now pastel, so call sites didn't need to change when the
/// palette shifted from a saturated hot-pink theme to this one.
abstract final class AppColors {
  static const pink = Color(0xFFE8A0B4); // dustier rose, not full pastel-baby-pink
  static const pinkLight = Color(0xFFF4C6D2);
  static const pinkDark = Color(0xFFC97C90);

  static const yellow = Color(0xFFF0D9A6); // soft sandy cream, not saturated yellow
  static const yellowSoft = Color(0xFFF7E8C8);
  static const yellowPale = Color(0xFFFFF8EC);

  static const white = Color(0xFFFFFDF8);
  static const greyLight = Color(0xFFF7F2EA);
  static const greyDark = Color(0xFF6D5A50); // warm brown, not neutral grey

  static const success = Color(0xFFA3C9A8); // muted sage
  static const danger = Color(0xFFE0A8A0); // dusty terracotta, not alarm-red
  static const warning = Color(0xFFEBC98F);

  // Dark-mode surfaces: warm charcoal/espresso rather than pure neutral black,
  // so dark mode keeps the same cozy feel instead of turning "techy".
  static const darkBackground = Color(0xFF2A2320);
  static const darkSurface = Color(0xFF352C27);
  static const darkSurfaceAlt = Color(0xFF413530);
  static const darkOnSurfaceMuted = Color(0xFFD8C9BE);

  /// Safety score -> semantic color, shared by markers, gauges, and badges.
  /// Kept muted (sage/sand/terracotta) instead of stoplight red/yellow/green
  /// so a "be careful" pin still reads as gentle, not alarming.
  static Color safetyScoreColor(int score) {
    if (score >= 70) return success;
    if (score >= 40) return warning;
    return danger;
  }
}
