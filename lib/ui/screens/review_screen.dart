import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../core/models/game_state.dart';
import '../../core/theme/skin_manager.dart';
import '../../services/audio_service.dart';
import '../widgets/custom_3d_button.dart';
import 'leaderboard_screen.dart';
import 'roulette_screen.dart';
import '../../providers/language_provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  void initState() {
    super.initState();
    AudioService().playBgm('score_board');
  }

  Widget _buildSquareSeal(bool isCorrect, SkinTheme theme) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: theme.hasNeonGlow
            ? [BoxShadow(color: isCorrect ? Colors.green : Colors.red, blurRadius: 10)]
            : const [BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2)],
      ),
      child: Icon(isCorrect ? Icons.check : Icons.close, color: Colors.white, size: 20),
    );
  }

  Widget _buildScoreCard(String text, Color color, SkinTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: theme.hasNeonGlow ? [BoxShadow(color: color, blurRadius: 8)] : [],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isHost = game.localPlayer?.isHost ?? false;
    final theme = SkinManager.getTheme(game.profileSkin);
    final lang = context.watch<LanguageProvider>();

    final bool allGuestsConfirmed = game.haveAllGuestsConfirmedVotes;
    final bool localConfirmed = game.hasLocalPlayerConfirmedVotes;
    final int confirmedCount = game.confirmedNonHostCount;
    final int totalGuests = game.nonHostPlayersCount;

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

      if (game.gameState.phase == GamePhase.leaderboard) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
        );
      } else if (game.gameState.phase == GamePhase.roulette) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RouletteScreen()),
        );
      }
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            game.gameState.winCondition == 'points'
                ? '${lang.get('review_title')} (${lang.get('round_label')} ${game.gameState.currentRound} • ${lang.get('goal_pts')}: ${game.gameState.targetScore})'
                : '${lang.get('review_title')} (${game.gameState.currentRound}/${game.gameState.totalRounds})',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: theme.titleColor,
              fontSize: game.gameState.winCondition == 'points' ? 18 : 24,
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
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
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
                      itemCount: game.gameState.players.length,
                      separatorBuilder: (_, __) => Divider(color: theme.borderColor, thickness: 2),
                      itemBuilder: (context, index) {
                        final p = game.gameState.players[index];
                        final int roundScore = game.gameState.roundScores[p.id] ?? 0;
                        final int projectedTotal = p.score + roundScore;
                        final bool playerConfirmed =
                            p.isHost || game.gameState.confirmedVoters.contains(p.id);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: SkinManager.getAvatarProvider(
                                    game.profileSkin,
                                    p.gender,
                                    p.avatarIndex,
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      if (!p.isHost)
                                        Row(
                                          children: [
                                            Icon(
                                              playerConfirmed
                                                  ? Icons.check_circle
                                                  : Icons.hourglass_top,
                                              size: 14,
                                              color: playerConfirmed
                                                  ? Colors.green[700]
                                                  : Colors.orange[800],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              playerConfirmed
                                                  ? lang.get('confirmed_badge')
                                                  : lang.get('rating_badge'),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: playerConfirmed
                                                    ? Colors.green[700]
                                                    : Colors.orange[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+$roundScore ${lang.get('pts')}',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: theme.hasNeonGlow
                                            ? Colors.greenAccent
                                            : Colors.green[800],
                                      ),
                                    ),
                                    Text(
                                      '${lang.get('total_pts')}: $projectedTotal ${lang.get('pts')}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...game.gameState.selectedCategories.map((cat) {
                              final String ans = p.currentAnswers?[cat] ?? '';
                              final bool baseValid = game.hasBaseValidity(ans);
                              final bool isValid = game.isWordValid(p.id, cat);

                              final votes = game.gameState.wordVotes[p.id]?[cat] ?? {};
                              final bool myVote = votes[game.localPlayer?.id] ?? true;

                              // Los jugadores que ya confirmaron sus calificaciones ya no pueden mover los switches
                              final bool canToggleVote =
                                  baseValid && p.id != game.localPlayer?.id && (isHost || !localConfirmed);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        lang.get(cat),
                                        style: TextStyle(
                                          color: theme.textColor.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        ans.isEmpty ? '-' : ans,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: theme.textColor,
                                          decoration: !isValid && baseValid
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (baseValid && p.id != game.localPlayer?.id)
                                      Switch(
                                        value: myVote,
                                        onChanged: canToggleVote
                                            ? (val) {
                                                AudioService().playClickMinor();
                                                game.toggleWordVote(p.id, cat, val);
                                              }
                                            : null,
                                        activeColor: Colors.green,
                                        inactiveThumbColor: Colors.red,
                                      ),
                                    _buildSquareSeal(isValid, theme),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreCard(lang.get('100_unique'), Colors.green, theme),
                      _buildScoreCard(lang.get('50_repeated'), Colors.orange, theme),
                      _buildScoreCard(lang.get('0_empty'), Colors.red, theme),
                    ],
                  ),
                ),
                if (isHost)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Custom3DButton(
                      text: !allGuestsConfirmed
                          ? '${lang.get('waiting_players_ratings')} ($confirmedCount/$totalGuests)'
                          : (!game.isMatchPointReached
                              ? lang.get('next_round')
                              : lang.get('view_final_podium')),
                      color: allGuestsConfirmed ? Colors.blue : Colors.blueGrey,
                      shadowColor: allGuestsConfirmed ? Colors.blue[900]! : Colors.blueGrey[800]!,
                      onPressed: () {
                        if (!allGuestsConfirmed) {
                          AudioService().playError();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${lang.get('waiting_players_ratings')} ($confirmedCount/$totalGuests)',
                              ),
                              backgroundColor: Colors.orange[800],
                            ),
                          );
                          return;
                        }
                        AudioService().playClickMajor();
                        game.finalizeRoundAndProceed(game.isMatchPointReached);
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: !localConfirmed
                        ? Custom3DButton(
                            text: lang.get('confirm_ratings'),
                            color: Colors.green,
                            shadowColor: Colors.green[900]!,
                            onPressed: () {
                              AudioService().playClickMajor();
                              game.confirmVotes();
                            },
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.greenAccent, width: 2),
                            ),
                            child: Text(
                              !allGuestsConfirmed
                                  ? '${lang.get('ratings_confirmed_wait')} ($confirmedCount/$totalGuests)'
                                  : (!game.isMatchPointReached
                                      ? lang.get('waiting_host_next_round')
                                      : lang.get('waiting_host')),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
