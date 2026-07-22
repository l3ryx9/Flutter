import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/wood_button.dart';
import '../../../core/widgets/wood_card.dart';
import '../../../core/widgets/wood_text_field.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_logger.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  UserModel? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isEditing = false;
  final _nameCtrl = TextEditingController();
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutExpo));
    _loadProfile();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;
      final data = await SupabaseService.client
          .from(SupabaseKeys.profiles)
          .select()
          .eq('id', userId)
          .single();
      final profile = UserModel.fromJson(data as Map<String, dynamic>);
      setState(() {
        _profile = profile;
        _nameCtrl.text = profile.displayName ?? '';
        _isLoading = false;
      });
      _entryCtrl.forward();
    } catch (e) {
      ErrorLogger.log('ProfileScreen._loadProfile', e.toString());
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final userId = SupabaseService.currentUserId!;
      final ext = picked.path.split('.').last;
      final path = 'avatars/$userId/avatar.$ext';
      final bytes = await File(picked.path).readAsBytes();
      await SupabaseService.client.storage
          .from(AppConstants.bucketAvatars)
          .uploadBinary(path, bytes,
              fileOptions: const FileOptions(upsert: true));
      final url = SupabaseService.client.storage
          .from(AppConstants.bucketAvatars)
          .getPublicUrl(path);
      await SupabaseService.client
          .from(SupabaseKeys.profiles)
          .update({'avatar_url': url}).eq('id', userId);
      setState(
          () => _profile = _profile?.copyWith(avatarUrl: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Photo de profil mise à jour ✓'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      ErrorLogger.log('ProfileScreen._pickAvatar', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur lors du chargement de la photo.'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await SupabaseService.client
          .from(SupabaseKeys.profiles)
          .update({'display_name': name}).eq('id', SupabaseService.currentUserId!);
      setState(() {
        _profile = _profile?.copyWith(displayName: name);
        _isEditing = false;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nom mis à jour ✓'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (_) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyTop,
      appBar: WoodAppBar(
        title: 'Profil',
        actions: [
          if (!_isEditing && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.edit, color: AppColors.goldLight),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.goldPrimary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 24),
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildStatsCard(),
                      const SizedBox(height: 16),
                      _buildActionsCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Hero(
              tag: 'profile_avatar',
              child: _isUploadingAvatar
                  ? Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.goldBorder, width: 3),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.goldPrimary),
                      ),
                    )
                  : UserAvatar(
                      avatarUrl: _profile?.avatarUrl,
                      displayName: _profile?.displayName,
                      isOnline: true,
                      size: 110,
                    ),
            ),
            GestureDetector(
              onTap: _pickAvatar,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.goldPrimary, AppColors.goldDark],
                  ),
                  border: Border.all(color: AppColors.woodDark, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.glowGold.withValues(alpha: 0.5),
                        blurRadius: 8)
                  ],
                ),
                child: const Icon(Icons.camera_alt,
                    color: AppColors.woodDark, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _profile?.displayName ?? 'Utilisateur',
          style: const TextStyle(
            fontFamily: 'Playfair',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.goldLight,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _profile?.email ?? '',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.onlineGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.onlineGreen.withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 4, backgroundColor: AppColors.onlineGreen),
              SizedBox(width: 6),
              Text('En ligne',
                  style: TextStyle(color: AppColors.onlineGreen, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    if (!_isEditing) {
      return WoodCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, color: AppColors.goldLight, size: 20),
                SizedBox(width: 8),
                Text('Informations',
                    style: TextStyle(
                        fontFamily: 'Playfair',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldLight)),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Nom affiché', value: _profile?.displayName ?? '—'),
            const SizedBox(height: 10),
            _InfoRow(label: 'Email', value: _profile?.email ?? '—'),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Membre depuis',
              value: _profile?.createdAt != null
                  ? '${_profile!.createdAt.day.toString().padLeft(2, '0')}/${_profile!.createdAt.month.toString().padLeft(2, '0')}/${_profile!.createdAt.year}'
                  : '—',
            ),
          ],
        ),
      );
    }
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Modifier le profil',
              style: TextStyle(
                  fontFamily: 'Playfair',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldLight)),
          const SizedBox(height: 16),
          WoodTextField(
            label: 'Nom affiché',
            controller: _nameCtrl,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Annuler',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: WoodButton(
                  label: 'Sauvegarder',
                  isLoading: _isSaving,
                  icon: Icons.check,
                  onPressed: _saveName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.goldLight, size: 20),
              SizedBox(width: 8),
              Text('Statistiques',
                  style: TextStyle(
                      fontFamily: 'Playfair',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLight)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatItem(
                      icon: Icons.message_outlined,
                      label: 'Messages',
                      value: '—')),
              Expanded(
                  child: _StatItem(
                      icon: Icons.analytics_outlined,
                      label: 'Analyses',
                      value: '—')),
              Expanded(
                  child: _StatItem(
                      icon: Icons.people_outline,
                      label: 'Contacts',
                      value: '—')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return WoodCard(
      child: Column(
        children: [
          _ActionItem(
            icon: Icons.lock_outline,
            label: 'Changer de mot de passe',
            onTap: () => context.go('/home/settings'),
            color: AppColors.turquoise,
          ),
          const Divider(color: Color(0x33FFD700), height: 24),
          _ActionItem(
            icon: Icons.delete_outline,
            label: 'Supprimer le compte',
            onTap: () => context.go('/home/delete-account'),
            color: AppColors.error,
          ),
          const Divider(color: Color(0x33FFD700), height: 24),
          _ActionItem(
            icon: Icons.logout,
            label: 'Se déconnecter',
            onTap: () {
              context.read<AuthBloc>().add(AuthSignOutRequested());
              context.go('/login');
            },
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: AppColors.goldLight, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Playfair')),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      );
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.color});

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
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6), size: 18),
          ],
        ),
      );
}
