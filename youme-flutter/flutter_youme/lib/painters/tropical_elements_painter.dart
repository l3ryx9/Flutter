import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Peint fleurs tropicales, feuilles exotiques et ananas stylisés
class TropicalElementsPainter extends CustomPainter {
  final double swayAnim;
  final double oscillateAnim;

  TropicalElementsPainter({required this.swayAnim, required this.oscillateAnim});

  @override
  void paint(Canvas canvas, Size size) {
    _drawExoticLeaves(canvas, size);
    _drawPineapples(canvas, size);
    _drawTropicalFlowers(canvas, size);
  }

  // ── Feuilles exotiques ──────────────────────────────────────────────────
  void _drawExoticLeaves(Canvas canvas, Size size) {
    final leaves = [
      _LeafPos(Offset(size.width * 0.22, size.height * 0.65), 0.85, 0.0),
      _LeafPos(Offset(size.width * 0.75, size.height * 0.62), 0.75, math.pi),
      _LeafPos(Offset(size.width * 0.60, size.height * 0.70), 0.65, math.pi * 0.3),
      _LeafPos(Offset(size.width * 0.35, size.height * 0.72), 0.55, math.pi * 1.7),
    ];
    for (final l in leaves) {
      canvas.save();
      canvas.translate(l.pos.dx, l.pos.dy);
      final sway = math.sin(swayAnim * math.pi * 2 + l.phase) * 0.07;
      canvas.rotate(sway);
      _drawBananaLeaf(canvas, l.scale, l.phase);
      canvas.restore();
    }
  }

  void _drawBananaLeaf(Canvas canvas, double scale, double phase) {
    final length = 70.0 * scale;
    final width = 22.0 * scale;
    final angle = -math.pi / 5 + math.sin(phase) * 0.2;

    final tip = Offset(math.cos(angle) * length, math.sin(angle) * length);
    final perp = Offset(-math.sin(angle), math.cos(angle));

    final leafPath = Path();
    leafPath.moveTo(0, 0);
    leafPath.cubicTo(
      perp.dx * width * 0.5 + math.cos(angle) * length * 0.3,
      perp.dy * width * 0.5 + math.sin(angle) * length * 0.3,
      perp.dx * width * 0.7 + math.cos(angle) * length * 0.65,
      perp.dy * width * 0.7 + math.sin(angle) * length * 0.65,
      tip.dx, tip.dy,
    );
    leafPath.cubicTo(
      -perp.dx * width * 0.7 + math.cos(angle) * length * 0.65,
      -perp.dy * width * 0.7 + math.sin(angle) * length * 0.65,
      -perp.dx * width * 0.5 + math.cos(angle) * length * 0.3,
      -perp.dy * width * 0.5 + math.sin(angle) * length * 0.3,
      0, 0,
    );

    final leafRect = Rect.fromLTWH(-width, -width, length + width * 2, length + width * 2);
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [const Color(0xFF69F0AE), const Color(0xFF00C853), const Color(0xFF1B5E20)],
    );
    canvas.drawPath(leafPath, Paint()..shader = grad.createShader(leafRect));

    // Nervure principale
    canvas.drawLine(
      Offset.zero, tip,
      Paint()
        ..color = const Color(0xFF81C784).withOpacity(0.7)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Nervures latérales
    for (int i = 1; i <= 5; i++) {
      final t = i / 6.0;
      final base = Offset(math.cos(angle) * length * t, math.sin(angle) * length * t);
      final nervLen = width * (1 - t * 0.4);
      canvas.drawLine(
        base,
        base + perp * nervLen,
        Paint()
          ..color = const Color(0xFF81C784).withOpacity(0.4)
          ..strokeWidth = 0.7
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        base,
        base - perp * nervLen,
        Paint()
          ..color = const Color(0xFF81C784).withOpacity(0.4)
          ..strokeWidth = 0.7
          ..style = PaintingStyle.stroke,
      );
    }

    // Reflet lumineux
    final hlPath = Path();
    hlPath.moveTo(0, 0);
    hlPath.cubicTo(
      perp.dx * width * 0.15 + math.cos(angle) * length * 0.3,
      perp.dy * width * 0.15 + math.sin(angle) * length * 0.3,
      perp.dx * width * 0.2 + math.cos(angle) * length * 0.65,
      perp.dy * width * 0.2 + math.sin(angle) * length * 0.65,
      tip.dx, tip.dy,
    );
    canvas.drawPath(
      hlPath,
      Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  // ── Ananas 3D ───────────────────────────────────────────────────────────
  void _drawPineapples(Canvas canvas, Size size) {
    final pineapples = [
      _PineapplePos(Offset(size.width * 0.18, size.height * 0.82), 0.70),
      _PineapplePos(Offset(size.width * 0.48, size.height * 0.80), 0.85),
      _PineapplePos(Offset(size.width * 0.78, size.height * 0.84), 0.65),
    ];
    for (int i = 0; i < pineapples.length; i++) {
      final p = pineapples[i];
      final bob = math.sin(oscillateAnim * math.pi * 2 + i * 1.2) * 4.0;
      _drawPineapple(canvas, p.pos.translate(0, bob), p.scale);
    }
  }

  void _drawPineapple(Canvas canvas, Offset center, double scale) {
    final w = 26.0 * scale;
    final h = 40.0 * scale;

    // Ombre portée
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, h * 0.55), width: w * 1.6, height: h * 0.22),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Corps de l'ananas – gradient 3D
    final bodyRect = Rect.fromCenter(center: center, width: w * 2, height: h * 2);
    final grad = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      colors: [
        const Color(0xFFFFEE58),
        const Color(0xFFFDD835),
        const Color(0xFFF9A825),
        const Color(0xFFE65100),
      ],
      stops: const [0.0, 0.3, 0.65, 1.0],
    );

    final bodyPath = Path();
    bodyPath.addOval(Rect.fromCenter(center: center, width: w * 2, height: h * 2));
    canvas.drawPath(bodyPath, Paint()..shader = grad.createShader(bodyRect));

    // Texture diamant (écailles)
    _drawPineappleTexture(canvas, center, w, h);

    // Reflet brillant
    final hlPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-w * 0.3, -h * 0.3),
        width: w * 0.5,
        height: h * 0.28,
      ),
      hlPaint,
    );

    // Couronne de feuilles
    _drawPineappleCrown(canvas, center.translate(0, -h), scale);
  }

  void _drawPineappleTexture(Canvas canvas, Offset center, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFFE65100).withOpacity(0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int row = -4; row <= 4; row++) {
      for (int col = -3; col <= 3; col++) {
        final ox = col * w * 0.45 + (row % 2 == 0 ? 0 : w * 0.22);
        final oy = row * h * 0.22;
        final px = center.dx + ox;
        final py = center.dy + oy;
        // Check inside ellipse
        final inX = ox / w;
        final inY = oy / h;
        if (inX * inX + inY * inY < 0.88) {
          final dp = 5.0;
          final path = Path();
          path.moveTo(px, py - dp);
          path.lineTo(px + dp, py);
          path.lineTo(px, py + dp);
          path.lineTo(px - dp, py);
          path.close();
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  void _drawPineappleCrown(Canvas canvas, Offset base, double scale) {
    final crownLeaves = [
      _CrownLeaf(-math.pi / 2, 30.0 * scale, 8.0 * scale),
      _CrownLeaf(-math.pi / 2.2, 25.0 * scale, 6.0 * scale),
      _CrownLeaf(-math.pi / 2 + 0.35, 22.0 * scale, 5.5 * scale),
      _CrownLeaf(-math.pi / 2 - 0.35, 22.0 * scale, 5.5 * scale),
      _CrownLeaf(-math.pi / 2 + 0.65, 16.0 * scale, 4.5 * scale),
      _CrownLeaf(-math.pi / 2 - 0.65, 16.0 * scale, 4.5 * scale),
    ];

    for (final cl in crownLeaves) {
      final tip = base + Offset(math.cos(cl.angle) * cl.length, math.sin(cl.angle) * cl.length);
      final perp = Offset(-math.sin(cl.angle), math.cos(cl.angle));
      final leafPath = Path();
      leafPath.moveTo(base.dx, base.dy);
      leafPath.quadraticBezierTo(
        base.dx + perp.dx * cl.width + math.cos(cl.angle) * cl.length * 0.5,
        base.dy + perp.dy * cl.width + math.sin(cl.angle) * cl.length * 0.5,
        tip.dx, tip.dy,
      );
      leafPath.quadraticBezierTo(
        base.dx - perp.dx * cl.width + math.cos(cl.angle) * cl.length * 0.5,
        base.dy - perp.dy * cl.width + math.sin(cl.angle) * cl.length * 0.5,
        base.dx, base.dy,
      );

      final lRect = Rect.fromPoints(base, tip);
      final lGrad = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [const Color(0xFF66BB6A), const Color(0xFF00E676), const Color(0xFFB9F6CA)],
      );
      canvas.drawPath(leafPath, Paint()..shader = lGrad.createShader(lRect));
    }
  }

  // ── Fleurs tropicales ────────────────────────────────────────────────────
  void _drawTropicalFlowers(Canvas canvas, Size size) {
    final flowers = [
      _FlowerPos(Offset(size.width * 0.28, size.height * 0.75), 0.80, const Color(0xFFFF4081), 0.0),
      _FlowerPos(Offset(size.width * 0.65, size.height * 0.73), 0.70, const Color(0xFFFF6D00), math.pi / 3),
      _FlowerPos(Offset(size.width * 0.45, size.height * 0.77), 0.60, const Color(0xFFAA00FF), math.pi * 0.8),
      _FlowerPos(Offset(size.width * 0.88, size.height * 0.79), 0.65, const Color(0xFFFFD600), math.pi * 1.3),
    ];

    for (int i = 0; i < flowers.length; i++) {
      final f = flowers[i];
      final osc = math.sin(oscillateAnim * math.pi * 2 + f.phase + i * 0.7) * 0.05;
      canvas.save();
      canvas.translate(f.pos.dx, f.pos.dy);
      canvas.rotate(osc);
      _drawFlower(canvas, f.scale, f.color, f.phase);
      canvas.restore();
    }
  }

  void _drawFlower(Canvas canvas, double scale, Color color, double phase) {
    final petalCount = 6;
    final petalLen = 22.0 * scale;
    final petalWidth = 10.0 * scale;

    for (int i = 0; i < petalCount; i++) {
      final angle = (i / petalCount) * math.pi * 2 + phase;
      final tip = Offset(math.cos(angle) * petalLen, math.sin(angle) * petalLen);
      final perp = Offset(-math.sin(angle), math.cos(angle));

      final petalPath = Path();
      petalPath.moveTo(0, 0);
      petalPath.cubicTo(
        perp.dx * petalWidth * 0.7 + math.cos(angle) * petalLen * 0.4,
        perp.dy * petalWidth * 0.7 + math.sin(angle) * petalLen * 0.4,
        perp.dx * petalWidth * 0.5 + math.cos(angle) * petalLen * 0.75,
        perp.dy * petalWidth * 0.5 + math.sin(angle) * petalLen * 0.75,
        tip.dx, tip.dy,
      );
      petalPath.cubicTo(
        -perp.dx * petalWidth * 0.5 + math.cos(angle) * petalLen * 0.75,
        -perp.dy * petalWidth * 0.5 + math.sin(angle) * petalLen * 0.75,
        -perp.dx * petalWidth * 0.7 + math.cos(angle) * petalLen * 0.4,
        -perp.dy * petalWidth * 0.7 + math.sin(angle) * petalLen * 0.4,
        0, 0,
      );

      // Gradient pétale (3D glossy)
      final petalRect = Rect.fromCircle(center: tip * 0.5, radius: petalLen);
      final pGrad = RadialGradient(
        center: Alignment(-0.4, -0.4),
        colors: [
          Color.lerp(Colors.white, color, 0.3)!,
          color,
          Color.lerp(color, Colors.black, 0.3)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      canvas.drawPath(petalPath, Paint()..shader = pGrad.createShader(petalRect));

      // Reflet
      canvas.drawLine(
        Offset.zero,
        tip * 0.6 + perp * petalWidth * 0.2,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    // Centre de la fleur – pistil glossy
    final pistilRect = Rect.fromCircle(center: Offset.zero, radius: 10 * scale);
    final pistilGrad = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      colors: [
        Colors.yellow.shade200,
        Colors.yellow.shade600,
        Colors.orange.shade800,
      ],
    );
    canvas.drawCircle(Offset.zero, 10 * scale, Paint()..shader = pistilGrad.createShader(pistilRect));
    canvas.drawCircle(
      Offset(-3 * scale, -3 * scale), 4 * scale,
      Paint()..color = Colors.white.withOpacity(0.45),
    );
  }

  @override
  bool shouldRepaint(TropicalElementsPainter old) =>
      old.swayAnim != swayAnim || old.oscillateAnim != oscillateAnim;
}

class _LeafPos {
  final Offset pos;
  final double scale;
  final double phase;
  _LeafPos(this.pos, this.scale, this.phase);
}

class _PineapplePos {
  final Offset pos;
  final double scale;
  _PineapplePos(this.pos, this.scale);
}

class _CrownLeaf {
  final double angle;
  final double length;
  final double width;
  _CrownLeaf(this.angle, this.length, this.width);
}

class _FlowerPos {
  final Offset pos;
  final double scale;
  final Color color;
  final double phase;
  _FlowerPos(this.pos, this.scale, this.color, this.phase);
}
