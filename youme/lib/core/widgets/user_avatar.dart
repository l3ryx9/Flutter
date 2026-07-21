import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/colors.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final double size;
  final bool isOnline;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.size = 48,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 6,
        height: size + 6,
        child: Stack(
          children: [
            Container(
              width: size + 6,
              height: size + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.goldLight, AppColors.goldDark, AppColors.goldPrimary],
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.glowGold, blurRadius: 12, spreadRadius: 1),
                  const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.woodDark, width: 2),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          width: size,
                          height: size,
                          placeholder: (_, __) => _placeholder(),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: size * 0.28,
                  height: size * 0.28,
                  decoration: BoxDecoration(
                    color: AppColors.onlineGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.woodDark, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onlineGreen.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    final initials = displayName != null && displayName!.isNotEmpty
        ? displayName!.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    return Container(
      color: AppColors.woodSurface,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'Playfair',
            color: AppColors.goldLight,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
