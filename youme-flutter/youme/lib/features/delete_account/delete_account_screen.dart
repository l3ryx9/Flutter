import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/wood_button.dart';
import '../../../core/widgets/wood_text_field.dart';
import '../../../core/widgets/tropical_background.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_logger.dart';
import '../../auth/bloc/auth_bloc.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen>
    with TickerProviderStateMixin {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isDeleting = false;
  bool _understood = false;
  late AnimationController _warningCtrl;
  late Animation<double> _warningShake;
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _warningCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _warningShake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _warningCtrl, curve: Curves.elasticIn),
    );
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _warningCtrl.dispose();
    _entryCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_understood) {
      _warningCtrl.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez cocher la case de confirmation.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    if (_passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre mot de passe.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_confirmCtrl.text != 'SUPPRIMER') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tapez exactement "SUPPRIMER" pour confirmer.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isDeleting = true);
    try {
      // Re-authenticate
      final email = SupabaseService.client.auth.currentUser?.email ?? '';
      await SupabaseService.signIn(email: email, password: _passCtrl.text);

      // Call server-side delete function
      await SupabaseService.callFunction(
        SupabaseKeys.fnDeleteAccount,
        body: {'userId': SupabaseService.currentUserId},
      );

      // Sign out
      await SupabaseService.client.auth.signOut();

      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      ErrorLogger.log('DeleteAccountScreen', e.toString());
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erreur : mot de passe incorrect ou erreur serveur. (${e.toString().substring(0, 50)})'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyTop,
      appBar: WoodAppBar(title: 'Supprimer le compte'),
      body: TropicalBackground(
        child: FadeTransition(
          opacity: _entryCtrl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildWarningBanner(),
                const SizedBox(height: 24),
                _buildConsequences(),
                const SizedBox(height: 24),
                _buildConfirmationForm(),
                const SizedBox(height: 24),
                _buildDeleteButton(),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Annuler, je veux garder mon compte',
                    style: TextStyle(color: AppColors.turquoise, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return AnimatedBuilder(
      animation: _warningShake,
      builder: (_, child) => Transform.translate(
        offset: Offset(
            8 * (1 - _warningShake.value) * ((_warningShake.value * 4).toInt().isOdd ? 1 : -1),
            0),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.error.withOpacity(0.3),
              AppColors.error.withOpacity(0.15),
            ],
          ),
          border: Border.all(color: AppColors.error.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: AppColors.error.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2)
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 52),
            const SizedBox(height: 12),
            const Text(
              'Action irréversible',
              style: TextStyle(
                fontFamily: 'Playfair',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La suppression de votre compte est permanente. Toutes vos données seront effacées définitivement.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.error.withOpacity(0.85),
                  fontSize: 14,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsequences() {
    final items = [
      (icon: Icons.message_outlined, text: 'Tous vos messages seront supprimés'),
      (icon: Icons.photo_library_outlined, text: 'Tous vos médias partagés seront effacés'),
      (icon: Icons.analytics_outlined, text: 'Toutes vos analyses IA seront perdues'),
      (icon: Icons.people_outline, text: 'Vos contacts ne pourront plus vous retrouver'),
      (icon: Icons.block, text: 'Votre accès sera immédiatement révoqué'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.woodMedium.withOpacity(0.5),
        border: Border.all(color: AppColors.woodHighlight.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ce qui sera supprimé :',
              style: TextStyle(
                  fontFamily: 'Playfair',
                  fontSize: 15,
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(item.icon, color: AppColors.error.withOpacity(0.7), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.text,
                          style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.85),
                              fontSize: 14)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildConfirmationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xBB5C3317), Color(0xBB3D1F0B)],
        ),
        border: Border.all(color: AppColors.goldBorder.withOpacity(0.4)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirmation requise',
              style: TextStyle(
                  fontFamily: 'Playfair',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldLight)),
          const SizedBox(height: 16),
          WoodTextField(
            label: 'Mot de passe actuel',
            controller: _passCtrl,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
          ),
          const SizedBox(height: 14),
          const Text(
            'Tapez "SUPPRIMER" pour confirmer :',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          WoodTextField(
            label: 'SUPPRIMER',
            controller: _confirmCtrl,
            prefixIcon: Icons.warning_outlined,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _understood = !_understood),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: _understood
                        ? AppColors.error
                        : Colors.transparent,
                    border: Border.all(
                      color: _understood ? AppColors.error : AppColors.textMuted,
                      width: 2,
                    ),
                  ),
                  child: _understood
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Je comprends que cette action est irréversible et que toutes mes données seront perdues.',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return WoodButton(
      label: _isDeleting ? 'Suppression...' : 'Supprimer définitivement mon compte',
      isLoading: _isDeleting,
      icon: Icons.delete_forever,
      width: double.infinity,
      accentColor: AppColors.error,
      onPressed: _isDeleting ? null : _deleteAccount,
    );
  }
}
