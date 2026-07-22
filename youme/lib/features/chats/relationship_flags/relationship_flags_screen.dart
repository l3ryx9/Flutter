import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/wood_card.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/ai_models.dart';
import '../../../core/constants/app_constants.dart';

class RelationshipFlagsScreen extends StatefulWidget {
  final String conversationId;
  const RelationshipFlagsScreen({super.key, required this.conversationId});
  @override State<RelationshipFlagsScreen> createState() => _RelationshipFlagsScreenState();
}

class _RelationshipFlagsScreenState extends State<RelationshipFlagsScreen> with SingleTickerProviderStateMixin {
  List<RelationshipFlag> _flags = [];
  bool _isLoading = true;
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _load(); }
  @override void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.client
          .from(SupabaseKeys.relationshipFlags)
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('detected_at', ascending: false);
      setState(() {
        _flags = (data as List<dynamic>).map((e) => RelationshipFlag.fromJson(e as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } catch (_) { setState(() => _isLoading = false); }
  }

  List<RelationshipFlag> get _greenFlags => _flags.where((f) => f.type == FlagType.greenFlag).toList();
  List<RelationshipFlag> get _redFlags => _flags.where((f) => f.type == FlagType.redFlag).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyTop,
      appBar: WoodAppBar(
        title: 'Signaux relationnels',
        actions: [
          Padding(padding: const EdgeInsets.only(right: 8),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.woodSurface,
                border: Border.all(color: AppColors.goldBorder.withValues(alpha: 0.5))),
              child: Text('${_greenFlags.length} ✅ · ${_redFlags.length} 🚩',
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.bold)))),
        ],
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [AppColors.woodMedium, AppColors.woodDark]),
            border: Border.all(color: AppColors.goldBorder.withValues(alpha: 0.4))),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [AppColors.goldLight, AppColors.goldDark])),
            labelColor: AppColors.woodDark, unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: '✅ Green Flags (${_greenFlags.length})'),
              Tab(text: '🚩 Red Flags (${_redFlags.length})'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _FlagList(flags: _greenFlags, isGreen: true),
                    _FlagList(flags: _redFlags, isGreen: false),
                  ],
                ),
        ),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.info.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3))),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppColors.info, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('Ces signaux sont des indicateurs probabilistes générés par IA, jamais des preuves. Utilisez votre jugement.',
              style: TextStyle(color: AppColors.info, fontSize: 11, height: 1.4))),
          ]),
        ),
      ]),
    );
  }
}

class _FlagList extends StatelessWidget {
  final List<RelationshipFlag> flags;
  final bool isGreen;
  const _FlagList({required this.flags, required this.isGreen});

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(isGreen ? '🌱' : '😊', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(isGreen ? 'Aucun signal positif détecté.' : 'Aucun signal négatif détecté.',
          style: const TextStyle(fontFamily: 'Playfair', fontSize: 16, color: AppColors.textPrimary)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: flags.length,
      itemBuilder: (_, i) => _FlagCard(flag: flags[i], isGreen: isGreen),
    );
  }
}

class _FlagCard extends StatelessWidget {
  final RelationshipFlag flag;
  final bool isGreen;
  const _FlagCard({required this.flag, required this.isGreen});

  Color get _color => isGreen ? AppColors.greenFlag : AppColors.redFlag;
  Color get _severityColor {
    switch (flag.severity) {
      case FlagSeverity.low: return AppColors.success;
      case FlagSeverity.medium: return AppColors.warning;
      case FlagSeverity.high: return AppColors.sunsetOrange;
      case FlagSeverity.critical: return AppColors.error;
    }
  }
  String get _severityLabel {
    switch (flag.severity) {
      case FlagSeverity.low: return 'Faible';
      case FlagSeverity.medium: return 'Modéré';
      case FlagSeverity.high: return 'Élevé';
      case FlagSeverity.critical: return 'Critique';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WoodCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isGreen ? Icons.check_circle : Icons.flag, color: _color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(flag.description,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3))),
          ]),
          const SizedBox(height: 10),
          if (flag.messageQuote != null) ...[
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _color.withValues(alpha: 0.1),
                border: Border(left: BorderSide(color: _color, width: 3))),
              child: Text('"${flag.messageQuote}"', style: TextStyle(color: _color, fontSize: 12, fontStyle: FontStyle.italic))),
            const SizedBox(height: 10),
          ],
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _severityColor.withValues(alpha: 0.15),
                border: Border.all(color: _severityColor.withValues(alpha: 0.4))),
              child: Text(_severityLabel, style: TextStyle(color: _severityColor, fontSize: 11, fontWeight: FontWeight.bold))),
            const Spacer(),
            Text(_formatDate(flag.detectedAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
