import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/wood_card.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});
  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen>
    with SingleTickerProviderStateMixin {
  List<_InvitationItem> _received = [];
  List<_InvitationItem> _sent = [];
  bool _isLoading = true;
  late AnimationController _staggerCtrl;
  int _tab = 0; // 0 = reçues, 1 = envoyées

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _load();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final receivedData = await SupabaseService.client
          .from(SupabaseKeys.contactRequests)
          .select('*, sender:sender_id(*)')
          .eq('receiver_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final sentData = await SupabaseService.client
          .from(SupabaseKeys.contactRequests)
          .select('*, receiver:receiver_id(*)')
          .eq('sender_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      setState(() {
        _received = (receivedData as List<dynamic>).map((e) {
          final m = e as Map<String, dynamic>;
          final sender = m['sender'] as Map<String, dynamic>?;
          return _InvitationItem(
            id: m['id'] as String,
            user: sender != null ? UserModel.fromJson(sender) : null,
            createdAt: DateTime.parse(m['created_at'] as String),
          );
        }).toList();

        _sent = (sentData as List<dynamic>).map((e) {
          final m = e as Map<String, dynamic>;
          final receiver = m['receiver'] as Map<String, dynamic>?;
          return _InvitationItem(
            id: m['id'] as String,
            user: receiver != null ? UserModel.fromJson(receiver) : null,
            createdAt: DateTime.parse(m['created_at'] as String),
          );
        }).toList();

        _isLoading = false;
      });
      _staggerCtrl.forward(from: 0);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _accept(String requestId, String senderId) async {
    try {
      final userId = SupabaseService.currentUserId!;
      await SupabaseService.client
          .from(SupabaseKeys.contactRequests)
          .update({'status': 'accepted'}).eq('id', requestId);

      // Create contact record both ways
      await SupabaseService.client.from(SupabaseKeys.contacts).insert([
        {
          'user_id': userId,
          'contact_id': senderId,
          'status': 'accepted',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'user_id': senderId,
          'contact_id': userId,
          'status': 'accepted',
          'created_at': DateTime.now().toIso8601String(),
        },
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande acceptée ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur lors de l\'acceptation.'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _decline(String requestId) async {
    try {
      await SupabaseService.client
          .from(SupabaseKeys.contactRequests)
          .update({'status': 'declined'}).eq('id', requestId);
      await _load();
    } catch (_) {}
  }

  Future<void> _cancel(String requestId) async {
    try {
      await SupabaseService.client
          .from(SupabaseKeys.contactRequests)
          .delete()
          .eq('id', requestId);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyTop,
      appBar: WoodAppBar(title: 'Invitations'),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.goldPrimary))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.goldPrimary,
                    backgroundColor: AppColors.woodMedium,
                    child: _tab == 0
                        ? _buildList(_received, received: true)
                        : _buildList(_sent, received: false),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C3317), Color(0xFF3D1F0B)],
        ),
        border: Border.all(color: AppColors.goldBorder.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _TabButton(
              label: 'Reçues (${_received.length})',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0)),
          _TabButton(
              label: 'Envoyées (${_sent.length})',
              selected: _tab == 1,
              onTap: () => setState(() => _tab = 1)),
        ],
      ),
    );
  }

  Widget _buildList(List<_InvitationItem> items, {required bool received}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              received ? Icons.inbox_outlined : Icons.outbox_outlined,
              color: AppColors.goldLight.withValues(alpha: 0.35),
              size: 70,
            ),
            const SizedBox(height: 16),
            Text(
              received ? 'Aucune invitation reçue' : 'Aucune invitation envoyée',
              style: const TextStyle(
                  fontFamily: 'Playfair', fontSize: 18, color: AppColors.goldLight),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final delay = i * 0.1;
        final anim = CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(delay.clamp(0.0, 0.9), (delay + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutExpo),
        );
        final item = items[i];
        return AnimatedBuilder(
          animation: anim,
          builder: (_, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: WoodCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      avatarUrl: item.user?.avatarUrl,
                      displayName: item.user?.displayName,
                      isOnline: item.user?.isOnline ?? false,
                      size: 50,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.user?.displayName ?? 'Utilisateur inconnu',
                            style: const TextStyle(
                              fontFamily: 'Playfair',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldLight,
                            ),
                          ),
                          Text(
                            item.user?.email ?? '',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(item.createdAt),
                            style: TextStyle(
                                color: AppColors.textMuted.withValues(alpha: 0.7), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (received) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: 'Refuser',
                          color: AppColors.error,
                          icon: Icons.close,
                          onTap: () => _decline(item.id),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Accepter',
                          color: AppColors.success,
                          icon: Icons.check,
                          onTap: () => _accept(item.id, item.user?.id ?? ''),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                        ),
                        child: Text('En attente',
                            style: TextStyle(color: AppColors.warning, fontSize: 12)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _cancel(item.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                          ),
                          child: const Text('Annuler',
                              style: TextStyle(color: AppColors.error, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes}min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _InvitationItem {
  final String id;
  final UserModel? user;
  final DateTime createdAt;
  _InvitationItem({required this.id, this.user, required this.createdAt});
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
            boxShadow: selected
                ? [BoxShadow(color: AppColors.glowGold.withValues(alpha: 0.4), blurRadius: 8)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.bold,
              color: selected ? AppColors.woodDark : AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.color,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
