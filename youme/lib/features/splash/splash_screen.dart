import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/colors.dart';
import '../../core/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Cubic(0.34, 1.56, 0.64, 1)));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.6)));
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(_textController);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutExpo));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) _navigate();
  }

  void _navigate() {
    final session = Supabase.instance.client.auth.currentSession;
    context.go(session != null ? AppRoutes.home : AppRoutes.login);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.sunsetGradient),
        child: Stack(
          children: [
            // Ocean
            Positioned(bottom: 0, left: 0, right: 0, height: 200,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.oceanBlue]),
                ),
              ),
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [AppColors.goldLight, AppColors.goldPrimary, AppColors.goldDark],
                            ),
                            boxShadow: [
                              BoxShadow(color: AppColors.glowGold.withValues(alpha: 0.8), blurRadius: 40, spreadRadius: 8),
                              const BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8)),
                            ],
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                          ),
                          child: const Center(
                            child: Text('💑', style: TextStyle(fontSize: 64)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Text
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => Opacity(
                      opacity: _textOpacity.value,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            const Text('YouMe',
                              style: TextStyle(fontFamily: 'Playfair', fontSize: 52,
                                fontWeight: FontWeight.bold, color: AppColors.goldLight,
                                letterSpacing: 4,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Votre espace à deux',
                              style: TextStyle(fontFamily: 'Lato', fontSize: 16,
                                color: AppColors.textPrimary.withValues(alpha: 0.8),
                                letterSpacing: 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Loading indicator
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => Opacity(
                      opacity: _textOpacity.value,
                      child: SizedBox(
                        width: 40, height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.goldPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
