import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFF8F9FE);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFB00020);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF8E87FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final TextTheme textTheme = GoogleFonts.ibmPlexSansTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    titleLarge: GoogleFonts.outfit(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    bodyLarge: GoogleFonts.ibmPlexSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    ),
    bodyMedium: GoogleFonts.ibmPlexSans(
      fontSize: 14,
      color: Colors.black54,
    ),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        color: surfaceColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
