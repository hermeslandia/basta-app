import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme_extension.dart';

class MinimalistSkin {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Off-white
      primaryColor: const Color(0xFF000000), // Pure Black
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF000000),
        secondary: Color(0xFF2962FF), // Electric Blue accent
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: const Color(0xFF111111),
        displayColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension(
          glowColor: Colors.transparent,
          borderWidth: 1.0,
          borderColor: const Color(0xFFE0E0E0),
          borderRadius: 8.0,
          headingStyle: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
