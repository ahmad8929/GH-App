import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import 'app_tokens.dart';

Color _hex(String hex) => AppTokens.hexToColor(hex);

/// Material 3, light, friendly & rounded — Poppins for display, Nunito for body.
///
/// When [t] is null (no theme selected, or a guest), every color resolves to
/// today's exact [AppTokens] values — zero visual change for users who
/// haven't picked a theme. When [t] is provided, its 10 colors are mapped
/// onto the same theme slots the app already uses:
/// primaryColor→primary · secondaryColor→secondary · backgroundColor→scaffold
/// background · headingColor→heading text & AppBar foreground ·
/// buttonBackground/buttonText→FilledButton · borderColor→input/divider
/// borders · navbarColor→AppBar background · footerColor→bottom
/// NavigationBar background (the closest mobile analog to a website footer).
ThemeData buildAppTheme([ThemeOption? t]) {
  final primary = t != null ? _hex(t.primaryColor) : AppTokens.primary;
  final primaryDark = t != null ? _hex(t.headingColor) : AppTokens.primaryDark;
  final secondary = t != null ? _hex(t.secondaryColor) : AppTokens.accent;
  final background = t != null ? _hex(t.backgroundColor) : AppTokens.background;
  final buttonBg = t != null ? _hex(t.buttonBackground) : AppTokens.primary;
  final buttonText = t != null ? _hex(t.buttonText) : Colors.white;
  final borderColor = t != null
      ? _hex(t.borderColor)
      : AppTokens.primaryDark.withValues(alpha: 0.15);
  final navbarColor = t != null ? _hex(t.navbarColor) : AppTokens.background;
  final footerColor = t != null ? _hex(t.footerColor) : AppTokens.surface;

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
    primary: primary,
    secondary: secondary,
    surface: AppTokens.surface,
  );

  final baseText = GoogleFonts.nunitoTextTheme();
  final displayText = GoogleFonts.poppinsTextTheme();

  final textTheme = baseText.copyWith(
    displayLarge: displayText.displayLarge?.copyWith(fontWeight: FontWeight.w700, color: primaryDark),
    displayMedium: displayText.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: primaryDark),
    displaySmall: displayText.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: primaryDark),
    headlineLarge: displayText.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: primaryDark),
    headlineMedium: displayText.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: primaryDark),
    headlineSmall: displayText.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: primaryDark),
    titleLarge: displayText.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: primaryDark),
    titleMedium: displayText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: displayText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: displayText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: navbarColor,
      foregroundColor: primaryDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: AppTokens.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.brLg),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: buttonBg,
        foregroundColor: buttonText,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.brMd),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: primary.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.brMd),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTokens.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s4,
        vertical: AppTokens.s3,
      ),
      border: OutlineInputBorder(
        borderRadius: AppTokens.brMd,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTokens.brMd,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTokens.brMd,
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppTokens.tint,
      selectedColor: primary,
      labelStyle: textTheme.labelMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      side: BorderSide.none,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: footerColor,
      indicatorColor: AppTokens.tint,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.brMd),
    ),
    dividerTheme: DividerThemeData(
      color: primaryDark.withValues(alpha: 0.08),
    ),
  );
}
