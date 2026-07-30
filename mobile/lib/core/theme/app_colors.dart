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

  static const white = Color(0xFFFFFFFF); // surface
  static const background = Color(0xFFFAFAFA);
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
}
