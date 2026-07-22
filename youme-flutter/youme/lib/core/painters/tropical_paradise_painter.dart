import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TROPICAL PARADISE — Widget principal
// ═══════════════════════════════════════════════════════════════════════════

class TropicalParadise extends StatefulWidget {
  final Widget? child;
  const TropicalParadise({super.key, this.child});

  @override
  State<TropicalParadise> createState() => _TropicalParadiseState();
}

class _TropicalParadiseState extends State<TropicalParadise>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final AnimationController _swayCtrl;
  late final AnimationController _bubbleCtrl;
  late final AnimationController _sunRayCtrl;
  late final AnimationController _cloudCtrl;
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 4))..repeat();
    _swayCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 5))..repeat(reverse: true);
    _bubbleCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 8))..repeat();
    _sunRayCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 14))..repeat();
    _cloudCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 28))..repeat();
    _particleCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 3200))..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _swayCtrl.dispose();
    _bubbleCtrl.dispose();
    _sunRayCtrl.dispose();
    _cloudCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveCtrl, _swayCtrl, _bubbleCtrl,
        _sunRayCtrl, _cloudCtrl, _particleCtrl,
      ]),
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1 — Sky + Sun
            CustomPaint(
              painter: SkySunPainter(
                sunRayT: _sunRayCtrl.value,
                particleT: _particleCtrl.value,
              ),
            ),
            // Layer 2 — Clouds
            CustomPaint(
              painter: CloudPainter(cloudT: _cloudCtrl.value),
            ),
            // Layer 3 — Sea + Beach
            CustomPaint(
              painter: SeaBeachPainter(waveT: _waveCtrl.value),
            ),
            // Layer 4 — Rocks + base flora
            CustomPaint(
              painter: RockFloraPainter(swayT: _swayCtrl.value),
            ),
            // Layer 5 — Palm trees
            CustomPaint(
              painter: PalmTreePainter(swayT: _swayCtrl.value),
            ),
            // Layer 6 — Flowers + pineapples + leaves
            CustomPaint(
              painter: FloraPainter(swayT: _swayCtrl.value),
            ),
            // Layer 7 — Bubbles + particles
            CustomPaint(
              painter: BubbleParticlePainter(
                bubbleT: _bubbleCtrl.value,
                particleT: _particleCtrl.value,
              ),
            ),
            // Child content
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w;

Color _lighten(Color c, double a) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + a).clamp(0.0, 1.0)).toColor();
}

Color _darken(Color c, double a) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - a).clamp(0.0, 1.0)).toColor();
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER 1 — Sky + Sun + Rays
// ═══════════════════════════════════════════════════════════════════════════

class SkySunPainter extends CustomPainter {
  final double sunRayT;
  final double particleT;
  SkySunPainter({required this.sunRayT, required this.particleT});

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    final horizonY = s.height * 0.42;

    // Sky gradient
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF0D2B55),
            Color(0xFF1565C0),
            Color(0xFF1E88E5),
            Color(0xFF42A5F5),
            Color(0xFF90CAF9),
            Color(0xFFE3F2FD),
          ],
          stops: [0.0, 0.18, 0.35, 0.52, 0.72, 1.0],
        ).createShader(rect),
    );

    // Horizon haze
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY - 40, s.width, 80),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFFFFF8E1).withOpacity(0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, horizonY - 40, s.width, 80)),
    );

    final sunX = s.width * 0.72;
    final sunY = s.height * 0.15;
    final sunCenter = Offset(sunX, sunY);

    // Sun outer glow
    for (final (r, op) in [(110.0, 0.06), (80.0, 0.10), (60.0, 0.14)]) {
      canvas.drawCircle(
        sunCenter, r,
        Paint()
          ..color = const Color(0xFFFFD54F).withOpacity(op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    // Sun rays (rotating)
    final rayPaint = Paint()
      ..color = const Color(0xFFFFF9C4).withOpacity(0.22)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(sunX, sunY);
    canvas.rotate(sunRayT * 2 * math.pi);
    const rayCount = 18;
    for (int i = 0; i < rayCount; i++) {
      final a = i / rayCount * 2 * math.pi;
      final len = (i.isEven ? 80 : 60) +
          math.sin(sunRayT * math.pi * 2 + i * 0.7) * 15;
      canvas.drawLine(
        Offset(math.cos(a) * 32, math.sin(a) * 32),
        Offset(math.cos(a) * len, math.sin(a) * len),
        rayPaint,
      );
    }
    canvas.restore();

    // Crepuscular rays (long diagonal)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, s.width, horizonY + 60));
    for (int i = 0; i < 8; i++) {
      final a = (i / 8 - 0.5) * 0.8 + math.pi / 2;
      final len = s.height * 0.75;
      final fade = math.sin(sunRayT * math.pi * 2 + i * 0.9) * 0.04 + 0.06;
      final rPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(255, 250, 200, fade * 2),
            Color.fromRGBO(255, 250, 200, 0),
          ],
        ).createShader(Rect.fromLTWH(
            sunX - 20, sunY, 40, len));
      canvas.drawPath(
        Path()
          ..moveTo(sunX, sunY)
          ..lineTo(
              sunX + math.cos(a - 0.05) * len,
              sunY + math.sin(a - 0.05) * len)
          ..lineTo(
              sunX + math.cos(a + 0.05) * len,
              sunY + math.sin(a + 0.05) * len)
          ..close(),
        rPaint,
      );
    }
    canvas.restore();

    // Sun core (3D glossy sphere)
    final sunRect = Rect.fromCircle(center: sunCenter, radius: 28);
    canvas.drawCircle(
      sunCenter,
      28,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.85,
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFF176),
            Color(0xFFFFD54F),
            Color(0xFFFF8F00),
          ],
          stops: [0.0, 0.3, 0.65, 1.0],
        ).createShader(sunRect),
    );

    // Sun specular
    canvas.drawCircle(
      Offset(sunX - 8, sunY - 8),
      10,
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Light sparkles
    final rng = math.Random(17);
    for (int i = 0; i < 20; i++) {
      final px = rng.nextDouble() * s.width;
      final py = rng.nextDouble() * horizonY;
      final phase = (particleT + i * 0.17) % 1.0;
      final alpha = math.sin(phase * math.pi) * 0.55;
      if (alpha <= 0) continue;
      _drawSparkle(canvas, Offset(px, py), 3 + rng.nextDouble() * 4,
          Colors.white.withOpacity(alpha));
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final p = Paint()..color = color;
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawLine(
        Offset(center.dx + math.cos(a) * 1, center.dy + math.sin(a) * 1),
        Offset(center.dx + math.cos(a) * size,
            center.dy + math.sin(a) * size),
        p..strokeWidth = 1.2,
      );
    }
    canvas.drawCircle(center, 1.5, p);
  }

  @override
  bool shouldRepaint(SkySunPainter o) =>
      o.sunRayT != sunRayT || o.particleT != particleT;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER 2 — Clouds (3D Bubble)
// ═══════════════════════════════════════════════════════════════════════════

class CloudPainter extends CustomPainter {
  final double cloudT;
  CloudPainter({required this.cloudT});

  @override
  void paint(Canvas canvas, Size s) {
    // Cloud definitions: (baseX%, y%, scale, speed)
    final clouds = [
      (0.08, 0.08, 1.1, 0.025),
      (0.40, 0.06, 0.75, 0.018),
      (0.72, 0.10, 0.95, 0.022),
      (0.20, 0.14, 0.60, 0.015),
      (0.58, 0.13, 0.80, 0.020),
    ];

    for (final (baseX, y, scale, speed) in clouds) {
      final drift = (baseX + cloudT * speed) % 1.15 - 0.08;
      _drawBubbleCloud(
        canvas,
        Offset(drift * s.width, y * s.height),
        scale * 70,
      );
    }
  }

  void _drawBubbleCloud(Canvas canvas, Offset center, double r) {
    final blobs = [
      (0.0, 0.0, r),
      (-r * 0.65, r * 0.15, r * 0.80),
      (r * 0.65, r * 0.15, r * 0.78),
      (-r * 0.35, -r * 0.25, r * 0.68),
      (r * 0.38, -r * 0.22, r * 0.65),
      (0.0, -r * 0.32, r * 0.55),
    ];

    for (final (dx, dy, br) in blobs) {
      final c = center + Offset(dx, dy);
      final bRect = Rect.fromCircle(center: c, radius: br);

      // Shadow
      canvas.drawCircle(
        c + const Offset(3, 5),
        br,
        Paint()
          ..color = Colors.black.withOpacity(0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Cloud body
      canvas.drawCircle(
        c,
        br,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.88,
            colors: const [
              Color(0xFFFFFFFF),
              Color(0xFFF5F9FF),
              Color(0xFFDDE8F5),
            ],
            stops: [0.0, 0.55, 1.0],
          ).createShader(bRect),
      );

      // Specular highlight
      canvas.drawCircle(
        c + Offset(-br * 0.28, -br * 0.32),
        br * 0.30,
        Paint()
          ..color = Colors.white.withOpacity(0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(CloudPainter o) => o.cloudT != cloudT;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER 3 — Sea + Waves + Beach
// ═══════════════════════════════════════════════════════════════════════════

class SeaBeachPainter extends CustomPainter {
  final double waveT;
  SeaBeachPainter({required this.waveT});

  @override
  void paint(Canvas canvas, Size s) {
    final seaTop = s.height * 0.42;
    final beachTop = s.height * 0.60;
    final beachBottom = s.height * 0.70;

    // ── Deep sea background ───────────────────────────────────────────
    final seaRect = Rect.fromLTWH(0, seaTop, s.width, s.height - seaTop);
    canvas.drawRect(
      seaRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF26C6DA),
            Color(0xFF00ACC1),
            Color(0xFF00838F),
            Color(0xFF006064),
          ],
          stops: [0.0, 0.3, 0.65, 1.0],
        ).createShader(seaRect),
    );

    // ── Sea floor transparency near beach ─────────────────────────────
    final shallowRect =
        Rect.fromLTWH(0, beachTop - 40, s.width, 80);
    canvas.drawRect(
      shallowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF80DEEA).withOpacity(0.4),
            const Color(0xFFE0F7FA).withOpacity(0.6),
          ],
        ).createShader(shallowRect),
    );

    // ── Animated waves (multiple layers) ─────────────────────────────
    final waveColors = [
      (const Color(0xFF4DD0E1), 0.0, 0.85, 10.0, 22.0, beachTop - 60),
      (const Color(0xFF80DEEA), 0.12, 0.90, 8.0, 18.0, beachTop - 40),
      (const Color(0xFFB2EBF2), 0.23, 0.95, 6.0, 14.0, beachTop - 22),
      (const Color(0xFFE0F7FA), 0.38, 1.00, 4.0, 10.0, beachTop - 8),
    ];

    for (final (color, phase, opacity, amp, freq, baseY) in waveColors) {
      _drawWave(canvas, s, waveT, phase, amp, freq, baseY, color.withOpacity(opacity));
    }

    // Foam sparkles
    final rng = math.Random(99);
    for (int i = 0; i < 30; i++) {
      final fx = rng.nextDouble() * s.width;
      final waveY = beachTop - 12 +
          math.sin((fx / s.width * 4 + waveT) * math.pi * 2) * 5;
      final twinkle = (math.sin(waveT * math.pi * 2 * 3 + i * 0.8) * 0.5 + 0.5);
      canvas.drawCircle(
        Offset(fx, waveY),
        1 + rng.nextDouble() * 1.5,
        Paint()..color = Colors.white.withOpacity(0.55 * twinkle),
      );
    }

    // ── Beach ─────────────────────────────────────────────────────────
    final beachPath = Path()
      ..moveTo(0, beachTop - 6)
      ..quadraticBezierTo(s.width * 0.25, beachTop + 4,
          s.width * 0.5, beachTop - 2)
      ..quadraticBezierTo(s.width * 0.75, beachTop - 8,
          s.width, beachTop + 2)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();

    final beachRect2 = Rect.fromLTWH(0, beachTop - 10, s.width,
        s.height - beachTop + 10);
    canvas.drawPath(
      beachPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFFF8DC),
            Color(0xFFF5DEB3),
            Color(0xFFDEB887),
            Color(0xFFD2B48C),
          ],
          stops: [0.0, 0.3, 0.65, 1.0],
        ).createShader(beachRect2),
    );

    // Beach wet zone (darker near water)
    final wetPath = Path()
      ..moveTo(0, beachTop - 6)
      ..quadraticBezierTo(s.width * 0.25, beachTop + 4,
          s.width * 0.5, beachTop - 2)
      ..quadraticBezierTo(s.width * 0.75, beachTop - 8,
          s.width, beachTop + 2)
      ..lineTo(s.width, beachTop + 22)
      ..lineTo(0, beachTop + 22)
      ..close();
    canvas.drawPath(
      wetPath,
      Paint()
        ..color = const Color(0xFFE0C870).withOpacity(0.3),
    );

    // Beach texture dots
    final rng2 = math.Random(55);
    for (int i = 0; i < 120; i++) {
      final bx = rng2.nextDouble() * s.width;
      final by = beachTop + 8 + rng2.nextDouble() * (s.height - beachTop - 8);
      canvas.drawCircle(
        Offset(bx, by),
        0.5 + rng2.nextDouble() * 1.2,
        Paint()..color = const Color(0xFFC19A6B).withOpacity(0.35),
      );
    }
  }

  void _drawWave(Canvas canvas, Size s, double t, double phase, double amp,
      double freq, double baseY, Color color) {
    final path = Path();
    path.moveTo(0, s.height);
    path.lineTo(0, baseY);
    for (double x = 0; x <= s.width; x += 1) {
      final y = baseY +
          math.sin((x / s.width * freq + t + phase) * math.pi * 2) * amp +
          math.sin((x / s.width * freq * 1.3 + t * 1.5 + phase) * math.pi * 2) *
              (amp * 0.4);
      path.lineTo(x, y);
    }
    path.lineTo(s.width, s.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(SeaBeachPainter o) => o.waveT != waveT;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER 4 — Rocks + Base Flora
// ═══════════════════════════════════════════════════════════════════════════

class RockFloraPainter extends CustomPainter {
  final double swayT;
  RockFloraPainter({required this.swayT});

  @override
  void paint(Canvas canvas, Size s) {
    final beachY = s.height * 0.60;

    // Rocks
    final rocks = [
      (s.width * 0.10, beachY + 10, 28.0, 20.0),
      (s.width * 0.15, beachY + 4, 20.0, 16.0),
      (s.width * 0.88, beachY + 8, 32.0, 22.0),
      (s.width * 0.83, beachY + 2, 18.0, 14.0),
      (s.width * 0.50, beachY + 12, 16.0, 12.0),
      (s.width * 0.55, beachY + 5, 12.0, 10.0),
    ];

    for (final (rx, ry, rw, rh) in rocks) {
      _drawRock(canvas, Offset(rx, ry), rw, rh);
    }

    // Small beach pebbles
    final rng = math.Random(22);
    for (int i = 0; i < 40; i++) {
      final px = rng.nextDouble() * s.width;
      final py = beachY + 8 + rng.nextDouble() * 50;
      final pr = 1.5 + rng.nextDouble() * 4;
      _drawRock(canvas, Offset(px, py), pr * 2.2, pr * 1.5);
    }
  }

  void _drawRock(Canvas canvas, Offset center, double w, double h) {
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: center + const Offset(3, 5),
          width: w, height: h * 0.6),
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final rRect = Rect.fromCenter(center: center, width: w, height: h);

    // Rock body (3D gradient)
    canvas.drawOval(
      rRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.88,
          colors: const [
            Color(0xFFCFD8DC),
            Color(0xFF90A4AE),
            Color(0xFF546E7A),
            Color(0xFF37474F),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ).createShader(rRect),
    );

    // Specular highlight
    canvas.drawOval(
      Rect.fromCenter(
          center: center + Offset(-w * 0.18, -h * 0.22),
          width: w * 0.35,
          height: h * 0.28),
      Paint()
        ..color = Colors.white.withOpacity(0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(RockFloraPainter o) => o.swayT != swayT;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER 5 — Palm Trees
// ═══════════════════════════════════════════════════════════════════════════

class PalmTreePainter extends CustomPainter {
  final double swayT;
  PalmTreePainter({required this.swayT});

  @override
  void paint(Canvas canvas, Size s) {
    final beachY = s.height * 0.60;

    // Palm trees: (baseX%, lean, scale, z-order)
    final trees = [
      (0.12, -0.12, 1.05, 0),
      (0.85, 0.10, 0.90, 0),
      (0.25, 0.06, 0.78, 1),
      (0.72, -0.08, 0.82, 1),
    ];

    // Sort by z-order (back to front)
    final sorted = [...trees]..sort((a, b) => a.$4.compareTo(b.$4));

    for (final (xf, lean, scale, _) in sorted) {
      _drawPalmTree(canvas, s, xf, lean, scale, beachY);
    }
  }

  void _drawPalmTree(
      Canvas canvas, Size s, double xFrac, double lean, double scale, double baseY) {
    final baseX = s.width * xFrac;
    final sway = math.sin(swayT * math.pi) * 0.04;
    final totalLean = lean + sway;

    final trunkH = 160.0 * scale;
    final segments = 10;

    // Draw trunk segments (tapered)
    for (int i = 0; i < segments; i++) {
      final t0 = i / segments;
      final t1 = (i + 1) / segments;
      final y0 = baseY - trunkH * t0;
      final y1 = baseY - trunkH * t1;
      final x0 = baseX + totalLean * trunkH * t0 * t0;
      final x1 = baseX + totalLean * trunkH * t1 * t1;
      final w0 = (10 - t0 * 5) * scale;
      final w1 = (10 - t1 * 5) * scale;

      final tPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF6D4C41),
            const Color(0xFF8D6E63),
            const Color(0xFF5D4037),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(x1 - w1, y1, w1 * 2, trunkH / segments));

      canvas.drawPath(
        Path()
          ..moveTo(x0 - w0, y0)
          ..lineTo(x0 + w0, y0)
          ..lineTo(x1 + w1, y1)
          ..lineTo(x1 - w1, y1)
          ..close(),
        tPaint,
      );

      // Segment ring
      canvas.drawLine(
        Offset(x1 - w1, y1),
        Offset(x1 + w1, y1),
        Paint()
          ..color = const Color(0xFF4E342E).withOpacity(0.5)
          ..strokeWidth = 0.8,
      );
    }

    final tipX = baseX + totalLean * trunkH;
    final tipY = baseY - trunkH;

    // Coconuts
    for (int c = 0; c < 3; c++) {
      final ca = c / 3 * 2 * math.pi + sway * 2;
      _drawCoconut(canvas,
          Offset(tipX + math.cos(ca) * 12 * scale, tipY + math.sin(ca) * 8 * scale),
          7 * scale);
    }

    // Fronds
    _drawFronds(canvas, Offset(tipX, tipY), scale, sway);
  }

  void _drawFronds(Canvas canvas, Offset tip, double scale, double sway) {
    final fronds = [
      (0.0, -1.0, 0.0),
      (-0.65, -0.78, -40.0 + sway * 30),
      (-0.9, -0.45, -65.0 + sway * 25),
      (-1.0, -0.1, -82.0 + sway * 20),
      (0.65, -0.78, 40.0 + sway * 30),
      (0.9, -0.45, 65.0 + sway * 25),
      (1.0, -0.1, 82.0 + sway * 20),
    ];

    for (final (dx, dy, angle) in fronds) {
      canvas.save();
      canvas.translate(tip.dx + dx * 8 * scale, tip.dy + dy * 8 * scale);
      canvas.rotate(angle * math.pi / 180);
      _drawFrond(canvas, scale, angle.abs() / 90);
      canvas.restore();
    }
  }

  void _drawFrond(Canvas canvas, double scale, double shadow) {
    final len = 70.0 * scale;
    final w = 14.0 * scale;
    final d = shadow.clamp(0.0, 1.0) * 0.35;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-w * 0.6, -len * 0.4, -w * 0.3, -len)
      ..quadraticBezierTo(0, -len * 1.1, w * 0.3, -len)
      ..quadraticBezierTo(w * 0.6, -len * 0.4, 0, 0);

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.lerp(const Color(0xFF43A047), const Color(0xFF1B5E20), d)!,
            Color.lerp(const Color(0xFF66BB6A), const Color(0xFF2E7D32), d)!,
            Color.lerp(const Color(0xFFA5D6A7), const Color(0xFF388E3C), d)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(-w, -len * 1.1, w * 2, len * 1.1)),
    );

    // Midrib
    canvas.drawLine(
      Offset.zero,
      Offset(0, -len),
      Paint()
        ..color = const Color(0xFF2E7D32).withOpacity(0.6)
        ..strokeWidth = 0.8,
    );

    // Leaflets
    for (int i = 2; i < 8; i++) {
      final t = i / 9;
      final lx = math.sin(t * math.pi) * w * 0.7;
      final ly = -len * t;
      final lLen = math.sin(t * math.pi) * 16 * scale;
      for (final side in [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(0, ly),
          Offset(side * lLen, ly - lLen * 0.3),
          Paint()
            ..color = Color.lerp(const Color(0xFF81C784),
                const Color(0xFF2E7D32), d)!
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  void _drawCoconut(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(
      center + Offset(r * 0.15, r * 0.15),
      r,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    final rr = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          radius: 0.9,
          colors: const [
            Color(0xFFA1887F),
            Color(0xFF795548),
            Color(0xFF4E342E),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rr),
    );
    canvas.drawCircle(
      center + Offset(-r * 0.25, -r * 0.3),
      r * 0.28,
      Paint()..color = Colors.white.withOpacity(0.32),
    );
  }

  @override
  bool shouldRepaint(PalmTreePainter o) => o.swayT != swayT;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER 6 — Flora (Flowers, Leaves, Pineapples)
// ═══════════════════════════════════════════════════════════════════════════

class FloraPainter extends CustomPainter {
  final double swayT;
  FloraPainter({required this.swayT});

  @override
  void paint(Canvas canvas, Size s) {
    final beachY = s.height * 0.60;
    final sway = math.sin(swayT * math.pi) * 0.06;

    // Tropical leaves
    final leafDefs = [
      (s.width * 0.05, beachY + 5, 1.0, -0.3 + sway),
      (s.width * 0.30, beachY + 2, 0.85, 0.2 - sway * 0.7),
      (s.width * 0.65, beachY + 6, 0.90, -0.15 + sway * 0.8),
      (s.width * 0.92, beachY + 3, 0.80, 0.25 - sway),
    ];
    for (final (lx, ly, lscale, lang) in leafDefs) {
      _drawTropicalLeaf(canvas, Offset(lx, ly), lscale, lang);
    }

    // Hibiscus flowers
    _drawHibiscus(canvas, Offset(s.width * 0.22, beachY - 5), 18, sway);
    _drawHibiscus(canvas,
        Offset(s.width * 0.78, beachY - 8), 15, -sway * 0.8);
    _drawHibiscus(canvas,
        Offset(s.width * 0.42, beachY - 2), 12, sway * 1.2);

    // Plumeria flowers
    _drawPlumeria(canvas, Offset(s.width * 0.18, beachY + 15), 14, -sway);
    _drawPlumeria(canvas, Offset(s.width * 0.82, beachY + 10), 12, sway * 0.9);

    // Pineapples
    _drawPineapple(canvas, Offset(s.width * 0.38, beachY + 8), 0.55);
    _drawPineapple(canvas, Offset(s.width * 0.62, beachY + 5), 0.48);

    // Exotic small flowers (ground)
    final rng = math.Random(33);
    for (int i = 0; i < 18; i++) {
      final fx = rng.nextDouble() * s.width;
      final fy = beachY + 5 + rng.nextDouble() * 35;
      final fr = 3 + rng.nextDouble() * 5;
      final fc = [
        const Color(0xFFFF4081),
        const Color(0xFFFF6D00),
        const Color(0xFFFFEA00),
        const Color(0xFFE040FB),
        const Color(0xFF40C4FF),
      ][rng.nextInt(5)];
      _drawSmallFlower(canvas, Offset(fx, fy), fr, fc, sway * (rng.nextDouble() * 2 - 1));
    }
  }

  void _drawTropicalLeaf(
      Canvas canvas, Offset base, double scale, double angle) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final len = 65.0 * scale;
    final w = 18.0 * scale;

    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(-w, -len * 0.3, -w * 1.1, -len * 0.7, 0, -len)
      ..cubicTo(w * 1.1, -len * 0.7, w, -len * 0.3, 0, 0);

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: const [
            Color(0xFF1B5E20),
            Color(0xFF388E3C),
            Color(0xFF66BB6A),
            Color(0xFFA5D6A7),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ).createShader(Rect.fromLTWH(-w, -len, w * 2, len)),
    );

    // Veins
    final veinPaint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.55)
      ..strokeWidth = 0.9;
    canvas.drawLine(Offset(0, 0), Offset(0, -len * 0.95), veinPaint);
    for (int i = 1; i <= 5; i++) {
      final t = i / 6;
      final vx = math.sin(t * math.pi) * w * 0.8;
      final vy = -len * t;
      canvas.drawLine(Offset(0, vy), Offset(-vx, vy - 10), veinPaint);
      canvas.drawLine(Offset(0, vy), Offset(vx, vy - 10), veinPaint);
    }

    // Specular
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(-w, -len, w * 2, len)),
    );
    canvas.restore();
  }

  void _drawHibiscus(
      Canvas canvas, Offset center, double r, double sway) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sway);

    // Shadow
    canvas.drawCircle(
      const Offset(2, 4),
      r * 1.2,
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Petals
    const petalColors = [
      Color(0xFFFF1744),
      Color(0xFFFF4081),
      Color(0xFFFF80AB),
    ];
    for (int i = 0; i < 5; i++) {
      final pa = i / 5 * 2 * math.pi;
      canvas.save();
      canvas.rotate(pa);
      final petalPath = Path()
        ..moveTo(0, 0)
        ..cubicTo(-r * 0.5, -r * 0.4, -r * 0.6, -r * 1.1, 0, -r * 1.35)
        ..cubicTo(r * 0.6, -r * 1.1, r * 0.5, -r * 0.4, 0, 0);

      final pr = Rect.fromLTWH(-r * 0.7, -r * 1.4, r * 1.4, r * 1.4);
      canvas.drawPath(
        petalPath,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.5),
            radius: 1.0,
            colors: [
              petalColors[0],
              petalColors[1],
              petalColors[2].withOpacity(0.7),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(pr),
      );
      // Petal vein
      canvas.drawLine(
        Offset(0, 0),
        Offset(0, -r * 1.25),
        Paint()
          ..color = Colors.white.withOpacity(0.35)
          ..strokeWidth = 0.8,
      );
      canvas.restore();
    }

    // Stamen
    canvas.drawCircle(
      Offset.zero,
      r * 0.28,
      Paint()..color = const Color(0xFFFFEB3B),
    );
    canvas.drawCircle(
      const Offset(-1.5, -1.5),
      r * 0.10,
      Paint()..color = Colors.white.withOpacity(0.65),
    );
    canvas.restore();
  }

  void _drawPlumeria(
      Canvas canvas, Offset center, double r, double sway) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sway);

    for (int i = 0; i < 5; i++) {
      final pa = i / 5 * 2 * math.pi;
      canvas.save();
      canvas.rotate(pa);
      final pr = Rect.fromLTWH(-r * 0.5, -r * 1.3, r, r * 1.3);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..cubicTo(-r * 0.45, -r * 0.35, -r * 0.5, -r * 1.0, 0, -r * 1.3)
          ..cubicTo(r * 0.5, -r * 1.0, r * 0.45, -r * 0.35, 0, 0),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.8),
            radius: 1.0,
            colors: const [
              Color(0xFFFFFFFF),
              Color(0xFFFFF9C4),
              Color(0xFFFFE082),
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(pr),
      );
      canvas.restore();
    }
    // Center
    canvas.drawCircle(
        Offset.zero, r * 0.22, Paint()..color = const Color(0xFFFFE082));
    canvas.restore();
  }

  void _drawPineapple(Canvas canvas, Offset center, double scale) {
    final cy = center.dy;
    final cx = center.dx;
    final h = 55.0 * scale;
    final w = 32.0 * scale;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + h * 0.52), width: w * 1.1, height: h * 0.18),
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final bodyRect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);

    // Body
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: const [
            Color(0xFFFFF59D),
            Color(0xFFF9A825),
            Color(0xFFE65100),
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(bodyRect),
    );

    // Diamond pattern
    canvas.save();
    canvas.clipOval(bodyRect);
    final lp = Paint()
      ..color = const Color(0xFFC77B0A).withOpacity(0.4)
      ..strokeWidth = 0.6;
    const cols = 6;
    const rows = 8;
    final dw2 = w / cols;
    final dh2 = h / rows;
    for (int row = 0; row <= rows; row++) {
      for (int col = 0; col <= cols; col++) {
        final x = cx - w / 2 + col * dw2 + (row.isOdd ? dw2 / 2 : 0);
        final y = cy - h / 2 + row * dh2;
        canvas.drawPath(
          Path()
            ..moveTo(x, y - dh2 * 0.36)
            ..lineTo(x + dw2 * 0.40, y)
            ..lineTo(x, y + dh2 * 0.36)
            ..lineTo(x - dw2 * 0.40, y)
            ..close(),
          lp,
        );
      }
    }
    canvas.restore();

    // Specular
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 0.5,
          colors: [Colors.white.withOpacity(0.45), Colors.transparent],
        ).createShader(bodyRect),
    );

    // Crown leaves (mini)
    final crownY = cy - h * 0.50;
    for (int i = 0; i < 5; i++) {
      final la = (i / 5 - 0.5) * 1.8;
      canvas.save();
      canvas.translate(cx + math.sin(la) * 8 * scale, crownY);
      canvas.rotate(la);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-4 * scale, -8 * scale, 0, -18 * scale)
          ..quadraticBezierTo(4 * scale, -8 * scale, 0, 0),
        Paint()..color = const Color(0xFF2E7D32),
      );
      canvas.restore();
    }
  }

  void _drawSmallFlower(
      Canvas canvas, Offset center, double r, Color color, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    for (int i = 0; i < 5; i++) {
      final a = i / 5 * 2 * math.pi;
      canvas.drawCircle(
        Offset(math.cos(a) * r * 0.9, math.sin(a) * r * 0.9),
        r * 0.65,
        Paint()..color = color.withOpacity(0.88),
      );
    }
    canvas.drawCircle(Offset.zero, r * 0.38, Paint()..color = const Color(0xFFFFEB3B));
    canvas.restore();
  }

  @override
  bool shouldRepaint(FloraPainter o) => o.swayT != swayT;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER 7 — Bubbles + Particles
// ═══════════════════════════════════════════════════════════════════════════

class BubbleParticlePainter extends CustomPainter {
  final double bubbleT;
  final double particleT;
  BubbleParticlePainter({required this.bubbleT, required this.particleT});

  @override
  void paint(Canvas canvas, Size s) {
    final rng = math.Random(88);

    // ── Floating bubbles ──────────────────────────────────────────────
    for (int i = 0; i < 18; i++) {
      final phase = (bubbleT + i * 0.055) % 1.0;
      final startX = rng.nextDouble() * s.width;
      final wobble = math.sin(phase * math.pi * 3 + i) * 18;
      final bx = startX + wobble;
      final by = s.height * 0.95 - phase * s.height * 1.1;
      final br = 5 + rng.nextDouble() * 16;
      final alpha = math.sin(phase * math.pi).clamp(0.0, 1.0);

      if (by > s.height + br || by < -br) continue;

      final brRect = Rect.fromCircle(center: Offset(bx, by), radius: br);

      // Bubble body (translucent)
      canvas.drawCircle(
        Offset(bx, by),
        br,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 1.0,
            colors: [
              Colors.white.withOpacity(0.14 * alpha),
              const Color(0xFF80DEEA).withOpacity(0.10 * alpha),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(brRect),
      );

      // Bubble rim
      canvas.drawCircle(
        Offset(bx, by),
        br,
        Paint()
          ..color = Colors.white.withOpacity(0.32 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );

      // Bubble inner specular
      canvas.drawCircle(
        Offset(bx - br * 0.32, by - br * 0.35),
        br * 0.22,
        Paint()..color = Colors.white.withOpacity(0.55 * alpha),
      );
      canvas.drawCircle(
        Offset(bx - br * 0.45, by - br * 0.48),
        br * 0.10,
        Paint()..color = Colors.white.withOpacity(0.75 * alpha),
      );

      // Rainbow iridescence
      canvas.drawCircle(
        Offset(bx, by),
        br,
        Paint()
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: math.pi * 2,
            colors: [
              Colors.transparent,
              const Color(0xFFE91E63).withOpacity(0.07 * alpha),
              const Color(0xFF9C27B0).withOpacity(0.07 * alpha),
              const Color(0xFF2196F3).withOpacity(0.07 * alpha),
              const Color(0xFF00BCD4).withOpacity(0.07 * alpha),
              Colors.transparent,
            ],
          ).createShader(brRect),
      );
    }

    // ── Light particles ──────────────────────────────────────────────
    final rng2 = math.Random(44);
    for (int i = 0; i < 35; i++) {
      final px = rng2.nextDouble() * s.width;
      final pyBase = rng2.nextDouble() * s.height;
      final phase = (particleT + i * 0.028) % 1.0;
      final py = pyBase - phase * 60;
      final palpha = math.sin(phase * math.pi) * 0.65;
      final pSize = 1.5 + rng2.nextDouble() * 3;

      canvas.drawCircle(
        Offset(px, py),
        pSize,
        Paint()
          ..color = const Color(0xFFFFFFFF).withOpacity(palpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // ── Gold sparkles over scene ─────────────────────────────────────
    final rng3 = math.Random(66);
    for (int i = 0; i < 12; i++) {
      final spx = rng3.nextDouble() * s.width;
      final spy = rng3.nextDouble() * s.height * 0.5;
      final phase = (particleT * 1.3 + i * 0.083) % 1.0;
      final salpha = math.sin(phase * math.pi) * 0.7;
      final sr = 2 + rng3.nextDouble() * 4;

      _drawStar4(
          canvas, Offset(spx, spy), sr, const Color(0xFFFFD740).withOpacity(salpha));
    }
  }

  void _drawStar4(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * 1, c.dy + math.sin(a) * 1),
        Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
        p,
      );
    }
    canvas.drawCircle(c, 1.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(BubbleParticlePainter o) =>
      o.bubbleT != bubbleT || o.particleT != particleT;
}
