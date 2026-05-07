import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFFB066FE);
  static const Color darkBackground = Color(0xFF000000);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color accentGreen = Color(0xFF00FF41);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color white = Colors.white;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: accentGreen,
      surface: cardBackground,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textGrey,
        ),
      ),
    ).copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: white,
      ),
    ),
  );
}
