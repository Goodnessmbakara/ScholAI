import 'package:flutter/material.dart';

/// Official Material 3 ThemeExtension for ScholAI semantic tokens.
/// Allows custom brand colors to integrate into ThemeData, support lerp animations,
/// and be accessed cleanly via `context.colors`.
@immutable
class ScholAIColors extends ThemeExtension<ScholAIColors> {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  final Color surfaceDark;
  final Color surfaceMid;
  final Color surfaceCard;

  final Color accent;
  final Color accentLight;

  final Color moodVeryLow;
  final Color moodLow;
  final Color moodNeutral;
  final Color moodGood;
  final Color moodGreat;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const ScholAIColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.surfaceDark,
    required this.surfaceMid,
    required this.surfaceCard,
    required this.accent,
    required this.accentLight,
    required this.moodVeryLow,
    required this.moodLow,
    required this.moodNeutral,
    required this.moodGood,
    required this.moodGreat,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  /// Dark mode palette (Default)
  static const dark = ScholAIColors(
    primary: Color(0xFFB85C38),
    primaryLight: Color(0xFFD4845A),
    primaryDark: Color(0xFF8C3D20),
    surfaceDark: Color(0xFF1C1612),
    surfaceMid: Color(0xFF2A201A),
    surfaceCard: Color(0xFF332820),
    accent: Color(0xFF7A8C5C),
    accentLight: Color(0xFFA8BA7E),
    moodVeryLow: Color(0xFF8B3A3A),
    moodLow: Color(0xFFB87333),
    moodNeutral: Color(0xFFD4A853),
    moodGood: Color(0xFF7A9E6A),
    moodGreat: Color(0xFF4E8B6F),
    textPrimary: Color(0xFFF5EBE0),
    textSecondary: Color(0xFFB0907A),
    textMuted: Color(0xFF6B4E3A),
  );

  /// Light mode palette
  static const light = ScholAIColors(
    primary: Color(0xFFB85C38),
    primaryLight: Color(0xFFD4845A),
    primaryDark: Color(0xFF8C3D20),
    surfaceDark: Color(0xFFFDF6EF),
    surfaceMid: Color(0xFFF7EBE0),
    surfaceCard: Color(0xFFEFE2D4),
    accent: Color(0xFF7A8C5C),
    accentLight: Color(0xFFA8BA7E),
    moodVeryLow: Color(0xFF8B3A3A),
    moodLow: Color(0xFFB87333),
    moodNeutral: Color(0xFFD4A853),
    moodGood: Color(0xFF7A9E6A),
    moodGreat: Color(0xFF4E8B6F),
    textPrimary: Color(0xFF2C221E),
    textSecondary: Color(0xFF6E5548),
    textMuted: Color(0xFF9E8475),
  );

  @override
  ScholAIColors copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? surfaceDark,
    Color? surfaceMid,
    Color? surfaceCard,
    Color? accent,
    Color? accentLight,
    Color? moodVeryLow,
    Color? moodLow,
    Color? moodNeutral,
    Color? moodGood,
    Color? moodGreat,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return ScholAIColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      surfaceDark: surfaceDark ?? this.surfaceDark,
      surfaceMid: surfaceMid ?? this.surfaceMid,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      moodVeryLow: moodVeryLow ?? this.moodVeryLow,
      moodLow: moodLow ?? this.moodLow,
      moodNeutral: moodNeutral ?? this.moodNeutral,
      moodGood: moodGood ?? this.moodGood,
      moodGreat: moodGreat ?? this.moodGreat,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ScholAIColors lerp(ThemeExtension<ScholAIColors>? other, double t) {
    if (other is! ScholAIColors) return this;
    return ScholAIColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      surfaceDark: Color.lerp(surfaceDark, other.surfaceDark, t)!,
      surfaceMid: Color.lerp(surfaceMid, other.surfaceMid, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      moodVeryLow: Color.lerp(moodVeryLow, other.moodVeryLow, t)!,
      moodLow: Color.lerp(moodLow, other.moodLow, t)!,
      moodNeutral: Color.lerp(moodNeutral, other.moodNeutral, t)!,
      moodGood: Color.lerp(moodGood, other.moodGood, t)!,
      moodGreat: Color.lerp(moodGreat, other.moodGreat, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

/// Convenience extension on BuildContext to access tokens cleanly via `context.colors`
extension ScholAIThemeX on BuildContext {
  ScholAIColors get colors =>
      Theme.of(this).extension<ScholAIColors>() ?? ScholAIColors.dark;
}
