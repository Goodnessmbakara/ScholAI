import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ScholAI colour palette — warm, earthy, not clinical.
/// Inspired by Adire textile tones + Headspace warmth.
class AppColors {
  // Primary — warm terracotta
  static const primary = Color(0xFFB85C38);
  static const primaryLight = Color(0xFFD4845A);
  static const primaryDark = Color(0xFF8C3D20);

  // Surface — dark mode warm base
  static const surfaceDark = Color(0xFF1C1612);
  static const surfaceMid = Color(0xFF2A201A);
  static const surfaceCard = Color(0xFF332820);

  // Surface — light mode
  static const surfaceLight = Color(0xFFFDF6EF);
  static const surfaceCardLight = Color(0xFFF5EBE0);

  // Accent — muted olive
  static const accent = Color(0xFF7A8C5C);
  static const accentLight = Color(0xFFA8BA7E);

  // Mood colours (5-level scale)
  static const moodVeryLow = Color(0xFF8B3A3A);   // deep red-brown
  static const moodLow = Color(0xFFB87333);        // copper
  static const moodNeutral = Color(0xFFD4A853);    // warm amber
  static const moodGood = Color(0xFF7A9E6A);       // muted green
  static const moodGreat = Color(0xFF4E8B6F);      // deeper green

  // Text
  static const textPrimary = Color(0xFFF5EBE0);
  static const textSecondary = Color(0xFFB0907A);
  static const textMuted = Color(0xFF6B4E3A);

  // Status
  static const error = Color(0xFFCF6679);
  static const warning = Color(0xFFD4A853);
  static const success = Color(0xFF7A9E6A);
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
