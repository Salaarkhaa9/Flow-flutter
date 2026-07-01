import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Website Brand Colors ──────────────────────────────────────────────────
  /// #0a2226 — deep dark teal-navy (primary brand color, nav, buttons)
  static const Color slateDeep = Color(0xFF0a2226);

  /// #132e35 — slightly lighter navy for card surfaces on dark sections
  static const Color slateLight = Color(0xFF132e35);

  /// #d6ff00 — neon lime-voltage (accent, CTA highlights on dark bg)
  static const Color limeVoltage = Color(0xFFd6ff00);

  // ── Surface / Background ──────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);  // pure white
  static const Color surfaceLight = Color(0xFFFAFAFA); // zinc-50
  static const Color surfaceMid = Color(0xFFF4F4F5);   // zinc-100
  static const Color borderColor = Color(0xFFE4E4E7);  // zinc-200

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF18181B);  // zinc-900
  static const Color textSecondary = Color(0xFF71717A); // zinc-500
  static const Color textMuted = Color(0xFFA1A1AA);    // zinc-400

  // ── Legacy aliases (keeps old references compiling) ───────────────────────
  static const Color primaryPurple = slateDeep;
  static const Color darkBackground = background;
  static const Color cardBackground = surfaceLight;
  static const Color accentGreen = limeVoltage;
  static const Color textGrey = textSecondary;
  static const Color white = Colors.white;

  // ── Theme ─────────────────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: slateDeep,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: slateDeep,
      secondary: limeVoltage,
      surface: surfaceLight,
      onPrimary: Colors.white,
      onSecondary: slateDeep,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: slateDeep,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: slateDeep,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        elevation: 0,
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceMid,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: slateDeep, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted),
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: slateDeep,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: slateDeep,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: slateDeep,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: slateDeep,
        ),
      ),
    ),
    // Keep dark theme as alias for backward compat
  );

  /// Kept for backward compatibility with screens that use AppTheme.darkTheme
  static final ThemeData darkTheme = lightTheme;
}
