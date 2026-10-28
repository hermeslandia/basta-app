import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/skin_manager.dart';
import '../services/download_service.dart';

class StoreProvider extends ChangeNotifier {
  final Map<String, bool> _purchasedThemes = {
    'party': true, // Viene por defecto
    'classic': true, // Viene por defecto
    'dia_muertos': true, // Gratuito para probar
  };

  final Map<String, double> _downloadProgress = {};

  StoreProvider() {
    _loadDownloadedState();
  }

  Future<void> _loadDownloadedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedList = prefs.getStringList('downloaded_themes') ?? [];
      for (final id in downloadedList) {
        SkinManager.setDownloaded(id, true);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading downloaded themes: $e');
    }
  }

  bool isPurchased(String themeId) {
    return _purchasedThemes[themeId] ?? false;
  }

  double getDownloadProgress(String themeId) {
    return _downloadProgress[themeId] ?? 0.0;
  }
  
  bool isDownloading(String themeId) {
    final progress = _downloadProgress[themeId];
    return progress != null && progress > 0.0 && progress < 1.0;
  }

  Future<void> purchaseTheme(String themeId) async {
    await Future.delayed(const Duration(seconds: 1));
    _purchasedThemes[themeId] = true;
    notifyListeners();
  }

  /// Descarga e instala un tema dinámicamente descomprimiendo su paquete ZIP
  Future<bool> downloadTheme(String themeId, {String? customUrl}) async {
    _downloadProgress[themeId] = 0.05;
    notifyListeners();

    final theme = SkinManager.getTheme(themeId);
    final String url = customUrl ?? theme.downloadUrl;

    final success = await DownloadService().downloadAndInstallTheme(
      themeId,
      url,
      onProgress: (p) {
        _downloadProgress[themeId] = p;
        notifyListeners();
      },
    );

    _downloadProgress.remove(themeId);

    if (success) {
      SkinManager.setDownloaded(themeId, true);
      try {
        final prefs = await SharedPreferences.getInstance();
        final downloadedList = prefs.getStringList('downloaded_themes') ?? [];
        if (!downloadedList.contains(themeId)) {
          downloadedList.add(themeId);
          await prefs.setStringList('downloaded_themes', downloadedList);
        }
      } catch (e) {
        debugPrint('Error saving downloaded theme: $e');
      }
    }

    notifyListeners();
    return success;
  }

  /// Permite reiniciar/eliminar un tema para probar el flujo de descarga nuevamente
  Future<void> resetTheme(String themeId) async {
    await SkinManager.deleteTheme(themeId);
    _downloadProgress.remove(themeId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedList = prefs.getStringList('downloaded_themes') ?? [];
      downloadedList.remove(themeId);
      await prefs.setStringList('downloaded_themes', downloadedList);
    } catch (_) {}
    notifyListeners();
  }
}
