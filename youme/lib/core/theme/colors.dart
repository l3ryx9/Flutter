import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === BOIS TROPICAL ===
  static const Color woodDark = Color(0xFF2C1A0E);
  static const Color woodMedium = Color(0xFF5C3317);
  static const Color woodLight = Color(0xFF8B5E3C);
  static const Color woodSurface = Color(0xFF6B4226);
  static const Color woodHighlight = Color(0xFFB87333);
  static const Color woodSatin = Color(0xFFA0522D);

  // === OR / DORURE ===
  static const Color goldPrimary = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color goldShimmer = Color(0xFFFFF0A0);
  static const Color goldBorder = Color(0xFFDAA520);

  // === TROPICAL ===
  static const Color turquoise = Color(0xFF00CED1);
  static const Color oceanBlue = Color(0xFF006994);
  static const Color leafGreen = Color(0xFF228B22);
  static const Color leafLight = Color(0xFF32CD32);
  static const Color hibiscusPink = Color(0xFFFF69B4);
  static const Color hibiscusRed = Color(0xFFDC143C);
  static const Color frangipanier = Color(0xFFFFF8E7);
  static const Color sunsetOrange = Color(0xFFFF6B35);
  static const Color sunsetPeach = Color(0xFFFFB347);

  // === FOND / CIEL ===
  static const Color skyTop = Color(0xFF1A0A2E);
  static const Color skyMid = Color(0xFF16213E);
  static const Color skyBottom = Color(0xFF0F3460);
  static const Color sunsetSky = Color(0xFFE8A87C);

  // === BEIGE CRÈME (champs texte) ===
  static const Color creamBase = Color(0xFFF5E6C8);
  static const Color creamLight = Color(0xFFFFF8F0);
  static const Color creamDark = Color(0xFFE8D5B0);

  // === BULLES DE CONVERSATION ===
  static const Color bubbleSent = Color(0xFF5C3317);
  static const Color bubbleReceived = Color(0xFF2C4A3E);
  static const Color bubbleGlass = Color(0x33FFFFFF);

  // === STATUTS ===
  static const Color onlineGreen = Color(0xFF00FF7F);
  static const Color offlineGray = Color(0xFF808080);
  static const Color typingYellow = Color(0xFFFFD700);

  // === ÉTAT ===
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // === IA / GEMINI ===
  static const Color aiPurple = Color(0xFF8B5CF6);
  static const Color aiBlue = Color(0xFF3B82F6);
  static const Color aiGlow = Color(0xFFE879F9);

  // === RED / GREEN FLAGS ===
  static const Color greenFlag = Color(0xFF10B981);
  static const Color redFlag = Color(0xFFEF4444);

  // === OMBRES ===
  static const Color shadowDark = Color(0xAA000000);
  static const Color shadowMedium = Color(0x66000000);
  static const Color shadowLight = Color(0x33000000);
  static const Color glowGold = Color(0x88D4A017);

  // === TEXTES ===
  static const Color textPrimary = Color(0xFFFFF8F0);
  static const Color textSecondary = Color(0xFFD4A017);
  static const Color textMuted = Color(0xFFB0A090);
  static const Color textOnWood = Color(0xFFFFF0D0);
  static const Color textDark = Color(0xFF1A0A00);

  // Dégradés
  static const LinearGradient woodGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [woodMedium, woodDark, woodSurface, woodMedium],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldLight, goldPrimary, goldDark],
  );

  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyTop, skyMid, skyBottom, oceanBlue],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyTop, Color(0xFF4A1A5C), sunsetOrange, sunsetPeach, oceanBlue],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static const RadialGradient woodRadial = RadialGradient(
    center: Alignment.topLeft,
    radius: 1.5,
    colors: [woodLight, woodMedium, woodDark],
  );

  static const LinearGradient bubbleSentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5E3C), Color(0xFF5C3317)],
  );

  static const LinearGradient bubbleReceivedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C4A3E), Color(0xFF1A3028)],
  );
}
