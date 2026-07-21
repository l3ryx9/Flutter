import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Peint le ciel avec dégradé, soleil, rayons et nuages légers
class SkyPainter extends CustomPainter {
  final double animValue; // 0..1 animation principale
  final double shimmerValue; // 0..1 scintillement

  SkyPainter({required this.animValue, required this.shimmerValue});

  @override
  void paint(Canvas canvas, Size size) {
    _drawSkyGradient(canvas, size);
    _drawSunRays(canvas, size);
    _drawSun(canvas, size);
    _drawClouds(canvas, size);
  }

  void _drawSkyGradient(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.65);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0A1628),
        const Color(0xFF0D47A1),
        const Color(0xFF1976D2),
        const Color(0xFF42A5F5),
        const Color(0xFF80DEEA),
        const Color(0xFFB2EBF2),
      ],
      stops: const [0.0, 0.15, 0.3, 0.55, 0.78, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Halo atmosphérique
    final haloPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.15, -0.7),
        radius: 0.6,
        colors: [
          Colors.white.withOpacity(0.18 + shimmerValue * 0.07),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, haloPaint);
  }

  void _drawSun(Canvas canvas, Size size) {
    final cx = size.width * 0.78;
    final cy = size.height * 0.08;

    // Glow externe
    for (int i = 4; i >= 0; i--) {
      final radius = 28.0 + i * 14.0;
      final opacity = (0.06 - i * 0.01) * (1 + shimmerValue * 0.3);
      final glowPaint = Paint()
        ..color = const Color(0xFFFFE082).withOpacity(opacity.clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6);
      canvas.drawCircle(Offset(cx, cy), radius, glowPaint);
    }

    // Corps du soleil – dégradé radial
    final sunRect = Rect.fromCircle(center: Offset(cx, cy), radius: 30);
    final sunGrad = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      colors: [
        Colors.white,
        const Color(0xFFFFF9C4),
        const Color(0xFFFFEB3B),
        const Color(0xFFFFA726),
      ],
      stops: const [0.0, 0.3, 0.65, 1.0],
    );
    final sunPaint = Paint()..shader = sunGrad.createShader(sunRect);
    canvas.drawCircle(Offset(cx, cy), 30, sunPaint);

    // Reflet brillant
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(cx - 9, cy - 9), 10, highlightPaint);
  }

  void _drawSunRays(Canvas canvas, Size size) {
    final cx = size.width * 0.78;
    final cy = size.height * 0.08;
    final rayPaint = Paint()
      ..color = const Color(0xFFFFE082).withOpacity(0.10 + shimmerValue * 0.05)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2 + animValue * 0.3;
      final r1 = 38.0;
      final r2 = 90.0 + (i % 3) * 20.0;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * r1, cy + math.sin(angle) * r1),
        Offset(cx + math.cos(angle) * r2, cy + math.sin(angle) * r2),
        rayPaint,
      );
    }

    // Rayons étendus vers la plage (conic light shafts)
    final shaftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFE082).withOpacity(0.04 + shimmerValue * 0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.65))
      ..blendMode = BlendMode.screen;

    for (int i = 0; i < 6; i++) {
      final angle = -math.pi / 4 + (i * math.pi / 10) + animValue * 0.05;
      final path = Path();
      path.moveTo(cx, cy);
      path.lineTo(
        cx + math.cos(angle - 0.04) * size.height,
        cy + math.sin(angle - 0.04) * size.height,
      );
      path.lineTo(
        cx + math.cos(angle + 0.04) * size.height,
        cy + math.sin(angle + 0.04) * size.height,
      );
      path.close();
      canvas.drawPath(path, shaftPaint);
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    final clouds = [
      _CloudData(offset: Offset(size.width * 0.05, size.height * 0.12), scale: 0.9, speed: 0.6),
      _CloudData(offset: Offset(size.width * 0.35, size.height * 0.07), scale: 0.65, speed: 0.45),
      _CloudData(offset: Offset(size.width * 0.55, size.height * 0.15), scale: 0.75, speed: 0.55),
    ];

    for (final cloud in clouds) {
      final dx = math.sin(animValue * cloud.speed * math.pi * 2) * 6.0;
      _drawCloud(canvas, cloud.offset.translate(dx, 0), cloud.scale);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.72)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final bubbles = [
      Offset(-28 * scale, 8 * scale),
      Offset(-14 * scale, 0),
      Offset(0, -4 * scale),
      Offset(14 * scale, 2 * scale),
      Offset(26 * scale, 8 * scale),
      Offset(-10 * scale, 12 * scale),
      Offset(10 * scale, 12 * scale),
    ];
    final radii = [16.0, 20.0, 24.0, 20.0, 16.0, 14.0, 14.0];

    for (int i = 0; i < bubbles.length; i++) {
      canvas.drawCircle(center + bubbles[i], radii[i] * scale, cloudPaint);
    }
    // Reflet en haut
    canvas.drawCircle(center + Offset(-4 * scale, -6 * scale), 8 * scale, highlightPaint);
  }

  @override
  bool shouldRepaint(SkyPainter old) =>
      old.animValue != animValue || old.shimmerValue != shimmerValue;
}

class _CloudData {
  final Offset offset;
  final double scale;
  final double speed;
  _CloudData({required this.offset, required this.scale, required this.speed});
}
