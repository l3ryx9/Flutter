import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class ErrorLogEntry {
  final DateTime timestamp;
  final String tag;
  final String message;
  // SÉCURITÉ : en release, les stack traces ne sont jamais stockées
  final String? stackTrace;

  ErrorLogEntry({
    required this.timestamp,
    required this.tag,
    required this.message,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'tag': tag,
        'message': message,
        // Stack traces uniquement en debug
        if (kDebugMode && stackTrace != null) 'stackTrace': stackTrace,
      };

  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) => ErrorLogEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        tag: json['tag'] as String,
        message: json['message'] as String,
        stackTrace: json['stackTrace'] as String?,
      );

  @override
  String toString() =>
      '[${timestamp.toLocal()}] [$tag] $message'
      '${kDebugMode && stackTrace != null ? '\n$stackTrace' : ''}';
}

class ErrorLogger {
  static const _key = 'error_log_entries';
  static final List<ErrorLogEntry> _entries = [];
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromStorage();
  }

  static void log(String tag, String message, {StackTrace? stackTrace}) {
    final entry = ErrorLogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      // SÉCURITÉ : en release, le message est tronqué à 200 caractères
      // pour éviter de stocker des données sensibles dans les logs
      message: kDebugMode ? message : message.substring(0, message.length.clamp(0, 200)),
      // SÉCURITÉ : stack traces uniquement en debug
      stackTrace: kDebugMode ? stackTrace?.toString() : null,
    );
    _entries.add(entry);
    if (_entries.length > AppConstants.maxErrorLogEntries) {
      _entries.removeAt(0);
    }
    _saveToStorage();

    // SÉCURITÉ : debugPrint uniquement en mode debug (jamais en release)
    if (kDebugMode) {
      debugPrint('[YouMe][$tag] $message');
    }
    // En release : aucune sortie console (les logs Android sont désactivés
    // via ProGuard dans proguard-rules.pro)
  }

  static List<ErrorLogEntry> get entries => List.unmodifiable(_entries);

  static void clear() {
    _entries.clear();
    _prefs?.remove(_key);
  }

  /// Export des logs — disponible uniquement en debug
  static String export() {
    if (!kDebugMode) return '';
    return _entries.map((e) => e.toString()).join('\n---\n');
  }

  static void _loadFromStorage() {
    final raw = _prefs?.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _entries.addAll(list
          .map((e) => ErrorLogEntry.fromJson(e as Map<String, dynamic>)));
    } catch (_) {}
  }

  static void _saveToStorage() {
    final raw = jsonEncode(_entries
        .take(AppConstants.maxErrorLogEntries)
        .map((e) => e.toJson())
        .toList());
    _prefs?.setString(_key, raw);
  }
}
