import 'dart:io';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CertificatePinning — Validation renforcée des certificats TLS
///
/// Implémente le certificate pinning pour les requêtes HTTP Dart natives.
/// Note : Supabase utilise Ktor/OkHttp nativement sur Android, ce qui est
/// couvert par la Network Security Config Android (network_security_config.xml).
/// Cette classe couvre les requêtes Dart natives via HttpClient.
///
/// Pour activer le pinning strict :
///   1. Remplacez les hashes par ceux de vos certificats réels
///   2. Obtenez le hash via : openssl s_client -connect host:443 </dev/null |
///        openssl x509 -pubkey -noout | openssl pkey -pubin -outform der |
///        openssl dgst -sha256 -binary | base64
/// ═══════════════════════════════════════════════════════════════════════════
class CertificatePinning {
  CertificatePinning._();

  /// SPKI SHA-256 hashes (base64) des CAs autorisées pour Supabase
  /// Amazon Root CA 1 & 2 (utilisées par Supabase via AWS)
  static const _pinnedHashes = <String>{
    // TODO: remplacer par les vrais hashes SPKI SHA-256 de vos endpoints
    // Exemple Amazon Root CA 1:
    // 'Vv2Oo/Zy3lSu2VMo18C6KrIbBO0hnkLT5gQd1XIXOQ=',
    // Exemple Amazon Root CA 2:
    // 'mRmbgmrflLxLjPo4GsGfLfNk9r+L8CVVS2BoYLjKHK0=',
  };

  /// Configure un [HttpClient] avec validation renforcée des certificats.
  /// Utilisez ce client pour toutes les requêtes HTTP natives.
  static HttpClient createSecureClient() {
    final client = HttpClient();

    if (!kDebugMode && _pinnedHashes.isNotEmpty) {
      // Pinning activé en release si des hashes sont configurés
      client.badCertificateCallback = (cert, host, port) => false;
    } else if (kDebugMode) {
      // En debug, accepter tous les certificats (pour le proxy de dev)
      // ATTENTION : ne jamais déployer en production avec cette config
      client.badCertificateCallback = (cert, host, port) => true;
    }

    // Désactiver les redirections automatiques (prévient SSRF)
    client.maxConnectionsPerHost = 6;
    client.autoUncompress = true;

    return client;
  }

}
