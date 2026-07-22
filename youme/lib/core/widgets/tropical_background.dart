import 'package:flutter/material.dart';
import '../theme/colors.dart';

class TropicalBackground extends StatelessWidget {
  final Widget child;
  final bool showSunset;

  const TropicalBackground({super.key, required this.child, this.showSunset = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: showSunset ? AppColors.sunsetGradient : AppColors.skyGradient,
      ),
      child: Stack(
        children: [
          // Ocean shimmer
          Positioned(
            bottom: 0, left: 0, right: 0, height: 180,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.oceanBlue, Color(0xFF004B6B)],
                ),
              ),
            ),
          ),
          // Palm silhouettes
          Positioned(bottom: 80, left: -30,
            child: _PalmTree(height: 220, angle: 0.15, color: const Color(0x88155724))),
          Positioned(bottom: 60, right: -20,
            child: _PalmTree(height: 200, angle: -0.12, color: const Color(0x88155724))),
          Positioned(bottom: 120, left: 40,
            child: _PalmTree(height: 160, angle: 0.08, color: const Color(0x66155724))),
          // Bokeh circles
          ..._buildBokeh(),
          // Content
          child,
        ],
      ),
    );
  }

  List<Widget> _buildBokeh() {
    const circles = [
      (left: 20.0, top: 100.0, size: 80.0, opacity: 0.04),
      (left: 200.0, top: 50.0, size: 120.0, opacity: 0.03),
      (left: 320.0, top: 200.0, size: 60.0, opacity: 0.05),
      (left: 100.0, top: 300.0, size: 100.0, opacity: 0.03),
      (left: 280.0, top: 400.0, size: 70.0, opacity: 0.04),
    ];
    return circles.map((c) => Positioned(
      left: c.left, top: c.top,
      child: Container(
        width: c.size, height: c.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.turquoise.withOpacity(c.opacity),
          boxShadow: [BoxShadow(color: AppColors.turquoise.withOpacity(c.opacity * 2), blurRadius: c.size)],
        ),
      ),
    )).toList();
  }
}

class _PalmTree extends StatelessWidget {
  final double height;
  final double angle;
  final Color color;

  const _PalmTree({required this.height, required this.angle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(height * 0.25, height),
        painter: _PalmPainter(color: color),
      ),
    );
  }
}

class _PalmPainter extends CustomPainter {
  final Color color;
  _PalmPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = size.width * 0.3..strokeCap = StrokeCap.round;
    // Trunk
    canvas.drawLine(Offset(size.width / 2, size.height), Offset(size.width / 2, size.height * 0.2), paint);
    // Leaves
    final leafPaint = Paint()..color = color.withOpacity(0.7)..style = PaintingStyle.fill;
    final top = Offset(size.width / 2, size.height * 0.2);
    for (var i = 0; i < 6; i++) {
      final end = Offset(top.dx + size.height * 0.3 * (i.isEven ? 1 : -0.8) * 0.6,
                         top.dy - size.height * 0.25 * 0.6);
      canvas.drawLine(top, end, leafPaint..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
