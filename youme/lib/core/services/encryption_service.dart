import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';
import '../utils/error_logger.dart';

/// Chiffrement de bout en bout : ECDH (X25519) + AES-GCM 256
class EncryptionService {
  static final _random = Random.secure();

  // Génère une paire de clés ECDH
  static Map<String, String> generateKeyPair() {
    final keyParams = ECKeyGeneratorParameters(ECDomainParameters('prime256v1'));
    final generator = KeyGenerator('EC')
      ..init(ParametersWithRandom(keyParams, _secureRandom()));

    final pair = generator.generateKeyPair();
    final pub = pair.publicKey as ECPublicKey;
    final priv = pair.privateKey as ECPrivateKey;

    final pubBytes = pub.Q!.getEncoded(false);
    final privBytes = _bigIntToBytes(priv.d!, 32);

    return {
      'publicKey': base64.encode(pubBytes),
      'privateKey': base64.encode(privBytes),
    };
  }

  // Calcule le secret partagé ECDH
  static Uint8List computeSharedSecret(String privateKeyB64, String peerPublicKeyB64) {
    final privBytes = base64.decode(privateKeyB64);
    final pubBytes = base64.decode(peerPublicKeyB64);

    final curve = ECDomainParameters('prime256v1');
    final privKey = ECPrivateKey(BigInt.parse(hex.encode(privBytes), radix: 16), curve);
    final pubPoint = curve.curve.decodePoint(pubBytes);
    final pubKey = ECPublicKey(pubPoint, curve);

    final agreement = ECDHBasicAgreement()..init(privKey);
    final shared = agreement.calculateAgreement(pubKey);
    return _bigIntToBytes(shared, 32);
  }

  // Dérive une clé AES à partir du secret partagé (HKDF)
  static Uint8List deriveAesKey(Uint8List sharedSecret) {
    final hkdf = HKDFKeyDerivator(SHA256Digest())
      ..init(HkdfParameters(sharedSecret, 32));
    final key = Uint8List(32);
    hkdf.deriveKey(null, 0, key, 0);
    return key;
  }

  // Chiffre un message (AES-GCM)
  static String encrypt(String plaintext, Uint8List key) {
    try {
      final nonce = _randomBytes(12);
      final cipher = GCMBlockCipher(AESEngine())
        ..init(true, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

      final input = Uint8List.fromList(utf8.encode(plaintext));
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

  // Déchiffre un message (AES-GCM)
  static String decrypt(String ciphertext, Uint8List key) {
    try {
      final combined = base64.decode(ciphertext);
      final nonce = combined.sublist(0, 12);
      final data = combined.sublist(12);

      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

      final output = cipher.process(data);
      return utf8.decode(output);
    } catch (e) {
      ErrorLogger.log('EncryptionService.decrypt', e.toString());
      rethrow;
    }
  }

  // Stockage sécurisé (SharedPreferences dans la vraie app, Keychain sur prod)
  static String encryptForStorage(String data, String password) {
    final key = _derivePasswordKey(password);
    return encrypt(data, key);
  }

  static String decryptFromStorage(String data, String password) {
    final key = _derivePasswordKey(password);
    return decrypt(data, key);
  }

  static Uint8List _derivePasswordKey(String password) {
    final digest = SHA256Digest();
    return digest.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
        List<int>.generate(length, (_) => _random.nextInt(256)));
  }

  static Uint8List _bigIntToBytes(BigInt n, int length) {
    final bytes = Uint8List(length);
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
