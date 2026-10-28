import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/audio_service.dart';
import '../widgets/custom_3d_button.dart';
import 'lobby_screen.dart';
import 'category_selection_screen.dart';
import '../../core/theme/skin_manager.dart';
import 'profile_screen.dart';
import '../../providers/language_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _internetCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Esperar a que cargue el perfil (incluyendo si el switch de música está apagado) antes de iniciar el BGM
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final game = context.read<GameProvider>();
      await game.ensureProfileLoaded();
      if (!mounted) return;
      AudioService().updateSettings(game);
      AudioService().playBgm('bgm');
    });
  }

  @override
  void dispose() {
    _internetCodeController.dispose();
    super.dispose();
  }

  void _checkProfile(BuildContext context, VoidCallback onValid) {
    final game = context.read<GameProvider>();
    final lang = context.read<LanguageProvider>();
    if (game.profileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.get('create_profile_first'))),
      );
    } else {
      onValid();
    }
  }

  void _onCreateGame(BuildContext context) {
    _checkProfile(context, () {
      final game = context.read<GameProvider>();
      game.resetGame();
      game.initializePlayer(game.profileName, true, game.profileAvatarIndex);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
      );
    });
  }

  void _onJoinGame(BuildContext context) {
    _checkProfile(context, () {
      context.read<GameProvider>().resetGame();
      context.read<NetworkProvider>().scanForLocalHosts();
      _showJoinModal(context);
    });
  }

  Future<void> _joinInternetRoomByCode(
    BuildContext dialogContext,
    NetworkProvider network,
    GameProvider game,
    String code,
  ) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    try {
      final success = await network.joinGame(game.profileName, cleanCode);
      if (success) {
        game.initializePlayer(game.profileName, false, game.profileAvatarIndex);
        if (!mounted) return;
        Navigator.pop(dialogContext);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LobbyScreen()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo entrar a la sala. Verifica el código o si ya inició.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showJoinModal(BuildContext context) {
    final game = context.read<GameProvider>();
    _internetCodeController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer2<NetworkProvider, LanguageProvider>(
          builder: (ctx, network, lang, child) {
            final bool isLocal = network.currentMode == NetworkMode.local;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLocal ? Icons.wifi : Icons.public,
                    color: isLocal ? Colors.green[700] : Colors.blueAccent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      lang.get('available_rooms'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isLocal) ...[
                        if (network.availableHosts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text(
                                  'Buscando salas en red Wi-Fi local...',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ...network.availableHosts.map(
                          (service) => Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.meeting_room, color: Colors.green),
                              title: Text(
                                service.name ?? lang.get('local_room'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(lang.get('join')),
                                onPressed: () async {
                                  AudioService().playClickMinor();
                                  final success = await network.joinGame(game.profileName, service);
                                  if (success) {
                                    game.initializePlayer(
                                      game.profileName,
                                      false,
                                      game.profileAvatarIndex,
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(dialogContext);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LobbyScreen()),
                                    );
                                  } else {
                                    if (!mounted) return;
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error al conectar. Es posible que la sala ya no exista.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // MODO INTERNET: 1. Ingresar por código (para salas privadas o públicas)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.vpn_key, size: 18, color: Colors.amber),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Ingresar con Código (Privada o Pública)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _internetCodeController,
                                      textCapitalization: TextCapitalization.characters,
                                      maxLength: 4,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                        fontSize: 16,
                                        letterSpacing: 2,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        hintText: 'Ej. A7K9',
                                        hintStyle: const TextStyle(color: Colors.black38),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      AudioService().playClickMinor();
                                      _joinInternetRoomByCode(
                                        dialogContext,
                                        network,
                                        game,
                                        _internetCodeController.text,
                                      );
                                    },
                                    child: Text(
                                      lang.get('join'),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.public, size: 18, color: Colors.green),
                            SizedBox(width: 6),
                            Text(
                              'Salas Públicas en Tiempo Real',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (network.availableInternetRooms.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'No hay salas públicas en espera.\n¡Crea una sala o ingresa con código privado!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                              ],
                            ),
                          )
                        else
                          ...network.availableInternetRooms.map(
                            (room) => Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                title: Text(
                                  room.roomName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Código: ${room.code}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '👤 ${room.playerCount} en sala',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    AudioService().playClickMinor();
                                    _joinInternetRoomByCode(
                                      dialogContext,
                                      network,
                                      game,
                                      room.code,
                                    );
                                  },
                                  child: Text(
                                    lang.get('join'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    network.stopRoomDiscovery();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        context.read<NetworkProvider>().stopRoomDiscovery();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkProvider>();
    final game = context.watch<GameProvider>();
    final lang = context.watch<LanguageProvider>();
    final isLocal = network.currentMode == NetworkMode.local;
    final theme = SkinManager.getTheme(game.profileSkin);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: SkinManager.getBackgroundProvider(theme.id),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Oficial
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, offset: Offset(0, 10), blurRadius: 15)
                        ],
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Image.asset(
                        'assets/global/icon/app_icon.png',
                        width: 220,
                        height: 220,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Wi-Fi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Switch(
                          value: !isLocal,
                          onChanged: (val) {
                            setState(
                              () => network.setMode(val ? NetworkMode.internet : NetworkMode.local),
                            );
                            AudioService().playClickMinor();
                          },
                          activeColor: Colors.blueAccent,
                        ),
                        const Text(
                          'Internet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  Custom3DButton(
                    text: 'JUGAR SOLO',
                    color: Colors.blue,
                    shadowColor: Colors.blue[900]!,
                    icon: Icons.play_arrow,
                    onPressed: () {
                      AudioService().playClickMajor();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Modo Solo próximamente...')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Custom3DButton(
                    text: lang.get('create_room').toUpperCase(),
                    color: Colors.orange,
                    shadowColor: Colors.deepOrange[900]!,
                    icon: Icons.settings,
                    onPressed: () {
                      AudioService().playClickMajor();
                      _onCreateGame(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  Custom3DButton(
                    text: lang.get('join_room').toUpperCase(),
                    color: Colors.green,
                    shadowColor: Colors.green[900]!,
                    icon: Icons.group,
                    onPressed: () {
                      AudioService().playClickMajor();
                      _onJoinGame(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  Custom3DButton(
                    text: lang.get('my_profile').toUpperCase(),
                    color: Colors.purple,
                    shadowColor: Colors.purple[900]!,
                    icon: Icons.person,
                    onPressed: () {
                      AudioService().playClickMajor();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
