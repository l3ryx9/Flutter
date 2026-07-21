import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Peint les bulles transparentes, particules lumineuses et effets atmosphériques
class AtmospherePainter extends CustomPainter {
  final double bubbleAnim;   // 0..1
  final double particleAnim; // 0..1
  final double shimmerValue;

  AtmospherePainter({
    required this.bubbleAnim,
    required this.particleAnim,
    required this.shimmerValue,
  });

  static final _rng = math.Random(1234);

  static final List<_BubbleData> _bubbles = List.generate(18, (i) {
    final r = _rng;
    return _BubbleData(
      x: r.nextDouble(),
      startY: 0.5 + r.nextDouble() * 0.5,
      radius: 4.0 + r.nextDouble() * 14.0,
      speed: 0.4 + r.nextDouble() * 0.6,
      phase: r.nextDouble(),
      wobble: r.nextDouble() * 0.03,
    );
  });

  static final List<_ParticleData> _particles = List.generate(35, (i) {
    final r = _rng;
    return _ParticleData(
      x: r.nextDouble(),
      y: 0.05 + r.nextDouble() * 0.9,
      radius: 1.0 + r.nextDouble() * 3.5,
      phase: r.nextDouble(),
      speed: 0.5 + r.nextDouble() * 1.0,
      color: [
        const Color(0xFFFFE082),
        const Color(0xFFFFCDD2),
        const Color(0xFFB3E5FC),
        const Color(0xFFC8E6C9),
        Colors.white,
      ][i % 5],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBubbles(canvas, size);
    _drawParticles(canvas, size);
    _drawLensFlares(canvas, size);
  }

  void _drawBubbles(Canvas canvas, Size size) {
    for (final b in _bubbles) {
      final progress = ((bubbleAnim * b.speed + b.phase) % 1.0);
      final y = (b.startY - progress * b.startY) * size.height;
      if (y < 0) continue;
      final x = b.x * size.width + math.sin(progress * math.pi * 4 + b.phase * 10) * b.wobble * size.width;

      _drawBubble(canvas, Offset(x, y), b.radius);
    }
  }

  void _drawBubble(Canvas canvas, Offset center, double radius) {
    // Corps translucide
    final bodyPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // Anneau brillant
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, ringPaint);

    // Reflet principal (haut gauche)
    final hlPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      center + Offset(-radius * 0.3, -radius * 0.35),
      radius * 0.28,
      hlPaint,
    );

    // Reflet secondaire (bas droit)
    final hl2Paint = Paint()
      ..color = const Color(0xFFADE8F4).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(
      center + Offset(radius * 0.25, radius * 0.3),
      radius * 0.18,
      hl2Paint,
    );

    // Reflet-arc de cercle en haut
    final arcRect = Rect.fromCircle(center: center, radius: radius * 0.85);
    canvas.drawArc(
      arcRect,
      -math.pi * 0.9,
      math.pi * 0.7,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final p in _particles) {
      final flicker = (math.sin(particleAnim * math.pi * 2 * p.speed + p.phase * math.pi * 2) + 1) / 2;
      final opacity = 0.2 + flicker * 0.7;
      final drift = math.sin(particleAnim * math.pi * 4 + p.phase * 10) * 8;
      final px = p.x * size.width + drift;
      final py = p.y * size.height + math.sin(particleAnim * math.pi * 2 * p.speed + p.phase * 5) * 6;

      // Glow
      canvas.drawCircle(
        Offset(px, py),
        p.radius * 2.5,
        Paint()
          ..color = p.color.withOpacity(opacity * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Corps
      canvas.drawCircle(
        Offset(px, py),
        p.radius * (0.7 + flicker * 0.5),
        Paint()..color = p.color.withOpacity(opacity),
      );
      // Reflet
      canvas.drawCircle(
        Offset(px - p.radius * 0.25, py - p.radius * 0.25),
        p.radius * 0.3,
        Paint()..color = Colors.white.withOpacity(opacity * 0.6),
      );
    }
  }

  void _drawLensFlares(Canvas canvas, Size size) {
    // Lens flare autour du soleil
    final sunX = size.width * 0.78;
    final sunY = size.height * 0.08;

    final flareOpacity = 0.08 + shimmerValue * 0.06;
    final flarePaint = Paint()
      ..color = Colors.white.withOpacity(flareOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Étoile de lumière 4 branches
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * math.pi + math.pi / 8;
      final len = 55.0 + shimmerValue * 15;
      canvas.drawLine(
        Offset(sunX - math.cos(angle) * 5, sunY - math.sin(angle) * 5),
        Offset(sunX + math.cos(angle) * len, sunY + math.sin(angle) * len),
        Paint()
          ..color = Colors.white.withOpacity(flareOpacity)
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Halo chromatic
    for (int i = 0; i < 3; i++) {
      final radius = 36.0 + i * 20.0;
      canvas.drawCircle(
        Offset(sunX, sunY),
        radius,
        Paint()
          ..color = [
            const Color(0xFFFF6D00),
            const Color(0xFFFFEB3B),
            Colors.white,
          ][i].withOpacity(flareOpacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(AtmospherePainter old) =>
      old.bubbleAnim != bubbleAnim ||
      old.particleAnim != particleAnim ||
      old.shimmerValue != shimmerValue;
}

class _BubbleData {
  final double x, startY, radius, speed, phase, wobble;
  _BubbleData({
    required this.x,
    required this.startY,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.wobble,
  });
}

class _ParticleData {
  final double x, y, radius, phase, speed;
  final Color color;
  _ParticleData({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
    required this.speed,
    required this.color,
  });
}
