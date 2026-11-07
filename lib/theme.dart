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
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
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

  static const cyber = CertPalette(
    accent: Color(0xFFFB7185),
    badgeBg: Color(0x1AFB7185),
    button: Color(0xFFE11D48),
  );

  static CertPalette of(String cert) {
    switch (cert) {
      case 'ccst':
        return ccst;
      case 'ccnp':
        return ccnp;
      case 'cyber':
        return cyber;
      case 'ccna':
        return ccna;
      default:
        return named(cert);
    }
  }

  /// Palette from a catalog colour name (Tailwind-style). Unknown → CCNA blue.
  static CertPalette named(String? name) {
    final base = _named[name?.trim().toLowerCase()];
    if (base == null) return ccna;
    return CertPalette(
      accent: base.$1,
      badgeBg: base.$1.withValues(alpha: 0.1),
      button: base.$2,
    );
  }

  static const Map<String, (Color, Color)> _named = {
    'rose': (Color(0xFFFB7185), Color(0xFFE11D48)),
    'red': (Color(0xFFF87171), Color(0xFFDC2626)),
    'orange': (Color(0xFFFB923C), Color(0xFFEA580C)),
    'amber': (Color(0xFFFBBF24), Color(0xFFD97706)),
    'yellow': (Color(0xFFFACC15), Color(0xFFCA8A04)),
    'lime': (Color(0xFFA3E635), Color(0xFF65A30D)),
    'green': (Color(0xFF4ADE80), Color(0xFF16A34A)),
    'emerald': (Color(0xFF34D399), Color(0xFF059669)),
    'teal': (Color(0xFF2DD4BF), Color(0xFF0D9488)),
    'cyan': (Color(0xFF22D3EE), Color(0xFF0891B2)),
    'sky': (Color(0xFF38BDF8), Color(0xFF0284C7)),
    'blue': (Color(0xFF60A5FA), Color(0xFF2563EB)),
    'indigo': (Color(0xFF818CF8), Color(0xFF4F46E5)),
    'violet': (Color(0xFFA78BFA), Color(0xFF7C3AED)),
    'purple': (Color(0xFFC084FC), Color(0xFF9333EA)),
    'fuchsia': (Color(0xFFE879F9), Color(0xFFC026D3)),
    'pink': (Color(0xFFF472B6), Color(0xFFDB2777)),
    'slate': (Color(0xFF94A3B8), Color(0xFF475569)),
    'gray': (Color(0xFF9CA3AF), Color(0xFF4B5563)),
  };
}
