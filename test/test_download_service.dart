import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:basta/services/download_service.dart';
import 'package:basta/core/theme/skin_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return 'build/test_documents';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = MockPathProviderPlatform();

  test('DownloadService can extract and install dia_muertos.zip', () async {
    final zipFile = File('dist_dlc/dia_muertos.zip');
    expect(zipFile.existsSync(), isTrue, reason: 'dist_dlc/dia_muertos.zip must exist');

    final success = await DownloadService().downloadAndInstallTheme(
      'dia_muertos',
      zipFile.path,
    );

    expect(success, isTrue);
    final theme = SkinManager.getTheme('dia_muertos');
    expect(theme.isDownloaded, isTrue);
    expect(theme.localDirectory, isNotNull);

    // Verificar que los archivos se descomprimieron en build/test_documents/themes/dia_muertos
    final extractedJson = File('build/test_documents/themes/dia_muertos/theme.json');
    expect(extractedJson.existsSync(), isTrue);

    final extractedCatrina = File('build/test_documents/themes/dia_muertos/images/dia_muertos_catrina_center.png');
    expect(extractedCatrina.existsSync(), isTrue);

    // Limpieza
    Directory('build/test_documents').deleteSync(recursive: true);
  });
}
