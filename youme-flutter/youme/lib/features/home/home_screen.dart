import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/painters/tropical_paradise_painter.dart';
import '../../core/widgets/bubble_button.dart';
import '../../core/router/app_router.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HOME SCREEN — Tropical Paradise 3D
// ═══════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      extendBodyBehindAppBar: true,
      body: _TropicalHomeBody(),
    );
  }
}

class _TropicalHomeBody extends StatelessWidget {
  const _TropicalHomeBody();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return TropicalParadise(
      child: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GlassChip(
                    icon: Icons.wb_sunny_rounded,
                    label: 'YouMe',
                    iconColor: const Color(0xFFFFD740),
                  ),
                  _GlassChip(
                    icon: Icons.notifications_rounded,
                    label: '3',
                    iconColor: Colors.white,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Center card ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _GlassCard(
                child: Column(
                  children: [
                    const Text(
                      '🌴 Bienvenue',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'YouMe',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: Color(0x50000000),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tropical Edition',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.55),
                        letterSpacing: 5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatBubble(label: 'Messages', value: '24'),
                        _StatBubble(label: 'Contacts', value: '138'),
                        _StatBubble(label: 'En ligne', value: '7'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Action buttons ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  BubbleButton(
                    label: 'Messages',
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF00BCD4),
                    width: size.width - 64,
                    onPressed: () => context.go('${AppRoutes.home}/conversations'),
                  ),
                  const SizedBox(height: 14),
                  BubbleButton(
                    label: 'Contacts',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF26A69A),
                    width: size.width - 64,
                    onPressed: () => context.go('${AppRoutes.home}/contacts'),
                  ),
                  const SizedBox(height: 14),
                  BubbleButton(
                    label: 'Recherche IA',
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFFAB47BC),
                    width: size.width - 64,
                    onPressed: () => context.go('${AppRoutes.home}/ai-search'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: BubbleButton(
                          label: 'Profil',
                          icon: Icons.person_rounded,
                          color: const Color(0xFF42A5F5),
                          width: double.infinity,
                          height: 52,
                          fontSize: 14,
                          onPressed: () => context.go('${AppRoutes.home}/profile'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BubbleButton(
                          label: 'Réglages',
                          icon: Icons.tune_rounded,
                          color: const Color(0xFF66BB6A),
                          width: double.infinity,
                          height: 52,
                          fontSize: 14,
                          onPressed: () =>
                              context.go('${AppRoutes.home}/settings'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GLASS CARD
// ═══════════════════════════════════════════════════════════════════════════

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.12),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GLASS CHIP
// ═══════════════════════════════════════════════════════════════════════════

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _GlassChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAT BUBBLE
// ═══════════════════════════════════════════════════════════════════════════

class _StatBubble extends StatelessWidget {
  final String label;
  final String value;

  const _StatBubble({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
