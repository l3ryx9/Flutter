import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../painters/sky_painter.dart';
import '../painters/sea_painter.dart';
import '../painters/beach_painter.dart';
import '../painters/palm_tree_painter.dart';
import '../painters/tropical_elements_painter.dart';
import '../painters/atmosphere_painter.dart';
import '../widgets/bubble_button.dart';

/// Page de connexion sur fond de paradis tropical animé
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // Contrôleurs principaux
  late final AnimationController _mainController;        // 8s loop
  late final AnimationController _waveController;        // 4s loop
  late final AnimationController _swayController;        // 6s loop
  late final AnimationController _bubbleController;      // 12s loop
  late final AnimationController _shimmerController;     // 3s loop

  // Contrôleur d'entrée de la page
  late final AnimationController _pageEntryController;
  late final Animation<double> _pageEntry;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _swayController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _bubbleController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _pageEntryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pageEntry = CurvedAnimation(parent: _pageEntryController, curve: Curves.easeOutCubic);
    _pageEntryController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _waveController.dispose();
    _swayController.dispose();
    _bubbleController.dispose();
    _shimmerController.dispose();
    _pageEntryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController, _waveController, _swayController,
          _bubbleController, _shimmerController, _pageEntry,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // ── Scène tropicale (calques de peinture) ──────────────────
              Positioned.fill(child: CustomPaint(
                painter: SkyPainter(
                  animValue: _mainController.value,
                  shimmerValue: _shimmerController.value,
                ),
              )),
              Positioned.fill(child: CustomPaint(
                painter: SeaPainter(
                  waveAnim: _waveController.value,
                  shimmerValue: _shimmerController.value,
                ),
              )),
              Positioned.fill(child: CustomPaint(
                painter: BeachPainter(animValue: _waveController.value),
              )),
              Positioned.fill(child: CustomPaint(
                painter: TropicalElementsPainter(
                  swayAnim: _swayController.value,
                  oscillateAnim: _mainController.value,
                ),
              )),
              Positioned.fill(child: CustomPaint(
                painter: PalmTreePainter(swayAnim: _swayController.value),
              )),
              Positioned.fill(child: CustomPaint(
                painter: AtmospherePainter(
                  bubbleAnim: _bubbleController.value,
                  particleAnim: _shimmerController.value,
                  shimmerValue: _shimmerController.value,
                ),
              )),

              // ── Carte de connexion flottante ──────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, (1 - _pageEntry.value) * 80),
                  child: Opacity(
                    opacity: _pageEntry.value,
                    child: _buildLoginCard(size),
                  ),
                ),
              ),

              // ── Logo YouMe en haut ─────────────────────────────────────
              Positioned(
                top: size.height * 0.06,
                left: 0, right: 0,
                child: Opacity(
                  opacity: _pageEntry.value,
                  child: _buildLogo(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(
                  math.cos(_shimmerController.value * math.pi * 2 - math.pi) * 2, 0,
                ),
                end: Alignment(
                  math.cos(_shimmerController.value * math.pi * 2) * 2, 0,
                ),
                colors: const [
                  Colors.white, Color(0xFFFFE082),
                  Colors.white, Color(0xFFADE8F4), Colors.white,
                ],
                stops: const [0.0, 0.2, 0.5, 0.75, 1.0],
              ).createShader(bounds),
              child: Text(
                'YouMe',
                textAlign: TextAlign.center,
                style: GoogleFonts.dancingScript(
                  fontSize: 54,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF023E8A).withOpacity(0.6),
                      offset: const Offset(0, 4),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
            Text(
              'Tropical Paradise',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 4,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginCard(Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).padding.bottom + 28),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.88),
            Colors.white.withOpacity(0.75),
            const Color(0xFFE0F7FA).withOpacity(0.82),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0096C7).withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pill indicateur
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF90E0EF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Bienvenue 🌺',
            style: GoogleFonts.poppins(
              fontSize: 26, fontWeight: FontWeight.w700,
              color: const Color(0xFF0077B6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connectez-vous à votre paradis',
            style: GoogleFonts.poppins(
              fontSize: 13, color: const Color(0xFF48CAE4),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),

          // Champ email
          _buildGlassField(
            controller: _emailController,
            hint: 'Adresse e-mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          // Champ mot de passe
          _buildGlassField(
            controller: _passwordController,
            hint: 'Mot de passe',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF48CAE4),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          // Mot de passe oublié
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Mot de passe oublié ?',
                style: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFF0096C7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Bouton Connexion
          Center(
            child: BubbleButton(
              text: _isLoading ? 'Connexion...' : 'Se connecter',
              color: const Color(0xFF0096C7),
              width: size.width - 48,
              height: 58,
              onPressed: _isLoading ? null : _handleLogin,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Diviseur
          Row(children: [
            Expanded(child: Divider(color: const Color(0xFF90E0EF).withOpacity(0.5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('ou', style: GoogleFonts.poppins(color: const Color(0xFF90E0EF), fontSize: 12)),
            ),
            Expanded(child: Divider(color: const Color(0xFF90E0EF).withOpacity(0.5))),
          ]),
          const SizedBox(height: 16),

          // Bouton S'inscrire
          Center(
            child: BubbleButton(
              text: "S'inscrire",
              color: const Color(0xFF48CAE4),
              width: size.width - 48,
              height: 52,
              onPressed: () {},
              textStyle: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF90E0EF).withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF48CAE4).withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF023E8A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14, color: const Color(0xFF90E0EF),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF48CAE4), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenue au paradis ! 🌴', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF0096C7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }
}
