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
  // Headings & primary text lean to a premium near-black in the default look.
  final primaryDark = t != null ? _hex(t.headingColor) : AppTokens.ink;
  final secondary = t != null ? _hex(t.secondaryColor) : AppTokens.accent;
  final background = t != null ? _hex(t.backgroundColor) : AppTokens.background;
  final buttonBg = t != null ? _hex(t.buttonBackground) : AppTokens.ink;
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
    displayLarge: displayText.displayLarge?.copyWith(fontWeight: FontWeight.w800, color: primaryDark, letterSpacing: -1),
    displayMedium: displayText.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: primaryDark, letterSpacing: -1),
    displaySmall: displayText.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: primaryDark, letterSpacing: -0.5),
    headlineLarge: displayText.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: primaryDark, letterSpacing: -0.5),
    headlineMedium: displayText.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: primaryDark, letterSpacing: -0.5),
    headlineSmall: displayText.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: primaryDark),
    titleLarge: displayText.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: primaryDark),
    titleMedium: displayText.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    titleSmall: displayText.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    labelLarge: displayText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
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
      shape: RoundedRectangleBorder(borderRadius: AppTokens.brXl),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: buttonBg,
        foregroundColor: buttonText,
        minimumSize: const Size(0, 54),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDark,
        minimumSize: const Size(0, 54),
        side: BorderSide(color: AppTokens.ink.withValues(alpha: 0.15)),
        shape: const StadiumBorder(),
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
        horizontal: AppTokens.s5,
        vertical: AppTokens.s4,
      ),
      border: OutlineInputBorder(
        borderRadius: AppTokens.brLg,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTokens.brLg,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTokens.brLg,
        borderSide: BorderSide(color: AppTokens.ink, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppTokens.surface,
      selectedColor: AppTokens.ink,
      checkmarkColor: Colors.white,
      // Selected chips are ink-dark → white label; unselected → ink label.
      // A WidgetStateColor on the label *colour* is the pattern chips honour
      // for both FilterChip and ChoiceChip (labelStyle/secondaryLabelStyle
      // do not reliably flip the colour on their own).
      labelStyle: textTheme.labelLarge?.copyWith(
        color: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : AppTokens.ink),
      ),
      secondaryLabelStyle: textTheme.labelLarge?.copyWith(
        color: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : AppTokens.ink),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s3, vertical: AppTokens.s2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      side: BorderSide.none,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t != null ? footerColor : AppTokens.surface,
      indicatorColor: AppTokens.ink,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : AppTokens.inkSoft,
          )),
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
