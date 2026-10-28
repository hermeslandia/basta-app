import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final dirs = ['assets/avatars/classic', 'assets/avatars/party'];
  
  for (final dirPath in dirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;
    
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.png'));
    
    for (final file in files) {
      if (file.lengthSync() < 1000000) {
        print('Skipping ${file.path} (already small: ${file.lengthSync()} bytes)');
        continue;
      }
      print('Processing ${file.path}...');
      final bytes = file.readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image != null) {
        final resized = img.copyResize(image, width: 256, height: 256, interpolation: img.Interpolation.linear);
        file.writeAsBytesSync(img.encodePng(resized, level: 6));
        print('Saved ${file.path}');
      }
    }
  }
}
