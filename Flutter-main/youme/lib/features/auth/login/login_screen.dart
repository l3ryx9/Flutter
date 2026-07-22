import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_button.dart';
import '../../../core/widgets/wood_text_field.dart';
import '../../../core/widgets/tropical_background.dart';
import '../../../core/router/app_router.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Anti-bot
  final _startTime = DateTime.now();
  int? _arithmeticAnswer;
  final _arithmeticCtrl = TextEditingController();
  late int _num1, _num2;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutExpo));
    _entryController.forward();
    _num1 = 3 + DateTime.now().millisecond % 10;
    _num2 = 2 + DateTime.now().second % 8;
    _arithmeticAnswer = _num1 + _num2;
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _arithmeticCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final fillTime = DateTime.now().difference(_startTime).inSeconds;
    if (fillTime < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez compléter le formulaire plus lentement.')));
      return;
    }
    final answer = int.tryParse(_arithmeticCtrl.text.trim());
    if (answer != _arithmeticAnswer) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réponse au calcul incorrecte.')));
      return;
    }
    context.read<AuthBloc>().add(AuthSignInRequested(_emailCtrl.text.trim(), _passCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) context.go(AppRoutes.home);
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
        }
      },
      child: Scaffold(
        body: TropicalBackground(
          showSunset: true,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      Center(
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(colors: [AppColors.goldLight, AppColors.goldPrimary, AppColors.goldDark]),
                            boxShadow: [BoxShadow(color: AppColors.glowGold.withOpacity(0.6), blurRadius: 30, spreadRadius: 4)],
                          ),
                          child: const Center(child: Text('💑', style: TextStyle(fontSize: 48))),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('YouMe', textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Playfair', fontSize: 40, fontWeight: FontWeight.bold,
                          color: AppColors.goldLight, letterSpacing: 3,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3))])),
                      const SizedBox(height: 8),
                      Text('Votre espace à deux', textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Lato', fontSize: 14, color: AppColors.textPrimary.withOpacity(0.7), letterSpacing: 1.5)),
                      const SizedBox(height: 48),
                      // Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xBB5C3317), Color(0xBB3D1F0B)]),
                          border: Border.all(color: AppColors.goldBorder.withOpacity(0.5), width: 1),
                          boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8))],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const Text('Connexion', style: TextStyle(fontFamily: 'Playfair', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
                              const SizedBox(height: 24),
                              WoodTextField(
                                label: 'Adresse email',
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Email requis';
                                  if (!v.contains('@')) return 'Email invalide';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              WoodTextField(
                                label: 'Mot de passe',
                                controller: _passCtrl,
                                obscureText: true,
                                prefixIcon: Icons.lock_outline,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Mot de passe requis';
                                  if (v.length < 6) return 'Au moins 6 caractères';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              WoodTextField(
                                label: 'Combien font $_num1 + $_num2 ?',
                                controller: _arithmeticCtrl,
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.calculate_outlined,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                validator: (v) => v == null || v.isEmpty ? 'Répondez au calcul' : null,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.push(AppRoutes.forgotPassword),
                                  child: const Text('Mot de passe oublié ?', style: TextStyle(color: AppColors.goldLight, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) => WoodButton(
                                  label: 'Se connecter',
                                  isLoading: state is AuthLoading,
                                  icon: Icons.login,
                                  width: double.infinity,
                                  onPressed: _submit,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('Pas encore de compte ?', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7), fontSize: 13)),
                                TextButton(
                                  onPressed: () => context.push(AppRoutes.register),
                                  child: const Text("S'inscrire", style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
