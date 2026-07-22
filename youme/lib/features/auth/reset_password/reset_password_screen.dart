import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_button.dart';
import '../../../core/widgets/wood_text_field.dart';
import '../../../core/widgets/tropical_background.dart';
import '../../../core/router/app_router.dart';
import '../bloc/auth_bloc.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override void dispose() { _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthPasswordUpdateRequested(_passCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthPasswordUpdated) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Mot de passe mis à jour !'), backgroundColor: AppColors.success));
          context.go(AppRoutes.login);
        }
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
                  const SizedBox(height: 40),
                  const Icon(Icons.lock_reset, color: AppColors.goldLight, size: 80),
                  const SizedBox(height: 24),
                  const Text('Nouveau mot de passe', style: TextStyle(fontFamily: 'Playfair', fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xBB5C3317), Color(0xBB3D1F0B)]),
                      border: Border.all(color: AppColors.goldBorder.withValues(alpha: 0.5)),
                      boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8))]),
                    child: Form(
                      key: _formKey,
                      child: Column(children: [
                        WoodTextField(label: 'Nouveau mot de passe', controller: _passCtrl, obscureText: true,
                          prefixIcon: Icons.lock_outline, textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (v.length < 8) return 'Au moins 8 caractères';
                            return null;
                          }),
                        const SizedBox(height: 16),
                        WoodTextField(label: 'Confirmer', controller: _confirmCtrl, obscureText: true,
                          prefixIcon: Icons.lock_outline, textInputAction: TextInputAction.done, onSubmitted: (_) => _submit(),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (v != _passCtrl.text) return 'Les mots de passe ne correspondent pas';
                            return null;
                          }),
                        const SizedBox(height: 24),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (_, state) => WoodButton(label: 'Mettre à jour', isLoading: state is AuthLoading,
                            icon: Icons.check, width: double.infinity, onPressed: _submit)),
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
