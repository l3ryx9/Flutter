import 'package:flutter/material.dart';
import '../theme/colors.dart';

class WoodBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  static const _items = [
    (icon: Icons.chat_bubble, label: 'Messages'),
    (icon: Icons.people, label: 'Contacts'),
    (icon: Icons.psychology, label: 'IA'),
    (icon: Icons.settings, label: 'Réglages'),
  ];

  const WoodBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF8B5E3C), Color(0xFF4A2510), Color(0xFF6B3D1E)],
        ),
        boxShadow: [
          const BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8), spreadRadius: 2),
          BoxShadow(color: AppColors.glowGold.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 4)),
          const BoxShadow(color: Color(0x22FFFFFF), blurRadius: 2, offset: Offset(0, -1)),
        ],
        border: Border.all(color: AppColors.goldBorder.withOpacity(0.6), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(31),
        child: Stack(
          children: [
            // Top gloss
            Positioned(top: 0, left: 0, right: 0, height: 30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0.12), Colors.transparent],
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(_items.length, (i) {
                final isSelected = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutExpo,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutExpo,
                            width: isSelected ? 52 : 40,
                            height: isSelected ? 52 : 40,
                            decoration: isSelected ? BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [AppColors.goldLight, AppColors.goldPrimary, AppColors.goldDark],
                              ),
                              boxShadow: [
                                BoxShadow(color: AppColors.glowGold.withOpacity(0.6), blurRadius: 16, spreadRadius: 2),
                                const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                              ],
                            ) : null,
                            child: Icon(
                              _items[i].icon,
                              color: isSelected ? AppColors.woodDark : AppColors.textMuted,
                              size: isSelected ? 26 : 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.goldLight : AppColors.textMuted,
                            ),
                            child: Text(_items[i].label),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
