import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme_extension.dart';

class ToysSkin {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE0F7FA), // Light blue pastel
      primaryColor: const Color(0xFFFFCDD2), // Pastel pink
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF64B5F6),
        secondary: Color(0xFFFFD54F),
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.snigletTextTheme().apply(
        bodyColor: const Color(0xFF37474F),
        displayColor: const Color(0xFF1565C0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD54F),
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black87, width: 3),
          ),
          elevation: 0,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension(
          glowColor: Colors.transparent,
          borderWidth: 3.0,
          borderColor: Colors.black87,
          borderRadius: 16.0,
          headingStyle: GoogleFonts.sniglet(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1565C0),
          ),
        ),
      ],
    );
  }
}
