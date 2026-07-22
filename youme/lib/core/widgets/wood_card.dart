import 'package:flutter/material.dart';
import '../theme/colors.dart';

class WoodCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool showGoldBorder;
  final VoidCallback? onTap;
  final double elevation;

  const WoodCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.showGoldBorder = true,
    this.onTap,
    this.elevation = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7A4A2A),
              Color(0xFF5C3317),
              Color(0xFF3D1F0B),
              Color(0xFF5C3317),
              Color(0xFF6B3D1E),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: elevation,
              offset: Offset(0, elevation / 2),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: AppColors.glowGold.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 0),
              spreadRadius: -2,
            ),
            const BoxShadow(
              color: Color(0x22FFFFFF),
              blurRadius: 2,
              offset: Offset(0, -1),
              spreadRadius: 0,
            ),
          ],
          border: showGoldBorder
              ? Border.all(color: AppColors.goldBorder.withValues(alpha: 0.6), width: 1)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // Top gloss
              Positioned(
                top: 0, left: 0, right: 0,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
            ],
          ),
        ),
      ),
    );
  }
}
