import 'dart:io';
import 'package:archive/archive.dart';

void main(List<String> args) {
  final themeName = args.isNotEmpty ? args[0] : 'dia_muertos';
  final sourceDir = Directory('dlc_src/$themeName');

  if (!sourceDir.existsSync()) {
    print('Error: El directorio ${sourceDir.path} no existe.');
    exit(1);
  }

  final outDir = Directory('dist_dlc');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final zipFilePath = '${outDir.path}/$themeName.zip';
  print('Empaquetando tema "$themeName" desde ${sourceDir.path}...');

  final archive = Archive();

  for (final entity in sourceDir.listSync(recursive: true)) {
    if (entity is File) {
      final relativePath = entity.path
          .substring(sourceDir.path.length + 1)
          .replaceAll(r'\', '/');
      final bytes = entity.readAsBytesSync();
      final archiveFile = ArchiveFile(relativePath, bytes.length, bytes);
      archive.addFile(archiveFile);
      print('  + $relativePath (${bytes.length} bytes)');
    }
  }

  final zipData = ZipEncoder().encode(archive);
  File(zipFilePath).writeAsBytesSync(zipData);
  final finalFile = File(zipFilePath);
  print('¡Éxito! Archivo generado: ${finalFile.path} (${(finalFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB)');
}
