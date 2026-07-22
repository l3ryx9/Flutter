import 'package:flutter/material.dart';
import '../theme/colors.dart';

class WoodAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;

  const WoodAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A4A2A), Color(0xFF4A2510), Color(0xFF6B3D1E)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: AppColors.glowGold.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 2)),
        ],
        border: const Border(bottom: BorderSide(color: AppColors.goldBorder, width: 1)),
      ),
      child: Row(
        children: [
          if (showBack)
            _CircularWoodButton(
              icon: Icons.arrow_back_ios_new,
              onTap: onBack ?? () => Navigator.of(context).pop(),
            )
          else if (leading != null)
            leading!
          else
            const SizedBox(width: 16),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Playfair',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldLight,
                  letterSpacing: 1.5,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
            ),
          ),
          if (actions != null)
            Row(mainAxisSize: MainAxisSize.min, children: actions!)
          else
            const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _CircularWoodButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircularWoodButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [AppColors.woodLight, AppColors.woodMedium, AppColors.woodDark],
          ),
          border: Border.all(color: AppColors.goldBorder.withValues(alpha: 0.7), width: 1.5),
          boxShadow: [
            const BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
            BoxShadow(color: AppColors.glowGold.withValues(alpha: 0.2), blurRadius: 10),
          ],
        ),
        child: Icon(icon, color: AppColors.goldLight, size: 18),
      ),
    );
  }
}
