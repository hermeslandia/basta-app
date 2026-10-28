import 'package:flutter/material.dart';

class SunFaceWidget extends StatelessWidget {
  final double size;

  const SunFaceWidget({Key? key, this.size = 122}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SunFacePainter(),
      ),
    );
  }
}

class _SunFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Sombra exterior cálida proyectada sobre los gajos de la ruleta
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.06),
      radius * 1.04,
      Paint()
        ..color = const Color(0x664A1E04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 2. Esfera principal con degradado 3D cálido (amarillo sol a dorado miel)
    final sphereRect = Rect.fromCircle(center: center, radius: radius);
    final spherePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.28, -0.32),
        radius: 0.95,
        colors: [
          Color(0xFFFFF36D),
          Color(0xFFFFD53D),
          Color(0xFFF5A31A),
        ],
        stops: [0.0, 0.62, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, radius, spherePaint);

    // 3. Sombra creciente interior abajo-derecha para volumen cartoon
    canvas.save();
    canvas.clipPath(Path()..addOval(sphereRect));
    final crescentShadow = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..addOval(
        Rect.fromCircle(
          center: Offset(center.dx - radius * 0.10, center.dy - radius * 0.12),
          radius: radius * 0.96,
        ),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      crescentShadow,
      Paint()..color = const Color(0x44C86400),
    );
    canvas.restore();

    // 4. Brillo doble estilo caricatura en la frente (arriba-izquierda)
    final highlightPaint = Paint()
      ..color = const Color(0xEBFFFDE7)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx - radius * 0.24, center.dy - radius * 0.58);
    canvas.rotate(-0.42);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.46,
        height: radius * 0.20,
      ),
      highlightPaint,
    );
    canvas.restore();

    canvas.drawCircle(
      Offset(center.dx + radius * 0.05, center.dy - radius * 0.67),
      radius * 0.065,
      highlightPaint,
    );

    // 5. Ojos felices arqueados (^ ^)
    final eyePaint = Paint()
      ..color = const Color(0xFF4E1F0D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.095
      ..strokeCap = StrokeCap.round;

    final eyeOffsetX = radius * 0.34;
    final eyeY = center.dy - radius * 0.06;
    final eyeHalfWidth = radius * 0.15;
    final eyeArchHeight = radius * 0.15;

    final leftEyePath = Path()
      ..moveTo(center.dx - eyeOffsetX - eyeHalfWidth, eyeY + eyeArchHeight * 0.25)
      ..quadraticBezierTo(
        center.dx - eyeOffsetX,
        eyeY - eyeArchHeight,
        center.dx - eyeOffsetX + eyeHalfWidth,
        eyeY + eyeArchHeight * 0.25,
      );
    canvas.drawPath(leftEyePath, eyePaint);

    final rightEyePath = Path()
      ..moveTo(center.dx + eyeOffsetX - eyeHalfWidth, eyeY + eyeArchHeight * 0.25)
      ..quadraticBezierTo(
        center.dx + eyeOffsetX,
        eyeY - eyeArchHeight,
        center.dx + eyeOffsetX + eyeHalfWidth,
        eyeY + eyeArchHeight * 0.25,
      );
    canvas.drawPath(rightEyePath, eyePaint);

    // 6. Mejillas sonrojadas ovaladas
    final cheekPaint = Paint()
      ..color = const Color(0xFFF36B64)
      ..style = PaintingStyle.fill;

    final cheekOffsetX = radius * 0.48;
    final cheekY = center.dy + radius * 0.14;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - cheekOffsetX, cheekY),
        width: radius * 0.28,
        height: radius * 0.16,
      ),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + cheekOffsetX, cheekY),
        width: radius * 0.28,
        height: radius * 0.16,
      ),
      cheekPaint,
    );

    // 7. Boca sonriente abierta con lengua rosada y contorno café
    final mouthTopY = center.dy + radius * 0.13;
    final mouthHalfW = radius * 0.25;
    final mouthBottomY = center.dy + radius * 0.48;

    final mouthPath = Path()
      ..moveTo(center.dx - mouthHalfW, mouthTopY)
      ..quadraticBezierTo(
        center.dx,
        mouthTopY + radius * 0.03,
        center.dx + mouthHalfW,
        mouthTopY,
      )
      ..cubicTo(
        center.dx + mouthHalfW * 1.05,
        mouthBottomY,
        center.dx - mouthHalfW * 1.05,
        mouthBottomY,
        center.dx - mouthHalfW,
        mouthTopY,
      )
      ..close();

    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFF4E1F0D)
        ..style = PaintingStyle.fill,
    );

    // Lengua recortada dentro de la boca
    canvas.save();
    canvas.clipPath(mouthPath);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, mouthBottomY - radius * 0.04),
        width: mouthHalfW * 1.65,
        height: radius * 0.28,
      ),
      Paint()
        ..color = const Color(0xFFFF6E67)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    // Contorno redondeado de la boca
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFF4E1F0D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.055
        ..strokeJoin = StrokeJoin.round,
    );

    // 8. Contorno exterior grueso estilo cartoon café oscuro
    canvas.drawCircle(
      center,
      radius - radius * 0.035,
      Paint()
        ..color = const Color(0xFF632C07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.075,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
