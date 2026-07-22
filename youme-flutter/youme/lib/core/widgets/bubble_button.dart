import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// BUBBLE BUTTON — Effet 3D Glossy Premium
// ═══════════════════════════════════════════════════════════════════════════

class BubbleButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color color;
  final double width;
  final double height;
  final double fontSize;

  const BubbleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = const Color(0xFF00BCD4),
    this.width = 280,
    this.height = 58,
    this.fontSize = 16,
  });

  @override
  State<BubbleButton> createState() => _BubbleButtonState();
}

class _BubbleButtonState extends State<BubbleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;
  late final Animation<double> _compress;

  bool _pressed = false;
  Offset? _tapPos;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _compress = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d) {
    setState(() {
      _pressed = true;
      _tapPos = d.localPosition;
    });
  }

  void _onTapUp(TapUpDetails d) {
    setState(() => _pressed = false);
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final scale = _pressed ? 0.93 : _pulse.value;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(38),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(_pressed ? 0.2 : 0.45),
                    blurRadius: _pressed ? 8 : 24,
                    spreadRadius: _pressed ? 0 : 2,
                    offset: Offset(0, _pressed ? 4 : 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: CustomPaint(
                  painter: _BubblePainter(
                    color: widget.color,
                    pressed: _pressed,
                    tapPos: _tapPos,
                    pulse: _ctrl.value,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            shadows: const [
                              Shadow(
                                color: Color(0x50000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────

class _BubblePainter extends CustomPainter {
  final Color color;
  final bool pressed;
  final Offset? tapPos;
  final double pulse;

  _BubblePainter({
    required this.color,
    required this.pressed,
    required this.tapPos,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(38));

    // Base gradient (dark at bottom)
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _lighten(color, 0.25),
            color,
            _darken(color, 0.20),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Inner glow (3D depth)
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.7),
          radius: 1.1,
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Top specular highlight (glossy pill)
    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, 4, size.width * 0.7, size.height * 0.38),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      highlightRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.55),
            Colors.white.withOpacity(0.05),
          ],
        ).createShader(highlightRect.outerRect),
    );

    // Ripple effect on tap
    if (pressed && tapPos != null) {
      canvas.save();
      canvas.clipRRect(rrect);
      final rp = pulse * 160 + 30;
      canvas.drawCircle(
        tapPos!,
        rp,
        Paint()..color = Colors.white.withOpacity((1 - pulse) * 0.22),
      );
      canvas.restore();
    }

    // Bottom rim light
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(_BubblePainter o) =>
      o.pressed != pressed || o.pulse != pulse || o.tapPos != tapPos;
}

// ═══════════════════════════════════════════════════════════════════════════
// SECONDARY BUTTON — Ghost style
// ═══════════════════════════════════════════════════════════════════════════

class BubbleOutlineButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color color;
  final double width;
  final double height;

  const BubbleOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = Colors.white,
    this.width = 280,
    this.height = 58,
  });

  @override
  State<BubbleOutlineButton> createState() => _BubbleOutlineButtonState();
}

class _BubbleOutlineButtonState extends State<BubbleOutlineButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final pulse = 1.0 + math.sin(_ctrl.value * math.pi) * 0.02;
        return Transform.scale(
          scale: _pressed ? 0.94 : pulse,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(38),
                border: Border.all(
                  color: widget.color.withOpacity(0.7),
                  width: 2,
                ),
                color: Colors.white.withOpacity(_pressed ? 0.15 : 0.1),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.color, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
