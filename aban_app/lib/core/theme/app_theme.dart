import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand colors
  static const Color primaryTeal = Color(0xFF043C40);
  static const Color primaryTealDark = Color(0xFF021E20); // for gradients
  static const Color accentGreen = Color(0xFF50C878);
  static const Color greenMist = Color(0xFFCFEBBD);
  static const Color cloud = Color(0xFFF8F9FA);

  // Semantic & neutral
  static const Color warning = Color(0xFFF4B740);
  static const Color error = Color(0xFFE5533D);
  static const Color ink = Color(0xFF131415);
  static const Color slate = Color(0xFF7A7F83);
  static const Color doveGray = Color(0xFFDADDE1);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryTealDark],
  );
}

class AppStyles {
  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
            color: AppColors.ink.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: -2)
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
            color: AppColors.ink.withOpacity(0.10),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: -8)
      ];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cloud,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryTeal,
        primary: AppColors.primaryTeal,
        onPrimary: AppColors.pureWhite,
        secondary: AppColors.accentGreen,
        background: AppColors.cloud,
        error: AppColors.error,
        surface: AppColors.pureWhite,
      ),
      textTheme:
          GoogleFonts.cairoTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(
            color: AppColors.ink, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.cairo(
            color: AppColors.ink, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.cairo(
            color: AppColors.ink, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.cairo(color: AppColors.ink),
        bodyMedium: GoogleFonts.cairo(color: AppColors.slate),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: AppColors.pureWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.ink,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.primaryTeal,
        primary: AppColors.accentGreen, // primary switches to accent in dark
        onPrimary: AppColors.ink,
        secondary: AppColors.greenMist,
        background: AppColors.ink,
        error: AppColors.error,
        surface: const Color(0xFF1C1E20), // slightly lighter than ink
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.cloud,
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
