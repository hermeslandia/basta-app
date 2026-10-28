import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/network_provider.dart';
import '../../core/models/game_state.dart';
import '../widgets/custom_3d_button.dart';
import '../widgets/neon_avatar_widget.dart';
import 'roulette_screen.dart';

import '../../core/theme/skin_manager.dart';
import '../../providers/language_provider.dart';
import '../../services/audio_service.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final network = context.read<NetworkProvider>();
    final isHost = game.localPlayer?.isHost ?? false;
    final theme = SkinManager.getTheme(game.profileSkin);
    final lang = context.watch<LanguageProvider>();
    final bool isInternet = network.currentMode == NetworkMode.internet;

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

    final String displayTitle = (game.gameState.roomName != null &&
            game.gameState.roomName!.trim().isNotEmpty)
        ? game.gameState.roomName!
        : (game.gameState.roomCode != null
            ? '${lang.get('room_title')} ${game.gameState.roomCode}'
            : lang.get('local_room_title'));

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          game.leaveGame();
          network.disconnect();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            displayTitle,
            style: TextStyle(
              color: theme.titleColor,
              fontWeight: FontWeight.w900,
              shadows: theme.textShadows,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.titleColor),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.titleColor),
            onPressed: () {
              AudioService().playClickMinor();
              game.leaveGame();
              network.disconnect();
              Navigator.pop(context);
            },
          ),
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
                // En modo Internet mostrar tarjeta con Código de Sala y estado Pública/Privada
                if (isInternet && game.gameState.roomCode != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.primaryContainerColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.borderColor, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              game.gameState.isPrivateRoom ? Icons.lock : Icons.public,
                              color: game.gameState.isPrivateRoom
                                  ? Colors.amber[800]
                                  : Colors.green[700],
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game.gameState.isPrivateRoom
                                      ? 'SALA PRIVADA'
                                      : 'SALA PÚBLICA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: game.gameState.isPrivateRoom
                                        ? Colors.amber[900]
                                        : Colors.green[800],
                                  ),
                                ),
                                Text(
                                  'CÓDIGO: ${game.gameState.roomCode}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Copiar código',
                          icon: Icon(Icons.copy, color: theme.textColor),
                          onPressed: () {
                            AudioService().playClickMinor();
                            Clipboard.setData(
                              ClipboardData(text: game.gameState.roomCode ?? ''),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Código ${game.gameState.roomCode} copiado al portapapeles',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                // Resumen del modo de juego configurado (Por Rondas o Por Puntuación Máxima)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.borderColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        game.gameState.winCondition == 'points'
                            ? Icons.emoji_events
                            : Icons.repeat,
                        color: Colors.amberAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        game.gameState.winCondition == 'points'
                            ? '${lang.get('mode_by_points')}: ${game.gameState.targetScore} ${lang.get('pts')} • ${game.gameState.timerDurationSeconds}s'
                            : '${lang.get('mode_by_rounds')}: ${game.gameState.totalRounds} • ${game.gameState.timerDurationSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: game.gameState.players.length,
                    itemBuilder: (context, index) {
                      final player = game.gameState.players[index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NeonAvatarWidget(
                            imageProvider: SkinManager.getAvatarProvider(
                              game.profileSkin,
                              player.gender,
                              player.avatarIndex,
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
                            isSelected: player.id == game.localPlayer?.id,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            player.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: theme.titleColor,
                              shadows: theme.textShadows,
                            ),
                          ),
                          if (player.isHost)
                            Text(
                              lang.get('host_crown'),
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                shadows: theme.textShadows,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                if (isHost)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Custom3DButton(
                      text: lang.get('start_game'),
                      color: Colors.green,
                      shadowColor: Colors.green[900]!,
                      onPressed: () {
                        if (game.gameState.players.length < 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.get('waiting_more_players') != 'waiting_more_players'
                                    ? lang.get('waiting_more_players')
                                    : 'Esperando a más integrantes... (Mínimo 2)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        AudioService().playClickMajor();
                        game.startRoulette();
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          lang.get('waiting_host'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
