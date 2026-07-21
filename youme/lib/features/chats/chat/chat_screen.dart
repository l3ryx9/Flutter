import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/chat_bubble.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/message_model.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});
  @override State<ChatScreen> createState() => _ChatScreenState();
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

  @override
  void initState() {
    super.initState();
    _sendBtnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _textCtrl.addListener(() => setState(() {}));
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.position.pixels < _scrollCtrl.position.maxScrollExtent - 200;
      if (show != _showScrollToBottom) setState(() => _showScrollToBottom = show);
    });
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _sendBtnCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.client
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('created_at', ascending: false)
          .limit(50);
      setState(() {
        _messages = (data as List<dynamic>)
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (_) { setState(() => _isLoading = false); }
  }

  void _subscribeToMessages() {
    SupabaseService.subscribeToTable(
      table: 'messages', schema: 'public',
      onInsert: (row) {
        if (row['conversation_id'] == widget.conversationId) {
          final msg = MessageModel.fromJson(row);
          setState(() => _messages.insert(0, msg));
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
      await SupabaseService.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': SupabaseService.currentUserId,
        'type': 'text',
        'encrypted_text': text, // TODO: encrypt with E2EE
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {} finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    // TODO: upload to Supabase Storage and send
  }

  Future<void> _shareLocation() async {
    // TODO: get current position and send
    await SupabaseService.client.from('messages').insert({
      'conversation_id': widget.conversationId,
      'sender_id': SupabaseService.currentUserId,
      'type': 'location',
      'location_lat': 48.8566,
      'location_lng': 2.3522,
      'location_label': 'Position actuelle',
      'status': 'sent',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyTop,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
                : Stack(
                    children: [
                      _messages.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                              controller: _scrollCtrl,
                              reverse: true,
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              itemCount: _messages.length,
                              itemBuilder: (_, i) => ChatBubble(
                                message: _messages[i],
                                isSentByMe: _messages[i].senderId == SupabaseService.currentUserId,
                                onReact: (emoji) => _reactToMessage(_messages[i].id, emoji),
                              ),
                            ),
                      if (_showScrollToBottom)
                        Positioned(
                          bottom: 16, right: 16,
                          child: GestureDetector(
                            onTap: () => _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutExpo),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [AppColors.goldLight, AppColors.goldDark]),
                                boxShadow: [BoxShadow(color: AppColors.glowGold.withOpacity(0.5), blurRadius: 12)]),
                              child: const Icon(Icons.keyboard_arrow_down, color: AppColors.woodDark),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF7A4A2A), Color(0xFF4A2510), Color(0xFF6B3D1E)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        border: const Border(bottom: BorderSide(color: AppColors.goldBorder, width: 1)),
      ),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.goldLight, size: 20), onPressed: () => context.pop()),
        UserAvatar(size: 36, isOnline: true),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Partenaire', style: TextStyle(fontFamily: 'Playfair', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
          Text('En ligne', style: TextStyle(fontSize: 11, color: AppColors.onlineGreen)),
        ])),
        IconButton(icon: const Icon(Icons.psychology, color: AppColors.aiPurple, size: 22),
          tooltip: 'Insights IA',
          onPressed: () => context.push('/home/chat/${widget.conversationId}/ai-insights')),
        IconButton(icon: const Icon(Icons.analytics_outlined, color: AppColors.goldLight, size: 22),
          tooltip: 'Analyse',
          onPressed: () => context.push('/home/chat/${widget.conversationId}/analysis')),
        IconButton(icon: const Icon(Icons.flag_outlined, color: AppColors.redFlag, size: 22),
          tooltip: 'Flags',
          onPressed: () => context.push('/home/chat/${widget.conversationId}/flags')),
        IconButton(icon: const Icon(Icons.location_on_outlined, color: AppColors.turquoise, size: 22),
          tooltip: 'Position en direct',
          onPressed: () => context.push('/home/chat/${widget.conversationId}/live-location')),
        const SizedBox(width: 4),
      ]),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🌴', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text('Début de votre conversation', style: TextStyle(fontFamily: 'Playfair', fontSize: 18, color: AppColors.textPrimary)),
        SizedBox(height: 8),
        Text('Envoyez le premier message !', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
      ]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xEE5C3317), Color(0xEE3D1F0B)]),
        border: const Border(top: BorderSide(color: AppColors.goldBorder, width: 0.5)),
        boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Row(children: [
        // Attachment
        GestureDetector(
          onTap: _showAttachmentMenu,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [AppColors.woodLight, AppColors.woodMedium]),
              border: Border.all(color: AppColors.goldBorder.withOpacity(0.5))),
            child: const Icon(Icons.add, color: AppColors.goldLight, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        // Text field
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.creamBase.withOpacity(0.15),
              border: Border.all(color: AppColors.goldBorder.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              maxLines: 5, minLines: 1,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Message…',
                hintStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.4)),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Send/Mic
        GestureDetector(
          onTap: _textCtrl.text.isNotEmpty ? _sendText : null,
          onLongPress: () => setState(() => _isRecording = true),
          onLongPressUp: () => setState(() => _isRecording = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                _textCtrl.text.isNotEmpty ? AppColors.goldLight : AppColors.woodLight,
                _textCtrl.text.isNotEmpty ? AppColors.goldDark : AppColors.woodMedium,
              ]),
              boxShadow: [BoxShadow(
                color: (_textCtrl.text.isNotEmpty ? AppColors.glowGold : Colors.black).withOpacity(0.4),
                blurRadius: 12,
              )],
            ),
            child: Icon(
              _isRecording ? Icons.fiber_manual_record : (_textCtrl.text.isNotEmpty ? Icons.send : Icons.mic),
              color: _textCtrl.text.isNotEmpty ? AppColors.woodDark : AppColors.goldLight,
              size: 20,
            ),
          ),
        ),
      ]),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.woodMedium,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Envoyer', style: TextStyle(fontFamily: 'Playfair', fontSize: 18, color: AppColors.goldLight, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _AttachOption(icon: Icons.image, label: 'Photo', color: AppColors.hibiscusPink, onTap: () { Navigator.pop(context); _pickImage(); }),
            _AttachOption(icon: Icons.videocam, label: 'Vidéo', color: AppColors.aiBlue, onTap: () => Navigator.pop(context)),
            _AttachOption(icon: Icons.location_on, label: 'Position', color: AppColors.error, onTap: () { Navigator.pop(context); _shareLocation(); }),
          ]),
        ]),
      ),
    );
  }

  void _reactToMessage(String messageId, String emoji) async {
    // TODO: update reactions in Supabase
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _AttachOption({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(width: 60, height: 60,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2), border: Border.all(color: color, width: 2)),
        child: Icon(icon, color: color, size: 28)),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
    ]),
  );
}
