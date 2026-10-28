import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';

/// Widget reutilizable de presentación para "Caduceo Antigravity Studio".
/// Ensambla el emblema pieza por pieza (bastón/serpientes, orbe, alas cibernéticas,
/// cristales antigravedad) con onda de choque neón y barrido de luz tipo estudio AAA.
class StudioIntroWidget extends StatefulWidget {
  final VoidCallback onFinished;

  const StudioIntroWidget({
    super.key,
    required this.onFinished,
  });

  @override
  State<StudioIntroWidget> createState() => _StudioIntroWidgetState();
}

class _StudioIntroWidgetState extends State<StudioIntroWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 1. Center Staff & Snakes (0.05 -> 0.35)
  late Animation<double> _centerOpacity;
  late Animation<double> _centerScale;

  // 2. Top Orb (0.20 -> 0.50)
  late Animation<double> _orbOpacity;
  late Animation<double> _orbOffsetY;

  // 3. Cybernetic Wings (0.32 -> 0.68)
  late Animation<double> _wingsOpacity;
  late Animation<double> _wingsSlide;
  late Animation<double> _wingsRotation;

  // 4. Shockwave & Flash at Wing Lock-in (0.55 -> 0.85)
  late Animation<double> _shockwaveProgress;

  // 5. Antigravity Crystals & Particles (0.50 -> 0.85)
  late Animation<double> _particlesOpacity;
  late Animation<double> _particlesFloatY;

  // 6. Studio Typography & Shimmer Sweep (0.48 -> 0.90)
  late Animation<double> _textOpacity;
  late Animation<double> _textSpacing;
  late Animation<double> _shimmerSweep;

  // 7. Final Fade Out (0.86 -> 1.00)
  late Animation<double> _masterFadeOut;

  bool _playedCoinSound = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _centerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.30, curve: Curves.easeOut),
      ),
    );
    _centerScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    _orbOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.38, curve: Curves.easeIn),
      ),
    );
    _orbOffsetY = Tween<double>(begin: -70.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.48, curve: Curves.easeOutBack),
      ),
    );

    _wingsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.48, curve: Curves.easeIn),
      ),
    );
    _wingsSlide = Tween<double>(begin: 95.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.64, curve: Curves.easeOutBack),
      ),
    );
    _wingsRotation = Tween<double>(begin: 0.22, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.64, curve: Curves.easeOutBack),
      ),
    );

    _shockwaveProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.56, 0.86, curve: Curves.easeOutCubic),
      ),
    );

    _particlesOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.76, curve: Curves.easeIn),
      ),
    );
    _particlesFloatY = Tween<double>(begin: 24.0, end: -4.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.90, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.72, curve: Curves.easeOut),
      ),
    );
    _textSpacing = Tween<double>(begin: 12.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.78, curve: Curves.easeOutCubic),
      ),
    );
    _shimmerSweep = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.56, 0.88, curve: Curves.easeInOut),
      ),
    );

    _masterFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.86, 1.00, curve: Curves.easeIn),
      ),
    );

    _controller.addListener(_onTick);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onFinished();
      }
    });

    _controller.forward();
  }

  void _onTick() {
    if (!_playedCoinSound && _controller.value >= 0.48) {
      _playedCoinSound = true;
      AudioService().playStudioCoin();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double logoSize = 260.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _masterFadeOut.value,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Fondo de resplandor energético detrás del emblema
                      if (_shockwaveProgress.value > 0.0)
                        CustomPaint(
                          size: const Size(logoSize, logoSize),
                          painter: _CyberShockwavePainter(
                            progress: _shockwaveProgress.value,
                          ),
                        ),

                      // 1. Ala Cibernética Izquierda
                      Opacity(
                        opacity: _wingsOpacity.value,
                        child: Transform.translate(
                          offset: Offset(-_wingsSlide.value, 0),
                          child: Transform.rotate(
                            angle: -_wingsRotation.value,
                            alignment: const Alignment(0.15, 0.0),
                            child: Image.asset(
                              'assets/global/images/studio_part_wing_left.png',
                              width: logoSize,
                              height: logoSize,
                            ),
                          ),
                        ),
                      ),

                      // 2. Ala Cibernética Derecha
                      Opacity(
                        opacity: _wingsOpacity.value,
                        child: Transform.translate(
                          offset: Offset(_wingsSlide.value, 0),
                          child: Transform.rotate(
                            angle: _wingsRotation.value,
                            alignment: const Alignment(-0.15, 0.0),
                            child: Image.asset(
                              'assets/global/images/studio_part_wing_right.png',
                              width: logoSize,
                              height: logoSize,
                            ),
                          ),
                        ),
                      ),

                      // 3. Bastón Central y Serpientes
                      Opacity(
                        opacity: _centerOpacity.value,
                        child: Transform.scale(
                          scale: _centerScale.value,
                          child: Image.asset(
                            'assets/global/images/studio_part_center.png',
                            width: logoSize,
                            height: logoSize,
                          ),
                        ),
                      ),

                      // 4. Orbe Cibernético Superior
                      Opacity(
                        opacity: _orbOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _orbOffsetY.value),
                          child: Image.asset(
                            'assets/global/images/studio_part_orb.png',
                            width: logoSize,
                            height: logoSize,
                          ),
                        ),
                      ),

                      // 5. Cristales y Partículas de Antigravedad
                      Opacity(
                        opacity: _particlesOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _particlesFloatY.value),
                          child: Image.asset(
                            'assets/global/images/studio_part_particles.png',
                            width: logoSize,
                            height: logoSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tipografía del Estudio con barrido de neón
                Opacity(
                  opacity: _textOpacity.value,
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      final double sweep = _shimmerSweep.value;
                      return LinearGradient(
                        begin: Alignment(sweep - 0.6, -0.3),
                        end: Alignment(sweep + 0.6, 0.3),
                        colors: const [
                          Color(0xFF00E5FF),
                          Color(0xFFFFFFFF),
                          Color(0xFFFF00E5),
                          Color(0xFF00E5FF),
                        ],
                        stops: const [0.0, 0.45, 0.65, 1.0],
                      ).createShader(bounds);
                    },
                    child: Column(
                      children: [
                        Text(
                          'CADUCEO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: _textSpacing.value,
                            shadows: const [
                              Shadow(
                                color: Color(0xAA00E5FF),
                                blurRadius: 16,
                              ),
                              Shadow(
                                color: Color(0x88FF00E5),
                                blurRadius: 28,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ANTIGRAVITY STUDIO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: (_textSpacing.value * 0.75).clamp(3.0, 8.0),
                            shadows: const [
                              Shadow(
                                color: Color(0xAAFF00E5),
                                blurRadius: 12,
                              ),
                            ],
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
      },
    );
  }
}

class _CyberShockwavePainter extends CustomPainter {
  final double progress;

  _CyberShockwavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.68;

    // Resplandor radial central que se enciende al acoplar las piezas
    final glowOpacity = math.sin(progress * math.pi).clamp(0.0, 1.0) * 0.45;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: glowOpacity),
          const Color(0xFFFF00E5).withValues(alpha: glowOpacity * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawCircle(center, maxRadius, glowPaint);

    // Anillo de onda de choque expansivo
    final ringRadius = maxRadius * (0.25 + 0.85 * progress);
    final ringAlpha = (1.0 - progress).clamp(0.0, 1.0);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1.0 - progress * 0.7)
      ..color = const Color(0xFF00E5FF).withValues(alpha: ringAlpha * 0.8);
    canvas.drawCircle(center, ringRadius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _CyberShockwavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
