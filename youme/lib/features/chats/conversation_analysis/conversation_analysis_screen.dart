import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/wood_card.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/ai_models.dart';
import '../../../core/constants/app_constants.dart';

class ConversationAnalysisScreen extends StatefulWidget {
  final String conversationId;
  const ConversationAnalysisScreen({super.key, required this.conversationId});
  @override State<ConversationAnalysisScreen> createState() => _ConversationAnalysisScreenState();
}

class _ConversationAnalysisScreenState extends State<ConversationAnalysisScreen> {
  DailySummary? _summary;
  PsychologicalProfile? _myProfile;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.currentUserId;
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final summaryData = await SupabaseService.client
          .from(SupabaseKeys.dailySummaries)
          .select()
          .eq('conversation_id', widget.conversationId)
          .eq('date', dateStr)
          .maybeSingle();

      final profileData = await SupabaseService.client
          .from(SupabaseKeys.psychologicalProfiles)
          .select()
          .eq('conversation_id', widget.conversationId)
          .eq('user_id', userId!)
          .maybeSingle();

      setState(() {
        if (summaryData != null) _summary = DailySummary.fromJson(summaryData);
        if (profileData != null) _myProfile = PsychologicalProfile.fromJson(profileData);
        _isLoading = false;
      });
    } catch (_) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyTop,
      appBar: WoodAppBar(title: 'Analyse de conversation'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.aiPurple))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.goldPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_summary != null) _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildRelationshipScore(),
                  const SizedBox(height: 16),
                  if (_myProfile != null) _buildProfileCard('Mon profil psychologique', _myProfile!),
                  const SizedBox(height: 16),
                  _buildFactsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return WoodCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.summarize, color: AppColors.goldLight, size: 20),
          const SizedBox(width: 8),
          const Text('Résumé du jour', style: TextStyle(fontFamily: 'Playfair', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
        ]),
        const SizedBox(height: 12),
        Text(_summary!.summary, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.6)),
      ]),
    );
  }

  Widget _buildRelationshipScore() {
    final score = _summary?.relationshipScore ?? 0.5;
    final percent = (score * 100).toInt();
    Color scoreColor;
    if (score > 0.7) scoreColor = AppColors.greenFlag;
    else if (score > 0.4) scoreColor = AppColors.warning;
    else scoreColor = AppColors.redFlag;

    return WoodCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.favorite, color: AppColors.hibiscusPink, size: 20),
          const SizedBox(width: 8),
          const Text('Score relationnel', style: TextStyle(fontFamily: 'Playfair', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
          const Spacer(),
          Text('$percent%', style: TextStyle(fontFamily: 'Playfair', fontSize: 28, fontWeight: FontWeight.bold, color: scoreColor)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score, minHeight: 12, color: scoreColor,
            backgroundColor: AppColors.woodDark.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        Text(score > 0.7 ? '💚 Relation épanouie' : score > 0.4 ? '💛 Relation stable' : '🔴 Attention requise',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      ]),
    );
  }

  Widget _buildProfileCard(String title, PsychologicalProfile profile) {
    return WoodCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.person_search, color: AppColors.aiPurple, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontFamily: 'Playfair', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
        ]),
        const SizedBox(height: 12),
        if (profile.traits.isNotEmpty) ...[
          const Text('Traits de caractère', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: profile.traits.map((t) =>
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.aiPurple.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.4))),
              child: Text(t, style: const TextStyle(color: AppColors.aiPurple, fontSize: 11)))
          ).toList()),
          const SizedBox(height: 12),
        ],
        if (profile.generalTone.isNotEmpty) ...[
          const Text('Ton général', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(profile.generalTone, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 12),
        ],
        if (profile.behavioralAdvice.isNotEmpty) ...[
          const Text('Conseils comportementaux', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...profile.behavioralAdvice.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('• ', style: TextStyle(color: AppColors.goldLight, fontSize: 16)),
              Expanded(child: Text(a, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4))),
            ]),
          )),
        ],
        if (profile.possibleAvoidance) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
            color: AppColors.warning.withValues(alpha: 0.15), border: Border.all(color: AppColors.warning.withValues(alpha: 0.4))),
            child: const Row(children: [
              Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Signes possibles d\'évitement détectés.', style: TextStyle(color: AppColors.warning, fontSize: 12))),
            ]))
        ],
      ]),
    );
  }

  Widget _buildFactsCard() {
    if (_summary == null || _summary!.highlightedFacts.isEmpty) return const SizedBox();
    return WoodCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.star, color: AppColors.goldLight, size: 20),
          SizedBox(width: 8),
          Text('Faits marquants', style: TextStyle(fontFamily: 'Playfair', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
        ]),
        const SizedBox(height: 12),
        ..._summary!.highlightedFacts.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.goldLight, AppColors.goldDark])),
              child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.woodDark)))),
            Expanded(child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4))),
          ]),
        )),
      ]),
    );
  }
}
