import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.skyTop,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.goldPrimary,
        onPrimary: AppColors.woodDark,
        secondary: AppColors.turquoise,
        onSecondary: AppColors.woodDark,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.woodMedium,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Lato',
      textTheme: _buildTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Playfair',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.goldLight,
          letterSpacing: 1.5,
        ),
        iconTheme: IconThemeData(color: AppColors.goldLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.woodMedium,
          foregroundColor: AppColors.goldLight,
          elevation: 8,
          shadowColor: AppColors.shadowDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Playfair',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.creamBase,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.woodHighlight, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.woodSatin, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.goldPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.woodMedium),
        hintStyle: TextStyle(color: AppColors.woodMedium.withOpacity(0.6)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.goldLight,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: AppColors.woodMedium,
        elevation: 12,
        shadowColor: AppColors.shadowDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      iconTheme: const IconThemeData(color: AppColors.goldLight, size: 24),
      dividerTheme: DividerThemeData(
        color: AppColors.woodHighlight.withOpacity(0.3),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.woodSurface,
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.woodDark,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.woodMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Playfair',
          fontSize: 20,
          color: AppColors.goldLight,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Playfair', color: AppColors.goldLight, fontSize: 48, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontFamily: 'Playfair', color: AppColors.goldLight, fontSize: 36, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontFamily: 'Playfair', color: AppColors.goldLight, fontSize: 28, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontFamily: 'Playfair', color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontFamily: 'Playfair', color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontFamily: 'Playfair', color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: 'Lato', color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontFamily: 'Lato', color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontFamily: 'Lato', color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontFamily: 'Lato', color: AppColors.textPrimary, fontSize: 16),
      bodyMedium: TextStyle(fontFamily: 'Lato', color: AppColors.textPrimary, fontSize: 14),
      bodySmall: TextStyle(fontFamily: 'Lato', color: AppColors.textMuted, fontSize: 12),
      labelLarge: TextStyle(fontFamily: 'Lato', color: AppColors.goldPrimary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      labelMedium: TextStyle(fontFamily: 'Lato', color: AppColors.goldPrimary, fontSize: 12, fontWeight: FontWeight.bold),
      labelSmall: TextStyle(fontFamily: 'Lato', color: AppColors.textMuted, fontSize: 10, letterSpacing: 0.5),
    );
  }
}
