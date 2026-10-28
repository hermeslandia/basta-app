import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../core/theme/skin_manager.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// Descarga un tema desde [downloadUrl] (o archivo local) y lo descomprime
  /// en <appDocDir>/themes/<themeId> registrándolo en SkinManager.
  Future<bool> downloadAndInstallTheme(
    String themeId,
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('Iniciando descarga/instalación para tema: $themeId desde $downloadUrl');
      onProgress?.call(0.05);

      final docDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${docDir.path}/themes/$themeId');

      List<int>? bytes;

      // 1. Descarga HTTP / HTTPS remota
      if (downloadUrl.startsWith('http://') || downloadUrl.startsWith('https://')) {
        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(downloadUrl));
          final response = await client.send(request);

          if (response.statusCode != 200) {
            debugPrint('Error HTTP ${response.statusCode} al descargar tema $themeId');
            return false;
          }

          final contentLength = response.contentLength ?? 0;
          int received = 0;
          final chunks = <List<int>>[];

          await for (final chunk in response.stream) {
            chunks.add(chunk);
            received += chunk.length;
            if (contentLength > 0 && onProgress != null) {
              // Progreso de descarga: 0.05 a 0.85
              final p = 0.05 + 0.80 * (received / contentLength);
              onProgress(p.clamp(0.05, 0.85));
            }
          }
          bytes = chunks.expand((x) => x).toList();
        } finally {
          client.close();
        }
      } 
      // 2. Archivo ZIP local en disco (para pruebas o emulador/desktop)
      else if (downloadUrl.isNotEmpty && (downloadUrl.startsWith('file://') || File(downloadUrl).existsSync())) {
        final cleanPath = downloadUrl.replaceFirst('file://', '');
        final localFile = File(cleanPath);
        if (localFile.existsSync()) {
          onProgress?.call(0.5);
          bytes = await localFile.readAsBytes();
        }
      }
      // 3. Fallback a dist_dlc/<themeId>.zip si existe localmente
      else {
        final distFile = File('dist_dlc/$themeId.zip');
        if (distFile.existsSync()) {
          debugPrint('Usando paquete local de prueba: ${distFile.path}');
          onProgress?.call(0.5);
          bytes = await distFile.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        debugPrint('No se obtuvieron bytes válidos para el tema $themeId.');
        return false;
      }

      onProgress?.call(0.85);
      debugPrint('Bytes recibidos (${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB). Descomprimiendo con archive...');

      // Descomprimir usando ZipDecoder
      final archive = ZipDecoder().decodeBytes(bytes);

      if (targetDir.existsSync()) {
        try {
          targetDir.deleteSync(recursive: true);
        } catch (_) {}
      }
      targetDir.createSync(recursive: true);

      final totalFiles = archive.length;
      int extractedCount = 0;

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final outFile = File('${targetDir.path}/$filename');
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content as List<int>);
        } else {
          Directory('${targetDir.path}/$filename').createSync(recursive: true);
        }
        extractedCount++;
        if (onProgress != null && totalFiles > 0) {
          final p = 0.85 + 0.15 * (extractedCount / totalFiles);
          onProgress(p.clamp(0.85, 1.0));
        }
      }

      // Leer theme.json recién extraído
      final themeJsonFile = File('${targetDir.path}/theme.json');
      if (themeJsonFile.existsSync()) {
        final jsonStr = await themeJsonFile.readAsString();
        final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
        final installedTheme = SkinTheme.fromJson(
          jsonMap,
          isDownloaded: true,
          localDirectory: targetDir.path,
        );
        SkinManager.registerTheme(installedTheme);
        debugPrint('Tema ${installedTheme.id} instalado y registrado exitosamente en ${targetDir.path}');
      } else {
        // Fallback si no viene theme.json
        SkinManager.setDownloaded(themeId, true);
      }

      onProgress?.call(1.0);
      return true;
    } catch (e, stack) {
      debugPrint('Error crítico en downloadAndInstallTheme para $themeId: $e\n$stack');
      return false;
    }
  }
}
