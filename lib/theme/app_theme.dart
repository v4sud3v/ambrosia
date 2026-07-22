import 'package:flutter/material.dart';

/// Ambrosia's visual identity.
///
/// The app is a medical *instrument* that listens privately, so the palette is
/// grounded in clinical trust with a single warm "ambrosia" amber reserved for
/// the live recording pulse — never used decoratively elsewhere.
class AppColors {
  const AppColors._();

  static const Color ink = Color(0xFF132A2B);
  static const Color teal = Color(0xFF0F5257);
  static const Color amber = Color(0xFFE8A33D); // reserved for the live pulse
  static const Color surface = Color(0xFFF7F6F3);
  static const Color slate = Color(0xFF6B7B7A);
  static const Color hairline = Color(0xFFE2E1DB);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.surface,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        // The elapsed time is the hero: large, tabular so digits don't jitter.
        displayLarge: const TextStyle(
          fontSize: 68,
          fontWeight: FontWeight.w300,
          letterSpacing: -1,
          color: AppColors.ink,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        titleMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        bodyMedium: const TextStyle(fontSize: 15, color: AppColors.slate),
        labelSmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: AppColors.slate,
        ),
      ),
    );
  }
}
