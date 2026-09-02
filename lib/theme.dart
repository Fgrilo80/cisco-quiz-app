import 'package:flutter/material.dart';

/// Cisco brand blue used throughout the app.
const Color ciscoBlue = Color(0xFF0A66C2);

const Color _bg = Color(0xFF020617);
const Color _surface = Color(0xFF0F172A);
const Color _card = Color(0xFF111827);
const Color _border = Color(0xFF334155);

ThemeData buildCiscoTheme() {
  const scheme = ColorScheme.dark(
    primary: ciscoBlue,
    onPrimary: Colors.white,
    secondary: Color(0xFF38BDF8),
    onSecondary: Color(0xFF0F172A),
    surface: _surface,
    onSurface: Color(0xFFE2E8F0),
    error: Color(0xFFF87171),
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: _bg,
    canvasColor: _bg,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: _surface,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: _card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ciscoBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _card,
      contentTextStyle: const TextStyle(color: Color(0xFFE2E8F0)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class CertPalette {
  const CertPalette({
    required this.accent,
    required this.badgeBg,
    required this.button,
  });

  final Color accent;
  final Color badgeBg;
  final Color button;

  static const ccst = CertPalette(
    accent: Color(0xFF34D399),
    badgeBg: Color(0x1A34D399),
    button: Color(0xFF059669),
  );

  static const ccna = CertPalette(
    accent: Color(0xFF60A5FA),
    badgeBg: Color(0x1A60A5FA),
    button: ciscoBlue,
  );

  static const ccnp = CertPalette(
    accent: Color(0xFFA78BFA),
    badgeBg: Color(0x1AA78BFA),
    button: Color(0xFF7C3AED),
  );

  static CertPalette of(String cert) {
    switch (cert) {
      case 'ccst':
        return ccst;
      case 'ccnp':
        return ccnp;
      default:
        return ccna;
    }
  }
}
