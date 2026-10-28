import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/skin_manager.dart';

class RoulettePainter extends CustomPainter {
  final int totalSlices = 26;
  final String skin;
  final List<String> letters;

  RoulettePainter({
    required this.skin,
    this.letters = const [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
    ],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double anglePerSlice = 2 * pi / totalSlices;

    // En party, classic y dia_muertos, los gajos entran debajo del marco 3D exterior
    final bool hasCustomFrame = skin == 'party' || skin == 'classic' || skin == 'dia_muertos';
    final double sliceRadius = hasCustomFrame ? radius * 0.885 : radius * 0.95;
    final Rect wheelRect = Rect.fromCircle(center: center, radius: sliceRadius);

    final List<Color> palette = _getPaletteForSkin(skin);

    canvas.save();
    canvas.clipPath(Path()..addOval(wheelRect));

    // 1. Dibujar los 26 gajos
    for (int i = 0; i < totalSlices; i++) {
      final double startAngle = i * anglePerSlice - (anglePerSlice / 2) - (pi / 2);
      final Color baseColor = palette[i % palette.length];

      final Paint slicePaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        wheelRect,
        startAngle,
        anglePerSlice,
        true,
        slicePaint,
      );

      // En el tema Clásico, añadir veta de madera radial y bisel en cada tablilla
      if (skin == 'classic') {
        _paintClassicWoodGrainOnSlice(
          canvas,
          center,
          sliceRadius,
          startAngle,
          anglePerSlice,
          i,
        );
      } else if (skin == 'dia_muertos') {
        _paintDiaMuertosSliceOrnaments(
          canvas,
          center,
          sliceRadius,
          startAngle,
          anglePerSlice,
          i,
        );
      }
    }

    // 2. Sombreado radial sobre los gajos (profundidad en centro y borde bajo el aro)
    if (skin == 'party') {
      final Paint radialShadePaint = Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x555A2605),
            Color(0x00000000),
            Color(0x18FFF8E1),
            Color(0x00000000),
            Color(0x45632B07),
          ],
          stops: const [0.0, 0.36, 0.68, 0.86, 1.0],
        ).createShader(wheelRect);
      canvas.drawCircle(center, sliceRadius, radialShadePaint);
    } else if (skin == 'classic') {
      final Paint woodRadialShade = Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x662B1204),
            Color(0x14000000),
            Color(0x14FFE0B2),
            Color(0x18000000),
            Color(0x60260F03),
          ],
          stops: const [0.0, 0.34, 0.65, 0.86, 1.0],
        ).createShader(wheelRect);
      canvas.drawCircle(center, sliceRadius, woodRadialShade);
    } else if (skin == 'dia_muertos') {
      final Paint fiestaRadialShade = Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x771E0636),
            Color(0x00000000),
            Color(0x22FFD54F),
            Color(0x15000000),
            Color(0x661A052E),
          ],
          stops: const [0.0, 0.35, 0.68, 0.86, 1.0],
        ).createShader(wheelRect);
      canvas.drawCircle(center, sliceRadius, fiestaRadialShade);
    }

    // 3. Dibujar líneas/ranuras separadoras entre los gajos
    for (int i = 0; i < totalSlices; i++) {
      final double boundaryAngle = i * anglePerSlice - (anglePerSlice / 2) - (pi / 2);
      final Offset outerEdge = Offset(
        center.dx + sliceRadius * cos(boundaryAngle),
        center.dy + sliceRadius * sin(boundaryAngle),
      );

      if (skin == 'classic') {
        // Bisel claro de luz junto a la ranura tallada
        final double highlightAngle = boundaryAngle + 0.009;
        canvas.drawLine(
          center,
          Offset(
            center.dx + sliceRadius * cos(highlightAngle),
            center.dy + sliceRadius * sin(highlightAngle),
          ),
          Paint()
            ..color = const Color(0x40F8DEC0)
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke,
        );

        // Ranura profunda tallada en madera
        canvas.drawLine(
          center,
          outerEdge,
          Paint()
            ..color = const Color(0xFF3B1A08)
            ..strokeWidth = 2.6
            ..style = PaintingStyle.stroke,
        );
      } else {
        canvas.drawLine(
          center,
          outerEdge,
          Paint()
            ..color = _getDividerColorForSkin(skin)
            ..strokeWidth = skin == 'party' ? 2.6 : 1.8
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // 4. Dibujar las 26 letras directamente en cada gajo
    final double letterRadius = hasCustomFrame ? sliceRadius * 0.775 : sliceRadius * 0.80;
    final double fontSize = hasCustomFrame ? radius * 0.125 : radius * 0.135;

    for (int i = 0; i < min(totalSlices, letters.length); i++) {
      final double sliceCenterAngle = i * anglePerSlice - (pi / 2);
      final Offset letterPos = Offset(
        center.dx + letterRadius * cos(sliceCenterAngle),
        center.dy + letterRadius * sin(sliceCenterAngle),
      );

      canvas.save();
      canvas.translate(letterPos.dx, letterPos.dy);
      // Rotamos +pi/2 para que la parte superior de la letra apunte hacia afuera del círculo
      canvas.rotate(sliceCenterAngle + pi / 2);

      final String char = letters[i];

      if (skin == 'party') {
        // Sombra cálida inferior
        final shadowPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: const Color(0x883E1904),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        shadowPainter.paint(
          canvas,
          Offset(-shadowPainter.width / 2, -shadowPainter.height / 2 + 2.0),
        );

        // Contorno grueso café oscuro estilo caricatura
        final strokePainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4.6
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..color = const Color(0xFF5C2808),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        strokePainter.paint(
          canvas,
          Offset(-strokePainter.width / 2, -strokePainter.height / 2),
        );

        // Relleno blanco brillante
        final fillPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: const Color(0xFFFFFDF7),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        fillPainter.paint(
          canvas,
          Offset(-fillPainter.width / 2, -fillPainter.height / 2),
        );
      } else if (skin == 'classic') {
        // Estilo pirograbado / tallado en bajorrelieve sobre madera
        final bool isIvorySlice = i == 0;
        final Color carvedFill = isIvorySlice
            ? const Color(0xFF7B4824)
            : const Color(0xFF47210C);

        // Bisel luminoso inferior-derecho del tallado
        final bevelLightPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: isIvorySlice
                  ? const Color(0xCCFFFFFF)
                  : const Color(0x88F4CBA0),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        bevelLightPainter.paint(
          canvas,
          Offset(-bevelLightPainter.width / 2 + 1.0, -bevelLightPainter.height / 2 + 1.2),
        );

        // Sombra profunda interior superior-izquierda del hueco tallado
        final innerShadowPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: const Color(0xAA210C02),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        innerShadowPainter.paint(
          canvas,
          Offset(-innerShadowPainter.width / 2 - 0.8, -innerShadowPainter.height / 2 - 0.8),
        );

        // Fondo de madera quemada tallada
        final carvedPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: carvedFill,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        carvedPainter.paint(
          canvas,
          Offset(-carvedPainter.width / 2, -carvedPainter.height / 2),
        );
      } else if (skin == 'dia_muertos') {
        // Sombra profunda mística del Mictlán
        final shadowPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: const Color(0xAA160428),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        shadowPainter.paint(
          canvas,
          Offset(-shadowPainter.width / 2, -shadowPainter.height / 2 + 2.2),
        );

        // Contorno grueso obsidiana/púrpura oscuro
        final strokePainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4.4
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..color = const Color(0xFF280645),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        strokePainter.paint(
          canvas,
          Offset(-strokePainter.width / 2, -strokePainter.height / 2),
        );

        // Relleno dorado marfil cálido de veladora
        final fillPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: const Color(0xFFFFF3C4),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        fillPainter.paint(
          canvas,
          Offset(-fillPainter.width / 2, -fillPainter.height / 2),
        );
      } else {
        final textPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4),
                Shadow(color: Colors.black87, blurRadius: 2, offset: Offset(1, 1)),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
      }

      canvas.restore();
    }

    canvas.restore();

    // Si no es party ni classic, dibujamos un borde estándar
    if (!hasCustomFrame) {
      final Paint borderPaint = Paint()
        ..color = _getDividerColorForSkin(skin)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0;
      canvas.drawCircle(center, sliceRadius, borderPaint);
    }
  }

  /// Dibuja vetas orgánicas de madera dentro de cada gajo para el tema Clásico
  void _paintClassicWoodGrainOnSlice(
    Canvas canvas,
    Offset center,
    double sliceRadius,
    double startAngle,
    double sweepAngle,
    int sliceIndex,
  ) {
    final Paint darkGrain = Paint()
      ..color = sliceIndex == 0
          ? const Color(0x188B5A2B)
          : const Color(0x223E1B08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Paint lightGrain = Paint()
      ..color = const Color(0x1AFBE4C6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int g = 1; g <= 3; g++) {
      final double frac = g / 4.0;
      final double angle = startAngle + sweepAngle * frac;
      final double waveOffset = ((sliceIndex * 7 + g * 3) % 5 - 2) * 0.008;

      final Path grainPath = Path()
        ..moveTo(
          center.dx + sliceRadius * 0.22 * cos(angle),
          center.dy + sliceRadius * 0.22 * sin(angle),
        )
        ..quadraticBezierTo(
          center.dx + sliceRadius * 0.58 * cos(angle + waveOffset),
          center.dy + sliceRadius * 0.58 * sin(angle + waveOffset),
          center.dx + sliceRadius * 0.96 * cos(angle),
          center.dy + sliceRadius * 0.96 * sin(angle),
        );

      canvas.drawPath(grainPath, g.isOdd ? darkGrain : lightGrain);
    }
  }

  /// Dibuja pétalos de cempasúchil y detalles de papel picado en cada gajo para Día de Muertos
  void _paintDiaMuertosSliceOrnaments(
    Canvas canvas,
    Offset center,
    double sliceRadius,
    double startAngle,
    double sweepAngle,
    int sliceIndex,
  ) {
    final double midAngle = startAngle + sweepAngle / 2;
    // Pequeño pétalo / destello decorativo hacia la zona media del gajo
    final Offset petalPos = Offset(
      center.dx + sliceRadius * 0.54 * cos(midAngle),
      center.dy + sliceRadius * 0.54 * sin(midAngle),
    );

    canvas.save();
    canvas.translate(petalPos.dx, petalPos.dy);
    canvas.rotate(midAngle + pi / 2);

    final Paint ornamentPaint = Paint()
      ..color = sliceIndex.isEven
          ? const Color(0x44FFD54F)
          : const Color(0x44FF80AB)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: sliceRadius * 0.045,
        height: sliceRadius * 0.095,
      ),
      ornamentPaint,
    );
    canvas.restore();
  }

  List<Color> _getPaletteForSkin(String skin) {
    if (skin == 'dia_muertos') {
      // Colores festivos de Ofrenda Mexicana: Naranja Cempasúchil, Morado Mictlán, Rosa Mexicano y Dorado Veladora
      const Color kCempasuchil = Color(0xFFF57C00);
      const Color kMictlanPurple = Color(0xFF6A1B9A);
      const Color kRosaMexicano = Color(0xFFC2185B);
      const Color kDoradoOfrenda = Color(0xFFE69A10);

      return const [
        kCempasuchil,   // A (destacado arriba en naranja cempasúchil como en la plantilla)
        kMictlanPurple, // B
        kDoradoOfrenda, // C
        kRosaMexicano,  // D
        kMictlanPurple, // E
        kCempasuchil,   // F
        kMictlanPurple, // G
        kRosaMexicano,  // H
        kCempasuchil,   // I
        kMictlanPurple, // J
        kDoradoOfrenda, // K
        kRosaMexicano,  // L
        kCempasuchil,   // M
        kMictlanPurple, // N
        kCempasuchil,   // O
        kRosaMexicano,  // P
        kMictlanPurple, // Q
        kDoradoOfrenda, // R
        kCempasuchil,   // S
        kMictlanPurple, // T
        kRosaMexicano,  // U
        kCempasuchil,   // V
        kMictlanPurple, // W
        kDoradoOfrenda, // X
        kRosaMexicano,  // Y
        kMictlanPurple, // Z
      ];
    } else if (skin == 'classic') {
      // Tonos de maderas nobles talladas (como en la imagen de referencia clásica)
      const Color kIvoryMaple = Color(0xFFF3ECE0); // Gajo A claro de referencia
      const Color kLightOak = Color(0xFFD9AE7E);
      const Color kGoldenTeak = Color(0xFFBF8756);
      const Color kWarmWalnut = Color(0xFFA5683C);
      const Color kDeepMahogany = Color(0xFF8C5129);

      return const [
        kIvoryMaple,   // A (destacado en marfil/arce claro como en la imagen)
        kLightOak,     // B
        kWarmWalnut,   // C
        kDeepMahogany, // D
        kWarmWalnut,   // E
        kGoldenTeak,   // F
        kWarmWalnut,   // G
        kLightOak,     // H
        kGoldenTeak,   // I
        kDeepMahogany, // J
        kWarmWalnut,   // K
        kGoldenTeak,   // L
        kDeepMahogany, // M
        kWarmWalnut,   // N
        kGoldenTeak,   // O
        kLightOak,     // P
        kWarmWalnut,   // Q
        kDeepMahogany, // R
        kWarmWalnut,   // S
        kLightOak,     // T
        kGoldenTeak,   // U
        kLightOak,     // V
        kWarmWalnut,   // W
        kDeepMahogany, // X
        kGoldenTeak,   // Y
        kWarmWalnut,   // Z
      ];
    } else {
      // Secuencia exacta de 26 colores cartoon para Party (sin vecinos repetidos)
      const Color kGreen = Color(0xFF43B653);
      const Color kYellow = Color(0xFFFFCE36);
      const Color kRed = Color(0xFFF25144);
      const Color kBlue = Color(0xFF4268D6);

      return const [
        kGreen,  // A (arriba al centro)
        kYellow, // B
        kRed,    // C
        kGreen,  // D
        kRed,    // E
        kYellow, // F
        kGreen,  // G
        kYellow, // H
        kRed,    // I
        kGreen,  // J
        kRed,    // K
        kYellow, // L
        kGreen,  // M
        kRed,    // N
        kGreen,  // O
        kYellow, // P
        kRed,    // Q
        kGreen,  // R
        kYellow, // S
        kRed,    // T
        kGreen,  // U
        kYellow, // V
        kRed,    // W
        kGreen,  // X
        kBlue,   // Y (toque azul clásico de la referencia)
        kRed,    // Z
      ];
    }
  }

  Color _getDividerColorForSkin(String skin) {
    if (skin == 'classic') {
      return const Color(0xFF3B1A08);
    } else if (skin == 'dia_muertos') {
      return const Color(0xFFFFCA28);
    } else {
      return const Color(0xFF6E340B);
    }
  }

  @override
  bool shouldRepaint(covariant RoulettePainter oldDelegate) {
    return oldDelegate.skin != skin;
  }
}

/// Marco exterior 3D estático:
/// - En Party: Aro dorado cartoon con brillos especulares y sombra interior.
/// - En Classic: Aro de madera torneada 3D con vetas concéntricas, bisel barnizado y sombra interior.
/// - En Día de Muertos: Aro de ofrenda dorado/bronce y obsidiana con flores de cempasúchil y remaches dorados.
class RouletteFramePainter extends CustomPainter {
  final String skin;

  RouletteFramePainter({required this.skin});

  @override
  void paint(Canvas canvas, Size size) {
    if (skin == 'party') {
      _paintPartyFrame(canvas, size);
    } else if (skin == 'classic') {
      _paintClassicWoodFrame(canvas, size);
    } else if (skin == 'dia_muertos') {
      _paintDiaMuertosFrame(canvas, size);
    }
  }

  void _paintPartyFrame(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    final double outerR = radius * 0.975;
    final double innerR = radius * 0.855;
    final double midR = (outerR + innerR) / 2;
    final double rimThickness = outerR - innerR;

    // 1. Sombra exterior proyectada por toda la ruleta
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.03),
      outerR,
      Paint()
        ..color = const Color(0x44000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 2. Sombra interior proyectada por el aro dorado sobre los gajos
    final Rect innerShadowRect = Rect.fromCircle(center: center, radius: innerR + 4);
    final Path innerShadowRing = Path()
      ..addOval(innerShadowRect)
      ..addOval(Rect.fromCircle(center: center, radius: innerR * 0.90))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      innerShadowRing,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x005A2404),
            Color(0x555A2404),
            Color(0x884A1B02),
          ],
          stops: const [0.82, 0.94, 1.0],
        ).createShader(innerShadowRect),
    );

    // 3. Base del aro dorado (anillo ámbar cálido)
    final Path rimPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerR))
      ..addOval(Rect.fromCircle(center: center, radius: innerR))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      rimPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFF6A821),
            Color(0xFFE58913),
            Color(0xFFD9790D),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: outerR)),
    );

    // 4. Bisel central elevado amarillo oro brillante
    canvas.drawCircle(
      center,
      midR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimThickness * 0.56
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFFE55B),
            Color(0xFFFFCA2C),
            Color(0xFFF7B21B),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: outerR)),
    );

    // 5. Reflejos especulares blancos/crema en curva (arriba y abajo como en la referencia)
    final Paint glossPaint = Paint()
      ..color = const Color(0xD8FFFDE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimThickness * 0.22
      ..strokeCap = StrokeCap.round;

    final Rect glossRect = Rect.fromCircle(center: center, radius: midR + rimThickness * 0.05);
    canvas.drawArc(glossRect, -pi * 0.72, pi * 0.16, false, glossPaint);
    canvas.drawArc(glossRect, -pi * 0.44, pi * 0.16, false, glossPaint);

    final Paint bottomGlossPaint = Paint()
      ..color = const Color(0x99FFF9C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimThickness * 0.18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(glossRect, pi * 0.36, pi * 0.10, false, bottomGlossPaint);
    canvas.drawArc(glossRect, pi * 0.54, pi * 0.10, false, bottomGlossPaint);

    canvas.drawCircle(
      Offset(center.dx, center.dy + midR),
      rimThickness * 0.15,
      Paint()..color = const Color(0xEEFFFDE7),
    );

    // 6. Contornos cartoon café oscuro (exterior e interior del aro)
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = const Color(0xFF632C07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2,
    );

    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..color = const Color(0xFF632C07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6,
    );
  }

  void _paintClassicWoodFrame(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    final double outerR = radius * 0.978;
    final double innerR = radius * 0.852;
    final double midR = (outerR + innerR) / 2;
    final double rimThickness = outerR - innerR;

    // 1. Sombra exterior profunda proyectada por el plato de madera
    canvas.drawCircle(
      Offset(center.dx + 3, center.dy + radius * 0.045),
      outerR,
      Paint()
        ..color = const Color(0x661A0902)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // 2. Sombra interior proyectada por el reborde de madera sobre los gajos
    final Rect innerShadowRect = Rect.fromCircle(center: center, radius: innerR + 4);
    final Path innerShadowRing = Path()
      ..addOval(innerShadowRect)
      ..addOval(Rect.fromCircle(center: center, radius: innerR * 0.89))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      innerShadowRing,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x002B1103),
            Color(0x662B1103),
            Color(0xAA1F0B02),
          ],
          stops: const [0.80, 0.93, 1.0],
        ).createShader(innerShadowRect),
    );

    // 3. Base del aro de madera torneada (caoba / nogal cálido)
    final Path rimPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerR))
      ..addOval(Rect.fromCircle(center: center, radius: innerR))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      rimPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.6, -0.8),
          end: Alignment(0.6, 0.8),
          colors: [
            Color(0xFFC48857),
            Color(0xFFA5673B),
            Color(0xFF7B4421),
          ],
          stops: [0.0, 0.52, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: outerR)),
    );

    // 4. Lomo torneado central de la moldura de madera (efecto cilindro curvado)
    canvas.drawCircle(
      center,
      midR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimThickness * 0.58
        ..shader = const LinearGradient(
          begin: Alignment(-0.5, -0.85),
          end: Alignment(0.5, 0.85),
          colors: [
            Color(0xFFD89E6B),
            Color(0xFFB57748),
            Color(0xFF8C5129),
          ],
          stops: [0.0, 0.48, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: outerR)),
    );

    // 5. Vetas concéntricas finas de madera torneada
    final Paint woodRingDark = Paint()
      ..color = const Color(0x333B1906)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawCircle(center, innerR + rimThickness * 0.25, woodRingDark);
    canvas.drawCircle(center, innerR + rimThickness * 0.76, woodRingDark);

    // 6. Brillo satinado de barniz de madera en el arco superior-izquierdo e inferior
    final Paint satinHighlight = Paint()
      ..color = const Color(0x66F5D2AC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimThickness * 0.20
      ..strokeCap = StrokeCap.round;

    final Rect highlightRect = Rect.fromCircle(center: center, radius: midR + rimThickness * 0.04);
    canvas.drawArc(highlightRect, -pi * 0.88, pi * 0.65, false, satinHighlight);

    final Paint bottomSatin = Paint()
      ..color = const Color(0x33E6B88A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimThickness * 0.14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(highlightRect, pi * 0.18, pi * 0.55, false, bottomSatin);

    // 7. Biseles oscuros exterior e interior (ranura de ensamblaje del marco)
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = const Color(0xFF4A220B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..color = const Color(0xFF3A1907)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8,
    );
  }

  void _paintDiaMuertosFrame(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    final double outerR = radius * 0.985;
    final double innerR = radius * 0.845;
    final double midR = (outerR + innerR) / 2;
    final double rimThickness = outerR - innerR;

    // 1. Resplandor dorado místico cálido detrás de la corona de cempasúchil
    canvas.drawCircle(
      center,
      outerR * 1.02,
      Paint()
        ..color = const Color(0x66FF8F00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.035),
      outerR,
      Paint()
        ..color = const Color(0x88150428)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // 2. Sombra interior proyectada por la corona floral sobre los gajos
    final Rect innerShadowRect = Rect.fromCircle(center: center, radius: innerR + 4);
    final Path innerShadowRing = Path()
      ..addOval(innerShadowRect)
      ..addOval(Rect.fromCircle(center: center, radius: innerR * 0.88))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      innerShadowRing,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x001D0536),
            Color(0x881D0536),
            Color(0xCC120224),
          ],
          stops: const [0.78, 0.92, 1.0],
        ).createShader(innerShadowRect),
    );

    // 3. Base del aro (cinta de ofrenda oscura de fondo)
    final Path rimPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerR))
      ..addOval(Rect.fromCircle(center: center, radius: innerR))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      rimPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8B3A05),
            Color(0xFF5D1D02),
            Color(0xFF380E00),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: outerR)),
    );

    // 4. Guirnalda continua de flores de cempasúchil alrededor de toda la circunferencia
    const int flowerCount = 30; // Densidad para formar una corona continua
    final double flowerRadius = rimThickness * 0.58;

    for (int i = 0; i < flowerCount; i++) {
      final double angle = (i * 2 * pi / flowerCount) - (pi / 2);
      final Offset pos = Offset(
        center.dx + midR * cos(angle),
        center.dy + midR * sin(angle),
      );

      // Sombra individual suave de la flor
      canvas.drawCircle(
        Offset(pos.dx, pos.dy + 1.5),
        flowerRadius * 0.95,
        Paint()
          ..color = const Color(0x553E1202)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Capa 1 (Exterior): Pétalos naranja profundo / rojizo
      const int outerPetals = 8;
      for (int p = 0; p < outerPetals; p++) {
        final double pAngle = angle + (p * 2 * pi / outerPetals);
        final Offset pCenter = Offset(
          pos.dx + flowerRadius * 0.42 * cos(pAngle),
          pos.dy + flowerRadius * 0.42 * sin(pAngle),
        );
        canvas.drawCircle(
          pCenter,
          flowerRadius * 0.44,
          Paint()..color = const Color(0xFFE65100),
        );
      }

      // Capa 2 (Media): Pétalos naranja cempasúchil brillante
      const int midPetals = 7;
      for (int p = 0; p < midPetals; p++) {
        final double pAngle = angle + (p * 2 * pi / midPetals) + 0.3;
        final Offset pCenter = Offset(
          pos.dx + flowerRadius * 0.26 * cos(pAngle),
          pos.dy + flowerRadius * 0.26 * sin(pAngle),
        );
        canvas.drawCircle(
          pCenter,
          flowerRadius * 0.36,
          Paint()..color = const Color(0xFFFF9800),
        );
      }

      // Capa 3 (Interior): Botón central amarillo dorado vivo
      canvas.drawCircle(
        pos,
        flowerRadius * 0.30,
        Paint()..color = const Color(0xFFFFD54F),
      );

      // Centro texturizado con micro-destello
      canvas.drawCircle(
        pos,
        flowerRadius * 0.15,
        Paint()..color = const Color(0xFFFFF176),
      );
    }

    // 5. Contorno interior sutil dorado que delimita perfectamente el plato con las letras
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..color = const Color(0xDDFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant RouletteFramePainter oldDelegate) {
    return oldDelegate.skin != skin;
  }
}

/// Puntero superior 3D según el tema:
/// - Party: Púa roja redondeada estilo caricatura con triángulo interior salmón.
/// - Classic: Cuña triangular de madera tallada 3D con bisel y veta vertical.
/// - Día de Muertos: Puntero joya dorado y rosa mexicano de ofrenda.
class RoulettePointerWidget extends StatelessWidget {
  final String skin;

  const RoulettePointerWidget({Key? key, required this.skin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (skin == 'party') {
      return const SizedBox(
        width: 52,
        height: 58,
        child: CustomPaint(
          painter: _PartyPointerPainter(),
        ),
      );
    } else if (skin == 'classic') {
      return const SizedBox(
        width: 50,
        height: 60,
        child: CustomPaint(
          painter: _ClassicWoodPointerPainter(),
        ),
      );
    } else if (skin == 'dia_muertos') {
      return const SizedBox(
        width: 54,
        height: 62,
        child: CustomPaint(
          painter: _DiaMuertosPointerPainter(),
        ),
      );
    }

    return const Icon(
      Icons.location_on,
      size: 50,
      color: Colors.redAccent,
      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
    );
  }
}

class _PartyPointerPainter extends CustomPainter {
  const _PartyPointerPainter();

  Path _buildPickPath(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    return Path()
      ..moveTo(cx, h * 0.06)
      ..cubicTo(w * 0.82, h * 0.06, w * 0.92, h * 0.16, w * 0.86, h * 0.36)
      ..cubicTo(w * 0.78, h * 0.62, cx + w * 0.12, h * 0.92, cx, h * 0.92)
      ..cubicTo(cx - w * 0.12, h * 0.92, w * 0.22, h * 0.62, w * 0.14, h * 0.36)
      ..cubicTo(w * 0.08, h * 0.16, w * 0.18, h * 0.06, cx, h * 0.06)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path pickPath = _buildPickPath(size);

    // 1. Sombra proyectada sobre el aro y el gajo superior
    canvas.save();
    canvas.translate(0, 3.0);
    canvas.drawPath(
      pickPath,
      Paint()
        ..color = const Color(0x663A1205)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();

    // 2. Relleno rojo coral con degradado 3D
    canvas.drawPath(
      pickPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF6659),
            Color(0xFFF1493C),
            Color(0xFFD63225),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // 3. Bisel luminoso interno cerca del borde superior
    canvas.save();
    canvas.clipPath(pickPath);
    canvas.drawPath(
      pickPath,
      Paint()
        ..color = const Color(0x55FF9E94)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0,
    );
    canvas.restore();

    // 4. Triángulo interior redondeado color salmón/rosado
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final Path innerTriangle = Path()
      ..moveTo(cx, h * 0.23)
      ..quadraticBezierTo(w * 0.68, h * 0.23, w * 0.64, h * 0.36)
      ..quadraticBezierTo(cx + w * 0.05, h * 0.60, cx, h * 0.62)
      ..quadraticBezierTo(cx - w * 0.05, h * 0.60, w * 0.36, h * 0.36)
      ..quadraticBezierTo(w * 0.32, h * 0.23, cx, h * 0.23)
      ..close();

    canvas.drawPath(
      innerTriangle,
      Paint()
        ..color = const Color(0xFFFF9887)
        ..style = PaintingStyle.fill,
    );

    // 5. Contorno grueso café rojizo oscuro estilo caricatura
    canvas.drawPath(
      pickPath,
      Paint()
        ..color = const Color(0xFF5A180C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClassicWoodPointerPainter extends CustomPainter {
  const _ClassicWoodPointerPainter();

  Path _buildWedgePath(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    return Path()
      ..moveTo(cx, h * 0.05)
      ..quadraticBezierTo(w * 0.84, h * 0.05, w * 0.88, h * 0.15)
      ..quadraticBezierTo(w * 0.68, h * 0.56, cx + w * 0.04, h * 0.90)
      ..quadraticBezierTo(cx, h * 0.95, cx - w * 0.04, h * 0.90)
      ..quadraticBezierTo(w * 0.32, h * 0.56, w * 0.12, h * 0.15)
      ..quadraticBezierTo(w * 0.16, h * 0.05, cx, h * 0.05)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path wedgePath = _buildWedgePath(size);

    // 1. Sombra lateral y hacia abajo (como en la imagen de referencia clásica)
    canvas.save();
    canvas.translate(4.0, 4.5);
    canvas.drawPath(
      wedgePath,
      Paint()
        ..color = const Color(0x881A0902)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();

    // 2. Canto lateral 3D de madera (espesor de la pieza tallada)
    canvas.save();
    canvas.translate(1.8, 2.2);
    canvas.drawPath(
      wedgePath,
      Paint()
        ..color = const Color(0xFF592D12)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    // 3. Cara principal de madera tallada
    canvas.drawPath(
      wedgePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD69C6A),
            Color(0xFFB67949),
            Color(0xFF93582E),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // 4. Vetas suaves y bisel iluminado dentro de la cuña
    canvas.save();
    canvas.clipPath(wedgePath);
    final double w = size.width;
    final double h = size.height;
    final Paint grainPaint = Paint()
      ..color = const Color(0x26421D08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.42, 0), Offset(w * 0.47, h), grainPaint);
    canvas.drawLine(Offset(w * 0.56, 0), Offset(w * 0.52, h), grainPaint);

    // Luz en el borde superior e izquierdo
    canvas.drawPath(
      wedgePath,
      Paint()
        ..color = const Color(0x66F5D2AC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    canvas.restore();

    // 5. Contorno fino de madera bruñida
    canvas.drawPath(
      wedgePath,
      Paint()
        ..color = const Color(0xFF4A220B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaMuertosPointerPainter extends CustomPainter {
  const _DiaMuertosPointerPainter();

  Path _buildPointerPath(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    return Path()
      ..moveTo(cx, h * 0.05)
      ..quadraticBezierTo(w * 0.86, h * 0.05, w * 0.88, h * 0.18)
      ..cubicTo(w * 0.72, h * 0.50, cx + w * 0.16, h * 0.82, cx, h * 0.94)
      ..cubicTo(cx - w * 0.16, h * 0.82, w * 0.28, h * 0.50, w * 0.12, h * 0.18)
      ..quadraticBezierTo(w * 0.14, h * 0.05, cx, h * 0.05)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path pointerPath = _buildPointerPath(size);

    // 1. Sombra mística proyectada
    canvas.save();
    canvas.translate(0, 3.5);
    canvas.drawPath(
      pointerPath,
      Paint()
        ..color = const Color(0x882A0845)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();

    // 2. Relleno con degradado naranja cempasúchil a dorado veladora y rosa mexicano
    canvas.drawPath(
      pointerPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFB300), // Dorado
            Color(0xFFFF6F00), // Cempasúchil
            Color(0xFFC2185B), // Rosa mexicano
          ],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Offset.zero & size),
    );

    // 3. Bisel dorado iluminado
    canvas.save();
    canvas.clipPath(pointerPath);
    canvas.drawPath(
      pointerPath,
      Paint()
        ..color = const Color(0x88FFF8E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    canvas.restore();

    // 4. Borde fino obsidiana / morado místico
    canvas.drawPath(
      pointerPath,
      Paint()
        ..color = const Color(0xFF310747)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );

    // 5. Gema central de amatista en el cabezal del puntero
    final double cx = size.width / 2;
    final double cy = size.height * 0.28;
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.14,
      Paint()..color = const Color(0xFF1E0636),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.11,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFFFFD54F),
            Color(0xFFE91E63),
            Color(0xFF6A1B9A),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.11)),
    );
    // Brillo blanco en la gema
    canvas.drawCircle(
      Offset(cx - 2, cy - 2),
      size.width * 0.03,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mano central de madera tallada 3D apuntando hacia arriba para el tema Clásico.
class ClassicWoodHandWidget extends StatelessWidget {
  final double size;

  const ClassicWoodHandWidget({Key? key, this.size = 148}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.18,
      child: CustomPaint(
        painter: _ClassicWoodHandPainter(),
      ),
    );
  }
}

class _ClassicWoodHandPainter extends CustomPainter {
  /// Construye la silueta esculpida de la mano de madera con el dedo índice apuntando a las 12 en punto
  Path _buildHandPath(Size size) {
    final double w = size.width;
    final double h = size.height;

    final Path path = Path();

    // Iniciar en la punta redondeada del dedo índice (arriba)
    path.moveTo(w * 0.39, h * 0.14);
    path.cubicTo(w * 0.39, h * 0.04, w * 0.52, h * 0.04, w * 0.52, h * 0.14);

    // Bajar por el lado derecho del índice hasta el pliegue del dedo medio
    path.lineTo(w * 0.52, h * 0.40);

    // Dedo medio (curvado arriba)
    path.cubicTo(w * 0.52, h * 0.34, w * 0.63, h * 0.34, w * 0.63, h * 0.42);
    path.lineTo(w * 0.63, h * 0.45);

    // Dedo anular (escalonado ligeramente más abajo)
    path.cubicTo(w * 0.63, h * 0.38, w * 0.74, h * 0.38, w * 0.74, h * 0.46);
    path.lineTo(w * 0.74, h * 0.50);

    // Dedo meñique (escalonado a la derecha)
    path.cubicTo(w * 0.74, h * 0.43, w * 0.84, h * 0.44, w * 0.84, h * 0.53);

    // Bajar por el costado derecho de la palma hacia la base redondeada de la muñeca
    path.lineTo(w * 0.84, h * 0.68);
    path.cubicTo(w * 0.84, h * 0.88, w * 0.68, h * 0.95, w * 0.53, h * 0.95);

    // Base inferior hacia el lado izquierdo (pulgar)
    path.cubicTo(w * 0.38, h * 0.95, w * 0.28, h * 0.84, w * 0.22, h * 0.68);

    // Subir hacia la punta del pulgar extendido a la izquierda
    path.lineTo(w * 0.15, h * 0.56);
    path.cubicTo(w * 0.09, h * 0.47, w * 0.17, h * 0.40, w * 0.25, h * 0.45);

    // Entrar del pulgar a la base izquierda del dedo índice
    path.quadraticBezierTo(w * 0.34, h * 0.50, w * 0.39, h * 0.47);

    // Subir recto por el lado izquierdo del dedo índice hasta la punta
    path.lineTo(w * 0.39, h * 0.14);
    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path handPath = _buildHandPath(size);

    // 1. Sombra exterior profunda proyectada sobre el centro de la ruleta
    canvas.save();
    canvas.translate(w * 0.045, h * 0.045);
    canvas.drawPath(
      handPath,
      Paint()
        ..color = const Color(0x881A0802)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.restore();

    // 2. Extrusión 3D del bloque de madera (canto inferior/derecho tallado)
    for (int step = 5; step >= 1; step--) {
      canvas.save();
      canvas.translate(step * 0.9, step * 1.3);
      canvas.drawPath(
        handPath,
        Paint()
          ..color = step > 3 ? const Color(0xFF5A2E13) : const Color(0xFF75401E)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }

    // 3. Superficie principal de madera tallada (degradado cálido de haya/roble)
    canvas.drawPath(
      handPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.55, -0.85),
          end: Alignment(0.65, 0.85),
          colors: [
            Color(0xFFDFAC79),
            Color(0xFFC58A58),
            Color(0xFFA66A3C),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // 4. Vetas curvas de madera tallada y biseles internos (recortados a la silueta)
    canvas.save();
    canvas.clipPath(handPath);

    // Vetas orgánicas verticales a lo largo de la mano y el dedo índice
    final Paint woodGrainDark = Paint()
      ..color = const Color(0x244A2008)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final Paint woodGrainLight = Paint()
      ..color = const Color(0x22F9DEC0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 7; i++) {
      final double xBase = w * (0.24 + i * 0.085);
      final Path grain = Path()
        ..moveTo(xBase, h * 0.05)
        ..cubicTo(
          xBase + w * 0.03,
          h * 0.35,
          xBase - w * 0.03,
          h * 0.68,
          xBase + w * 0.02,
          h * 0.96,
        );
      canvas.drawPath(grain, i.isEven ? woodGrainDark : woodGrainLight);
    }

    // Sombra suave interna en el borde derecho/inferior para dar volumen redondeado
    canvas.drawPath(
      handPath,
      Paint()
        ..color = const Color(0x4452250B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Luz cálida en el bisel izquierdo/superior del pulgar, índice y nudillos
    canvas.drawPath(
      handPath,
      Paint()
        ..color = const Color(0x77F7D8B5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );

    // Hendiduras talladas entre los dedos (índice-medio, medio-anular, anular-meñique)
    final Paint fingerGroove = Paint()
      ..color = const Color(0xFF5E3014)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final Paint fingerGrooveHighlight = Paint()
      ..color = const Color(0x66F2CBA0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Ranura entre índice y medio
    canvas.drawLine(Offset(w * 0.52, h * 0.40), Offset(w * 0.52, h * 0.56), fingerGroove);
    canvas.drawLine(Offset(w * 0.532, h * 0.41), Offset(w * 0.532, h * 0.55), fingerGrooveHighlight);

    // Ranura entre medio y anular
    canvas.drawLine(Offset(w * 0.63, h * 0.44), Offset(w * 0.63, h * 0.58), fingerGroove);
    canvas.drawLine(Offset(w * 0.642, h * 0.45), Offset(w * 0.642, h * 0.57), fingerGrooveHighlight);

    // Ranura entre anular y meñique
    canvas.drawLine(Offset(w * 0.74, h * 0.48), Offset(w * 0.74, h * 0.60), fingerGroove);
    canvas.drawLine(Offset(w * 0.752, h * 0.49), Offset(w * 0.752, h * 0.59), fingerGrooveHighlight);

    canvas.restore();

    // 5. Contorno exterior fino de madera tallada
    canvas.drawPath(
      handPath,
      Paint()
        ..color = const Color(0xFF4E250D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Medallón central de Catrina que gira en sentido contrario a la ruleta
class DiaMuertosCatrinaCenterWidget extends StatelessWidget {
  final double size;

  const DiaMuertosCatrinaCenterWidget({Key? key, this.size = 100}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0xBB19062A),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x77FF6F00),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFB300),
          width: 3.0,
        ),
      ),
      child: ClipOval(
        child: Image(
          image: SkinManager.getCatrinaCenterProvider(),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
