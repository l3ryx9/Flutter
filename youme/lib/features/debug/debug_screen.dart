import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/wood_card.dart';
import '../../../core/widgets/wood_button.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/error_logger.dart';
import '../../../core/constants/app_constants.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});
  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen>
    with TickerProviderStateMixin {
  List<ErrorLogEntry> _logs = [];
  Map<String, dynamic> _systemInfo = {};
  bool _isLoading = true;
  bool _isTestingApi = false;
  String _apiTestResult = '';
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    // SECURITY: Debug screen is restricted to debug builds only.
    // In production, redirect immediately back.
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    if (kReleaseMode) return; // Don't load sensitive data in release
    _load();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (kReleaseMode) return;
    setState(() => _isLoading = true);
    try {
      final logs = ErrorLogger.entries.toList();
      final userId = SupabaseService.currentUserId;
      final session = SupabaseService.client.auth.currentSession;

      setState(() {
        _logs = logs;
        _systemInfo = {
          'User ID': userId ?? '—',
          'Session expires': session?.expiresAt != null
              ? DateTime.fromMillisecondsSinceEpoch(session!.expiresAt! * 1000)
                  .toString()
              : '—',
          'Supabase URL': AppConstants.supabaseUrl,
          'App version': AppConstants.appVersion,
          'Total logs': logs.length.toString(),
          'Build mode': kDebugMode ? 'DEBUG' : kProfileMode ? 'PROFILE' : 'RELEASE',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testApi() async {
    if (kReleaseMode) return;
    setState(() {
      _isTestingApi = true;
      _apiTestResult = '';
    });
    try {
      final start = DateTime.now();
      final res = await SupabaseService.client.functions.invoke('health-check');
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      setState(() {
        _apiTestResult = '✓ API OK en ${elapsed}ms — ${res.status}';
        _isTestingApi = false;
      });
    } catch (e) {
      setState(() {
        _apiTestResult = '✗ Erreur: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}';
        _isTestingApi = false;
      });
    }
  }

  Future<void> _exportLogs() async {
    if (kReleaseMode) return;
    final buffer = StringBuffer();
    buffer.writeln('=== YouMe Debug Log Export ===');
    buffer.writeln('Exported at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Build: ${kDebugMode ? "DEBUG" : "PROFILE"}');
    buffer.writeln('=====================================\n');
    // Note: User ID intentionally omitted from exports for privacy
    for (final log in _logs) {
      buffer.writeln('[${log.timestamp}] [${log.tag}]');
      buffer.writeln('  ${log.message}');
      if (log.stackTrace != null) {
        buffer.writeln('  Stack: ${log.stackTrace}');
      }
      buffer.writeln();
    }
    await Share.share(buffer.toString(), subject: 'YouMe Debug Logs');
  }

  void _clearLogs() {
    if (kReleaseMode) return;
    ErrorLogger.clear();
    setState(() => _logs = []);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs effacés ✓'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SECURITY: Block access in production builds entirely
    if (kReleaseMode) {
      return Scaffold(
        backgroundColor: AppColors.skyTop,
        appBar: WoodAppBar(title: 'Mode développeur'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock, color: AppColors.goldLight, size: 64),
              SizedBox(height: 16),
              Text(
                'Accès restreint',
                style: TextStyle(
                  fontFamily: 'Playfair',
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Cette section est réservée aux builds de développement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.skyTop,
      appBar: WoodAppBar(
        title: 'Mode développeur',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.goldLight),
              onPressed: _load,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _entryCtrl,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // System info
                  WoodCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Info système',
                            style: TextStyle(
                                fontFamily: 'Playfair',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldLight)),
                        const SizedBox(height: 12),
                        ..._systemInfo.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(children: [
                                Text('${e.key}: ',
                                    style: const TextStyle(
                                        color: AppColors.textMuted, fontSize: 12)),
                                Expanded(
                                    child: Text(e.value.toString(),
                                        style: const TextStyle(
                                            color: AppColors.textPrimary, fontSize: 12))),
                              ]),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // API test
                  WoodCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Test API',
                            style: TextStyle(
                                fontFamily: 'Playfair',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldLight)),
                        const SizedBox(height: 12),
                        WoodButton(
                          label: 'Tester la connexion Edge Function',
                          isLoading: _isTestingApi,
                          onPressed: _testApi,
                          icon: Icons.wifi,
                        ),
                        if (_apiTestResult.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_apiTestResult,
                              style: TextStyle(
                                  color: _apiTestResult.startsWith('✓')
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Logs
                  WoodCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Expanded(
                            child: Text('Logs d\'erreur',
                                style: TextStyle(
                                    fontFamily: 'Playfair',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldLight)),
                          ),
                          TextButton.icon(
                            onPressed: _exportLogs,
                            icon: const Icon(Icons.share, size: 16, color: AppColors.aiBlue),
                            label: const Text('Exporter',
                                style: TextStyle(color: AppColors.aiBlue, fontSize: 12)),
                          ),
                          TextButton.icon(
                            onPressed: _clearLogs,
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                            label: const Text('Effacer',
                                style: TextStyle(color: AppColors.error, fontSize: 12)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        if (_logs.isEmpty)
                          const Text('Aucun log.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                        else
                          ..._logs.take(50).map((log) => GestureDetector(
                                onLongPress: () {
                                  Clipboard.setData(ClipboardData(text: log.toString()));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copié ✓')),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.woodDark,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('[${log.tag}]',
                                          style: const TextStyle(
                                              color: AppColors.warning,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                      Text(log.message,
                                          style: const TextStyle(
                                              color: AppColors.textPrimary, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
