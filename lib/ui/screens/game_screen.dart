import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../core/models/game_state.dart';
import '../widgets/custom_3d_button.dart';
import 'review_screen.dart';
import '../../core/theme/skin_manager.dart';
import '../../providers/language_provider.dart';
import '../../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Timer _timer;
  int _timeLeft = 0;
  bool _answersSubmitted = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    AudioService().playBgm('timelapse');
    final game = context.read<GameProvider>();
    _timeLeft = game.gameState.timerDurationSeconds;

    for (var cat in game.gameState.selectedCategories) {
      _controllers[cat] = TextEditingController();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final isFrozen = game.gameState.phase == GamePhase.frozen ||
          (game.gameState.frozenById != null && game.gameState.frozenById!.isNotEmpty);
      if (_timeLeft > 0 && !isFrozen) {
        setState(() => _timeLeft--);
        if (_timeLeft <= 10 && _timeLeft > 0) {
          AudioService().playCountdown();
        }
      } else if (_timeLeft <= 0 && !isFrozen) {
        _timer.cancel();
      }
    });
  }

  void _submitAnswers() {
    final game = context.read<GameProvider>();
    final answers = <String, String>{};
    _controllers.forEach((key, controller) {
      answers[key] = controller.text.trim().toUpperCase();
    });
    game.submitAnswers(answers);
  }

  void _basta() {
    if (_answersSubmitted) return;
    final game = context.read<GameProvider>();

    bool isValid = true;
    int filledCount = 0;

    for (var controller in _controllers.values) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        if (!game.hasBaseValidity(text)) isValid = false;
        filledCount++;
      }
    }

    if (filledCount < _controllers.length || !isValid) {
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            filledCount < _controllers.length
                ? lang.get('write_all_categories')
                : lang.get('invalid_words'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      AudioService().playError();
      return;
    }

    // Enviar el evento basta_pressed para que suene la alarma y aparezca la mano roja en TODOS los equipos
    game.pressBasta();
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isFrozen = game.gameState.phase == GamePhase.frozen ||
        (game.gameState.frozenById != null && game.gameState.frozenById!.isNotEmpty);
    final theme = SkinManager.getTheme(game.profileSkin);
    final lang = context.watch<LanguageProvider>();

    if ((isFrozen || _timeLeft == 0) && !_answersSubmitted) {
      _answersSubmitted = true;
      _timer.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitAnswers();
      });

      if (game.localPlayer?.isHost == true && _timeLeft == 0) {
        Future.delayed(const Duration(seconds: 4), () {
          game.forceEvaluatePoints();
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (game.roomClosed) {
        final msg = game.roomClosedMessage ?? lang.get('room_closed');
        game.resetGame();
        AudioService().playBgm('bgm');
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return;
      }

      if (game.gameState.phase == GamePhase.review ||
          game.gameState.phase == GamePhase.scoring) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReviewScreen()),
        );
      }
    });

    if (isFrozen) {
      String stopperName = '';
      if (game.gameState.frozenById != null && game.gameState.frozenById!.isNotEmpty) {
        final idx = game.gameState.players
            .indexWhere((p) => p.id == game.gameState.frozenById);
        if (idx != -1) {
          stopperName = game.gameState.players[idx].name;
        }
      }

      return PopScope(
        canPop: false,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: SkinManager.getBackgroundProvider(theme.id),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.redAccent, width: 4),
                        boxShadow: const [
                          BoxShadow(color: Colors.redAccent, blurRadius: 30, spreadRadius: 4),
                        ],
                      ),
                      child: const Icon(
                        Icons.pan_tool,
                        size: 110,
                        color: Colors.redAccent,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      lang.get('stop_button'),
                      style: const TextStyle(
                        fontSize: 68,
                        fontWeight: FontWeight.w900,
                        color: Colors.redAccent,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 12, offset: Offset(0, 4)),
                          Shadow(color: Colors.white38, blurRadius: 16),
                        ],
                      ),
                    ),
                    if (stopperName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '¡$stopperName presionó ${lang.get('stop_button')}!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.amberAccent,
                          shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      lang.get('waiting_server'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            '${lang.get('letter_title')}: ${game.gameState.currentLetter}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: theme.titleColor,
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
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryContainerColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.borderColor, width: 3),
                    boxShadow: theme.hasNeonGlow
                        ? [BoxShadow(color: theme.borderColor, blurRadius: 10)]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: Colors.amber, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        '$_timeLeft',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: game.gameState.selectedCategories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.get(cat),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: theme.titleColor,
                                shadows: theme.textShadows,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _controllers[cat],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.primaryContainerColor,
                                hintText: '...',
                                hintStyle: TextStyle(
                                  color: theme.textColor.withValues(alpha: 0.5),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: theme.borderColor, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: theme.borderColor, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Custom3DButton(
                      text: lang.get('stop_button'),
                      color: Colors.red,
                      shadowColor: Colors.red[900]!,
                      onPressed: _basta,
                    ),
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
