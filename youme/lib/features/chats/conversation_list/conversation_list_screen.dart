import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/wood_card.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/conversation_model.dart';
import 'package:intl/intl.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});
  @override State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> with SingleTickerProviderStateMixin {
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadConversations();
  }

  @override void dispose() { _staggerCtrl.dispose(); super.dispose(); }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;
      final data = await SupabaseService.client
          .from('conversations')
          .select('*, profiles:participant_ids(*)')
          .contains('participant_ids', [userId])
          .order('updated_at', ascending: false);
      // Parse
      setState(() {
        _conversations = (data as List<dynamic>)
            .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
      _staggerCtrl.forward();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildSkeleton()
                : _conversations.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        color: AppColors.goldPrimary,
                        backgroundColor: AppColors.woodMedium,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          itemCount: _conversations.length,
                          itemBuilder: (_, i) {
                            final delay = i * 0.1;
                            final anim = CurvedAnimation(
                              parent: _staggerCtrl,
                              curve: Interval(delay.clamp(0.0, 0.9), (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutExpo),
                            );
                            return AnimatedBuilder(
                              animation: anim,
                              builder: (_, child) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: _ConversationTile(conversation: _conversations[i]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        const Text('Messages', style: TextStyle(fontFamily: 'Playfair', fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
        const Spacer(),
        Container(
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [AppColors.woodLight, AppColors.woodMedium]),
            border: Border.all(color: AppColors.goldBorder.withValues(alpha: 0.7), width: 1.5),
            boxShadow: [const BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))]),
          child: IconButton(icon: const Icon(Icons.search, color: AppColors.goldLight, size: 22), onPressed: () {}),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('💬', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('Aucune conversation', style: TextStyle(fontFamily: 'Playfair', fontSize: 20, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Ajoutez un contact pour commencer', style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.6), fontSize: 14)),
      ]),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          color: AppColors.woodMedium.withValues(alpha: 0.3)),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final partner = conversation.partner;
    final last = conversation.lastMessage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WoodCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push('/home/chat/${conversation.id}'),
        child: Row(children: [
          UserAvatar(imageUrl: partner?.avatarUrl, displayName: partner?.displayName, size: 52, isOnline: conversation.isPartnerOnline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(partner?.displayName ?? 'Inconnu',
                  style: const TextStyle(fontFamily: 'Lato', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis)),
                if (last != null) Text(_formatDate(last.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                if (conversation.isPartnerTyping)
                  const Text('En train d\'écrire...', style: TextStyle(color: AppColors.turquoise, fontSize: 13, fontStyle: FontStyle.italic))
                else
                  Expanded(child: Text(last?.decryptedText ?? '🔐', style: const TextStyle(fontSize: 13, color: AppColors.textMuted), overflow: TextOverflow.ellipsis, maxLines: 1)),
                if (conversation.unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.goldLight, AppColors.goldDark])),
                    child: Text('${conversation.unreadCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.woodDark)),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return DateFormat('EEEE', 'fr').format(dt);
    return DateFormat('dd/MM', 'fr').format(dt);
  }
}
