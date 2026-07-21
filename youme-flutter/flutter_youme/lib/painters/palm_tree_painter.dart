import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Peint plusieurs palmiers 3D avec animation de balancement
class PalmTreePainter extends CustomPainter {
  final double swayAnim; // 0..1

  PalmTreePainter({required this.swayAnim});

  @override
  void paint(Canvas canvas, Size size) {
    // Palmier arrière-plan gauche
    _drawPalm(
      canvas,
      size,
      base: Offset(size.width * 0.08, size.height * 0.78),
      height: size.height * 0.45,
      sway: swayAnim,
      scale: 0.75,
      flip: false,
      tint: const Color(0xFF5D4037).withOpacity(0.8),
    );

    // Palmier arrière-plan droit
    _drawPalm(
      canvas,
      size,
      base: Offset(size.width * 0.92, size.height * 0.76),
      height: size.height * 0.42,
      sway: swayAnim,
      scale: 0.7,
      flip: true,
      tint: const Color(0xFF4E342E).withOpacity(0.8),
    );

    // Palmier avant-plan gauche (grand)
    _drawPalm(
      canvas,
      size,
      base: Offset(size.width * 0.0, size.height * 0.85),
      height: size.height * 0.60,
      sway: swayAnim,
      scale: 1.0,
      flip: false,
      tint: const Color(0xFF6D4C41),
    );

    // Palmier avant-plan droit (grand)
    _drawPalm(
      canvas,
      size,
      base: Offset(size.width * 1.0, size.height * 0.83),
      height: size.height * 0.58,
      sway: swayAnim,
      scale: 0.95,
      flip: true,
      tint: const Color(0xFF5D4037),
    );
  }

  void _drawPalm(
    Canvas canvas,
    Size size, {
    required Offset base,
    required double height,
    required double sway,
    required double scale,
    required bool flip,
    required Color tint,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    if (flip) canvas.scale(-1, 1);

    final swayOffset = math.sin(sway * math.pi * 2) * 10 * scale;

    // Tronc (courbe de Bézier)
    _drawTrunk(canvas, height, swayOffset, scale, tint);

    // Noix de coco
    _drawCoconuts(canvas, height, swayOffset, scale);

    // Feuilles
    _drawLeaves(canvas, height, swayOffset, scale, sway);

    canvas.restore();
  }

  void _drawTrunk(Canvas canvas, double height, double swayOffset, double scale, Color tint) {
    final trunkWidth = 14.0 * scale;
    final ctrl1 = Offset(swayOffset * 0.3, -height * 0.4);
    final ctrl2 = Offset(swayOffset * 0.7, -height * 0.75);
    final tip = Offset(swayOffset, -height);

    // Ombre du tronc
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = trunkWidth + 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final shadowPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(ctrl1.dx + 4, ctrl1.dy, ctrl2.dx + 4, ctrl2.dy, tip.dx + 4, tip.dy);
    canvas.drawPath(shadowPath, shadowPaint);

    // Corps du tronc avec gradient 3D
    for (int seg = 0; seg < 12; seg++) {
      final t0 = seg / 12;
      final t1 = (seg + 1) / 12;

      final p0 = _cubicBezier(Offset.zero, ctrl1, ctrl2, tip, t0);
      final p1 = _cubicBezier(Offset.zero, ctrl1, ctrl2, tip, t1);

      final w0 = trunkWidth * (1.0 - t0 * 0.4);
      final w1 = trunkWidth * (1.0 - t1 * 0.4);

      // Anneau de palmier
      final segColor = Color.lerp(
        const Color(0xFF8D6E63),
        const Color(0xFF4E342E),
        t0,
      )!;

      final segPaint = Paint()
        ..color = segColor
        ..style = PaintingStyle.fill;

      final angle = math.atan2(p1.dy - p0.dy, p1.dx - p0.dx) + math.pi / 2;
      final segPath = Path();
      segPath.moveTo(p0.dx - math.cos(angle) * w0, p0.dy - math.sin(angle) * w0);
      segPath.lineTo(p0.dx + math.cos(angle) * w0, p0.dy + math.sin(angle) * w0);
      segPath.lineTo(p1.dx + math.cos(angle) * w1, p1.dy + math.sin(angle) * w1);
      segPath.lineTo(p1.dx - math.cos(angle) * w1, p1.dy - math.sin(angle) * w1);
      segPath.close();
      canvas.drawPath(segPath, segPaint);

      // Reflet latéral
      final hlPaint = Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      final hlPath = Path();
      hlPath.moveTo(p0.dx - math.cos(angle) * w0, p0.dy - math.sin(angle) * w0);
      hlPath.lineTo(p0.dx - math.cos(angle) * w0 * 0.3, p0.dy - math.sin(angle) * w0 * 0.3);
      hlPath.lineTo(p1.dx - math.cos(angle) * w1 * 0.3, p1.dy - math.sin(angle) * w1 * 0.3);
      hlPath.lineTo(p1.dx - math.cos(angle) * w1, p1.dy - math.sin(angle) * w1);
      hlPath.close();
      canvas.drawPath(hlPath, hlPaint);
    }
  }

  Offset _cubicBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1 - t;
    return Offset(
      mt * mt * mt * p0.dx +
          3 * mt * mt * t * p1.dx +
          3 * mt * t * t * p2.dx +
          t * t * t * p3.dx,
      mt * mt * mt * p0.dy +
          3 * mt * mt * t * p1.dy +
          3 * mt * t * t * p2.dy +
          t * t * t * p3.dy,
    );
  }

  void _drawCoconuts(Canvas canvas, double height, double swayOffset, double scale) {
    final tip = Offset(swayOffset, -height);
    final positions = [
      tip + Offset(-6 * scale, 12 * scale),
      tip + Offset(4 * scale, 14 * scale),
      tip + Offset(-2 * scale, 20 * scale),
    ];

    for (final pos in positions) {
      final rect = Rect.fromCircle(center: pos, radius: 9 * scale);
      final grad = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          const Color(0xFFA5D6A7),
          const Color(0xFF66BB6A),
          const Color(0xFF388E3C),
          const Color(0xFF1B5E20),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      );
      final coconutPaint = Paint()..shader = grad.createShader(rect);
      canvas.drawCircle(pos, 9 * scale, coconutPaint);
      // Reflet
      final hlPaint = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(pos + Offset(-3 * scale, -3 * scale), 3.5 * scale, hlPaint);
    }
  }

  void _drawLeaves(Canvas canvas, double height, double swayOffset, double scale, double sway) {
    final tip = Offset(swayOffset, -height);
    final leafAngles = [-math.pi / 2.2, -math.pi / 3.5, -math.pi / 6, 0, math.pi / 6,
      math.pi / 3.5, math.pi / 2.2];
    final leafLengths = [0.9, 1.0, 0.95, 0.85, 0.95, 1.0, 0.9];

    for (int i = 0; i < leafAngles.length; i++) {
      final baseAngle = leafAngles[i];
      final leafSway = math.sin(sway * math.pi * 2 + i * 0.6) * 0.08;
      final angle = baseAngle + leafSway;
      final leafLen = 75.0 * scale * leafLengths[i];
      _drawLeaf(canvas, tip, angle, leafLen, scale, i);
    }
  }

  void _drawLeaf(Canvas canvas, Offset tip, double angle, double length, double scale, int idx) {
    final depth = (idx % 3) / 3.0;
    final leafColor = Color.lerp(
      const Color(0xFF66BB6A),
      const Color(0xFF1B5E20),
      depth * 0.6,
    )!;
    final shadowColor = const Color(0xFF1B5E20).withOpacity(0.4);

    final ctrl1 = Offset(
      tip.dx + math.cos(angle + 0.3) * length * 0.5,
      tip.dy + math.sin(angle + 0.3) * length * 0.5,
    );
    final ctrl2 = Offset(
      tip.dx + math.cos(angle - 0.15) * length * 0.85,
      tip.dy + math.sin(angle - 0.15) * length * 0.85,
    );
    final end = Offset(
      tip.dx + math.cos(angle) * length,
      tip.dy + math.sin(angle) * length,
    );

    // Ombre feuille
    final shadowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(ctrl1.dx + 3, ctrl1.dy + 3, ctrl2.dx + 3, ctrl2.dy + 3, end.dx + 3, end.dy + 3);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = shadowColor
        ..strokeWidth = 8 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Corps de la feuille – forme ovale plate
    final leafPath = Path();
    final perp = Offset(-math.sin(angle), math.cos(angle));
    final leafWidth = 11.0 * scale;

    leafPath.moveTo(tip.dx, tip.dy);
    leafPath.cubicTo(
      ctrl1.dx + perp.dx * leafWidth,
      ctrl1.dy + perp.dy * leafWidth,
      ctrl2.dx + perp.dx * leafWidth * 0.6,
      ctrl2.dy + perp.dy * leafWidth * 0.6,
      end.dx, end.dy,
    );
    leafPath.cubicTo(
      ctrl2.dx - perp.dx * leafWidth * 0.6,
      ctrl2.dy - perp.dy * leafWidth * 0.6,
      ctrl1.dx - perp.dx * leafWidth,
      ctrl1.dy - perp.dy * leafWidth,
      tip.dx, tip.dy,
    );

    final leafRect = Rect.fromLTWH(
      tip.dx - length, tip.dy - length, length * 2, length * 2,
    );
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFA5D6A7),
        leafColor,
        const Color(0xFF1B5E20),
      ],
    );
    canvas.drawPath(
      leafPath,
      Paint()..shader = grad.createShader(leafRect),
    );

    // Nervure centrale
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, end.dx, end.dy),
      Paint()
        ..color = const Color(0xFF81C784).withOpacity(0.6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    // Reflet
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx + perp.dx * 2, tip.dy + perp.dy * 2)
        ..cubicTo(
          ctrl1.dx + perp.dx * leafWidth * 0.5,
          ctrl1.dy + perp.dy * leafWidth * 0.5,
          ctrl2.dx + perp.dx * leafWidth * 0.3,
          ctrl2.dy + perp.dy * leafWidth * 0.3,
          end.dx, end.dy,
        ),
      Paint()
        ..color = Colors.white.withOpacity(0.22)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(PalmTreePainter old) => old.swayAnim != swayAnim;
}
