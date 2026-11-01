import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ScholAI colour palette — warm, earthy, not clinical.
/// Inspired by Adire textile tones + Headspace warmth.
class AppColors {
  // Primary — bold terracotta
  static const primary = Color(0xFFD0703C);
  static const primaryLight = Color(0xFFE8946B);
  static const primaryDark = Color(0xFF9A4A22);

  // Surface — deep cocoa base
  static const surfaceDark = Color(0xFF140E0A);
  static const surfaceMid = Color(0xFF241811);
  static const surfaceCard = Color(0xFF2E1F16);

  // Surface — light mode
  static const surfaceLight = Color(0xFFFDF3E9);
  static const surfaceCardLight = Color(0xFFF3E4D3);

  // Accent — leaf green
  static const accent = Color(0xFF7E9B4A);
  static const accentLight = Color(0xFFB3C27B);

  // Mood colours (5-level scale)
  static const moodVeryLow = Color(0xFF9C4040);   // deep clay red
  static const moodLow = Color(0xFFC47B33);        // copper
  static const moodNeutral = Color(0xFFD9A441);    // ochre gold
  static const moodGood = Color(0xFF87A45F);       // leaf
  static const moodGreat = Color(0xFF4F9370);      // deep leaf

  // Text
  static const textPrimary = Color(0xFFF7ECDD);
  static const textSecondary = Color(0xFFC29B82);
  static const textMuted = Color(0xFF7A5C48);

  // Status
  static const error = Color(0xFFD46A70);
  static const warning = Color(0xFFD9A441);
  static const success = Color(0xFF87A45F);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.surfaceDark,
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          displayMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          displaySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          headlineSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: AppColors.textMuted),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surfaceLight,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.surfaceLight,
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme),
        cardTheme: CardThemeData(
          color: AppColors.surfaceCardLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}
