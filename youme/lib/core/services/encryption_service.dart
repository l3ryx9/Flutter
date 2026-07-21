import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/error_logger.dart';

/// Résultat d'une paire de clés ECDH
class KeyPair {
  final String publicKeyHex;
  final String privateKeyHex;
  const KeyPair({required this.publicKeyHex, required this.privateKeyHex});
}

/// Chiffrement de bout en bout : ECDH (prime256v1) + AES-GCM 256
class EncryptionService {
  static final _random = Random.secure();

  static const _prefPrivKey = 'e2ee_priv_';
  static const _prefPubKey  = 'e2ee_pub_';

  // ──────────────────────────────────────────────────────────────────
  // Gestion des clés persistantes (stockage local)
  // ──────────────────────────────────────────────────────────────────

  /// Charge la paire de clés existante ou en génère une nouvelle.
  /// Les clés sont persistées dans SharedPreferences (hex-encodées).
  /// En production : utiliser flutter_secure_storage ou le Keychain.
  static Future<KeyPair> getOrCreateKeyPair(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPriv = prefs.getString('$_prefPrivKey$userId');
    final storedPub  = prefs.getString('$_prefPubKey$userId');

    if (storedPriv != null && storedPub != null) {
      return KeyPair(publicKeyHex: storedPub, privateKeyHex: storedPriv);
    }

    // Génère une nouvelle paire
    final pair = _generateRawKeyPair();
    await prefs.setString('$_prefPrivKey$userId', pair.privateKeyHex);
    await prefs.setString('$_prefPubKey$userId',  pair.publicKeyHex);
    return pair;
  }

  /// Supprime les clés locales (ex. à la déconnexion)
  static Future<void> clearKeyPair(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefPrivKey$userId');
    await prefs.remove('$_prefPubKey$userId');
  }

  // ──────────────────────────────────────────────────────────────────
  // ECDH + dérivation de clé
  // ──────────────────────────────────────────────────────────────────

  static KeyPair _generateRawKeyPair() {
    final keyParams = ECKeyGeneratorParameters(ECDomainParameters('prime256v1'));
    final generator = KeyGenerator('EC')
      ..init(ParametersWithRandom(keyParams, _secureRandom()));

    final pair     = generator.generateKeyPair();
    final pub      = pair.publicKey  as ECPublicKey;
    final priv     = pair.privateKey as ECPrivateKey;

    final pubBytes  = pub.Q!.getEncoded(false); // uncompressed point
    final privBytes = _bigIntToBytes(priv.d!, 32);

    return KeyPair(
      publicKeyHex:  hex.encode(pubBytes),
      privateKeyHex: hex.encode(privBytes),
    );
  }

  /// Dérive la clé AES partagée via ECDH.
  /// Retourne une chaîne hex représentant les 32 octets de clé AES.
  static String deriveSharedKey({
    required String myPrivateKeyHex,
    required String partnerPublicKeyHex,
  }) {
    final privBytes = Uint8List.fromList(hex.decode(myPrivateKeyHex));
    final pubBytes  = Uint8List.fromList(hex.decode(partnerPublicKeyHex));

    final curve   = ECDomainParameters('prime256v1');
    final privKey = ECPrivateKey(
        BigInt.parse(hex.encode(privBytes), radix: 16), curve);
    final pubPoint = curve.curve.decodePoint(pubBytes);
    final pubKey   = ECPublicKey(pubPoint, curve);

    final agreement = ECDHBasicAgreement()..init(privKey);
    final shared    = agreement.calculateAgreement(pubKey);
    final sharedBytes = _bigIntToBytes(shared, 32);

    // HKDF pour obtenir une clé AES déterministe
    final hkdf = HKDFKeyDerivator(SHA256Digest())
      ..init(HkdfParameters(sharedBytes, 32));
    final aesKey = Uint8List(32);
    hkdf.deriveKey(null, 0, aesKey, 0);
    return hex.encode(aesKey);
  }

  // ──────────────────────────────────────────────────────────────────
  // Chiffrement / Déchiffrement AES-GCM
  // Accepte une clé en hex (32 octets = 64 chars hex)
  // ──────────────────────────────────────────────────────────────────

  static String encrypt(String plaintext, String keyHex) {
    try {
      final key   = Uint8List.fromList(hex.decode(keyHex));
      final nonce = _randomBytes(12);
      final cipher = GCMBlockCipher(AESEngine())
        ..init(true, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

      final input  = Uint8List.fromList(utf8.encode(plaintext));
      final output = cipher.process(input);

      final combined = Uint8List(nonce.length + output.length);
      combined.setRange(0, nonce.length, nonce);
      combined.setRange(nonce.length, combined.length, output);
      return base64.encode(combined);
    } catch (e) {
      ErrorLogger.log('EncryptionService.encrypt', e.toString());
      rethrow;
    }
  }

  static String decrypt(String ciphertext, String keyHex) {
    try {
      final key      = Uint8List.fromList(hex.decode(keyHex));
      final combined = base64.decode(ciphertext);
      final nonce    = combined.sublist(0, 12);
      final data     = combined.sublist(12);

      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

      final output = cipher.process(data);
      return utf8.decode(output);
    } catch (e) {
      ErrorLogger.log('EncryptionService.decrypt', e.toString());
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Chiffrement basé sur mot de passe (stockage local)
  // ──────────────────────────────────────────────────────────────────

  static String encryptForStorage(String data, String password) {
    final keyHex = _derivePasswordKeyHex(password);
    return encrypt(data, keyHex);
  }

  static String decryptFromStorage(String data, String password) {
    final keyHex = _derivePasswordKeyHex(password);
    return decrypt(data, keyHex);
  }

  static String _derivePasswordKeyHex(String password) {
    final digest = SHA256Digest();
    final keyBytes = digest.process(Uint8List.fromList(utf8.encode(password)));
    return hex.encode(keyBytes);
  }

  // ──────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────

  static Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
        List<int>.generate(length, (_) => _random.nextInt(256)));
  }

  static Uint8List _bigIntToBytes(BigInt n, int length) {
    final bytes  = Uint8List(length);
    final hexStr = n.toRadixString(16).padLeft(length * 2, '0');
    for (var i = 0; i < length; i++) {
      bytes[i] = int.parse(hexStr.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  static SecureRandom _secureRandom() {
    final secureRandom = FortunaRandom();
    secureRandom.seed(KeyParameter(_randomBytes(32)));
    return secureRandom;
  }
}
