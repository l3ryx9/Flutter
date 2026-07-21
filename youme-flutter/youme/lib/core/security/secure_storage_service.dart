import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SecureStorageService — Stockage sécurisé via Android Keystore / iOS Keychain
///
/// Remplace SharedPreferences pour toutes les données sensibles :
///   • clés E2EE (privées et publiques)
///   • tokens d'authentification
///   • clés de chiffrement locales
///
/// Android : utilise EncryptedSharedPreferences backed by Android Keystore
/// iOS     : utilise le Keychain
/// ═══════════════════════════════════════════════════════════════════════════
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Utilise Android Keystore (AES-256-GCM) — matériel si disponible
      encryptedSharedPreferences: true,
      // Inaccessible en dehors de l'app, même sur appareil rooté
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      // Accessible uniquement quand l'appareil est déverrouillé
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ─── Opérations de base ────────────────────────────────────────────────

  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // ─── Helpers typés ────────────────────────────────────────────────────

  static Future<void> writeInt(String key, int value) async {
    await write(key, value.toString());
  }

  static Future<int?> readInt(String key) async {
    final val = await read(key);
    return val != null ? int.tryParse(val) : null;
  }

  static Future<void> writeBool(String key, {required bool value}) async {
    await write(key, value.toString());
  }

  static Future<bool?> readBool(String key) async {
    final val = await read(key);
    return val != null ? val == 'true' : null;
  }
}
