import 'package:flutter/material.dart';
import '../../core/models/player.dart';
import '../../core/theme/skin_manager.dart';

class PodiumWidget extends StatelessWidget {
  final List<Player> topPlayers;
  final SkinTheme theme;

  const PodiumWidget({Key? key, required this.topPlayers, required this.theme}) : super(key: key);

  Widget _buildPodiumColumn(Player? player, int position, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (player != null) ...[
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.borderColor, width: 3),
              boxShadow: theme.hasNeonGlow ? [BoxShadow(color: theme.borderColor, blurRadius: 10)] : const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              image: DecorationImage(
                image: SkinManager.getAvatarProvider(theme.id, player.gender, player.avatarIndex),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(player.name, style: TextStyle(fontWeight: FontWeight.bold, color: theme.titleColor, shadows: theme.textShadows)),
        ] else
          const SizedBox(height: 84), // Placeholder if empty
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: theme.borderColor, width: 2),
            boxShadow: theme.hasNeonGlow ? [BoxShadow(color: color, blurRadius: 10)] : const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.primaryContainerColor),
            child: Text('$position', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = topPlayers.isNotEmpty ? topPlayers[0] : null;
    final second = topPlayers.length > 1 ? topPlayers[1] : null;
    final third = topPlayers.length > 2 ? topPlayers[2] : null;

    List<Color> getPodiumColors() {
      if (theme.avatarFolder == 'neon') {
        return [Colors.amberAccent, Colors.grey[300]!, Colors.deepOrangeAccent];
      } else if (theme.avatarFolder == 'classic') {
        return [Colors.orange[700]!, Colors.blueGrey[400]!, Colors.brown[600]!];
      } else {
        return [Colors.amber, Colors.grey[400]!, Colors.brown[300]!];
      }
    }
    
    final colors = getPodiumColors();

    return SizedBox(
      height: 250,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumColumn(second, 2, 100, colors[1]),
          const SizedBox(width: 8),
          _buildPodiumColumn(first, 1, 140, colors[0]),
          const SizedBox(width: 8),
          _buildPodiumColumn(third, 3, 80, colors[2]),
        ],
      ),
    );
  }
}
