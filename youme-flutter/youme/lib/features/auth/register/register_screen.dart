import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_button.dart';
import '../../../core/widgets/wood_text_field.dart';
import '../../../core/widgets/tropical_background.dart';
import '../../../core/router/app_router.dart';
import '../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _arithmeticCtrl = TextEditingController();
  late AnimationController _entryCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  final _startTime = DateTime.now();
  late int _num1, _num2;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutExpo));
    _entryCtrl.forward();
    _num1 = 5 + DateTime.now().millisecond % 12;
    _num2 = 3 + DateTime.now().second % 7;
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _arithmeticCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (DateTime.now().difference(_startTime).inSeconds < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez prendre le temps de remplir le formulaire.')));
      return;
    }
    final answer = int.tryParse(_arithmeticCtrl.text.trim());
    if (answer != _num1 + _num2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réponse au calcul incorrecte.')));
      return;
    }
    context.read<AuthBloc>().add(AuthSignUpRequested(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim()));
  }

  String _passwordStrength(String pass) {
    if (pass.length < 6) return 'Trop court';
    if (pass.length < 10) return 'Faible';
    if (!pass.contains(RegExp(r'[A-Z]')) || !pass.contains(RegExp(r'[0-9]'))) return 'Moyen';
    if (pass.contains(RegExp(r'[!@#\$%^&*]'))) return 'Très fort';
    return 'Fort';
  }

  Color _strengthColor(String s) {
    switch (s) {
      case 'Trop court': return AppColors.error;
      case 'Faible': return AppColors.warning;
      case 'Moyen': return AppColors.sunsetOrange;
      case 'Fort': return AppColors.success;
      case 'Très fort': return AppColors.greenFlag;
      default: return AppColors.textMuted;
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    children: [
                      Row(children: [
                        IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.goldLight)),
                        const Spacer(),
                        const Text('Inscription', style: TextStyle(fontFamily: 'Playfair', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
                        const Spacer(), const SizedBox(width: 48),
                      ]),
                      const SizedBox(height: 24),
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
                              WoodTextField(label: 'Prénom', controller: _nameCtrl, prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Prénom requis' : null),
                              const SizedBox(height: 16),
                              WoodTextField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined, textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Email requis';
                                  if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
                                  return null;
                                }),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _passCtrl,
                                builder: (_, val, __) {
                                  final strength = val.text.isEmpty ? '' : _passwordStrength(val.text);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      WoodTextField(label: 'Mot de passe', controller: _passCtrl, obscureText: true,
                                        prefixIcon: Icons.lock_outline, textInputAction: TextInputAction.next,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'Mot de passe requis';
                                          if (v.length < 8) return 'Au moins 8 caractères';
                                          return null;
                                        }),
                                      if (strength.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          const SizedBox(width: 4),
                                          Text('Force : $strength', style: TextStyle(fontSize: 12, color: _strengthColor(strength), fontWeight: FontWeight.bold)),
                                        ]),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              WoodTextField(label: 'Confirmer le mot de passe', controller: _confirmPassCtrl,
                                obscureText: true, prefixIcon: Icons.lock_outline, textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Confirmation requise';
                                  if (v != _passCtrl.text) return 'Les mots de passe ne correspondent pas';
                                  return null;
                                }),
                              const SizedBox(height: 16),
                              WoodTextField(label: 'Combien font $_num1 + $_num2 ?', controller: _arithmeticCtrl,
                                keyboardType: TextInputType.number, prefixIcon: Icons.calculate_outlined,
                                textInputAction: TextInputAction.done, onSubmitted: (_) => _submit(),
                                validator: (v) => (v == null || v.isEmpty) ? 'Répondez au calcul' : null),
                              const SizedBox(height: 24),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (_, state) => WoodButton(
                                  label: "S'inscrire", isLoading: state is AuthLoading,
                                  icon: Icons.person_add, width: double.infinity, onPressed: _submit),
                              ),
                              const SizedBox(height: 16),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('Déjà un compte ?', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7), fontSize: 13)),
                                TextButton(onPressed: () => context.pop(),
                                  child: const Text('Se connecter', style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13))),
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
