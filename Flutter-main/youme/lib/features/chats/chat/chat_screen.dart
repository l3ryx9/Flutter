import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/chat_bubble.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_logger.dart';
import '../../../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRecording = false;
  bool _showScrollToBottom = false;
  late AnimationController _sendBtnCtrl;

  // E2EE: shared key for this conversation (derived from ECDH handshake)
  // In a real deployment, this key is established once per conversation
  // and stored encrypted in the user's keychain.
  String? _sharedKey;

  @override
  void initState() {
    super.initState();
    _sendBtnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _textCtrl.addListener(() => setState(() {}));
    _scrollCtrl.addListener(() {
      final show =
          _scrollCtrl.position.pixels < _scrollCtrl.position.maxScrollExtent - 200;
      if (show != _showScrollToBottom) setState(() => _showScrollToBottom = show);
    });
    _loadMessages();
    _subscribeToMessages();
    _initE2EE();
  }

  @override
  void dispose() {
    _sendBtnCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Initialise le chiffrement de bout en bout pour cette conversation.
  /// Tente de charger la clé partagée déjà négociée ; sinon la génère.
  Future<void> _initE2EE() async {
    try {
      // Retrieve partner's public key from profiles
      final convData = await SupabaseService.client
          .from(SupabaseKeys.conversations)
          .select('participant_ids')
          .eq('id', widget.conversationId)
          .single();
      final participants = (convData['participant_ids'] as List<dynamic>).cast<String>();
      final partnerId = participants.firstWhere(
        (id) => id != SupabaseService.currentUserId,
        orElse: () => '',
      );
      if (partnerId.isEmpty) return;

      final partnerProfile = await SupabaseService.client
          .from(SupabaseKeys.profiles)
          .select('public_key')
          .eq('id', partnerId)
          .maybeSingle();

      final partnerPublicKeyHex = partnerProfile?['public_key'] as String?;
      if (partnerPublicKeyHex == null) return;

      // Load our private key from secure storage (SharedPreferences for now)
      // In production: use flutter_secure_storage or platform Keychain
      final myKeyPair = await EncryptionService.getOrCreateKeyPair(
        SupabaseService.currentUserId!,
      );

      // Ensure our public key is published to profiles
      await SupabaseService.client
          .from(SupabaseKeys.profiles)
          .update({'public_key': myKeyPair.publicKeyHex})
          .eq('id', SupabaseService.currentUserId!);

      // Derive shared secret via ECDH
      _sharedKey = EncryptionService.deriveSharedKey(
        myPrivateKeyHex: myKeyPair.privateKeyHex,
        partnerPublicKeyHex: partnerPublicKeyHex,
      );
    } catch (e) {
      ErrorLogger.log('ChatScreen._initE2EE', e.toString());
      // Fallback: messages will still be sent (without E2EE encryption),
      // but _sharedKey will be null and a warning banner will show.
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.client
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('created_at', ascending: false)
          .limit(AppConstants.messagesPageSize);
      setState(() {
        _messages = (data as List<dynamic>)
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      ErrorLogger.log('ChatScreen._loadMessages', e.toString());
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    SupabaseService.subscribeToTable(
      table: 'messages',
      schema: 'public',
      onInsert: (row) {
        if (row['conversation_id'] == widget.conversationId) {
          final msg = MessageModel.fromJson(row);
          setState(() => _messages.insert(0, msg));
        }
      },
      onUpdate: (row) {
        if (row['conversation_id'] == widget.conversationId) {
          final updated = MessageModel.fromJson(row);
          final idx = _messages.indexWhere((m) => m.id == updated.id);
          if (idx >= 0) setState(() => _messages[idx] = updated);
        }
      },
    );
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    setState(() => _isSending = true);
    try {
      String encryptedText;
      bool isEncrypted = false;

      if (_sharedKey != null) {
        // E2EE active: encrypt before sending
        encryptedText = EncryptionService.encrypt(text, _sharedKey!);
        isEncrypted = true;
      } else {
        // E2EE not yet established (partner hasn't generated keys yet)
        encryptedText = text;
      }

      await SupabaseService.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': SupabaseService.currentUserId,
        'type': 'text',
        'encrypted_text': encryptedText,
        'is_encrypted': isEncrypted,
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ErrorLogger.log('ChatScreen._sendText', e.toString());
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() => _isSending = true);
    try {
      final userId = SupabaseService.currentUserId!;
      final ext = file.path.split('.').last;
      final path = '${AppConstants.bucketMedia}/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await File(file.path).readAsBytes();

      await SupabaseService.client.storage
          .from(AppConstants.bucketMedia)
          .uploadBinary(path, bytes,
              fileOptions: FileOptions(upsert: false, contentType: 'image/$ext'));

      final url = SupabaseService.client.storage
          .from(AppConstants.bucketMedia)
          .getPublicUrl(path);

      await SupabaseService.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': userId,
        'type': 'image',
        'media_url': url,
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ErrorLogger.log('ChatScreen._pickImage', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur lors de l\'envoi de la photo.'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _shareLocation() async {
    setState(() => _isSending = true);
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Permission de localisation refusée.'),
                backgroundColor: AppColors.warning),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await SupabaseService.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': SupabaseService.currentUserId,
        'type': 'location',
        'location_lat': position.latitude,
        'location_lng': position.longitude,
        'location_label': 'Ma position',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ErrorLogger.log('ChatScreen._shareLocation', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible d\'obtenir la position.'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _reactToMessage(String messageId, String emoji) async {
    try {
      await SupabaseService.client.from(SupabaseKeys.messageReactions).upsert({
        'message_id': messageId,
        'user_id': SupabaseService.currentUserId,
        'emoji': emoji,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ErrorLogger.log('ChatScreen._reactToMessage', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyTop,
      appBar: WoodAppBar(
        title: 'Conversation',
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology, color: AppColors.aiPurple),
            onPressed: () => context.go(
                '/home/chat/${widget.conversationId}/ai-insights'),
            tooltip: 'Insights IA',
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppColors.goldLight),
            onPressed: () => context.go(
                '/home/chat/${widget.conversationId}/analysis'),
            tooltip: 'Analyse',
          ),
          IconButton(
            icon: const Icon(Icons.flag, color: AppColors.redFlag),
            onPressed: () =>
                context.go('/home/chat/${widget.conversationId}/flags'),
            tooltip: 'Signaux',
          ),
        ],
      ),
      body: Column(children: [
        // E2EE status banner
        if (_sharedKey == null && !_isLoading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.warning.withOpacity(0.2),
            child: Row(children: [
              const Icon(Icons.lock_open, color: AppColors.warning, size: 14),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Chiffrement E2EE en attente d\'initialisation',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ]),
          )
        else if (_sharedKey != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: AppColors.success.withOpacity(0.12),
            child: Row(children: [
              const Icon(Icons.lock, color: AppColors.success, size: 13),
              const SizedBox(width: 6),
              const Text(
                'Chiffrement de bout en bout activé',
                style: TextStyle(color: AppColors.success, fontSize: 11),
              ),
            ]),
          ),

        // Messages list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.goldPrimary))
              : Stack(children: [
                  ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe =
                          msg.senderId == SupabaseService.currentUserId;
                      return ChatBubble(
                        message: msg,
                        isMe: isMe,
                        sharedKey: _sharedKey,
                        onLongPress: (emoji) =>
                            _reactToMessage(msg.id, emoji),
                      );
                    },
                  ),
                  if (_showScrollToBottom)
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: FloatingActionButton.small(
                        backgroundColor: AppColors.woodMedium,
                        onPressed: () => _scrollCtrl.animateTo(0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut),
                        child: const Icon(Icons.keyboard_arrow_down,
                            color: AppColors.goldLight),
                      ),
                    ),
                ]),
        ),

        // Input bar
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.woodMedium,
          border: Border(top: BorderSide(color: AppColors.goldBorder.withOpacity(0.2))),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.goldLight),
            onPressed: _showAttachmentMenu,
          ),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Message…',
                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.woodDark,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendText(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _textCtrl.text.isNotEmpty ? _sendText : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _textCtrl.text.isNotEmpty
                    ? const LinearGradient(
                        colors: [AppColors.goldPrimary, AppColors.goldDark])
                    : null,
                color: _textCtrl.text.isEmpty
                    ? AppColors.woodHighlight.withOpacity(0.3)
                    : null,
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.woodDark)))
                  : Icon(
                      _textCtrl.text.isNotEmpty ? Icons.send : Icons.mic,
                      color: _textCtrl.text.isNotEmpty
                          ? AppColors.woodDark
                          : AppColors.goldLight,
                      size: 20,
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.woodMedium,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Envoyer',
              style: TextStyle(
                  fontFamily: 'Playfair',
                  fontSize: 18,
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _AttachOption(
                icon: Icons.image,
                label: 'Photo',
                color: AppColors.hibiscusPink,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                }),
            _AttachOption(
                icon: Icons.location_on,
                label: 'Position',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  _shareLocation();
                }),
            _AttachOption(
                icon: Icons.map,
                label: 'Live',
                color: AppColors.turquoise,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/home/chat/${widget.conversationId}/live-location');
                }),
          ]),
        ]),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachOption(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                  border: Border.all(color: color, width: 2)),
              child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        ]),
      );
}
