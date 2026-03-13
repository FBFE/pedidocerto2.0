import 'package:flutter/material.dart';

/// Design system do Pedido Certo (Style Guide / Figma).
/// Inspirado em AppSheet: produtividade, alta densidade de informação, interface limpa.
class PedidoCertoTheme {
  PedidoCertoTheme._();

  // --- Paleta de cores (Style Guide) ---
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color primaryBlueDark = Color(0xFF1557B0);
  static const Color tealAccent = Color(0xFF00897B);
  static const Color white = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFFE0E0E0);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color labelGray = Color(0xFF6B7280);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);

  // --- Espaçamentos (XS: 4, S: 8, M: 16, L: 24, XL: 32) ---
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;

  // --- Raios (cards 8px, inputs 8px) ---
  static const double radiusCard = 8;
  static const double radiusInput = 8;

  /// Breakpoint para layout em coluna (sidebar abaixo do conteúdo). Abaixo disso use Column.
  static const double breakpointSidebarStack = 700;
  /// Largura mínima sugerida para sidebar (calendário, painéis). Use para evitar overflow.
  static const double sidebarMinContentWidth = 200;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        onPrimary: white,
        primaryContainer: primaryBlue.withValues(alpha: 0.12),
        onPrimaryContainer: primaryBlue,
        secondary: tealAccent,
        onSecondary: white,
        surface: white,
        onSurface: const Color(0xFF1F2937),
        surfaceContainerHighest: scaffoldBackground,
        onSurfaceVariant: labelGray,
        outline: borderGray,
        error: errorRed,
        onError: white,
        tertiary: tealAccent,
      ),
      scaffoldBackgroundColor: scaffoldBackground,

      // AppBar: fundo branco, sombra suave, sticky (elevation 1)
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: Color(0xFF1F2937),
        elevation: 1,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: Color(0x1A000000),
        titleTextStyle: TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Color(0xFF374151), size: 24),
      ),

      // Tipografia: Roboto (padrão Flutter) — Headline 20/500, Title 16/600, Body 14/400, Caption 12/400
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: Color(0xFF111827),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Color(0xFF111827),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: Color(0xFF374151),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: Color(0xFF6B7280),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),

      // Cards: branco, borda cinza, 8px radius, elevação suave
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: borderGray, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Inputs: bordas 8px, focus Primary Blue 2px
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusInput)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: const TextStyle(color: labelGray, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),

      // Botão principal: Primary Blue, 8px radius
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusInput)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusInput)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      dividerTheme: const DividerThemeData(color: mediumGray, thickness: 1),
      dividerColor: mediumGray,

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusInput)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
      ),
    );
  }

  /// Cores para badges de status (Style Guide).
  static Color statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('aprovad') || s.contains('vigente') || s.contains('ativo')) return successGreen;
    if (s.contains('pendente') || s.contains('em análise')) return warningOrange;
    if (s.contains('rejeitad') || s.contains('cancelad') || s.contains('atrasad')) return errorRed;
    if (s.contains('progresso')) return primaryBlue;
    return labelGray; // inativo, vencido
  }
}
