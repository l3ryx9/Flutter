import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSentByMe;
  final bool showTimestamp;
  final void Function(String emoji)? onReact;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.showTimestamp = true,
    this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isSentByMe ? 64 : 12,
        right: isSentByMe ? 12 : 64,
        top: 4, bottom: 4,
      ),
      child: Column(
        crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'message_${message.id}',
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onLongPress: () => _showReactionPicker(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutExpo,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isSentByMe ? 20 : 4),
                      bottomRight: Radius.circular(isSentByMe ? 4 : 20),
                    ),
                    gradient: isSentByMe
                        ? AppColors.bubbleSentGradient
                        : AppColors.bubbleReceivedGradient,
                    boxShadow: [
                      BoxShadow(
                        color: (isSentByMe ? AppColors.woodDark : AppColors.oceanBlue).withValues(alpha: 0.5),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.08),
                        blurRadius: 2, offset: const Offset(0, -1),
                      ),
                    ],
                    border: Border.all(
                      color: isSentByMe
                          ? AppColors.goldBorder.withValues(alpha: 0.3)
                          : AppColors.turquoise.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Glass gloss
                      Positioned(
                        top: 0, left: 0, right: 0, height: 24,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.white.withValues(alpha: 0.15), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: _buildContent(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (message.reactions != null && message.reactions!.isNotEmpty)
            _buildReactions(),
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  if (isSentByMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.decryptedText ?? '🔐',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.4),
        );
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(width: 200, height: 150,
            child: Center(child: Icon(Icons.image, color: AppColors.textMuted, size: 48)),
          ),
        );
      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq, color: AppColors.goldLight, size: 20),
            const SizedBox(width: 8),
            Expanded(child: LinearProgressIndicator(
              value: 0, color: AppColors.goldPrimary,
              backgroundColor: AppColors.woodDark.withValues(alpha: 0.3),
            )),
            const SizedBox(width: 8),
            Text(message.voiceDuration ?? '0:00',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        );
      case MessageType.location:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: AppColors.error, size: 20),
            const SizedBox(width: 6),
            const Text('Position partagée', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ],
        );
      case MessageType.system:
        return Text(
          message.decryptedText ?? '',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        );
      default:
        return Text(message.decryptedText ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15));
    }
  }

  Widget _buildReactions() {
    return Wrap(
      children: (message.reactions ?? {}).entries.map((e) => Container(
        margin: const EdgeInsets.only(top: 3, right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.woodSurface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldBorder.withValues(alpha: 0.4)),
        ),
        child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 12)),
      )).toList(),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textMuted));
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: AppColors.textMuted);
      case MessageStatus.received:
        return const Icon(Icons.done_all, size: 12, color: AppColors.textMuted);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 12, color: AppColors.turquoise);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: AppColors.error);
    }
  }

  void _showReactionPicker(BuildContext context) {
    const emojis = ['❤️', '😍', '😂', '😮', '😢', '👍'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.woodMedium,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis.map((e) => GestureDetector(
            onTap: () { Navigator.pop(context); onReact?.call(e); },
            child: Text(e, style: const TextStyle(fontSize: 32)),
          )).toList(),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
