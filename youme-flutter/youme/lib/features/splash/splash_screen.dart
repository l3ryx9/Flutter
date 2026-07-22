import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SPLASH SCREEN — Ananas 3D + Explosion + YouMe
// ═══════════════════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ─── Controllers ────────────────────────────────────────────────────────
  late final AnimationController _timelineCtrl;
  late final AnimationController _shimmerCtrl;

  // ─── Animations ─────────────────────────────────────────────────────────
  late final Animation<double> _pineappleScale;
  late final Animation<double> _pineappleOpacity;
  late final Animation<double> _explosionProgress;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textScale;
  late final Animation<double> _fadeOut;

  // ─── Explosion data ─────────────────────────────────────────────────────
  final List<_Piece> _pieces = [];
  final _rng = math.Random(42);

  static const _pieceColors = [
    Color(0xFFF9A825), Color(0xFFE65100), Color(0xFF2E7D32),
    Color(0xFF1B5E20), Color(0xFFFDD835), Color(0xFFFF8F00),
    Color(0xFFFFCC02), Color(0xFF558B2F), Color(0xFFF57F17),
  ];

  @override
  void initState() {
    super.initState();
    _buildPieces();

    _timelineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          context.go(AppRoutes.login);
        }
      });

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Pineapple enters: 0 → 22%
    _pineappleScale = CurvedAnimation(
      parent: _timelineCtrl,
      curve: const Interval(0.00, 0.22, curve: Curves.elasticOut),
    );

    // Pineapple fades at explosion: 30% → 44%
    _pineappleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(0.30, 0.44, curve: Curves.easeOut),
      ),
    );

    // Explosion scatter: 30% → 74%
    _explosionProgress = CurvedAnimation(
      parent: _timelineCtrl,
      curve: const Interval(0.30, 0.74, curve: Curves.easeOut),
    );

    // Text appears: 44% → 72%
    _textOpacity = CurvedAnimation(
      parent: _timelineCtrl,
      curve: const Interval(0.44, 0.70, curve: Curves.easeIn),
    );

    _textScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(0.44, 0.74, curve: Curves.elasticOut),
      ),
    );

    // Fade out: 87% → 100%
    _fadeOut = CurvedAnimation(
      parent: _timelineCtrl,
      curve: const Interval(0.87, 1.00, curve: Curves.easeInOut),
    );

    _timelineCtrl.forward();
  }

  void _buildPieces() {
    for (int i = 0; i < 32; i++) {
      final angle = (i / 32) * 2 * math.pi + _rng.nextDouble() * 0.35;
      _pieces.add(_Piece(
        angle: angle,
        speed: 100 + _rng.nextDouble() * 300,
        rotSpeed: (_rng.nextDouble() - 0.5) * 12,
        size: 6 + _rng.nextDouble() * 20,
        color: _pieceColors[_rng.nextInt(_pieceColors.length)],
        shape: _rng.nextInt(3),
        gravity: 60 + _rng.nextDouble() * 140,
      ));
    }
  }

  @override
  void dispose() {
    _timelineCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_timelineCtrl, _shimmerCtrl]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background
              CustomPaint(painter: _SplashBgPainter(_timelineCtrl.value), size: size),

              // Explosion pieces
              if (_explosionProgress.value > 0)
                CustomPaint(
                  painter: _ExplosionPainter(
                    pieces: _pieces,
                    progress: _explosionProgress.value,
                    center: Offset(size.width / 2, size.height / 2),
                  ),
                  size: size,
                ),

              // 3D Pineapple
              if (_pineappleOpacity.value > 0)
                Center(
                  child: Opacity(
                    opacity: _pineappleOpacity.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _pineappleScale.value,
                      child: CustomPaint(
                        painter: _Pineapple3DPainter(),
                        size: const Size(130, 165),
                      ),
                    ),
                  ),
                ),

              // YouMe text
              if (_textOpacity.value > 0)
                Center(
                  child: Opacity(
                    opacity: _textOpacity.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _textScale.value,
                      child: _ShimmerText(shimmer: _shimmerCtrl.value),
                    ),
                  ),
                ),

              // Fade to white
              if (_fadeOut.value > 0)
                Opacity(
                  opacity: _fadeOut.value.clamp(0.0, 1.0),
                  child: const ColoredBox(color: Colors.white),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA
// ═══════════════════════════════════════════════════════════════════════════

class _Piece {
  final double angle, speed, rotSpeed, size, gravity;
  final Color color;
  final int shape;
  const _Piece({
    required this.angle,
    required this.speed,
    required this.rotSpeed,
    required this.size,
    required this.color,
    required this.shape,
    required this.gravity,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER — Background splash
// ═══════════════════════════════════════════════════════════════════════════

class _SplashBgPainter extends CustomPainter {
  final double t;
  _SplashBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Sky gradient
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071A35),
            Color(0xFF0A3A6E),
            Color(0xFF0D6EAD),
            Color(0xFF00A8C6),
            Color(0xFF00D4A8),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(rect),
    );

    // Glow orb
    final glowOpacity = (math.sin(t * math.pi) * 0.4).clamp(0.0, 0.4);
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.5,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 220, 60, glowOpacity),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(
            center: Offset(cx, cy), radius: size.width * 0.5)),
    );

    // Stars
    final rng = math.Random(13);
    for (int i = 0; i < 80; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height * 0.6;
      final r = 0.5 + rng.nextDouble() * 1.8;
      final twinkle = (math.sin(t * 5 + i * 1.1) * 0.4 + 0.6).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(sx, sy),
        r,
        Paint()..color = Colors.white.withOpacity(0.55 * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(_SplashBgPainter o) => o.t != t;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER — 3D Pineapple
// ═══════════════════════════════════════════════════════════════════════════

class _Pineapple3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.60;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 14), width: 78, height: 20),
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Body oval
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy - 8),
      width: 78,
      height: 94,
    );

    // 3D radial gradient
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: const [
            Color(0xFFFFF59D),
            Color(0xFFF9A825),
            Color(0xFFE65100),
            Color(0xFFBF360C),
          ],
          stops: const [0.0, 0.4, 0.75, 1.0],
        ).createShader(bodyRect),
    );

    // Diamond cross-hatch
    _drawDiamonds(canvas, cx, cy - 8, 39, 47);

    // Specular highlight
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 0.55,
          colors: [Colors.white.withOpacity(0.55), Colors.transparent],
        ).createShader(bodyRect),
    );

    // Rim
    canvas.drawOval(
      bodyRect,
      Paint()
        ..color = const Color(0xFFC77B0A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Crown
    _drawCrown(canvas, cx, cy - 55);
  }

  void _drawDiamonds(Canvas canvas, double cx, double cy, double rx, double ry) {
    canvas.save();
    canvas.clipOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));
    final paint = Paint()
      ..color = const Color(0xFFC77B0A).withOpacity(0.45)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    const cols = 7;
    const rows = 10;
    final dw = rx * 2 / cols;
    final dh = ry * 2 / rows;
    for (int row = 0; row <= rows; row++) {
      for (int col = 0; col <= cols; col++) {
        final x = cx - rx + col * dw + (row.isOdd ? dw / 2 : 0);
        final y = cy - ry + row * dh;
        canvas.drawPath(
          Path()
            ..moveTo(x, y - dh * 0.38)
            ..lineTo(x + dw * 0.42, y)
            ..lineTo(x, y + dh * 0.38)
            ..lineTo(x - dw * 0.42, y)
            ..close(),
          paint,
        );
      }
    }
    canvas.restore();
  }

  void _drawCrown(Canvas canvas, double cx, double baseY) {
    final leafDefs = [
      (0.0, -1.0, 0.0),
      (-0.55, -0.92, -30.0),
      (-0.88, -0.70, -52.0),
      (-1.05, -0.42, -68.0),
      (0.55, -0.92, 30.0),
      (0.88, -0.70, 52.0),
      (1.05, -0.42, 68.0),
    ];
    for (final (dx, dy, ang) in leafDefs) {
      canvas.save();
      canvas.translate(cx + dx * 12, baseY + dy * 8);
      canvas.rotate(ang * math.pi / 180);
      _drawLeaf(canvas, ang.abs() / 90);
      canvas.restore();
    }
  }

  void _drawLeaf(Canvas canvas, double shadow) {
    final d = shadow.clamp(0.0, 1.0) * 0.4;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-9, -14, 0, -38)
      ..quadraticBezierTo(9, -14, 0, 0);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF81C784), const Color(0xFF1B5E20), d)!,
            Color.lerp(const Color(0xFF388E3C), const Color(0xFF1B5E20), d + 0.3)!,
          ],
        ).createShader(const Rect.fromLTWH(-10, -42, 20, 42)),
    );
    canvas.drawLine(
      Offset.zero,
      const Offset(0, -36),
      Paint()
        ..color = const Color(0xFF1B5E20).withOpacity(0.5)
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER — Explosion
// ═══════════════════════════════════════════════════════════════════════════

class _ExplosionPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double progress;
  final Offset center;

  const _ExplosionPainter(
      {required this.pieces, required this.progress, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final tCurved = math.pow(t, 0.55).toDouble();

    for (final p in pieces) {
      final dist = p.speed * tCurved;
      final grav = p.gravity * t * t;
      final x = center.dx + math.cos(p.angle) * dist;
      final y = center.dy + math.sin(p.angle) * dist + grav;
      final rot = p.rotSpeed * t * math.pi;
      final alpha = (1.0 - math.pow(t, 1.6)).clamp(0.0, 1.0).toDouble();
      if (alpha <= 0) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);

      final s = p.size * (1.0 + t * 0.4);
      final paint = Paint()..color = p.color.withOpacity(alpha);

      switch (p.shape) {
        case 0:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.55),
              const Radius.circular(3),
            ),
            paint,
          );
        case 1:
          canvas.drawPath(
            Path()
              ..moveTo(0, -s * 0.58)
              ..lineTo(s * 0.5, s * 0.5)
              ..lineTo(-s * 0.5, s * 0.5)
              ..close(),
            paint,
          );
        default:
          canvas.drawPath(
            Path()
              ..moveTo(0, -s * 0.5)
              ..lineTo(s * 0.42, 0)
              ..lineTo(0, s * 0.5)
              ..lineTo(-s * 0.42, 0)
              ..close(),
            paint,
          );
      }

      // Glint
      if (alpha > 0.25) {
        canvas.drawCircle(
          Offset(-s * 0.22, -s * 0.22),
          s * 0.14,
          Paint()
            ..color = Colors.white.withOpacity(alpha * 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.restore();
    }

    // Central dust cloud
    if (t > 0.04 && t < 0.65) {
      final op = (math.sin(t / 0.65 * math.pi) * 0.28).clamp(0.0, 0.28);
      canvas.drawCircle(
        center,
        55 + t * 90,
        Paint()
          ..color = Color.fromRGBO(255, 215, 120, op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
    }
  }

  @override
  bool shouldRepaint(_ExplosionPainter o) => o.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET — Shimmer text
// ═══════════════════════════════════════════════════════════════════════════

class _ShimmerText extends StatelessWidget {
  final double shimmer;
  const _ShimmerText({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final s = shimmer * 1.7 - 0.35;
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFFFF9C4),
          Color(0xFFFFFFFF),
          Color(0xFFB3E5FC),
          Color(0xFFFFFFFF),
        ],
        stops: [
          (s - 0.35).clamp(0.0, 1.0),
          (s - 0.06).clamp(0.0, 1.0),
          s.clamp(0.0, 1.0),
          (s + 0.06).clamp(0.0, 1.0),
          (s + 0.35).clamp(0.0, 1.0),
        ],
      ).createShader(bounds),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'YouMe',
            style: TextStyle(
              fontSize: 78,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 8,
              height: 1.0,
              shadows: [
                Shadow(
                  color: Color(0x60000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
                Shadow(
                  color: Color(0x4000BFFF),
                  blurRadius: 45,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 2.5,
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [Colors.transparent, Colors.white, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tropical Edition',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 5,
            ),
          ),
        ],
      ),
    );
  }
}
