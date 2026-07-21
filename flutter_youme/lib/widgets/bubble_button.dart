import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Bouton Bubble 3D Premium avec animations élastiques
class BubbleButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double width;
  final double height;
  final TextStyle? textStyle;
  final Widget? icon;

  const BubbleButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color = const Color(0xFF00B4D8),
    this.textColor = Colors.white,
    this.width = 260,
    this.height = 58,
    this.textStyle,
    this.icon,
  });

  @override
  State<BubbleButton> createState() => _BubbleButtonState();
}

class _BubbleButtonState extends State<BubbleButton>
    with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final AnimationController _pulseController;
  late final AnimationController _rippleController;

  late final Animation<double> _scaleAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _rippleAnim;

  bool _isPressed = false;
  Offset _rippleOffset = Offset.zero;

  @override
  void initState() {
    super.initState();

    // Press / release élastique
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );

    // Pulsation permanente
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ripple
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _handleTapDown(TapDownDetails details) async {
    setState(() {
      _isPressed = true;
      _rippleOffset = details.localPosition;
    });
    _pressController.forward();
    _rippleController.forward(from: 0);
  }

  Future<void> _handleTapUp(TapUpDetails details) async {
    await _pressController.reverse();
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    _pressController.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnim, _pulseAnim, _rippleAnim]),
      builder: (context, child) {
        final scale = _isPressed ? _scaleAnim.value : _pulseAnim.value;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onPressed,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: CustomPaint(
                painter: _BubbleButtonPainter(
                  color: widget.color,
                  isPressed: _isPressed,
                  rippleProgress: _rippleAnim.value,
                  rippleOffset: _rippleOffset,
                  buttonSize: Size(widget.width, widget.height),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.text,
                        style: widget.textStyle ??
                            TextStyle(
                              color: widget.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 1),
                                  blurRadius: 4,
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
        );
      },
    );
  }
}

class _BubbleButtonPainter extends CustomPainter {
  final Color color;
  final bool isPressed;
  final double rippleProgress;
  final Offset rippleOffset;
  final Size buttonSize;

  _BubbleButtonPainter({
    required this.color,
    required this.isPressed,
    required this.rippleProgress,
    required this.rippleOffset,
    required this.buttonSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // ── Ombre portée (profondeur) ──
    final shadowPaint = Paint()
      ..color = color.withOpacity(isPressed ? 0.25 : 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isPressed ? 6 : 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.translate(0, isPressed ? 2 : 6),
        Radius.circular(radius),
      ),
      shadowPaint,
    );

    // ── Corps du bouton (gradient 3D) ──
    final bodyGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(Colors.white, color, 0.35)!,
        color,
        Color.lerp(color, Colors.black, 0.2)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawRRect(rrect, Paint()..shader = bodyGrad.createShader(rect));

    // ── Bordure glossy ──
    final borderGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.6),
        Colors.white.withOpacity(0.1),
      ],
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = borderGrad.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Reflet lumineux (haut) ──
    final highlightRect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.06,
      size.width * 0.8,
      size.height * 0.38,
    );
    final hlRRect = RRect.fromRectAndRadius(highlightRect, Radius.circular(radius * 0.8));
    final hlGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(isPressed ? 0.25 : 0.45),
        Colors.white.withOpacity(0.0),
      ],
    );
    canvas.drawRRect(hlRRect, Paint()..shader = hlGrad.createShader(highlightRect));

    // ── Ripple personnalisé ──
    if (rippleProgress > 0 && rippleProgress < 1) {
      final maxRadius = math.sqrt(
        math.pow(size.width, 2) + math.pow(size.height, 2),
      );
      final rippleRadius = maxRadius * rippleProgress;
      final rippleOpacity = (1 - rippleProgress) * 0.35;

      canvas.clipRRect(rrect);
      canvas.drawCircle(
        rippleOffset,
        rippleRadius,
        Paint()..color = Colors.white.withOpacity(rippleOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BubbleButtonPainter old) =>
      old.isPressed != isPressed ||
      old.rippleProgress != rippleProgress ||
      old.color != color;
}
