import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// RPG color palette used throughout the application.
class RPGColors {
  RPGColors._();

  static const Color black = Color(0xFF0A0A0A);
  static const Color darkPurple = Color(0xFF4A1A8F);
  static const Color gold = Color(0xFFCF9F1A);
  static const Color darkRed = Color(0xFF8F1A1A);
  static const Color darkGray = Color(0xFF1E1E1E);
  static const Color darkGrayLight = Color(0xFF2A2A2A);

  // Derived / accent shades
  static const Color purpleLight = Color(0xFF6A3AAF);
  static const Color goldLight = Color(0xFFE8BF3A);
  static const Color redLight = Color(0xFFAF3A3A);
  static const Color white = Color(0xFFE0E0E0);
  static const Color grayText = Color(0xFF888888);
}

/// Pre-built text styles for different game elements.
class RPGTextStyles {
  RPGTextStyles._();

  /// Style for the Dungeon Master narration text (gold, italic).
  static TextStyle masterNarration = GoogleFonts.cinzel(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: RPGColors.gold,
    fontStyle: FontStyle.italic,
    height: 1.5,
  );

  /// Style for system messages (gray, smaller).
  static TextStyle systemMessage = GoogleFonts.robotoMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: RPGColors.grayText,
    height: 1.4,
  );

  /// Style for player chat messages (white).
  static TextStyle playerChat = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: RPGColors.white,
    height: 1.4,
  );

  /// Style for combat result messages (red, bold).
  static TextStyle combatMessage = GoogleFonts.robotoMono(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: RPGColors.darkRed,
    height: 1.4,
  );

  /// Style for headings and titles.
  static TextStyle heading = GoogleFonts.cinzel(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: RPGColors.gold,
  );

  /// Style for subheadings.
  static TextStyle subheading = GoogleFonts.cinzel(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: RPGColors.goldLight,
  );

  /// Style for body text.
  static TextStyle body = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: RPGColors.white,
  );

  /// Style for button labels.
  static TextStyle button = GoogleFonts.cinzel(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: RPGColors.white,
  );

  /// Style for small labels.
  static TextStyle label = GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: RPGColors.gold,
  );
}

/// Builds the application-wide dark RPG theme.
ThemeData buildRPGTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: RPGColors.black,
    primaryColor: RPGColors.darkPurple,
    colorScheme: const ColorScheme.dark(
      primary: RPGColors.darkPurple,
      secondary: RPGColors.gold,
      surface: RPGColors.darkGray,
      error: RPGColors.darkRed,
      onPrimary: RPGColors.white,
      onSecondary: RPGColors.black,
      onSurface: RPGColors.white,
      onError: RPGColors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: RPGColors.darkGray,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: RPGTextStyles.heading.copyWith(fontSize: 18),
      iconTheme: const IconThemeData(color: RPGColors.gold),
    ),
    cardTheme: CardTheme(
      color: RPGColors.darkGrayLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: RPGColors.darkPurple, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RPGColors.darkPurple,
        foregroundColor: RPGColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        textStyle: RPGTextStyles.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: RPGColors.gold,
        textStyle: RPGTextStyles.label,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RPGColors.darkGrayLight,
      labelStyle: RPGTextStyles.label,
      hintStyle: TextStyle(color: RPGColors.grayText.withOpacity(0.6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: RPGColors.darkPurple, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: RPGColors.gold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: RPGColors.darkRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: RPGColors.darkRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    iconTheme: const IconThemeData(color: RPGColors.gold),
    dividerColor: RPGColors.darkPurple.withOpacity(0.3),
    textTheme: TextTheme(
      headlineLarge: RPGTextStyles.heading,
      headlineMedium: RPGTextStyles.subheading,
      bodyLarge: RPGTextStyles.body,
      bodyMedium: RPGTextStyles.playerChat,
      labelLarge: RPGTextStyles.button,
    ),
  );
}
