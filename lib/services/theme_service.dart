import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/theme/skin_manager.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  /// Sincroniza el catálogo de temas disponibles desde Firebase Realtime Database
  /// bajo el nodo 'themes_catalog'. Si no hay conexión o no existe, usa catálogo base.
  Future<List<SkinTheme>> syncThemesCatalog() async {
    try {
      final ref = FirebaseDatabase.instance.ref('themes_catalog');
      final snapshot = await ref.get().timeout(const Duration(seconds: 4));

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        if (data is Map) {
          final remoteThemes = <SkinTheme>[];
          data.forEach((key, val) {
            if (val is Map) {
              final map = Map<String, dynamic>.from(val);
              final themeId = map['id'] ?? key.toString();
              map['id'] = themeId;

              final existing = SkinManager.getTheme(themeId);
              // Si ya está descargado/instalado en disco, preservamos su estado local
              final bool isDownloaded = existing.isDownloaded;

              final skinTheme = SkinTheme.fromJson(
                map,
                isDownloaded: isDownloaded,
                localDirectory: existing.localDirectory,
              );
              SkinManager.registerTheme(skinTheme);
              remoteThemes.add(skinTheme);
            }
          });
          debugPrint('Catálogo remoto de temas sincronizado: ${remoteThemes.length} temas recibidos.');
          return remoteThemes;
        }
      }
    } catch (e) {
      debugPrint('Aviso: No se pudo conectar a themes_catalog en Firebase ($e). Usando catálogo local/fallback.');
    }

    return SkinManager.getAvailableThemes();
  }

  /// Sube o actualiza la metadata de un tema en Firebase Realtime Database
  Future<bool> publishThemeToCatalog({
    required String id,
    required String name,
    required String description,
    required String downloadUrl,
    required String coverPath,
    required String backgroundPath,
    required String rouletteBackgroundPath,
    required String primaryContainerColor,
    required String titleColor,
    required String textColor,
    required String borderColor,
    bool isPremium = false,
    double price = 0.0,
    int version = 1,
  }) async {
    try {
      final ref = FirebaseDatabase.instance.ref('themes_catalog/$id');
      await ref.set({
        'id': id,
        'name': name,
        'description': description,
        'downloadUrl': downloadUrl,
        'coverPath': coverPath,
        'backgroundPath': backgroundPath,
        'rouletteBackgroundPath': rouletteBackgroundPath,
        'primaryContainerColor': primaryContainerColor,
        'titleColor': titleColor,
        'textColor': textColor,
        'borderColor': borderColor,
        'isPremium': isPremium,
        'price': price,
        'version': version,
        'updatedAt': ServerValue.timestamp,
      });
      debugPrint('Tema $id publicado en themes_catalog exitosamente.');
      return true;
    } catch (e) {
      debugPrint('Error al publicar tema en Firebase: $e');
      return false;
    }
  }
}
