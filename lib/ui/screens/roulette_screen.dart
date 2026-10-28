import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../core/models/game_state.dart';
import '../widgets/custom_3d_button.dart';
import '../widgets/roulette_painter.dart';
import '../widgets/sun_face_widget.dart';
import 'game_screen.dart';
import '../../core/theme/skin_manager.dart';
import '../../providers/language_provider.dart';
import '../../services/audio_service.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({Key? key}) : super(key: key);

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  bool _isSpinning = false;
  int _lastSliceIndex = -1;
  int? _lastSpinId;

  final List<String> letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

  int _countdown = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    AudioService().stopBgm(); // Detener música de fondo al iniciar las partidas
    _lastSpinId = context.read<GameProvider>().gameState.spinId;

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _spinAnimation = Tween<double>(begin: 0, end: 0).animate(_spinController);

    _spinController.addListener(() {
      final double anglePerLetter = 2 * pi / letters.length;
      final int sliceIndex = (_spinAnimation.value / anglePerLetter).floor();
      if (_lastSliceIndex != -1 && sliceIndex != _lastSliceIndex) {
        AudioService().playRoulette();
      }
      _lastSliceIndex = sliceIndex;
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onSpinButtonPressed() {
    if (_isSpinning) return;
    final game = context.read<GameProvider>();
    if (game.localPlayer?.id == game.gameState.activePlayerId) {
      // Filtrar las letras que aún no han salido en esta partida para no repetir letra
      final used = game.gameState.usedLetters;
      final List<int> availableIndices = [];
      for (int i = 0; i < letters.length; i++) {
        if (!used.contains(letters[i])) {
          availableIndices.add(i);
        }
      }
      final int randomIndex = availableIndices.isNotEmpty
          ? availableIndices[Random().nextInt(availableIndices.length)]
          : Random().nextInt(letters.length);

      // Notificar a TODOS los jugadores el índice objetivo para que todas las ruletas giren y caigan en la misma letra
      game.startRouletteSpin(randomIndex, letters[randomIndex]);
    }
  }

  void _animateSpinToIndex(int targetIndex) {
    if (_isSpinning) return;
    setState(() => _isSpinning = true);

    final double anglePerLetter = 2 * pi / letters.length;
    final double currentAngle = _spinAnimation.value % (2 * pi);
    // Calculamos el ángulo exacto para que la letra ganadora quede centrada arriba (12 en punto)
    final double targetMod = ((letters.length - targetIndex) % letters.length) * anglePerLetter;
    double deltaToTarget = (targetMod - currentAngle) % (2 * pi);
    if (deltaToTarget < 0) deltaToTarget += 2 * pi;
    // Sumamos 3 vueltas completas para que los tics encajen con el audio
    final double targetAngle = deltaToTarget + (3 * 2 * pi);

    _spinAnimation = Tween<double>(
      begin: currentAngle,
      end: currentAngle + targetAngle,
    ).animate(
      CurvedAnimation(
        parent: _spinController,
        curve: Curves.easeOutCirc,
      ),
    );

    _lastSliceIndex = (currentAngle / anglePerLetter).floor();

    _spinController.forward(from: 0).then((_) {
      if (!mounted) return;
      AudioService().playThemeBell();
      final game = context.read<GameProvider>();
      if (game.localPlayer?.id == game.gameState.activePlayerId) {
        game.selectLetter(letters[targetIndex]);
      }
    });
  }

  void _startCountdown() {
    if (_countdown <= 1) return;
    if (_countdownTimer != null && _countdownTimer!.isActive) return;
    _countdown = 3;
    AudioService().playReady(_countdown);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
          AudioService().playReady(_countdown);
        } else {
          AudioService().playReadyGo();
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final theme = SkinManager.getTheme(game.profileSkin);
    final lang = context.watch<LanguageProvider>();

    // Si llegó un nuevo giro de ruleta válido por red (spinId > 0), animar el giro en TODOS los dispositivos hacia la misma letra
    final int incomingSpinId = game.gameState.spinId;
    final int incomingTargetIndex = game.gameState.spinTargetIndex;
    if (incomingSpinId > 0 &&
        incomingTargetIndex >= 0 &&
        incomingSpinId != _lastSpinId &&
        game.gameState.phase == GamePhase.roulette) {
      _lastSpinId = incomingSpinId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animateSpinToIndex(incomingTargetIndex);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (game.roomClosed) {
        final msg = game.roomClosedMessage ?? lang.get('room_closed');
        game.resetGame();
        AudioService().playBgm('bgm');
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      if (game.gameState.phase == GamePhase.playing) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      }
    });

    if (game.gameState.phase == GamePhase.letterCountdown) {
      _startCountdown();
    }

    final bool isActivePlayer = game.localPlayer?.id == game.gameState.activePlayerId;
    final String activePlayerName = game.gameState.players.isNotEmpty
        ? game.gameState.players
            .firstWhere(
              (p) => p.id == game.gameState.activePlayerId,
              orElse: () => game.gameState.players.first,
            )
            .name
        : '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: SkinManager.getRouletteBackgroundProvider(theme.id),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lang.get('drawing_letter'),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: theme.titleColor,
                          shadows: theme.textShadows,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // TODOS los jugadores ven la ruleta 3D girar en tiempo real y caer en la misma letra
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: 340,
                            height: 340,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // 1. Disco interior giratorio (gajos + letras A-Z)
                                AnimatedBuilder(
                                  animation: _spinAnimation,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _spinAnimation.value,
                                      child: child,
                                    );
                                  },
                                  child: CustomPaint(
                                    size: const Size(340, 340),
                                    painter: RoulettePainter(
                                      skin: game.profileSkin,
                                      letters: letters,
                                    ),
                                  ),
                                ),
                                // 2. Marco exterior 3D estático (dorado en Party, madera torneada en Clásico)
                                if (game.profileSkin == 'party' || game.profileSkin == 'classic' || game.profileSkin == 'dia_muertos')
                                  IgnorePointer(
                                    child: CustomPaint(
                                      size: const Size(340, 340),
                                      painter: RouletteFramePainter(skin: game.profileSkin),
                                    ),
                                  ),
                                // 3. Centro temático estático (Sol feliz en Party, Mano de madera tallada 3D en Clásico)
                                if (game.profileSkin == 'party')
                                  const SunFaceWidget(size: 124)
                                else if (game.profileSkin == 'classic')
                                  Transform.translate(
                                    offset: const Offset(0, -10),
                                    child: const ClassicWoodHandWidget(size: 132),
                                  )
                                else if (game.profileSkin == 'dia_muertos')
                                  AnimatedBuilder(
                                    animation: _spinAnimation,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: -_spinAnimation.value,
                                        child: child,
                                      );
                                    },
                                    child: const DiaMuertosCatrinaCenterWidget(size: 94),
                                  ),
                                // 4. Puntero superior 3D anclado al borde del aro
                                Positioned(
                                  top: (game.profileSkin == 'party' || game.profileSkin == 'classic' || game.profileSkin == 'dia_muertos')
                                      ? -8
                                      : -4,
                                  child: RoulettePointerWidget(skin: game.profileSkin),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isActivePlayer)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: Custom3DButton(
                              text: _isSpinning ? 'GIRANDO...' : lang.get('spin_again'),
                              color: _isSpinning ? Colors.grey : Colors.orange,
                              shadowColor: _isSpinning ? Colors.grey[800]! : Colors.deepOrange[900]!,
                              onPressed: _onSpinButtonPressed,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber, width: 2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isSpinning ? '¡Girando la ruleta!' : 'Turno del jugador:',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activePlayerName,
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // OVERLAY CUENTA REGRESIVA
            if (game.gameState.phase == GamePhase.letterCountdown)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game.gameState.currentLetter ?? '',
                        style: TextStyle(
                          fontSize: 150,
                          fontWeight: FontWeight.w900,
                          color: theme.hasNeonGlow ? Colors.cyanAccent : Colors.white,
                          shadows: const [BoxShadow(color: Colors.cyan, blurRadius: 40)],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$_countdown',
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
