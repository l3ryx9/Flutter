import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Peint un ananas 3D en plein centre – utilisé sur le splash screen
class PineapplePainter extends CustomPainter {
  final double scale;       // zoom ou explosion scale
  final double rotation;    // rotation en radians
  final double opacity;

  PineapplePainter({
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);
    canvas.scale(scale);

    final paint = Paint()..style = PaintingStyle.fill;

    // Ombre
    paint.color = Colors.black.withOpacity(0.18 * opacity);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(Rect.fromCenter(center: Offset(8, 60), width: 90, height: 28), paint);
    paint.maskFilter = null;

    // Corps
    final bodyRect = Rect.fromCenter(center: Offset.zero, width: 80, height: 110);
    final bodyGrad = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      colors: [
        Colors.yellow.shade100.withOpacity(opacity),
        const Color(0xFFFDD835).withOpacity(opacity),
        const Color(0xFFF9A825).withOpacity(opacity),
        const Color(0xFFE65100).withOpacity(opacity),
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
    );
    canvas.drawOval(bodyRect, Paint()..shader = bodyGrad.createShader(bodyRect));

    // Texture diamant
    _drawTexture(canvas, opacity);

    // Reflet
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-16, -26), width: 28, height: 38),
      Paint()
        ..color = Colors.white.withOpacity(0.4 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Couronne
    _drawCrown(canvas, opacity);

    canvas.restore();
  }

  void _drawTexture(Canvas canvas, double opacity) {
    final paint = Paint()
      ..color = const Color(0xFFE65100).withOpacity(0.30 * opacity)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    for (int row = -5; row <= 5; row++) {
      for (int col = -3; col <= 3; col++) {
        final ox = col * 14.0 + (row % 2 == 0 ? 0 : 7.0);
        final oy = row * 10.0;
        final inX = ox / 38;
        final inY = oy / 52;
        if (inX * inX + inY * inY < 0.92) {
          final path = Path()
            ..moveTo(ox, oy - 4)
            ..lineTo(ox + 5, oy)
            ..lineTo(ox, oy + 4)
            ..lineTo(ox - 5, oy)
            ..close();
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  void _drawCrown(Canvas canvas, double opacity) {
    const leafData = [
      [-90, 70],
      [-70, 62],
      [-50, 55],
      [-110, 62],
      [-130, 55],
    ];
    for (final d in leafData) {
      final angle = d[0] * math.pi / 180;
      final len = d[1].toDouble();
      final tip = Offset(math.cos(angle) * len, math.sin(angle) * len);
      final perp = Offset(-math.sin(angle), math.cos(angle));
      final w = 7.0;
      final base = const Offset(0, -52);

      final path = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          base.dx + perp.dx * w + math.cos(angle) * len * 0.45,
          base.dy + perp.dy * w + math.sin(angle) * len * 0.45,
          tip.dx, tip.dy,
        )
        ..quadraticBezierTo(
          base.dx - perp.dx * w + math.cos(angle) * len * 0.45,
          base.dy - perp.dy * w + math.sin(angle) * len * 0.45,
          base.dx, base.dy,
        );

      final rect = Rect.fromPoints(base, tip);
      final grad = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF2E7D32).withOpacity(opacity),
          const Color(0xFF66BB6A).withOpacity(opacity),
          const Color(0xFFB9F6CA).withOpacity(opacity),
        ],
      );
      canvas.drawPath(path, Paint()..shader = grad.createShader(rect));
    }
  }

  @override
  bool shouldRepaint(PineapplePainter old) =>
      old.scale != scale || old.rotation != rotation || old.opacity != opacity;
}
