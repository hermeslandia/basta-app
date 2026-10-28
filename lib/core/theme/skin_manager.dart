import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SkinTheme {
  final String id;
  final String name;
  final String backgroundPath;
  final String rouletteBackgroundPath;
  final String coverPath;
  final String catrinaCenterPath;
  final String avatarFolder;
  final Color primaryContainerColor;
  final Color titleColor;
  final Color textColor;
  final Color borderColor;
  final List<Shadow> textShadows;
  final bool isDownloaded;
  final bool isBuiltIn;
  final bool isPremium;
  final double price;
  final String description;
  final String downloadUrl;
  final String? localDirectory;
  
  bool get hasNeonGlow => id == 'neon';

  const SkinTheme({
    required this.id,
    required this.name,
    required this.backgroundPath,
    this.rouletteBackgroundPath = '',
    this.coverPath = '',
    this.catrinaCenterPath = '',
    required this.avatarFolder,
    required this.primaryContainerColor,
    required this.titleColor,
    required this.textColor,
    required this.borderColor,
    required this.textShadows,
    this.isDownloaded = false,
    this.isBuiltIn = false,
    this.isPremium = false,
    this.price = 0.0,
    this.description = '',
    this.downloadUrl = '',
    this.localDirectory,
  });

  static Color _parseColor(dynamic value, Color fallback) {
    if (value == null) return fallback;
    if (value is int) return Color(value);
    if (value is String) {
      String clean = value.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
      if (clean.length == 6) clean = 'FF$clean';
      final int? parsed = int.tryParse(clean, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return fallback;
  }

  // Factory para carga desde JSON (remoto o archivo local)
  factory SkinTheme.fromJson(
    Map<String, dynamic> json, {
    bool isDownloaded = false,
    String? localDirectory,
  }) {
    return SkinTheme(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      backgroundPath: json['backgroundPath'] ?? '',
      rouletteBackgroundPath: json['rouletteBackgroundPath'] ?? '',
      coverPath: json['coverPath'] ?? '',
      catrinaCenterPath: json['catrinaCenterPath'] ?? '',
      avatarFolder: json['avatarFolder'] ?? 'avatars',
      primaryContainerColor: _parseColor(json['primaryContainerColor'], Colors.purple),
      titleColor: _parseColor(json['titleColor'], Colors.amber),
      textColor: _parseColor(json['textColor'], Colors.white),
      borderColor: _parseColor(json['borderColor'], Colors.deepOrange),
      textShadows: const [
        Shadow(color: Color(0xFF000000), offset: Offset(2, 2), blurRadius: 4),
      ],
      isDownloaded: isDownloaded,
      isBuiltIn: json['isBuiltIn'] ?? false,
      isPremium: json['isPremium'] ?? false,
      price: (json['price'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      localDirectory: localDirectory,
    );
  }

  SkinTheme copyWith({
    String? id,
    String? name,
    String? backgroundPath,
    String? rouletteBackgroundPath,
    String? coverPath,
    String? catrinaCenterPath,
    String? avatarFolder,
    Color? primaryContainerColor,
    Color? titleColor,
    Color? textColor,
    Color? borderColor,
    List<Shadow>? textShadows,
    bool? isDownloaded,
    bool? isBuiltIn,
    bool? isPremium,
    double? price,
    String? description,
    String? downloadUrl,
    String? localDirectory,
  }) {
    return SkinTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundPath: backgroundPath ?? this.backgroundPath,
      rouletteBackgroundPath: rouletteBackgroundPath ?? this.rouletteBackgroundPath,
      coverPath: coverPath ?? this.coverPath,
      catrinaCenterPath: catrinaCenterPath ?? this.catrinaCenterPath,
      avatarFolder: avatarFolder ?? this.avatarFolder,
      primaryContainerColor: primaryContainerColor ?? this.primaryContainerColor,
      titleColor: titleColor ?? this.titleColor,
      textColor: textColor ?? this.textColor,
      borderColor: borderColor ?? this.borderColor,
      textShadows: textShadows ?? this.textShadows,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isPremium: isPremium ?? this.isPremium,
      price: price ?? this.price,
      description: description ?? this.description,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      localDirectory: localDirectory ?? this.localDirectory,
    );
  }

  // Obtener proveedor de imagen abstracto (Asset vs File local)
  ImageProvider getImageProvider(String relativePath) {
    if (relativePath.isEmpty) {
      return const AssetImage('assets/themes/party/images/party_bg.png');
    }

    // 0. Si es una URL remota de red (ej. portada remota de GitHub)
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return NetworkImage(relativePath);
    }

    // 1. Si está descargado y hay directorio local
    if (!isBuiltIn && localDirectory != null) {
      final fullPath = relativePath.startsWith(localDirectory!)
          ? relativePath
          : '$localDirectory/$relativePath';
      final file = File(fullPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    // 2. Si ya viene con prefijo assets/
    if (relativePath.startsWith('assets/')) {
      return AssetImage(relativePath);
    }

    // 3. Si existe como archivo directo
    final directFile = File(relativePath);
    if (directFile.existsSync()) {
      return FileImage(directFile);
    }

    // 4. Si es built-in y es relativo
    return AssetImage(relativePath);
  }
}

class SkinManager {
  // Solo 10 profesiones
  static const List<String> occupations = [
    'doctor',
    'policia',
    'bombero',
    'panadero',
    'maestro',
    'constructor',
    'cartero',
    'veterinario',
    'marinero',
    'enfermera',
  ];

  // Registro dinámico de temas
  static final Map<String, SkinTheme> _registeredThemes = {
    'party': const SkinTheme(
      id: 'party',
      name: 'Party',
      backgroundPath: 'assets/themes/party/images/party_bg.png',
      coverPath: 'assets/themes/party/images/party_cover.png',
      avatarFolder: 'party',
      primaryContainerColor: Colors.white70,
      titleColor: Colors.white,
      textColor: Colors.black87,
      borderColor: Colors.pinkAccent,
      textShadows: [Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 4)],
      isDownloaded: true,
      isBuiltIn: true,
    ),
    'classic': SkinTheme(
      id: 'classic',
      name: 'Clásico',
      backgroundPath: 'assets/themes/classic/images/classic_bg.png',
      coverPath: 'assets/themes/classic/images/classic_cover.png',
      avatarFolder: 'classic',
      primaryContainerColor: const Color(0xFFFDF5E6),
      titleColor: Colors.amber[100]!,
      textColor: Colors.brown[900]!,
      borderColor: Colors.amber[700]!,
      textShadows: const [Shadow(color: Colors.black87, offset: Offset(2, 2), blurRadius: 4)],
      isDownloaded: true,
      isBuiltIn: true,
    ),
    'dia_muertos': const SkinTheme(
      id: 'dia_muertos',
      name: 'Día de Muertos',
      backgroundPath: 'assets/themes/dia_muertos/images/dia_muertos_bg.png',
      rouletteBackgroundPath: 'assets/themes/dia_muertos/images/dia_muertos_roulette_bg.png',
      coverPath: 'assets/themes/dia_muertos/images/dia_muertos_cover.png',
      catrinaCenterPath: 'assets/themes/dia_muertos/images/dia_muertos_catrina_center.png',
      avatarFolder: 'dia_muertos',
      primaryContainerColor: Color(0xFF2B0A3D), // Morado ofrenda profundo
      titleColor: Color(0xFFFF9E1B), // Dorado cempasúchil encendido
      textColor: Colors.white,
      borderColor: Color(0xFFFF6F00), // Naranja veladora
      textShadows: [
        Shadow(color: Color(0xFF000000), offset: Offset(2, 2), blurRadius: 4),
        Shadow(color: Color(0xFFE91E63), offset: Offset(0, 0), blurRadius: 8),
      ],
      isDownloaded: false, // Descargable tipo DLC
      isBuiltIn: true,
      isPremium: false,
      price: 0.0,
      description: 'Ofrendas, cempasúchil, papel picado y calaveritas festivas.',
      downloadUrl: 'https://github.com/hermeslandia/basta-dlc/releases/download/v1.0.0/dia_muertos.zip',
    ),
    'neon': const SkinTheme(
      id: 'neon',
      name: 'Neón',
      backgroundPath: '',
      coverPath: 'assets/themes/neon/images/neon_cover.png',
      avatarFolder: '',
      primaryContainerColor: Colors.black,
      titleColor: Colors.cyanAccent,
      textColor: Colors.white,
      borderColor: Colors.pinkAccent,
      textShadows: [],
      isDownloaded: false,
      isBuiltIn: false,
      isPremium: false,
      description: 'El futuro es brillante con este tema estilo Cyberpunk gratuito.',
    ),
    'disney': const SkinTheme(
      id: 'disney',
      name: 'Cuentos',
      backgroundPath: '',
      coverPath: 'assets/themes/disney/images/disney_cover.png',
      avatarFolder: '',
      primaryContainerColor: Colors.white,
      titleColor: Colors.pink,
      textColor: Colors.black,
      borderColor: Colors.pinkAccent,
      textShadows: [],
      isDownloaded: false,
      isBuiltIn: false,
      isPremium: true,
      price: 4.99,
      description: 'Magia pura en tus partidas de BASTA. Tema premium oficial.',
    ),
  };

  /// Carga y registra los temas instalados localmente en el almacenamiento del dispositivo
  static Future<void> loadInstalledThemes() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final themesDir = Directory('${docDir.path}/themes');
      if (!themesDir.existsSync()) return;

      final entities = themesDir.listSync();
      for (final entity in entities) {
        if (entity is Directory) {
          final themeJsonFile = File('${entity.path}/theme.json');
          if (themeJsonFile.existsSync()) {
            final jsonStr = await themeJsonFile.readAsString();
            final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
            final theme = SkinTheme.fromJson(
              jsonMap,
              isDownloaded: true,
              localDirectory: entity.path,
            );
            registerTheme(theme);
            debugPrint('Tema local cargado con éxito: ${theme.id} (${theme.name})');
          }
        }
      }
    } catch (e) {
      debugPrint('Error al cargar temas locales instalados: $e');
    }
  }

  static List<SkinTheme> getAvailableThemes() {
    return _registeredThemes.values.toList();
  }

  static SkinTheme getTheme(String id) {
    return _registeredThemes[id] ?? _registeredThemes['party']!;
  }

  static void registerTheme(SkinTheme theme) {
    _registeredThemes[theme.id] = theme;
  }

  static void setDownloaded(String themeId, bool downloaded) {
    final current = _registeredThemes[themeId];
    if (current != null) {
      _registeredThemes[themeId] = current.copyWith(isDownloaded: downloaded);
    }
  }

  static Future<void> deleteTheme(String themeId) async {
    try {
      final current = _registeredThemes[themeId];
      if (current != null && current.localDirectory != null) {
        final dir = Directory(current.localDirectory!);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Error al eliminar archivos del tema $themeId: $e');
    }
    setDownloaded(themeId, false);
  }

  static ImageProvider getAvatarProvider(String themeId, String gender, int avatarIndex) {
    final theme = getTheme(themeId);
    final folder = theme.avatarFolder.isNotEmpty ? theme.avatarFolder : 'party';
    final occupation = occupations[avatarIndex % occupations.length];

    // Si es un tema descargado externamente, buscar en su carpeta de avatares local
    if (!theme.isBuiltIn && theme.localDirectory != null) {
      final localFile = File('${theme.localDirectory}/avatars/avatar_${gender.toLowerCase()}_$occupation.png');
      if (localFile.existsSync()) {
        return FileImage(localFile);
      }
    }

    final relativePath = 'assets/themes/$folder/avatars/avatar_${gender.toLowerCase()}_$occupation.png';
    return theme.getImageProvider(relativePath);
  }

  static ImageProvider getBackgroundProvider(String themeId) {
    final theme = getTheme(themeId);
    return theme.getImageProvider(theme.backgroundPath);
  }

  static ImageProvider getRouletteBackgroundProvider(String themeId) {
    final theme = getTheme(themeId);
    final path = theme.rouletteBackgroundPath.isNotEmpty
        ? theme.rouletteBackgroundPath
        : theme.backgroundPath;
    return theme.getImageProvider(path);
  }

  static ImageProvider getCatrinaCenterProvider() {
    final theme = getTheme('dia_muertos');
    final path = theme.catrinaCenterPath.isNotEmpty
        ? theme.catrinaCenterPath
        : 'assets/themes/dia_muertos/images/dia_muertos_catrina_center.png';
    return theme.getImageProvider(path);
  }
}
