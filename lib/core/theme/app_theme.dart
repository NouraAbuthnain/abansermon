import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ──────────────────────────────────────────────
  // Brand — Primary (deep teal tones)
  // ──────────────────────────────────────────────
  static const Color primaryTeal = Color(0xFF043C40);       // Main brand color — app bars, nav highlights
  static const Color primaryTealDark = Color(0xFF021E20);   // Darker teal — used in gradient endpoints

  // ──────────────────────────────────────────────
  // Brand — Accent (green tones)
  // ──────────────────────────────────────────────
  static const Color accentGreen = Color(0xFF50C878);       // Primary CTA — buttons, active indicators, links
  static const Color accentGreenHover = Color(0xFF45B86A);  // Hover state for accent green elements
  static const Color accentGreenDark = Color(0xFF3DA85E);   // Pressed/active state for accent green elements
  static const Color greenMist = Color(0xFFCFEBBD);         // Soft green tint — tags, badges, light highlights

  // ──────────────────────────────────────────────
  // Neutral — Text and icons
  // ──────────────────────────────────────────────
  static const Color ink = Color(0xFF131415);               // Primary text — headings, body copy (light mode)
  static const Color slate = Color(0xFF7A7F83);             // Secondary text — subtitles, captions, inactive icons
  static const Color doveGray = Color(0xFFDADDE1);          // Tertiary text — placeholders, dividers, borders

  // ──────────────────────────────────────────────
  // Backgrounds and surfaces
  // ──────────────────────────────────────────────
  static const Color pureWhite = Color(0xFFFFFFFF);         // Cards, sheets, navbar background (light mode)
  static const Color cloud = Color(0xFFF8F9FA);             // Scaffold background (light mode)

  // ──────────────────────────────────────────────
  // Button — secondary (dark mode surface tones)
  // ──────────────────────────────────────────────
  static const Color secondaryDarkBg = Color(0xFF2A2D30);       // Default — secondary button and navbar bg (dark mode)
  static const Color secondaryDarkHover = Color(0xFF343840);    // Hover state
  static const Color secondaryDarkPressed = Color(0xFF22252A);  // Pressed/active state

  // ──────────────────────────────────────────────
  // Button — secondary (light mode surface tones)
  // ──────────────────────────────────────────────
  static const Color secondaryLightBg = Color(0xFFF0F1F3);       // Default — secondary button bg (light mode)
  static const Color secondaryLightHover = Color(0xFFE4E6E9);    // Hover state
  static const Color secondaryLightPressed = Color(0xFFD8DBDF);  // Pressed/active state

  // ──────────────────────────────────────────────
  // Semantic — status and feedback
  // ──────────────────────────────────────────────
  static const Color warning = Color(0xFFF4B740);           // Warnings, caution banners
  static const Color error = Color(0xFFE5533D);             // Errors, destructive actions, validation

  // ──────────────────────────────────────────────
  // Gradients
  // ──────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryTealDark],                 // Deep teal → darker teal (onboarding, headers)
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
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(
            color: AppColors.ink, fontSize: 32, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.cairo(
            color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.cairo(
            color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.cairo(color: AppColors.ink, fontSize: 16),
        bodyMedium: GoogleFonts.cairo(color: AppColors.slate, fontSize: 14),
        labelLarge: GoogleFonts.cairo(color: AppColors.slate, fontSize: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
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
        primary: AppColors.accentGreen,
        onPrimary: AppColors.ink,
        secondary: AppColors.greenMist,
        background: AppColors.ink,
        error: AppColors.error,
        surface: const Color(0xFF1C1E20),
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(
            color: AppColors.pureWhite,
            fontSize: 32,
            fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.cairo(
            color: AppColors.pureWhite,
            fontSize: 24,
            fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.cairo(
            color: AppColors.pureWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.cairo(color: AppColors.pureWhite, fontSize: 16),
        bodyMedium:
            GoogleFonts.cairo(color: AppColors.doveGray, fontSize: 14),
        labelLarge:
            GoogleFonts.cairo(color: AppColors.doveGray, fontSize: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.cloud,
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
