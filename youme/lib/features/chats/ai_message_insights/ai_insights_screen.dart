import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/wood_card.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/ai_models.dart';
import '../../../core/constants/app_constants.dart';

class AiInsightsScreen extends StatefulWidget {
  final String conversationId;
  const AiInsightsScreen({super.key, required this.conversationId});
  @override State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> with SingleTickerProviderStateMixin {
  List<MessageInsight> _insights = [];
  bool _isLoading = true;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _loadInsights();
  }
  @override void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.client
          .from(SupabaseKeys.aiMessageInsights)
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('analyzed_at', ascending: false)
          .limit(50);
      setState(() {
        _insights = (data as List<dynamic>).map((e) => MessageInsight.fromJson(e as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
      _animCtrl.forward();
    } catch (_) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyTop,
      appBar: WoodAppBar(title: 'Insights IA', actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.aiPurple.withOpacity(0.2),
              border: Border.all(color: AppColors.aiPurple.withOpacity(0.6))),
            child: const Icon(Icons.psychology, color: AppColors.aiPurple, size: 20)),
        ),
      ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.aiPurple))
          : _insights.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _insights.length,
                  itemBuilder: (_, i) {
                    final delay = i * 0.08;
                    final anim = CurvedAnimation(parent: _animCtrl,
                      curve: Interval(delay.clamp(0.0, 0.9), (delay + 0.35).clamp(0.0, 1.0), curve: Curves.easeOutExpo));
                    return AnimatedBuilder(
                      animation: anim,
                      builder: (_, child) => FadeTransition(opacity: anim,
                        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim), child: child)),
                      child: _InsightCard(insight: _insights[i]),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🧠', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('Aucun insight disponible', style: TextStyle(fontFamily: 'Playfair', fontSize: 20, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('L\'IA analysera vos messages au fil de la conversation.', textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textPrimary.withOpacity(0.6), fontSize: 13)),
    ]));
  }
}

class _InsightCard extends StatelessWidget {
  final MessageInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WoodCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _EmotionBadge(emotion: insight.emotion, score: insight.emotionScore),
            const Spacer(),
            Text(_formatDate(insight.analyzedAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 12),
          Text(insight.summary, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
          if (insight.topics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6,
              children: insight.topics.map((t) => _Tag(label: t, color: AppColors.aiPurple)).toList()),
          ],
          if (insight.entities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6,
              children: insight.entities.map((e) => _Tag(label: e, color: AppColors.turquoise)).toList()),
          ],
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _EmotionBadge extends StatelessWidget {
  final String emotion; final double score;
  const _EmotionBadge({required this.emotion, required this.score});

  Color get _color {
    switch (emotion.toLowerCase()) {
      case 'joie': case 'happy': return AppColors.success;
      case 'tristesse': case 'sad': return AppColors.aiBlue;
      case 'colère': case 'anger': return AppColors.error;
      case 'peur': case 'fear': return AppColors.warning;
      case 'dégoût': return AppColors.redFlag;
      case 'surprise': return AppColors.sunsetOrange;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _color.withOpacity(0.2),
      border: Border.all(color: _color.withOpacity(0.6))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _color)),
      const SizedBox(width: 6),
      Text(emotion, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(width: 4),
      Text('${(score * 100).toInt()}%', style: TextStyle(color: _color.withOpacity(0.7), fontSize: 11)),
    ]),
  );
}

class _Tag extends StatelessWidget {
  final String label; final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withOpacity(0.15),
      border: Border.all(color: color.withOpacity(0.4))),
    child: Text(label, style: TextStyle(color: color, fontSize: 11)),
  );
}
