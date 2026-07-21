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
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _load();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testApi() async {
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
        _apiTestResult = '✗ Erreur: ${e.toString().substring(0, 80)}';
        _isTestingApi = false;
      });
    }
  }

  Future<void> _exportLogs() async {
    final buffer = StringBuffer();
    buffer.writeln('=== YouMe Debug Log Export ===');
    buffer.writeln('Exported at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('User ID: ${SupabaseService.currentUserId ?? "unknown"}');
    buffer.writeln('=====================================\n');
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.goldPrimary))
          : FadeTransition(
              opacity: _entryCtrl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSystemInfo(),
                    const SizedBox(height: 16),
                    _buildApiTest(),
                    const SizedBox(height: 16),
                    _buildLogPanel(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSystemInfo() {
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.goldLight, size: 20),
              SizedBox(width: 8),
              Text('Informations système',
                  style: TextStyle(
                      fontFamily: 'Playfair',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLight)),
            ],
          ),
          const SizedBox(height: 14),
          ..._systemInfo.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(e.key,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: e.value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${e.key} copié'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Text(
                          e.value,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildApiTest() {
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.network_check, color: AppColors.turquoise, size: 20),
              SizedBox(width: 8),
              Text('Test API',
                  style: TextStyle(
                      fontFamily: 'Playfair',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLight)),
            ],
          ),
          const SizedBox(height: 14),
          WoodButton(
            label: 'Tester la connexion Supabase',
            icon: Icons.cloud_outlined,
            isLoading: _isTestingApi,
            onPressed: _isTestingApi ? null : _testApi,
          ),
          if (_apiTestResult.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _apiTestResult.startsWith('✓')
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _apiTestResult.startsWith('✓')
                      ? AppColors.success.withOpacity(0.4)
                      : AppColors.error.withOpacity(0.4),
                ),
              ),
              child: Text(
                _apiTestResult,
                style: TextStyle(
                  color: _apiTestResult.startsWith('✓')
                      ? AppColors.success
                      : AppColors.error,
                  fontSize: 13,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogPanel() {
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: AppColors.goldLight, size: 20),
              const SizedBox(width: 8),
              const Text('Journal des erreurs',
                  style: TextStyle(
                      fontFamily: 'Playfair',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLight)),
              const Spacer(),
              Text('${_logs.length} entrées',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _logs.isEmpty ? null : _exportLogs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.turquoise.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.turquoise.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, color: AppColors.turquoise, size: 16),
                        SizedBox(width: 6),
                        Text('Exporter',
                            style: TextStyle(
                                color: AppColors.turquoise,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _logs.isEmpty ? null : _clearLogs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                        SizedBox(width: 6),
                        Text('Effacer',
                            style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_logs.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _logs.length,
                  reverse: true,
                  itemBuilder: (_, i) {
                    final log = _logs[_logs.length - 1 - i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '[${log.tag}]',
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                log.timestamp.toIso8601String().substring(11, 19),
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                          Text(
                            log.message,
                            style: const TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontSize: 11,
                              fontFamily: 'Courier',
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Divider(color: Color(0x22FFFFFF), height: 10),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.success.withOpacity(0.6), size: 40),
                  const SizedBox(height: 8),
                  const Text('Aucune erreur enregistrée',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
