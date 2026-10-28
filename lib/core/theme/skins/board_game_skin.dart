import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme_extension.dart';

class BoardGameSkin {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE8DCC4), // Parchment beige
      primaryColor: const Color(0xFF2E7D32), // Forest Green
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2E7D32),
        secondary: Color(0xFFB71C1C), // Wine Red
        surface: Color(0xFFD7CCC8), // Wood-like brown tint
      ),
      textTheme: GoogleFonts.playfairDisplayTextTheme().apply(
        bodyColor: const Color(0xFF3E2723), // Dark brown text
        displayColor: const Color(0xFF1B5E20),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB71C1C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFF3E2723), width: 1.5),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension(
          glowColor: Colors.transparent,
          borderWidth: 2.0,
          borderColor: const Color(0xFF3E2723),
          borderRadius: 4.0,
          headingStyle: GoogleFonts.playfairDisplay(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB71C1C),
          ),
        ),
      ],
    );
  }
}
