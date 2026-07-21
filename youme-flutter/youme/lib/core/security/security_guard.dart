// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// ═══════════════════════════════════════════════════════════════════════════
/// SecurityGuard — Multicouche protection contre :
///   • Root / Jailbreak
///   • Émulateurs
///   • Outils de hooking (Frida, Xposed, LSPosed, Magisk)
///   • APK repackagé / signature modifiée
///   • Environnements de débogage non autorisés
/// ═══════════════════════════════════════════════════════════════════════════
class SecurityGuard {
  SecurityGuard._();

  /// Package name attendu — modifiez si vous changez l'applicationId
  static const _expectedPackage = 'com.youme.app';

  /// Hash SHA-256 du certificat de release (à remplacer par votre vrai hash)
  /// Générez-le avec :
  ///   keytool -printcert -jarfile app-release.apk | grep SHA256
  /// puis encodez en base64 et placez ici.
  /// Laissez vide pour désactiver la vérification en CI (sans keystore de release).
  static const _expectedCertHash = ''; // TODO: remplir avant release finale

  // ─── Chemins suspects indiquant un root ────────────────────────────────
  static const _rootPaths = [
    '/system/app/Superuser.apk',
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/data/local/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/system/bin/.ext/.su',
    '/system/usr/we-need-root/su',
    '/cache/su',
    '/data/su',
    '/dev/com.koushikdutta.superuser.daemon/',
    '/system/app/SuperSU.apk',
    '/system/app/SuperSU/',
    '/system/xbin/daemonsu',
    '/system/etc/init.d/99SuperSUDaemon',
    '/dev/com.noshufou.android.su',
  ];

  // ─── Chemins suspects indiquant Frida ────────────────────────────────────
  static const _fridaPaths = [
    '/data/local/tmp/frida-server',
    '/data/local/tmp/re.frida.server',
    '/sdcard/frida-server',
    '/tmp/frida-server',
  ];

  // ─── Chemins suspects indiquant Xposed / LSPosed / EdXposed ─────────────
  static const _hookingPaths = [
    '/system/framework/XposedBridge.jar',
    '/system/lib/libxposed_art.so',
    '/system/lib64/libxposed_art.so',
    '/system/xposed.prop',
    '/data/adb/lspatch',
    '/data/adb/modules/lsposed',
    '/data/adb/modules/EdXposed-v5',
    '/data/adb/modules/zygisk_lsposed',
    '/data/adb/modules/riru_lsposed',
  ];

  // ─── Chemins suspects indiquant Magisk ───────────────────────────────────
  static const _magiskPaths = [
    '/sbin/.magisk',
    '/sbin/.core/mirror',
    '/sbin/.core/img',
    '/data/adb/magisk',
    '/data/adb/magisk.img',
    '/cache/magisk.img',
    '/dev/magisk',
    '/sbin/magisk',
  ];

  /// Lance toutes les vérifications de sécurité.
  /// Retourne un [SecurityReport] décrivant chaque menace détectée.
  static Future<SecurityReport> runAll() async {
    // En mode debug, on passe toutes les vérifications pour ne pas gêner
    // le développement — sauf si vous souhaitez tester la détection.
    if (kDebugMode) {
      return SecurityReport.clean();
    }

    final results = await Future.wait([
      _checkRoot(),
      _checkEmulator(),
      _checkHookingFrameworks(),
      _checkPackageIntegrity(),
      _checkDebuggability(),
    ]);

    return SecurityReport(
      isRooted: results[0],
      isEmulator: results[1],
      hasHookingFramework: results[2],
      hasPackageTampered: results[3],
      isDebuggable: results[4],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Root / Jailbreak detection
  // ══════════════════════════════════════════════════════════════════════════

  static Future<bool> _checkRoot() async {
    if (!Platform.isAndroid) return false;

    // 1. Vérification des fichiers suspects
    for (final path in [..._rootPaths, ..._magiskPaths]) {
      if (await _fileExists(path)) return true;
    }

    // 2. Tentative d'exécution de 'su' — si ça réussit, l'appareil est rooté
    try {
      final result = await Process.run('su', ['-c', 'id'],
              runInShell: true)
          .timeout(const Duration(seconds: 2));
      if (result.exitCode == 0) return true;
    } catch (_) {
      // Échoue normalement sur un appareil non rooté
    }

    // 3. Vérification de l'existence de binaires dangereux via PATH
    try {
      final result = await Process.run('which', ['su'])
          .timeout(const Duration(seconds: 2));
      if (result.stdout.toString().isNotEmpty) return true;
    } catch (_) {}

    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Emulator detection
  // ══════════════════════════════════════════════════════════════════════════

  static Future<bool> _checkEmulator() async {
    if (!Platform.isAndroid) return false;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;

      // Heuristiques d'émulateur
      final suspicious = [
        android.fingerprint.contains('generic'),
        android.fingerprint.contains('unknown'),
        android.model.contains('google_sdk'),
        android.model.contains('Emulator'),
        android.model.contains('Android SDK built for x86'),
        android.manufacturer.contains('Genymotion'),
        android.manufacturer.toLowerCase().contains('unknown'),
        android.hardware.contains('goldfish'),
        android.hardware.contains('ranchu'),
        android.hardware.contains('vbox86'),
        android.brand.startsWith('generic'),
        android.device.contains('generic'),
        android.product.contains('sdk'),
        android.product.contains('vbox'),
        android.isPhysicalDevice == false,
        // QEMU fingerprint
        android.fingerprint.startsWith('generic:'),
      ];

      return suspicious.where((e) => e).length >= 2;
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Hooking frameworks (Frida, Xposed, LSPosed)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<bool> _checkHookingFrameworks() async {
    if (!Platform.isAndroid) return false;

    // 1. Chemins de fichiers Frida
    for (final path in _fridaPaths) {
      if (await _fileExists(path)) return true;
    }

    // 2. Chemins de fichiers Xposed / LSPosed
    for (final path in _hookingPaths) {
      if (await _fileExists(path)) return true;
    }

    // 3. Détection Frida via port (port 27042 par défaut de frida-server)
    try {
      final socket = await Socket.connect(
        '127.0.0.1',
        27042,
        timeout: const Duration(milliseconds: 300),
      );
      socket.destroy();
      return true; // Frida server actif !
    } catch (_) {
      // Normal — port fermé sur un appareil propre
    }

    // 4. Détection via /proc/self/maps (bibliothèques Frida chargées)
    try {
      final maps = File('/proc/self/maps');
      if (await maps.exists()) {
        final content = await maps.readAsString();
        final fridaIndicators = [
          'frida',
          'gum-js-loop',
          'gmain',
          'linjector',
          'libfrida',
        ];
        for (final indicator in fridaIndicators) {
          if (content.contains(indicator)) return true;
        }
      }
    } catch (_) {}

    // 5. Détection via propriétés système
    try {
      final result = await Process.run('getprop', [])
          .timeout(const Duration(seconds: 2));
      final props = result.stdout.toString();
      if (props.contains('ro.debuggable=1') ||
          props.contains('service.adb.root=1')) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Package integrity (APK repackagé / signature modifiée)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<bool> _checkPackageIntegrity() async {
    try {
      final info = await PackageInfo.fromPlatform();

      // Vérification du nom de package
      if (info.packageName != _expectedPackage) {
        return true; // APK repackagé avec un autre package name
      }

      // Vérification du hash du certificat si configuré
      if (_expectedCertHash.isNotEmpty) {
        final certHash = await _getCertificateHash();
        if (certHash != null && certHash != _expectedCertHash) {
          return true; // Signature modifiée
        }
      }

      return false;
    } catch (_) {
      return false; // Erreur de lecture → ne pas bloquer l'app
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Debuggability check
  // ══════════════════════════════════════════════════════════════════════════

  static Future<bool> _checkDebuggability() async {
    // kDebugMode est false en release — c'est la vérification principale côté Dart
    if (kDebugMode || kProfileMode) return true;

    // Vérification native via getprop
    try {
      final result = await Process.run('getprop', ['ro.debuggable'])
          .timeout(const Duration(seconds: 1));
      return result.stdout.toString().trim() == '1';
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════════════════

  static Future<bool> _fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }

  /// Récupère le hash SHA-256 du certificat de signature via un MethodChannel
  static Future<String?> _getCertificateHash() async {
    try {
      const channel = MethodChannel('com.youme.app/security');
      final certBytes = await channel.invokeMethod<Uint8List>('getCertificate');
      if (certBytes == null) return null;
      final digest = sha256.convert(certBytes);
      return base64.encode(digest.bytes);
    } catch (_) {
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SecurityReport — résultat de l'audit de sécurité
// ═══════════════════════════════════════════════════════════════════════════

class SecurityReport {
  final bool isRooted;
  final bool isEmulator;
  final bool hasHookingFramework;
  final bool hasPackageTampered;
  final bool isDebuggable;

  const SecurityReport({
    required this.isRooted,
    required this.isEmulator,
    required this.hasHookingFramework,
    required this.hasPackageTampered,
    required this.isDebuggable,
  });

  factory SecurityReport.clean() => const SecurityReport(
        isRooted: false,
        isEmulator: false,
        hasHookingFramework: false,
        hasPackageTampered: false,
        isDebuggable: false,
      );

  /// true si au moins une menace critique est détectée
  bool get hasCriticalThreat =>
      isRooted || hasHookingFramework || hasPackageTampered;

  /// true si l'app tourne dans un environnement non conforme
  bool get isCompromised => hasCriticalThreat || (isDebuggable && !kDebugMode);

  List<String> get threats {
    final list = <String>[];
    if (isRooted) list.add('ROOT_DETECTED');
    if (isEmulator) list.add('EMULATOR_DETECTED');
    if (hasHookingFramework) list.add('HOOKING_FRAMEWORK_DETECTED');
    if (hasPackageTampered) list.add('PACKAGE_TAMPERED');
    if (isDebuggable) list.add('DEBUGGABLE_BUILD');
    return list;
  }

  @override
  String toString() => 'SecurityReport(threats: $threats)';
}
