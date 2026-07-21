import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/explosion_particle.dart';
import '../painters/pineapple_painter.dart';

/// Splash Screen entièrement animé : ananas → explosion → texte YouMe → transition
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Phase 1 – entrée de l'ananas
  late final AnimationController _entryController;
  late final Animation<double> _entryScale;
  late final Animation<double> _entryOpacity;

  // Phase 2 – wobble avant explosion
  late final AnimationController _wobbleController;
  late final Animation<double> _wobbleAnim;

  // Phase 3 – explosion
  late final AnimationController _explosionController;
  late final Animation<double> _explodeScale;
  late final Animation<double> _pineappleOpacity;

  // Phase 4 – texte YouMe
  late final AnimationController _textController;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textScale;
  late final Animation<double> _textShimmer;

  // Phase 5 – transition vers login
  late final AnimationController _transitionController;
  late final Animation<double> _fadeOut;

  // Particules physiques
  final List<ExplosionParticle> _fragments = [];
  final List<DustParticle> _dust = [];
  final List<LightBurst> _bursts = [];
  bool _showExplosion = false;

  // Ticker pour la physique
  late final Ticker _physicsTicker;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _startSequence();
    _physicsTicker = createTicker(_updatePhysics)..start();
  }

  void _initControllers() {
    _entryController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _entryScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
    ]).animate(_entryController);
    _entryOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4)),
    );

    _wobbleController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _wobbleAnim = Tween(begin: 0.0, end: 1.0).animate(_wobbleController);

    _explosionController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300),
    );
    _explodeScale = Tween(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _explosionController, curve: Curves.easeOut),
    );
    _pineappleOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _explosionController, curve: const Interval(0.3, 1.0)),
    );

    _textController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _textScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
    ]).animate(_textController);
    _textShimmer = Tween(begin: 0.0, end: 1.0).animate(_textController);

    _transitionController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );
    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  Future<void> _startSequence() async {
    // Phase 1 : entrée de l'ananas
    await _entryController.forward();

    // Attendre 1 seconde de pause
    await Future.delayed(const Duration(milliseconds: 1000));

    // Phase 2 : wobble
    _wobbleController.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 400));
    _wobbleController.stop();

    // Phase 3 : explosion
    _triggerExplosion();
    await _explosionController.forward();
    setState(() => _showExplosion = true);

    // Phase 4 : texte YouMe
    await Future.delayed(const Duration(milliseconds: 200));
    await _textController.forward();

    // Attendre que les particules s'estompent
    await Future.delayed(const Duration(milliseconds: 1200));

    // Phase 5 : transition
    await _transitionController.forward();
  }

  void _triggerExplosion() {
    setState(() {
      // 24 fragments principaux
      for (int i = 0; i < 24; i++) {
        _fragments.add(ExplosionParticle.random(i));
      }
      // Poussière tropicale
      for (int i = 0; i < 12; i++) {
        final angle = (i / 12) * math.pi * 2;
        _dust.add(DustParticle(
          x: math.cos(angle) * 20,
          y: math.sin(angle) * 20,
        ));
      }
      // Éclats lumineux
      for (int i = 0; i < 16; i++) {
        final angle = (i / 16) * math.pi * 2;
        _bursts.add(LightBurst(x: 0, y: 0, angle: angle));
      }
    });
  }

  void _updatePhysics(Duration elapsed) {
    if (!_showExplosion) return;
    setState(() {
      for (final f in _fragments) f.update();
      for (final d in _dust) d.update();
      for (final b in _bursts) b.update();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _wobbleController.dispose();
    _explosionController.dispose();
    _textController.dispose();
    _transitionController.dispose();
    _physicsTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _entryController,
        _wobbleController,
        _explosionController,
        _textController,
        _transitionController,
      ]),
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        return Opacity(
          opacity: _fadeOut.value,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1976D2),
                    Color(0xFF0096C7),
                    Color(0xFF48CAE4),
                  ],
                  stops: [0.0, 0.3, 0.65, 1.0],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Fond étoilé / particules de fond
                  _buildBackgroundParticles(size),

                  // Fragments d'explosion
                  if (_showExplosion)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ExplosionPainter(
                          fragments: _fragments,
                          dust: _dust,
                          bursts: _bursts,
                          center: Offset(size.width / 2, size.height / 2),
                        ),
                      ),
                    ),

                  // Ananas principal
                  if (!_showExplosion || _explosionController.value < 1.0)
                    Transform.scale(
                      scale: _entryScale.value * _explodeScale.value *
                          (1.0 + math.sin(_wobbleAnim.value * math.pi * 4) * 0.04),
                      child: SizedBox(
                        width: 160,
                        height: 200,
                        child: CustomPaint(
                          painter: PineapplePainter(
                            opacity: _pineappleOpacity.value * _entryOpacity.value,
                            rotation: math.sin(_wobbleAnim.value * math.pi * 2) * 0.06,
                          ),
                        ),
                      ),
                    ),

                  // Flash d'explosion
                  if (_showExplosion && _explosionController.value < 0.5)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(
                          (0.5 - _explosionController.value) * 1.4,
                        ),
                      ),
                    ),

                  // Texte YouMe
                  if (_textController.value > 0)
                    Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.scale(
                        scale: _textScale.value,
                        child: _buildYouMeText(size),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundParticles(Size size) {
    return Positioned.fill(
      child: CustomPaint(painter: _SplashBgPainter()),
    );
  }

  Widget _buildYouMeText(Size size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Espace pour compenser l'ananas
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(
                math.cos(_textShimmer.value * math.pi * 2 - math.pi) * 2,
                0,
              ),
              end: Alignment(
                math.cos(_textShimmer.value * math.pi * 2) * 2,
                0,
              ),
              colors: const [
                Color(0xFFFFFFFF),
                Color(0xFFFFE082),
                Color(0xFFFFFFFF),
                Color(0xFFADE8F4),
                Color(0xFFFFFFFF),
              ],
              stops: const [0.0, 0.2, 0.5, 0.75, 1.0],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: Text(
            'YouMe',
            style: GoogleFonts.dancingScript(
              fontSize: 72,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: const Color(0xFF00B4D8).withOpacity(0.8),
                  offset: const Offset(0, 4),
                  blurRadius: 20,
                ),
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tropical Paradise',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.75),
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

// ── Painters auxiliaires ─────────────────────────────────────────────────────

class _SplashBgPainter extends CustomPainter {
  static final _rng = math.Random(42);
  static final _stars = List.generate(60, (i) => Offset(
    _rng.nextDouble(),
    _rng.nextDouble(),
  ));

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        0.8 + _rng.nextDouble() * 1.5,
        Paint()..color = Colors.white.withOpacity(0.15 + _rng.nextDouble() * 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(_SplashBgPainter old) => false;
}

class _ExplosionPainter extends CustomPainter {
  final List<ExplosionParticle> fragments;
  final List<DustParticle> dust;
  final List<LightBurst> bursts;
  final Offset center;

  _ExplosionPainter({
    required this.fragments,
    required this.dust,
    required this.bursts,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (final d in dust) d.draw(canvas);
    for (final b in bursts) b.draw(canvas);
    for (final f in fragments) f.draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ExplosionPainter old) => true;
}
