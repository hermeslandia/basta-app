import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme_extension.dart';

class PartySkin {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFD54F), // Amarillo brillante
      primaryColor: const Color(0xFF9C27B0), // Morado festivo
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF9C27B0),
        secondary: Color(0xFFE040FB), // Rosa eléctrico
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.comicNeueTextTheme().apply(
        bodyColor: Colors.black87,
        displayColor: const Color(0xFF9C27B0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE040FB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension(
          glowColor: Colors.transparent,
          borderWidth: 0,
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          headingStyle: GoogleFonts.comicNeue(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF9C27B0),
          ),
        ),
      ],
    );
  }
}
