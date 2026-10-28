import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skin_manager.dart';
import 'app_theme_extension.dart';

class ThemeManager extends ChangeNotifier {
  String _currentSkinId = 'party';

  String get currentSkinId => _currentSkinId;
  
  SkinTheme get currentSkinTheme => SkinManager.getTheme(_currentSkinId);

  ThemeData get currentThemeData {
    final themeDef = currentSkinTheme;
    
    // Construir ThemeData dinámicamente a partir de la definición de SkinTheme
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: themeDef.primaryContainerColor, 
      primaryColor: themeDef.borderColor,
      colorScheme: ColorScheme.light(
        primary: themeDef.borderColor,
        secondary: themeDef.titleColor,
        surface: themeDef.primaryContainerColor,
      ),
      textTheme: GoogleFonts.comicNeueTextTheme().apply(
        bodyColor: themeDef.textColor,
        displayColor: themeDef.titleColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeDef.borderColor,
          foregroundColor: themeDef.textColor,
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
            color: themeDef.titleColor,
          ),
        ),
      ],
    );
  }

  void changeSkin(String skinId) {
    if (_currentSkinId != skinId) {
      _currentSkinId = skinId;
      notifyListeners();
    }
  }
}
