import 'package:flutter/material.dart';

/// Tema Cool Blue inspirado no pacote Cool Blue (cursores e identidade visual).
/// Atribuição: Daniel W. - http://www.rw-designer.com/cursor-set/coolblue
class CoolBlueTheme {
  CoolBlueTheme._();

  static const Color primary = Color(0xFF1B4965);
  static const Color primaryLight = Color(0xFF2E6B8A);
  static const Color primaryDark = Color(0xFF0D2D3D);
  static const Color accent = Color(0xFF5FA8D3);
  static const Color surface = Color(0xFFF0F4F8);
  static const Color background = Color(0xFFE8EEF2);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: primaryDark.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
