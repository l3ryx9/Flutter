import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Peint la plage de sable blanc avec rochers arrondis
class BeachPainter extends CustomPainter {
  final double animValue;

  BeachPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    _drawSand(canvas, size);
    _drawSandDetails(canvas, size);
    _drawRocks(canvas, size);
    _drawWaterEdge(canvas, size);
  }

  void _drawSand(Canvas canvas, Size size) {
    // Plage principale
    final sandPath = Path();
    sandPath.moveTo(0, size.height * 0.55);

    for (double x = 0; x <= size.width; x += 4) {
      final y = size.height * 0.55 +
          math.sin(x / size.width * math.pi * 3) * 6 +
          math.cos(x / size.width * math.pi * 5) * 3;
      sandPath.lineTo(x, y);
    }
    sandPath.lineTo(size.width, size.height);
    sandPath.lineTo(0, size.height);
    sandPath.close();

    final sandRect = Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5);
    final sandGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFFF8E1),
        const Color(0xFFFFECB3),
        const Color(0xFFFFE082),
        const Color(0xFFFFD54F),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    final sandPaint = Paint()..shader = sandGrad.createShader(sandRect);
    canvas.drawPath(sandPath, sandPaint);

    // Ombre portée sur le bord de l'eau
    final shadowPath = Path();
    shadowPath.moveTo(0, size.height * 0.53);
    for (double x = 0; x <= size.width; x += 4) {
      final y = size.height * 0.54 + math.sin(x / size.width * math.pi * 3) * 4;
      shadowPath.lineTo(x, y);
    }
    shadowPath.lineTo(size.width, size.height * 0.58);
    shadowPath.lineTo(0, size.height * 0.58);
    shadowPath.close();

    final shadowPaint = Paint()
      ..color = const Color(0xFFFFB300).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(shadowPath, shadowPaint);
  }

  void _drawSandDetails(Canvas canvas, Size size) {
    final rng = math.Random(7);
    // Petits grains et ondulations
    final detailPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final x = rng.nextDouble() * size.width;
      final y = size.height * 0.6 + rng.nextDouble() * size.height * 0.2;
      final w = 20.0 + rng.nextDouble() * 40;
      final path = Path();
      path.moveTo(x, y);
      path.quadraticBezierTo(x + w / 2, y - 4, x + w, y);
      canvas.drawPath(path, detailPaint);
    }
  }

  void _drawRocks(Canvas canvas, Size size) {
    final rocks = [
      _RockData(center: Offset(size.width * 0.12, size.height * 0.72), rx: 32, ry: 22),
      _RockData(center: Offset(size.width * 0.88, size.height * 0.68), rx: 28, ry: 18),
      _RockData(center: Offset(size.width * 0.80, size.height * 0.75), rx: 18, ry: 13),
      _RockData(center: Offset(size.width * 0.05, size.height * 0.80), rx: 16, ry: 11),
    ];

    for (final r in rocks) {
      _drawRock(canvas, r);
    }
  }

  void _drawRock(Canvas canvas, _RockData r) {
    final rect = Rect.fromCenter(center: r.center, width: r.rx * 2, height: r.ry * 2);

    // Corps du rocher avec gradient 3D
    final grad = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      colors: [
        const Color(0xFFB0BEC5),
        const Color(0xFF78909C),
        const Color(0xFF546E7A),
        const Color(0xFF37474F),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
    final bodyPaint = Paint()..shader = grad.createShader(rect);

    final path = Path();
    path.addOval(rect);
    canvas.drawPath(path, bodyPaint);

    // Ombre sous le rocher
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: r.center.translate(0, r.ry * 0.6),
        width: r.rx * 1.8,
        height: r.ry * 0.5,
      ),
      shadowPaint,
    );

    // Reflet lumineux
    final hlPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: r.center.translate(-r.rx * 0.25, -r.ry * 0.3),
        width: r.rx * 0.6,
        height: r.ry * 0.35,
      ),
      hlPaint,
    );
  }

  void _drawWaterEdge(Canvas canvas, Size size) {
    // Zone humide au bord de l'eau
    final wetPath = Path();
    final baseY = size.height * 0.555;
    wetPath.moveTo(0, baseY);
    for (double x = 0; x <= size.width; x += 3) {
      final y = baseY +
          math.sin((x / size.width) * math.pi * 4 + animValue * math.pi * 2) * 5;
      wetPath.lineTo(x, y);
    }
    wetPath.lineTo(size.width, baseY + 12);
    wetPath.lineTo(0, baseY + 12);
    wetPath.close();

    final wetPaint = Paint()
      ..color = const Color(0xFF90E0EF).withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(wetPath, wetPaint);
  }

  @override
  bool shouldRepaint(BeachPainter old) => old.animValue != animValue;
}

class _RockData {
  final Offset center;
  final double rx;
  final double ry;
  _RockData({required this.center, required this.rx, required this.ry});
}
