import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Représente un fragment de l'explosion de l'ananas
class ExplosionParticle {
  final double angle;       // direction initiale (radians)
  final double speed;       // vitesse de départ
  final double rotSpeed;    // vitesse de rotation propre
  final Color color;
  final double size;
  final int shapeType;      // 0=triangle, 1=circle, 2=rect, 3=drop
  double x = 0;
  double y = 0;
  double rot = 0;
  double velX;
  double velY;
  double velRot;
  double gravity;
  double opacity;

  static final _rng = math.Random();

  ExplosionParticle({required this.angle, required this.speed, required this.rotSpeed,
      required this.color, required this.size, required this.shapeType})
      : velX = math.cos(angle) * speed,
        velY = math.sin(angle) * speed,
        velRot = rotSpeed,
        gravity = 0.5 + _rng.nextDouble() * 0.8,
        opacity = 1.0;

  static ExplosionParticle random(int index) {
    final rng = _rng;
    final angle = (index / 24) * math.pi * 2 + rng.nextDouble() * 0.8;
    final colors = [
      const Color(0xFFFDD835),
      const Color(0xFFFF6D00),
      const Color(0xFF66BB6A),
      const Color(0xFFE65100),
      const Color(0xFFF9A825),
      const Color(0xFFB9F6CA),
      const Color(0xFF43A047),
      Colors.white,
    ];
    return ExplosionParticle(
      angle: angle,
      speed: 4.0 + rng.nextDouble() * 8.0,
      rotSpeed: (rng.nextDouble() - 0.5) * 0.25,
      color: colors[index % colors.length],
      size: 6.0 + rng.nextDouble() * 20.0,
      shapeType: index % 4,
    );
  }

  /// Met à jour la physique
  void update() {
    velY += gravity * 0.016 * 60;   // 60fps normalisé
    velX *= 0.98;                    // friction air
    x += velX;
    y += velY;
    rot += velRot;
    opacity = (opacity - 0.008).clamp(0.0, 1.0);
  }

  /// Dessine le fragment sur le canvas
  void draw(Canvas canvas) {
    if (opacity <= 0) return;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    switch (shapeType) {
      case 0: // triangle
        final path = Path()
          ..moveTo(0, -size / 2)
          ..lineTo(size / 2, size / 2)
          ..lineTo(-size / 2, size / 2)
          ..close();
        canvas.drawPath(path, paint);
      case 1: // circle
        canvas.drawCircle(Offset.zero, size / 2, paint);
        canvas.drawCircle(
          Offset(-size * 0.15, -size * 0.15),
          size * 0.18,
          Paint()..color = Colors.white.withOpacity(opacity * 0.5),
        );
      case 2: // rect
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.6),
            const Radius.circular(3),
          ),
          paint,
        );
      case 3: // drop (forme ananas)
        final dPath = Path()
          ..moveTo(0, -size * 0.6)
          ..cubicTo(size * 0.4, -size * 0.3, size * 0.4, size * 0.3, 0, size * 0.6)
          ..cubicTo(-size * 0.4, size * 0.3, -size * 0.4, -size * 0.3, 0, -size * 0.6);
        canvas.drawPath(dPath, paint);
    }

    canvas.restore();
  }
}

/// Particule de poussière tropicale
class DustParticle {
  double x, y, radius, opacity, velX, velY;
  final Color color;

  static final _rng = math.Random();

  DustParticle({required this.x, required this.y})
      : radius = 8.0 + _rng.nextDouble() * 20.0,
        opacity = 0.4 + _rng.nextDouble() * 0.4,
        velX = (_rng.nextDouble() - 0.5) * 3,
        velY = -1.0 - _rng.nextDouble() * 2.0,
        color = [
          const Color(0xFFFFE082),
          const Color(0xFFA5D6A7),
          Colors.white,
        ][_rng.nextInt(3)];

  void update() {
    x += velX;
    y += velY;
    radius += 0.8;
    opacity = (opacity - 0.012).clamp(0.0, 1.0);
  }

  void draw(Canvas canvas) {
    if (opacity <= 0) return;
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..color = color.withOpacity(opacity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}

/// Éclat lumineux
class LightBurst {
  double x, y, radius, opacity;
  final Color color;
  final double angle;

  static final _rng = math.Random();

  LightBurst({required this.x, required this.y, required this.angle})
      : radius = 2.0 + _rng.nextDouble() * 8.0,
        opacity = 0.8 + _rng.nextDouble() * 0.2,
        color = [
          Colors.white,
          const Color(0xFFFFE082),
          const Color(0xFFFFF9C4),
        ][_rng.nextInt(3)];

  void update() {
    x += math.cos(angle) * 5;
    y += math.sin(angle) * 5;
    opacity = (opacity - 0.02).clamp(0.0, 1.0);
  }

  void draw(Canvas canvas) {
    if (opacity <= 0) return;
    // Glow
    canvas.drawCircle(
      Offset(x, y),
      radius * 3,
      Paint()
        ..color = color.withOpacity(opacity * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Point brillant
    canvas.drawCircle(Offset(x, y), radius, Paint()..color = color.withOpacity(opacity));
  }
}
