import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/wood_card.dart';
import '../../../core/widgets/wood_text_field.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/contact_model.dart';
import '../../../models/user_model.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with TickerProviderStateMixin {
  List<ContactModel> _contacts = [];
  List<UserModel> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSendingRequest = false;
  final _searchCtrl = TextEditingController();
  late AnimationController _staggerCtrl;
  late AnimationController _searchCtrlAnim;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _searchCtrlAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _loadContacts();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _searchCtrlAnim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;
      final data = await SupabaseService.client
          .from(SupabaseKeys.contacts)
          .select('*, profiles:contact_id(*)')
          .eq('user_id', userId)
          .eq('status', 'accepted');
      setState(() {
        _contacts = (data as List<dynamic>)
            .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
      _staggerCtrl.forward(from: 0);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final userId = SupabaseService.currentUserId;
      final data = await SupabaseService.client
          .from(SupabaseKeys.profiles)
          .select()
          .ilike('display_name', '%${query.trim()}%')
          .neq('id', userId ?? '')
          .limit(10);
      setState(() {
        _searchResults = (data as List<dynamic>)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isSearching = false;
      });
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _sendRequest(UserModel user) async {
    setState(() => _isSendingRequest = true);
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;
      await SupabaseService.client.from(SupabaseKeys.contactRequests).insert({
        'sender_id': userId,
        'receiver_id': user.id,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Demande envoyée à ${user.displayName ?? user.email} ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur lors de l\'envoi de la demande.'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  Future<void> _startConversation(ContactModel contact) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;
      final ids = [userId, contact.contactId]..sort();
      final existing = await SupabaseService.client
          .from(SupabaseKeys.conversations)
          .select('id')
          .contains('participant_ids', ids)
          .maybeSingle();
      String convId;
      if (existing != null) {
        convId = existing['id'] as String;
      } else {
        final created = await SupabaseService.client
            .from(SupabaseKeys.conversations)
            .insert({
              'participant_ids': ids,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();
        convId = created['id'] as String;
      }
      if (mounted) context.go('/home/chat/$convId');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          if (_searchCtrl.text.isNotEmpty) _buildSearchResults(),
          if (_searchCtrl.text.isEmpty)
            Expanded(child: _buildContactsList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Icon(Icons.people, color: AppColors.goldLight, size: 26),
          const SizedBox(width: 10),
          const Text(
            'Contacts',
            style: TextStyle(
              fontFamily: 'Playfair',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.goldLight,
              letterSpacing: 1.2,
              shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
            ),
          ),
          const Spacer(),
          _IconButton(
            icon: Icons.mail_outline,
            onTap: () => context.go('/home/invitations'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: WoodTextField(
        label: 'Rechercher un utilisateur...',
        controller: _searchCtrl,
        prefixIcon: Icons.search,
        onChanged: (v) {
          setState(() {});
          _search(v);
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: _isSearching
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
          : _searchResults.isEmpty
              ? _buildSearchEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  itemCount: _searchResults.length,
                  itemBuilder: (_, i) => _SearchResultTile(
                    user: _searchResults[i],
                    isSending: _isSendingRequest,
                    onSend: () => _sendRequest(_searchResults[i]),
                  ),
                ),
    );
  }

  Widget _buildSearchEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, color: AppColors.goldLight.withOpacity(0.4), size: 64),
          const SizedBox(height: 12),
          Text(
            'Aucun résultat',
            style: TextStyle(color: AppColors.textMuted, fontSize: 16, fontFamily: 'Lato'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary));
    }
    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, color: AppColors.goldLight.withOpacity(0.35), size: 80),
            const SizedBox(height: 16),
            const Text(
              'Aucun contact encore',
              style: TextStyle(fontFamily: 'Playfair', fontSize: 20, color: AppColors.goldLight),
            ),
            const SizedBox(height: 8),
            const Text(
              'Recherchez un utilisateur ci-dessus\npour envoyer une demande.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadContacts,
      color: AppColors.goldPrimary,
      backgroundColor: AppColors.woodMedium,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: _contacts.length,
        itemBuilder: (_, i) {
          final delay = i * 0.1;
          final anim = CurvedAnimation(
            parent: _staggerCtrl,
            curve: Interval(delay.clamp(0.0, 0.9), (delay + 0.4).clamp(0.0, 1.0),
                curve: Curves.easeOutExpo),
          );
          return AnimatedBuilder(
            animation: anim,
            builder: (_, child) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _ContactTile(
              contact: _contacts[i],
              onTap: () => _startConversation(_contacts[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Tile : contact existant ────────────────────────────────────────────────
class _ContactTile extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onTap;
  const _ContactTile({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final profile = contact.contactUser;
    return WoodCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        children: [
          UserAvatar(
            imageUrl: profile?.avatarUrl,
            displayName: profile?.displayName,
            isOnline: profile?.isOnline ?? false,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.displayName ?? 'Utilisateur',
                  style: const TextStyle(
                    fontFamily: 'Playfair',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile?.email ?? '',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.goldPrimary, AppColors.goldDark],
              ),
              boxShadow: [
                BoxShadow(
                    color: AppColors.glowGold.withOpacity(0.4),
                    blurRadius: 8)
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, color: AppColors.woodDark, size: 16),
                SizedBox(width: 4),
                Text('Message',
                    style: TextStyle(
                        color: AppColors.woodDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tile : résultat de recherche ───────────────────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final UserModel user;
  final bool isSending;
  final VoidCallback onSend;
  const _SearchResultTile(
      {required this.user, required this.isSending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return WoodCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: user.avatarUrl,
            displayName: user.displayName,
            isOnline: user.isOnline,
            size: 48,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.email,
                  style: const TextStyle(
                    fontFamily: 'Playfair',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldLight,
                  ),
                ),
                if (user.displayName != null)
                  Text(user.email,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.turquoise.withOpacity(0.2),
                border: Border.all(color: AppColors.turquoise.withOpacity(0.6)),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.turquoise, strokeWidth: 2))
                  : const Icon(Icons.person_add_outlined,
                      color: AppColors.turquoise, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bouton icône ────────────────────────────────────────────────────────────
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [AppColors.woodLight, AppColors.woodMedium, AppColors.woodDark],
          ),
          border: Border.all(color: AppColors.goldBorder.withOpacity(0.7), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: AppColors.goldLight, size: 18),
      ),
    );
  }
}
