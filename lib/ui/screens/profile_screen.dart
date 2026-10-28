import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/store_provider.dart';
import '../widgets/custom_3d_button.dart';
import '../../core/theme/skin_manager.dart';
import '../widgets/neon_avatar_widget.dart';
import 'credits_screen.dart';
import '../../services/audio_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  int _selectedAvatar = 0;
  late String _selectedSkin;
  late String _selectedGender;
  bool _sfxEnabled = true;
  bool _bgmEnabled = true;
  bool _hasSaved = false;
  final int totalAvatars = SkinManager.occupations.length; 

  @override
  void initState() {
    super.initState();
    final game = context.read<GameProvider>();
    _nameController = TextEditingController(text: game.profileName);
    _selectedAvatar = game.profileAvatarIndex;
    _selectedSkin = game.profileSkin;
    _selectedGender = game.profileGender;
    _sfxEnabled = game.profileSfxEnabled;
    _bgmEnabled = game.profileBgmEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_hasSaved) return;
    _hasSaved = true;
    String name = _nameController.text.trim();
    if (name.isEmpty) {
      name = 'Jugador ${Random().nextInt(9000) + 1000}';
    }
    context.read<GameProvider>().saveProfile(name, _selectedAvatar, _selectedSkin, _selectedGender, _sfxEnabled, _bgmEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SkinManager.getTheme(_selectedSkin);
    final lang = context.watch<LanguageProvider>();

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _save();
        }
      },
      child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          lang.get('profile_title'), 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2))]
          )
        ),
        centerTitle: true,
        backgroundColor: Colors.black26,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, shadows: [Shadow(color: Colors.black87, blurRadius: 4)]),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditsScreen()));
            },
          ),
          DropdownButton<AppLanguage>(
            value: lang.currentLanguage,
            icon: const Icon(Icons.language, color: Colors.white, shadows: [Shadow(color: Colors.black87, blurRadius: 4)]),
            dropdownColor: theme.primaryContainerColor.withOpacity(0.9),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: AppLanguage.es, child: Text('🇪🇸 ES', style: TextStyle(fontWeight: FontWeight.bold))),
              DropdownMenuItem(value: AppLanguage.en, child: Text('🇺🇸 EN', style: TextStyle(fontWeight: FontWeight.bold))),
              DropdownMenuItem(value: AppLanguage.pt, child: Text('🇧🇷 PT', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            onChanged: (val) {
              if (val != null) lang.setLanguage(val);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: SkinManager.getBackgroundProvider(theme.id),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryContainerColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderColor, width: 2),
                  boxShadow: theme.hasNeonGlow ? [BoxShadow(color: theme.borderColor, blurRadius: 10, spreadRadius: 1)] : [],
                ),
                child: Row(
                  children: [
                    Text(lang.get('player_name'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.textColor, shadows: theme.textShadows)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: Builder(
                          builder: (context) {
                            final bool isDarkTheme = theme.textColor == Colors.white ||
                                theme.primaryContainerColor.computeLuminance() < 0.35;
                            final Color inputBgColor = isDarkTheme
                                ? Colors.black.withValues(alpha: 0.45)
                                : Colors.grey[200]!;
                            final Color inputTextColor =
                                isDarkTheme ? Colors.white : Colors.black87;
                            return TextField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: inputTextColor),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 12),
                                hintText: lang.get('name_hint'),
                                hintStyle: TextStyle(
                                    color: isDarkTheme
                                        ? Colors.white54
                                        : Colors.black38),
                                filled: true,
                                fillColor: inputBgColor,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDarkTheme
                                        ? theme.borderColor.withValues(alpha: 0.6)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: theme.borderColor, width: 2),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de Tema (Skin) - Carrusel Escanable
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lang.get('visual_theme'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: theme.titleColor, shadows: theme.textShadows)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final themes = SkinManager.getAvailableThemes();
                                final skinDef = themes[index % themes.length];
                                final isSelected = _selectedSkin == skinDef.id;
                                return GestureDetector(
                                  onLongPress: () {
                                    if ((!skinDef.isBuiltIn || skinDef.id == 'dia_muertos') && skinDef.isDownloaded) {
                                      final store = context.read<StoreProvider>();
                                      store.resetTheme(skinDef.id);
                                      if (_selectedSkin == skinDef.id) {
                                        setState(() => _selectedSkin = 'party');
                                        AudioService().setTheme('party');
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Se desinstaló ${skinDef.name} para volver a probar la descarga.'))
                                      );
                                    }
                                  },
                                  onTap: () {
                                    final store = context.read<StoreProvider>();
                                    bool isPurchased = store.isPurchased(skinDef.id) || !skinDef.isPremium;
                                    
                                    if (skinDef.isDownloaded) {
                                      setState(() => _selectedSkin = skinDef.id);
                                      AudioService().setTheme(skinDef.id);
                                      AudioService().playClickMinor();
                                    } else {
                                      // Logica de Tienda Dummy
                                      if (!isPurchased) {
                                        store.purchaseTheme(skinDef.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Comprando ${skinDef.name} por \$${skinDef.price}...'), duration: const Duration(seconds: 2))
                                        );
                                      } else if (!store.isDownloading(skinDef.id)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                                const SizedBox(width: 10),
                                                Text('Descargando ${skinDef.name}...'),
                                              ],
                                            ),
                                            duration: const Duration(seconds: 2),
                                            backgroundColor: const Color(0xFF6A1B9A),
                                          )
                                        );
                                        store.downloadTheme(skinDef.id).then((success) {
                                          if (mounted) {
                                            if (success) {
                                              setState(() => _selectedSkin = skinDef.id);
                                              AudioService().setTheme(skinDef.id);
                                              AudioService().playThemeBell();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.check_circle, color: Colors.greenAccent),
                                                      const SizedBox(width: 8),
                                                      Text('¡Tema ${skinDef.name} instalado con éxito!'),
                                                    ],
                                                  ),
                                                  duration: const Duration(seconds: 3),
                                                  backgroundColor: const Color(0xFF4A148C),
                                                )
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.error_outline, color: Colors.redAccent),
                                                      const SizedBox(width: 8),
                                                      Text('No se pudo descargar ${skinDef.name}.'),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.red[900],
                                                )
                                              );
                                            }
                                          }
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    width: 100, // Fijar un ancho para que las imagenes de portada luzcan bien
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.blueAccent : theme.primaryContainerColor.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isSelected ? Colors.white : theme.borderColor, width: isSelected ? 2 : 1),
                                      image: skinDef.coverPath.isNotEmpty 
                                        ? DecorationImage(
                                            image: skinDef.getImageProvider(skinDef.coverPath),
                                            fit: BoxFit.cover,
                                            colorFilter: isSelected ? null : ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                                          ) 
                                        : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          skinDef.name.toUpperCase(), 
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 12, 
                                            color: (isSelected || skinDef.coverPath.isNotEmpty) ? Colors.white : theme.textColor,
                                            shadows: skinDef.coverPath.isNotEmpty ? const [Shadow(color: Colors.black, blurRadius: 4)] : null,
                                          )
                                        ),
                                        Consumer<StoreProvider>(
                                          builder: (context, store, child) {
                                            bool isPurchased = store.isPurchased(skinDef.id) || !skinDef.isPremium;
                                            
                                            if (skinDef.isDownloaded) {
                                              return const SizedBox.shrink();
                                            }

                                            if (store.isDownloading(skinDef.id)) {
                                              final progress = store.getDownloadProgress(skinDef.id);
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: SizedBox(
                                                  width: 16, height: 16, 
                                                  child: CircularProgressIndicator(
                                                    value: progress > 0 ? progress : null,
                                                    strokeWidth: 2, 
                                                    color: Colors.blueAccent,
                                                  ),
                                                ),
                                              );
                                            }

                                            return Column(
                                              children: [
                                                Icon(
                                                  isPurchased ? Icons.cloud_download : Icons.lock, 
                                                  size: 16, 
                                                  color: isPurchased ? Colors.blueAccent : Colors.amber,
                                                  shadows: skinDef.coverPath.isNotEmpty ? const [Shadow(color: Colors.black, blurRadius: 4)] : null,
                                                ),
                                                if (!isPurchased && skinDef.price > 0)
                                                  Text(
                                                    '\$${skinDef.price}',
                                                    style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black, blurRadius: 2)]),
                                                  ),
                                              ],
                                            );
                                          }
                                        ),
                                      ],                  
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Selector de Género
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Text(lang.get('gender'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.titleColor, shadows: theme.textShadows)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: WrapAlignment.start,
                            children: [
                              ChoiceChip(
                                label: Text(lang.get('male'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _selectedGender == 'M' ? Colors.white : Colors.black)),
                                selected: _selectedGender == 'M',
                                selectedColor: Colors.blueAccent,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(4),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedGender = 'M');
                                },
                              ),
                              ChoiceChip(
                                label: Text(lang.get('female'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _selectedGender == 'F' ? Colors.white : Colors.black)),
                                selected: _selectedGender == 'F',
                                selectedColor: Colors.pinkAccent,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(4),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedGender = 'F');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Configuracion de Audio
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.primaryContainerColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.borderColor, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.music_note, color: theme.textColor, size: 28),
                            const SizedBox(width: 4),
                            Switch(
                              value: _bgmEnabled,
                              onChanged: (val) {
                                setState(() => _bgmEnabled = val);
                                context.read<GameProvider>().saveAudioSettings(_sfxEnabled, _bgmEnabled);
                                AudioService().playClickMinor();
                              },
                              activeColor: Colors.greenAccent,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.volume_up, color: theme.textColor, size: 28),
                            const SizedBox(width: 4),
                            Switch(
                              value: _sfxEnabled,
                              onChanged: (val) {
                                setState(() => _sfxEnabled = val);
                                context.read<GameProvider>().saveAudioSettings(_sfxEnabled, _bgmEnabled);
                                AudioService().playClickMinor();
                              },
                              activeColor: Colors.greenAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(lang.get('choose_avatar'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.titleColor, shadows: theme.textShadows)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.primaryContainerColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.borderColor, width: 2),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(8),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: totalAvatars,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedAvatar == index;
                        final colors = [Colors.yellowAccent, Colors.greenAccent, Colors.blueAccent, Colors.pinkAccent, Colors.purpleAccent];
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = index),
                          child: NeonAvatarWidget(
                            radius: 30, // Reducir tamaño del avatar
                            imageProvider: SkinManager.getAvatarProvider(_selectedSkin, _selectedGender, index),
                            glowColor: theme.hasNeonGlow ? colors[index % colors.length] : Colors.amber,
                            isSelected: isSelected,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Custom3DButton(
                    text: lang.get('save_profile'),
                    color: Colors.green,
                    shadowColor: Colors.green[900]!,
                    onPressed: () {
                      _save();
                      Navigator.pop(context);
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ), // Container
    ), // Scaffold
  ); // PopScope
}
}
