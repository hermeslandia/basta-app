import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/network_provider.dart';
import '../widgets/custom_3d_button.dart';
import '../widgets/podium_widget.dart';
import '../widgets/neon_avatar_widget.dart';

import '../../core/theme/skin_manager.dart';
import '../../providers/language_provider.dart';
import 'roulette_screen.dart';
import '../../core/models/game_state.dart';
import '../../core/models/player.dart';
import 'lobby_screen.dart';
import '../../services/audio_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    // Reproducir música de podio (si el switch de música está activo)
    AudioService().playBgm('podium_music');
  }

  @override
  void dispose() {
    // Restaurar BGM normal al salir (si el switch de música está activo)
    AudioService().playBgm('bgm');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final network = context.read<NetworkProvider>();
    final theme = SkinManager.getTheme(game.profileSkin);
    final lang = context.watch<LanguageProvider>();
    final bool isHost = game.localPlayer?.isHost == true;
    final bool hasMoreRounds = false; // LeaderboardScreen es siempre el podio final de la partida

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (game.roomClosed) {
        final msg = game.roomClosedMessage ?? lang.get('room_closed');
        game.resetGame();
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      if (game.gameState.phase == GamePhase.roulette) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RouletteScreen()),
        );
      }
    });

    // Ordenamos a los jugadores por puntaje mayor a menor
    final sortedPlayers = List<Player>.from(game.gameState.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            lang.get('final_results'),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: theme.titleColor,
              fontSize: 28,
              shadows: theme.textShadows,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Podio 3D
                PodiumWidget(topPlayers: sortedPlayers, theme: theme),
                const SizedBox(height: 24),

                // Tabla de Resultados Completos
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.primaryContainerColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.borderColor, width: 4),
                      boxShadow: theme.hasNeonGlow
                          ? [BoxShadow(color: theme.borderColor, blurRadius: 10)]
                          : [],
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedPlayers.length,
                      separatorBuilder: (_, __) => Divider(color: theme.borderColor, thickness: 1),
                      itemBuilder: (context, index) {
                        final p = sortedPlayers[index];
                        return Row(
                          children: [
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: theme.textColor.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            NeonAvatarWidget(
                              radius: 16,
                              imageProvider: SkinManager.getAvatarProvider(
                                game.profileSkin,
                                p.gender,
                                p.avatarIndex,
                              ),
                              glowColor: theme.hasNeonGlow
                                  ? [
                                      Colors.yellowAccent,
                                      Colors.greenAccent,
                                      Colors.blueAccent,
                                      Colors.pinkAccent,
                                      Colors.purpleAccent
                                    ][index % 5]
                                  : theme.borderColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                            Text(
                              '${p.score} ${lang.get('pts')}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: theme.hasNeonGlow ? Colors.greenAccent : Colors.green[800],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: hasMoreRounds
                      ? (isHost
                          ? Column(
                              children: [
                                Custom3DButton(
                                  text: lang.get('next_round'),
                                  color: Colors.green,
                                  shadowColor: Colors.green[900]!,
                                  onPressed: () {
                                    AudioService().playClickMinor();
                                    AudioService().playThemeNextRound();
                                    game.nextRound();
                                  },
                                ),
                                const SizedBox(height: 12),
                                Custom3DButton(
                                  text: lang.get('leave_room'),
                                  color: Colors.red,
                                  shadowColor: Colors.red[900]!,
                                  onPressed: () {
                                    AudioService().playClickMinor();
                                    game.leaveGame();
                                    network.disconnect();
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  },
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  lang.get('waiting_host_next_round'),
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ))
                      : Column(
                          children: [
                            // Tanto el Host como los Invitados ven "Regresar a Lobby" y "Salir de Sala"
                            Custom3DButton(
                              text: lang.get('return_to_lobby'),
                              color: Colors.green,
                              shadowColor: Colors.green[900]!,
                              onPressed: () {
                                AudioService().playClickMinor();
                                if (isHost) {
                                  game.hostWantsToPlayAgain();
                                } else {
                                  game.guestWantsToPlayAgain();
                                }
                                Navigator.of(context).popUntil((route) => route.isFirst);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LobbyScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Custom3DButton(
                              text: lang.get('leave_room'),
                              color: Colors.red,
                              shadowColor: Colors.red[900]!,
                              onPressed: () {
                                AudioService().playClickMinor();
                                game.leaveGame();
                                network.disconnect();
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
