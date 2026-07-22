import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_text_field.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/app_constants.dart';

class AiSearchScreen extends StatefulWidget {
  const AiSearchScreen({super.key});
  @override
  State<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends State<AiSearchScreen>
    with TickerProviderStateMixin {
  final _queryCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isThinking = false;
  late AnimationController _pulseCtrl;
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _messages.add(_ChatMessage(
      isUser: false,
      text: 'Bonjour 💛 Je suis votre assistant IA YouMe. Posez-moi des questions sur vos conversations, votre relation ou demandez-moi des conseils !',
    ));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty || _isThinking) return;
    _queryCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: query));
      _isThinking = true;
    });
    _scrollToBottom();

    try {
      final result = await SupabaseService.callFunction(
        SupabaseKeys.fnGeminiChat,
        body: {'query': query, 'userId': SupabaseService.currentUserId},
      );
      final reply = result['reply'] as String? ??
          'Désolé, je n\'ai pas pu générer de réponse.';
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: reply));
        _isThinking = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(_ChatMessage(
          isUser: false,
          text: 'Je suis temporairement indisponible. Réessayez dans quelques instants.',
          isError: true,
        ));
        _isThinking = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutExpo,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          if (_isThinking) _buildThinkingIndicator(),
          _buildInputArea(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _entryCtrl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            // IA icon with glow
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(colors: [
                    AppColors.aiPurple,
                    Color(0xFF6B1FA3),
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.aiPurple
                          .withValues(alpha: 0.3 + _pulseCtrl.value * 0.3),
                      blurRadius: 16 + _pulseCtrl.value * 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assistant IA',
                  style: TextStyle(
                    fontFamily: 'Playfair',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldLight,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Propulsé par Gemini',
                  style: TextStyle(
                    color: AppColors.aiPurple.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        return _MessageBubble(message: _messages[i]);
      },
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.aiPurple.withValues(alpha: 0.3),
                  AppColors.aiBlue.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.4)),
            ),
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300 + i * 100),
                      width: 6,
                      height: 6 + (_pulseCtrl.value * 4 * (i == 1 ? 1.5 : 1)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            AppColors.aiPurple.withValues(alpha: 0.6 + _pulseCtrl.value * 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.skyTop.withValues(alpha: 0),
            AppColors.skyTop.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: WoodTextField(
              label: 'Posez une question...',
              controller: _queryCtrl,
              onSubmitted: (_) => _send(),
              prefixIcon: Icons.auto_awesome,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isThinking ? null : _send,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isThinking
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.aiPurple, Color(0xFF4A0082)],
                        ),
                  color: _isThinking ? AppColors.woodMedium : null,
                  boxShadow: _isThinking
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.aiPurple.withValues(alpha: 
                                0.4 + _pulseCtrl.value * 0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                ),
                child: Icon(
                  _isThinking ? Icons.hourglass_empty : Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ─────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 20),
            ),
            gradient: isUser
                ? const LinearGradient(
                    colors: [Color(0xFF7A4A2A), Color(0xFF5C3317)],
                  )
                : message.isError
                    ? LinearGradient(
                        colors: [
                          AppColors.error.withValues(alpha: 0.3),
                          AppColors.error.withValues(alpha: 0.15),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.aiPurple.withValues(alpha: 0.3),
                          AppColors.aiBlue.withValues(alpha: 0.2),
                        ],
                      ),
            border: Border.all(
              color: isUser
                  ? AppColors.goldBorder.withValues(alpha: 0.4)
                  : message.isError
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.aiPurple.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        message.isError ? Icons.error_outline : Icons.auto_awesome,
                        color: message.isError ? AppColors.error : AppColors.aiPurple,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.isError ? 'Erreur' : 'Assistant IA',
                        style: TextStyle(
                          color: message.isError ? AppColors.error : AppColors.aiPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                message.text,
                style: TextStyle(
                  color: isUser ? AppColors.creamLight : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final bool isError;
  _ChatMessage({required this.isUser, required this.text, this.isError = false});
}

// ─── Suggestion chips ───────────────────────────────────────────────────────
// ignore: unused_element
class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.aiPurple.withValues(alpha: 0.2),
              AppColors.aiBlue.withValues(alpha: 0.15),
            ],
          ),
          border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: const TextStyle(color: AppColors.aiPurple, fontSize: 13)),
      ),
    );
  }
}
