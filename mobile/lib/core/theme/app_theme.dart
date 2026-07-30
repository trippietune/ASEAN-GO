import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Thai text (Sarabun) is layered over the Latin base (Inter) so Thai
/// glyphs render correctly while English/numeric strings get Inter's clean,
/// professional shapes — the standard pairing for a polished product UI.
TextTheme _brandTextTheme(TextTheme base, Color onSurface) {
  final inter = GoogleFonts.interTextTheme(base);
  return GoogleFonts.sarabunTextTheme(inter).apply(
    bodyColor: onSurface,
    displayColor: onSurface,
  );
}

/// Standard Material page transition — a professional UI shouldn't call
/// attention to its own navigation.
class _SoftFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SoftFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

ThemeData buildAppTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = isDark
      ? const ColorScheme.dark(
          primary: AppColors.pinkLight,
          onPrimary: AppColors.greyDark,
          secondary: AppColors.yellow,
          onSecondary: AppColors.greyDark,
          surface: AppColors.darkSurface,
          onSurface: AppColors.white,
          error: AppColors.danger,
          onError: AppColors.greyDark,
        )
      : const ColorScheme.light(
          primary: AppColors.pink,
          onPrimary: AppColors.white,
          secondary: AppColors.yellow,
          onSecondary: AppColors.greyDark,
          surface: AppColors.white,
          onSurface: AppColors.greyDark,
          error: AppColors.danger,
          onError: AppColors.white,
        );

  final scaffoldBackground = isDark ? AppColors.darkBackground : AppColors.background;
  final cardSurface = isDark ? AppColors.darkSurface : AppColors.white;

  final textTheme = _brandTextTheme(
    ThemeData(brightness: brightness).textTheme,
    colorScheme.onSurface,
  ).apply(fontSizeFactor: 1.0);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBackground,
    textTheme: textTheme.copyWith(
      bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.6),
      bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.5),
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _SoftFadePageTransitionsBuilder(),
        TargetPlatform.iOS: _SoftFadePageTransitionsBuilder(),
      },
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? AppColors.darkSurface : scaffoldBackground,
      foregroundColor: isDark ? AppColors.white : AppColors.greyDark,
      iconTheme: const IconThemeData(color: AppColors.pinkDark),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),

    cardTheme: CardThemeData(
      color: cardSurface,
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        // pinkDark (not pink) as the button fill: white-on-pink is 4.35:1,
        // just under WCAG AA's 4.5:1 for this text size — pinkDark clears it
        // at 5.87:1 comfortably.
        backgroundColor: AppColors.pinkDark,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.pinkDark.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.pinkDark,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.pinkDark,
        side: const BorderSide(color: AppColors.pink, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.pinkDark,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.textHint),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.textHint),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.pink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      indicatorColor: AppColors.pinkLight.withValues(alpha: 0.5),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.pinkDark : (isDark ? AppColors.darkOnSurfaceMuted : Colors.grey),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.pinkDark : (isDark ? AppColors.darkOnSurfaceMuted : Colors.grey),
        );
      }),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.yellowPale,
      labelStyle: TextStyle(color: isDark ? AppColors.yellow : AppColors.pinkDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    ),

    dividerTheme: DividerThemeData(
      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
      space: 1,
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      dragHandleColor: isDark ? Colors.white24 : AppColors.textHint,
    ),
  );
}
