package com.youme.app

import io.flutter.embedding.android.FlutterActivity

/**
 * YouMe MainActivity
 *
 * Security notes:
 * - R8 minification & obfuscation enabled in release builds (build.gradle)
 * - debuggable=false in release (AndroidManifest.xml)
 * - cleartext traffic disabled (network_security_config.xml)
 * - allowBackup=false prevents data extraction via adb backup
 *
 * Native security checks (root, emulator, hooking) are implemented in Dart
 * via the SecurityGuard service using platform channels and safe_device package.
 */
class MainActivity : FlutterActivity()
