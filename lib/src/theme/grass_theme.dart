import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'grass_colors.dart';

ThemeData buildGrassTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final seed = isDark ? GrassColors.grassAccent : GrassColors.grassPrimary;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    primary: GrassColors.grassPrimary,
    secondary: GrassColors.grassAccent,
    // Dark background: not "pure black", closer to modern storefront UI.
    surface: isDark ? const Color(0xFF111418) : GrassColors.grassWhite,
  );

  final textTheme = GoogleFonts.montserratTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: textTheme.apply(
      bodyColor: isDark ? GrassColors.grassWhite : GrassColors.grassBlack,
      displayColor: isDark ? GrassColors.grassWhite : GrassColors.grassBlack,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      foregroundColor: isDark ? GrassColors.grassWhite : GrassColors.grassBlack,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: isDark ? GrassColors.grassWhite : GrassColors.grassBlack,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}

