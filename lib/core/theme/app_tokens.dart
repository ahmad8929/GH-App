import 'package:flutter/material.dart';

/// Design tokens — the single source of truth for color, spacing, and shape.
/// Widgets must pull from these (usually via [Theme]) — no hard-coded values.
class AppTokens {
  AppTokens._();

  // Brand palette (light theme)
  static const Color primary = Color(0xFF1E56A0);
  static const Color primaryDark = Color(0xFF163172);
  static const Color accent = Color(0xFFFFC93C);
  static const Color tint = Color(0xFFD6E4F0);
  static const Color background = Color(0xFFF6F6F6);
  static const Color surface = Colors.white;

  // Semantic
  static const Color success = Color(0xFF1F9D6D);
  static const Color warning = Color(0xFFB7791F);
  static const Color danger = Color(0xFFD64550);
  static const Color mint = Color(0xFF24B899);
  static const Color coral = Color(0xFFFF6F61);
  static const Color lavender = Color(0xFF8B7CF6);

  // Spacing scale
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;

  // Corner radii (16–20dp, friendly and rounded)
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusPill = 999;

  static BorderRadius get brSm => BorderRadius.circular(radiusSm);
  static BorderRadius get brMd => BorderRadius.circular(radiusMd);
  static BorderRadius get brLg => BorderRadius.circular(radiusLg);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  /// Parses "#rgb" or "#rrggbb" (both valid per the backend's Theme model
  /// validation) into a [Color].
  static Color hexToColor(String hex) {
    var h = hex.replaceFirst('#', '');
    if (h.length == 3) {
      h = h.split('').map((c) => '$c$c').join();
    }
    final value = int.tryParse(h, radix: 16) ?? 0x1E56A0;
    return Color(0xFF000000 | value);
  }
}
