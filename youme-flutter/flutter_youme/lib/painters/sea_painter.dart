import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Peint la mer turquoise avec vagues animées et reflets
class SeaPainter extends CustomPainter {
  final double waveAnim; // 0..1
  final double shimmerValue;

  SeaPainter({required this.waveAnim, required this.shimmerValue});

  @override
  void paint(Canvas canvas, Size size) {
    _drawDeepWater(canvas, size);
    _drawWaveLayers(canvas, size);
    _drawFoam(canvas, size);
    _drawSeaReflections(canvas, size);
  }

  void _drawDeepWater(Canvas canvas, Size size) {
    final seaTop = size.height * 0.42;
    final rect = Rect.fromLTRB(0, seaTop, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF48CAE4),
        const Color(0xFF0096C7),
        const Color(0xFF0077B6),
        const Color(0xFF023E8A),
      ],
      stops: const [0.0, 0.3, 0.65, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawWaveLayers(Canvas canvas, Size size) {
    // Couche 1 – vague de fond (lente)
    _drawWaveLayer(
      canvas,
      size,
      baseY: size.height * 0.44,
      amplitude: 10,
      frequency: 1.8,
      phase: waveAnim * math.pi * 2,
      colors: [
        const Color(0xFF90E0EF).withOpacity(0.55),
        const Color(0xFF48CAE4).withOpacity(0.3),
        Colors.transparent,
      ],
      heightFraction: 0.25,
    );

    // Couche 2 – vague principale
    _drawWaveLayer(
      canvas,
      size,
      baseY: size.height * 0.45,
      amplitude: 14,
      frequency: 2.2,
      phase: waveAnim * math.pi * 2 + math.pi * 0.7,
      colors: [
        const Color(0xFFADE8F4).withOpacity(0.65),
        const Color(0xFF48CAE4).withOpacity(0.4),
        Colors.transparent,
      ],
      heightFraction: 0.22,
    );

    // Couche 3 – vague avant-plan
    _drawWaveLayer(
      canvas,
      size,
      baseY: size.height * 0.47,
      amplitude: 8,
      frequency: 2.8,
      phase: waveAnim * math.pi * 2 + math.pi * 1.4,
      colors: [
        Colors.white.withOpacity(0.4),
        const Color(0xFFCAF0F8).withOpacity(0.25),
        Colors.transparent,
      ],
      heightFraction: 0.15,
    );
  }

  void _drawWaveLayer(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double amplitude,
    required double frequency,
    required double phase,
    required List<Color> colors,
    required double heightFraction,
  }) {
    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 2) {
      final y = baseY +
          math.sin((x / size.width) * math.pi * frequency + phase) * amplitude +
          math.sin((x / size.width) * math.pi * frequency * 1.7 + phase * 1.3) *
              amplitude *
              0.4;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final rect = Rect.fromLTWH(0, baseY - amplitude, size.width, size.height * heightFraction);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawPath(path, paint);
  }

  void _drawFoam(Canvas canvas, Size size) {
    final foamPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final rng = math.Random(42);
    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble() * size.width;
      final phase = waveAnim * math.pi * 2 + i * 0.8;
      final baseY = size.height * 0.455;
      final y = baseY + math.sin(phase) * 8 + rng.nextDouble() * 6;
      final r = 3.0 + rng.nextDouble() * 5;
      canvas.drawCircle(Offset(x, y), r, foamPaint);
    }
  }

  void _drawSeaReflections(Canvas canvas, Size size) {
    final refPaint = Paint()
      ..color = Colors.white.withOpacity(0.12 + shimmerValue * 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final rng = math.Random(99);
    for (int i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final y = size.height * 0.48 + rng.nextDouble() * size.height * 0.15;
      final w = 15.0 + rng.nextDouble() * 35;
      final phase = waveAnim * math.pi * 2 + i;
      canvas.drawLine(
        Offset(x + math.cos(phase) * 4, y),
        Offset(x + w + math.cos(phase + 0.5) * 4, y),
        refPaint,
      );
    }
  }

  @override
  bool shouldRepaint(SeaPainter old) =>
      old.waveAnim != waveAnim || old.shimmerValue != shimmerValue;
}
