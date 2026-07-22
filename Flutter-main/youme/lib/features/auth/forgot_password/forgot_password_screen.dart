import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_button.dart';
import '../../../core/widgets/wood_text_field.dart';
import '../../../core/widgets/tropical_background.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthPasswordResetRequested(_emailCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthPasswordResetSent) setState(() => _sent = true);
        if (state is AuthError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
      },
      child: Scaffold(
        body: TropicalBackground(
          showSunset: true,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(children: [
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.goldLight)),
                    const Spacer(),
                    const Text('Mot de passe oublié', style: TextStyle(fontFamily: 'Playfair', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
                    const Spacer(), const SizedBox(width: 48),
                  ]),
                  const SizedBox(height: 48),
                  if (_sent)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(colors: [Color(0xBB1A3028), Color(0xBB0D1F17)]),
                        border: Border.all(color: AppColors.greenFlag.withOpacity(0.5))),
                      child: Column(children: [
                        const Icon(Icons.mark_email_read, color: AppColors.greenFlag, size: 64),
                        const SizedBox(height: 16),
                        const Text('Email envoyé !', style: TextStyle(fontFamily: 'Playfair', fontSize: 22, color: AppColors.greenFlag, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Vérifiez votre boîte mail et suivez le lien pour réinitialiser votre mot de passe.',
                          textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.8), fontSize: 14, height: 1.5)),
                        const SizedBox(height: 24),
                        WoodButton(label: 'Retour à la connexion', icon: Icons.login, width: double.infinity, onPressed: () => context.pop()),
                      ]),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Color(0xBB5C3317), Color(0xBB3D1F0B)]),
                        border: Border.all(color: AppColors.goldBorder.withOpacity(0.5)),
                        boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8))]),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          const Icon(Icons.lock_reset, color: AppColors.goldLight, size: 56),
                          const SizedBox(height: 16),
                          const Text('Réinitialiser votre mot de passe', textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Playfair', fontSize: 20, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Entrez votre adresse email et nous vous enverrons un lien de réinitialisation.',
                            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.6), fontSize: 13, height: 1.4)),
                          const SizedBox(height: 24),
                          WoodTextField(label: 'Adresse email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined, textInputAction: TextInputAction.done, onSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email requis';
                              if (!v.contains('@')) return 'Email invalide';
                              return null;
                            }),
                          const SizedBox(height: 24),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (_, state) => WoodButton(label: 'Envoyer le lien', isLoading: state is AuthLoading,
                              icon: Icons.send_outlined, width: double.infinity, onPressed: _submit)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
