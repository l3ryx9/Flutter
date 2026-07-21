import 'package:flutter/material.dart';
import '../theme/colors.dart';

class WoodButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? accentColor;

  const WoodButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
    this.accentColor,
  });

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B5E3C),
                    Color(0xFF5C3317),
                    Color(0xFF3D1F0B),
                    Color(0xFF5C3317),
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: AppColors.glowGold.withOpacity(0.3 + _glowAnim.value * 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                  const BoxShadow(
                    color: Color(0x33FFFFFF),
                    blurRadius: 2,
                    offset: Offset(0, -1),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: AppColors.goldBorder.withOpacity(0.8),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // Wood grain texture lines
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: CustomPaint(painter: _WoodGrainPainter()),
                    ),
                  ),
                  // Top gloss
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: widget.height * 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(17),
                          topRight: Radius.circular(17),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.goldLight,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon, color: AppColors.goldLight, size: 20),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.label,
                                style: const TextStyle(
                                  fontFamily: 'Playfair',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldLight,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 8; i++) {
      final y = size.height * (i + 0.5) / 8;
      final path = Path()
        ..moveTo(0, y + (i.isEven ? 2 : -2))
        ..quadraticBezierTo(size.width * 0.4, y + (i.isEven ? -3 : 3),
            size.width * 0.7, y + (i.isEven ? 2 : -1))
        ..quadraticBezierTo(size.width * 0.85, y + (i.isEven ? -1 : 2),
            size.width, y + (i.isEven ? 1 : -1));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
