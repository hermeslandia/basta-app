import 'package:flutter/material.dart';

class NeonAvatarWidget extends StatelessWidget {
  final ImageProvider imageProvider;
  final Color glowColor;
  final bool isSelected;
  final double radius;

  const NeonAvatarWidget({
    Key? key,
    required this.imageProvider,
    required this.glowColor,
    this.isSelected = false,
    this.radius = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(
          color: isSelected ? Colors.white : glowColor.withValues(alpha: 0.8),
          width: isSelected ? 4 : 3,
        ),
        boxShadow: [
          // Sombra exterior para dar el efecto Neon Glow
          BoxShadow(
            color: glowColor.withValues(alpha: isSelected ? 0.8 : 0.4),
            blurRadius: isSelected ? 20 : 10,
            spreadRadius: isSelected ? 5 : 2,
          ),
          // Sombra de luz cenital (Highlight)
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
          // Sombra interior (Sombra de profundidad)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ],
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.2),
            ],
            stops: const [0.6, 1.0],
          ),
        ),
      ),
    );
  }
}
