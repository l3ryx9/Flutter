import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/security/security_guard.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/error_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Vérification des variables d'environnement (build-time) ────────
  // Lève une AssertionError si SUPABASE_URL ou SUPABASE_ANON_KEY sont absentes.
  AppConstants.assertRequiredEnv();

  // ── 2. Orientation portrait uniquement ────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── 3. Style barre de statut ──────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ── 4. Initialisation du logger d'erreurs ─────────────────────────────
  await ErrorLogger.init();
  FlutterError.onError = (details) {
    // Ne logge jamais les stack traces complètes en release (informations
    // sensibles sur la structure interne de l'app).
    if (kDebugMode) {
      ErrorLogger.log('Flutter Error', details.exceptionAsString(),
          stackTrace: details.stack);
    } else {
      // En release, on logue uniquement le type d'erreur, pas la trace
      ErrorLogger.log('Flutter Error', details.exception.runtimeType.toString());
    }
  };

  // ── 5. Vérifications de sécurité au démarrage ─────────────────────────
  // Ces vérifications sont ignorées en debug pour faciliter le développement.
  if (!kDebugMode) {
    final report = await SecurityGuard.runAll();

    if (report.isCompromised) {
      // L'application refuse de démarrer si l'environnement est compromis.
      // Afficher une erreur et quitter proprement.
      ErrorLogger.log('Security', 'Compromised environment: ${report.threats}');
      _showSecurityBlockScreen();
      return; // Ne pas continuer l'initialisation
    }
  }

  // ── 6. Initialisation Supabase ────────────────────────────────────────
  await SupabaseService.initialize();

  // ── 7. Initialisation Firebase (optionnel — ne bloque pas l'app) ──────
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    // FCM non critique — l'app fonctionne sans notifications
    ErrorLogger.log('Firebase Init', 'Initialization failed');
    // Note: e.toString() non loggé en release pour éviter les fuites d'info
  }

  runApp(const YouMeApp());
}

/// Affiche un écran de blocage et quitte l'application si l'environnement
/// est jugé non sécurisé (root, hooking, APK repackagé).
void _showSecurityBlockScreen() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  color: Color(0xFFE94560),
                  size: 72,
                ),
                SizedBox(height: 24),
                Text(
                  'Sécurité compromise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  "YouMe ne peut pas s'exécuter dans cet environnement.\n\n"
                  "Veuillez utiliser un appareil non rooté et télécharger "
                  "l'application depuis le Google Play Store officiel.",
                  style: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  // Quitter l'application après 4 secondes
  Future.delayed(const Duration(seconds: 4), () {
    SystemNavigator.pop();
  });
}
