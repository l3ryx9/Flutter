import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class ErrorLogEntry {
  final DateTime timestamp;
  final String tag;
  final String message;
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
        if (stackTrace != null) 'stackTrace': stackTrace,
      };

  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) => ErrorLogEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        tag: json['tag'] as String,
        message: json['message'] as String,
        stackTrace: json['stackTrace'] as String?,
      );

  @override
  String toString() =>
      '[${timestamp.toLocal()}] [$tag] $message${stackTrace != null ? '\n$stackTrace' : ''}';
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
      message: message,
      stackTrace: stackTrace?.toString(),
    );
    _entries.add(entry);
    if (_entries.length > AppConstants.maxErrorLogEntries) {
      _entries.removeAt(0);
    }
    _saveToStorage();
    if (kDebugMode) {
      debugPrint('[YouMe][$tag] $message');
    }
  }

  static List<ErrorLogEntry> get entries => List.unmodifiable(_entries);

  static void clear() {
    _entries.clear();
    _prefs?.remove(_key);
  }

  static String export() {
    return _entries.map((e) => e.toString()).join('\n---\n');
  }

  static void _loadFromStorage() {
    final raw = _prefs?.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _entries.addAll(list.map((e) => ErrorLogEntry.fromJson(e as Map<String, dynamic>)));
    } catch (_) {}
  }

  static void _saveToStorage() {
    final raw = jsonEncode(_entries.take(AppConstants.maxErrorLogEntries).map((e) => e.toJson()).toList());
    _prefs?.setString(_key, raw);
  }
}
