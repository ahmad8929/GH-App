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
  static const Color background = Color(0xFFF3F4F6);
  static const Color surface = Colors.white;

  // Redesign palette — near-black "ink" for headings & dark controls, and a
  // warm gold for the primary shopping CTA (matches the pharmacy-app look).
  static const Color ink = Color(0xFF17181F);
  static const Color inkSoft = Color(0xFF5A5E6B);
  static const Color gold = Color(0xFFF4C24A);
  static const Color goldDark = Color(0xFFE0A32E);

  // Semantic
  static const Color success = Color(0xFF1F9D6D);
  static const Color warning = Color(0xFFB7791F);
  static const Color danger = Color(0xFFD64550);
  static const Color mint = Color(0xFF24B899);
  static const Color coral = Color(0xFFFF6F61);
  static const Color lavender = Color(0xFF8B7CF6);

  /// Global UI scale. Every size below — plus the text theme's font sizes, the
  /// default icon size, and the fixed dimensions in screens (all written as
  /// `<base> * AppTokens.scale`) — is derived from this, so the whole UI can be
  /// tightened or loosened from one number. 1.0 is the original design size.
  static const double scale = 0.8;

  // Spacing scale
  static const double s1 = 4 * scale;
  static const double s2 = 8 * scale;
  static const double s3 = 12 * scale;
  static const double s4 = 16 * scale;
  static const double s5 = 24 * scale;
  static const double s6 = 32 * scale;

  // Corner radii — larger & rounder for the redesign.
  static const double radiusSm = 12 * scale;
  static const double radiusMd = 18 * scale;
  static const double radiusLg = 24 * scale;
  static const double radiusXl = 30 * scale;
  static const double radiusPill = 999;

  /// Default icon size (Material's own default is 24).
  static const double iconSize = 24 * scale;

  static BorderRadius get brSm => BorderRadius.circular(radiusSm);
  static BorderRadius get brMd => BorderRadius.circular(radiusMd);
  static BorderRadius get brLg => BorderRadius.circular(radiusLg);
  static BorderRadius get brXl => BorderRadius.circular(radiusXl);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.06),
          blurRadius: 24 * scale,
          offset: const Offset(0, 12 * scale),
        ),
      ];

  /// Vibrant product gradients used on hero cards and product tiles — the
  /// signature look of the pharmacy-app inspiration. [gradientFor] picks a
  /// stable one from any string key (e.g. a listing id) so a grid looks
  /// colourful and varied while each item keeps the same colour every render.
  static const List<List<Color>> gradients = [
    [Color(0xFF9E1B4B), Color(0xFF6C0F35)], // wine
    [Color(0xFFF2B33D), Color(0xFFDD8A17)], // gold
    [Color(0xFF6E97C7), Color(0xFF47699F)], // blue
    [Color(0xFF2BA98A), Color(0xFF14755C)], // teal
    [Color(0xFF7C6BEB), Color(0xFF5B45D6)], // violet
    [Color(0xFFEB6A5E), Color(0xFFCF4034)], // coral
  ];

  static LinearGradient gradientFor(String key) {
    final colors = gradients[(key.hashCode & 0x7fffffff) % gradients.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

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
