import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/wood_card.dart';
import '../bloc/settings_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FadeTransition(
        opacity: _entryCtrl,
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settings) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Paramètres', icon: Icons.settings),
                  const SizedBox(height: 16),

                  // ─── Apparence ───────────────────────────────────────────
                  _buildGroupLabel('Apparence'),
                  WoodCard(
                    child: Column(
                      children: [
                        _ThemeTile(current: settings.themeMode),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Notifications ───────────────────────────────────────
                  _buildGroupLabel('Notifications'),
                  WoodCard(
                    child: _SwitchTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications push',
                      subtitle: 'Recevez les messages même en arrière-plan',
                      value: settings.notificationsEnabled,
                      color: AppColors.turquoise,
                      onChanged: (v) =>
                          context.read<SettingsBloc>().add(SettingsNotificationsToggled(v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Intelligence Artificielle ───────────────────────────
                  _buildGroupLabel('Intelligence Artificielle'),
                  WoodCard(
                    child: Column(
                      children: [
                        _SwitchTile(
                          icon: Icons.auto_awesome,
                          label: 'Analyse IA des messages',
                          subtitle: 'Détection d\'émotions et insights',
                          value: settings.aiEnabled,
                          color: AppColors.aiPurple,
                          onChanged: (v) =>
                              context.read<SettingsBloc>().add(SettingsAiToggled(v)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Confidentialité ─────────────────────────────────────
                  _buildGroupLabel('Confidentialité & Sécurité'),
                  WoodCard(
                    child: Column(
                      children: [
                        _NavTile(
                          icon: Icons.lock_outline,
                          label: 'Changer de mot de passe',
                          color: AppColors.warning,
                          onTap: _showPasswordDialog,
                        ),
                        const _Divider(),
                        _NavTile(
                          icon: Icons.security,
                          label: 'Chiffrement de bout en bout',
                          color: AppColors.success,
                          onTap: _showEncryptionInfo,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                            ),
                            child: const Text('Actif',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Compte ──────────────────────────────────────────────
                  _buildGroupLabel('Compte'),
                  WoodCard(
                    child: Column(
                      children: [
                        _NavTile(
                          icon: Icons.person_outline,
                          label: 'Modifier le profil',
                          color: AppColors.goldLight,
                          onTap: () => context.go('/home/profile'),
                        ),
                        const _Divider(),
                        _NavTile(
                          icon: Icons.bug_report_outlined,
                          label: 'Mode développeur',
                          color: AppColors.textMuted,
                          onTap: () => context.go('/home/debug'),
                        ),
                        const _Divider(),
                        _NavTile(
                          icon: Icons.delete_forever,
                          label: 'Supprimer le compte',
                          color: AppColors.error,
                          onTap: () => context.go('/home/delete-account'),
                        ),
                        const _Divider(),
                        _NavTile(
                          icon: Icons.logout,
                          label: 'Se déconnecter',
                          color: AppColors.warning,
                          onTap: () {
                            context.read<AuthBloc>().add(AuthSignOutRequested());
                            context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Version
                  Center(
                    child: Text(
                      'YouMe v1.0.0',
                      style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.goldLight, size: 26),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Playfair',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.goldLight,
            letterSpacing: 1.2,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.goldPrimary.withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showPasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.woodMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Changer le mot de passe',
            style: TextStyle(
                fontFamily: 'Playfair',
                color: AppColors.goldLight,
                fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(ctrl: currentCtrl, label: 'Mot de passe actuel', obscure: true),
            const SizedBox(height: 10),
            _DialogField(ctrl: newCtrl, label: 'Nouveau mot de passe', obscure: true),
            const SizedBox(height: 10),
            _DialogField(ctrl: confirmCtrl, label: 'Confirmer', obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: AppColors.woodDark),
            onPressed: () {
              if (newCtrl.text == confirmCtrl.text && newCtrl.text.length >= 8) {
                context.read<AuthBloc>().add(
                    AuthPasswordUpdateRequested(newCtrl.text));
                Navigator.of(context).pop();
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showEncryptionInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.woodMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppColors.success),
            SizedBox(width: 8),
            Text('Chiffrement E2E',
                style: TextStyle(
                    fontFamily: 'Playfair',
                    color: AppColors.goldLight,
                    fontSize: 18)),
          ],
        ),
        content: const Text(
          'Vos messages sont protégés par un chiffrement de bout en bout (ECDH X25519 + AES-GCM 256). '
          'Seuls vous et votre partenaire pouvez lire vos conversations. '
          'Votre clé privée ne quitte jamais votre appareil.',
          style: TextStyle(color: AppColors.textPrimary, height: 1.5, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

// ─── Tile composants ─────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  final ThemeMode current;
  const _ThemeTile({required this.current});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.palette_outlined, color: AppColors.goldLight, size: 20),
            SizedBox(width: 10),
            Text('Thème',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ThemeOption(
              label: 'Clair',
              icon: Icons.light_mode,
              selected: current == ThemeMode.light,
              onTap: () => context.read<SettingsBloc>().add(SettingsThemeChanged(ThemeMode.light)),
            ),
            const SizedBox(width: 8),
            _ThemeOption(
              label: 'Sombre',
              icon: Icons.dark_mode,
              selected: current == ThemeMode.dark,
              onTap: () => context.read<SettingsBloc>().add(SettingsThemeChanged(ThemeMode.dark)),
            ),
            const SizedBox(width: 8),
            _ThemeOption(
              label: 'Auto',
              icon: Icons.brightness_auto,
              selected: current == ThemeMode.system,
              onTap: () => context.read<SettingsBloc>().add(SettingsThemeChanged(ThemeMode.system)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: selected
                  ? const LinearGradient(
                      colors: [AppColors.goldPrimary, AppColors.goldDark])
                  : null,
              border: Border.all(
                color: selected
                    ? AppColors.goldBorder
                    : AppColors.woodHighlight.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Icon(icon,
                    color:
                        selected ? AppColors.woodDark : AppColors.textMuted,
                    size: 18),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: selected ? AppColors.woodDark : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
        ),
      );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _SwitchTile(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.value,
      required this.color,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
          ),
        ],
      );
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;
  const _NavTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      this.trailing});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: color, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            trailing ??
                Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6), size: 18),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: Color(0x22FFD700), height: 1),
      );
}

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  const _DialogField({required this.ctrl, required this.label, this.obscure = false});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.woodDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.woodHighlight.withValues(alpha: 0.4)),
          ),
        ),
      );
}
