import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ForensIQ Theme Colors (from screenshots)
  static const Color darkBackground = Color(0xFF081019);
  static const Color cardDark = Color(0xFF111C28);
  static const Color cardBorder = Color(0xFF1C2D3F);
  static const Color inputBackground = Color(0xFF0E1724);

  static const Color neonMint = Color(0xFF00E699);
  static const Color emeraldGreen = Color(0xFF00E699);
  static const Color emeraldDark = Color(0xFF00B377);

  static const Color manipulatedRed = Color(0xFFFF7A7A);
  static const Color errorRed = Color(0xFFFF5252);
  static const Color inconclusiveGray = Color(0xFF8A9BB0);
  static const Color warningOrange = Color(0xFFFFB74D);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: neonMint,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: GoogleFonts.inter().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: neonMint,
      surface: cardDark,
      onSurface: Colors.white,
      error: errorRed,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.normal, color: Colors.white),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.normal, color: const Color(0xFFD1D5DB)),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.normal, color: inconclusiveGray),
    ),
    dividerColor: cardBorder,
    iconTheme: const IconThemeData(color: Colors.white),
    cardTheme: CardThemeData(
      color: cardDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: cardBorder, width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardDark,
      selectedItemColor: neonMint,
      unselectedItemColor: inconclusiveGray,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cardBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cardBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: neonMint, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, color: inconclusiveGray, fontSize: 15),
    ),
  );

  static final ThemeData lightTheme = darkTheme;
}

