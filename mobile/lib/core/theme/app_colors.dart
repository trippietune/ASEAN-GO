import 'package:flutter/material.dart';

/// Professional, saturated brand palette — vivid pink as the primary accent,
/// gold as the secondary. Field names are kept stable from the previous
/// pastel iteration (pink/yellow/etc.) even though the values are now fully
/// saturated Material-style tones, so most call sites didn't need to change
/// when the palette shifted back to a polished, professional look.
abstract final class AppColors {
  static const pink = Color(0xFFE91E63); // primary
  static const pinkLight = Color(0xFFF8BBD0); // primary light — backgrounds, hover state
  static const pinkDark = Color(0xFFC2185B); // primary dark — emphasis, active state

  static const yellow = Color(0xFFF9A825); // secondary — highlight, XP, coin
  static const yellowSoft = Color(0xFFFFECB3); // secondary light, warmer — gradient partner to pinkLight
  static const yellowPale = Color(0xFFFFF3E0); // secondary light, paler — card/section backgrounds
  static const yellowDark = Color(0xFFF57F17); // secondary dark — emphasis
  static const creamYellow = Color(0xFFFFF8E7); // pastel background gradient stop
  static const lightYellow = Color(0xFFFFFDE7); // pastel background gradient stop
  static const softCream = Color(0xFFFFFDF5); // pastel background gradient stop, warmest/lightest

  static const white = Color(0xFFFFFFFF); // surface
  static const background = Color(0xFFFFF8E7); // pastel yellow app background (was neutral 0xFFFAFAFA)
  static const greyLight = Color(0xFFF5F5F5); // surface dark / secondary background
  static const greyDark = Color(0xFF212121); // text primary

  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);

  static const success = Color(0xFF43A047);
  static const danger = Color(0xFFE53935);
  static const warning = Color(0xFFFB8C00);
  static const info = Color(0xFF1E88E5); // also used for checkpoint map markers
  static const questPurple = Color(0xFF8E24AA); // quest-linked map markers only

  // Dark-mode surfaces: neutral charcoal, standard Material dark-theme tones.
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkSurfaceAlt = Color(0xFF2A2A2A);
  static const darkOnSurfaceMuted = Color(0xFFBDBDBD);

  /// Safety score -> semantic color, shared by markers, gauges, and badges.
  static Color safetyScoreColor(int score) {
    if (score >= 70) return success;
    if (score >= 40) return warning;
    return danger;
  }

  // XP bar tier colors (levels 1-40, 8 tiers of 5 levels each). Levels 41+
  // switch to a full multi-stop gradient instead — see xpBarGradient below.
  static Color xpBarColor(int level) {
    if (level <= 5) return const Color(0xFFF8BBD0);
    if (level <= 10) return const Color(0xFFFFCC80);
    if (level <= 15) return const Color(0xFFFFF59D);
    if (level <= 20) return const Color(0xFFC5E1A5);
    if (level <= 25) return const Color(0xFF90CAF9);
    if (level <= 30) return const Color(0xFFCE93D8);
    if (level <= 35) return const Color(0xFFF48FB1);
    return const Color(0xFFFFD54F); // 36-40
  }

  static Color xpBarSecondaryColor(int level) {
    if (level <= 5) return const Color(0xFFF06292);
    if (level <= 10) return const Color(0xFFFFA726);
    if (level <= 15) return const Color(0xFFFDD835);
    if (level <= 20) return const Color(0xFF66BB6A);
    if (level <= 25) return const Color(0xFF42A5F5);
    if (level <= 30) return const Color(0xFFAB47BC);
    if (level <= 35) return const Color(0xFFE91E63);
    return const Color(0xFFFFA000); // 36-40
  }

  static const xpBarRainbowColors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFA94D),
    Color(0xFFFFD93D),
    Color(0xFF51CF66),
    Color(0xFF4DABF7),
    Color(0xFF9775FA),
    Color(0xFFF783AC),
  ];

  static const xpBarSpecialColors = [
    Color(0xFFE040FB),
    Color(0xFF7C4DFF),
    Color(0xFF536DFE),
    Color(0xFF00BCD4),
    Color(0xFF00E676),
    Color(0xFFFFEA00),
    Color(0xFFFF9100),
    Color(0xFFFF1744),
  ];

  /// Level -> XP bar gradient. Levels 1-40 use a two-stop tier gradient,
  /// 41-50 a rainbow, 51+ a "special" gradient — matching the level titles
  /// (นักเดินทาง, นักผจญภัย, ... ตำนาน, ราชา, ระดับตำนาน) the design assigns
  /// to each range.
  static Gradient xpBarGradient(int level) {
    if (level <= 40) {
      return LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [xpBarColor(level), xpBarSecondaryColor(level)],
      );
    }
    if (level <= 50) {
      return const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: xpBarRainbowColors,
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: xpBarSpecialColors,
    );
  }

  /// A single representative color per level tier, for places that can't
  /// render a gradient (a plain [Color] field, an icon tint) — levels 1-40
  /// use their tier's primary color; 41+ picks the first stop of the
  /// rainbow/special gradient so it still visually hints at that tier.
  static Color xpTierAccentColor(int level) {
    if (level <= 40) return xpBarColor(level);
    if (level <= 50) return xpBarRainbowColors.first;
    return xpBarSpecialColors.first;
  }
}
