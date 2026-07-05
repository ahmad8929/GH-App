import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Material 3, light, friendly & rounded — Poppins for display, Nunito for body.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppTokens.primary,
    brightness: Brightness.light,
    primary: AppTokens.primary,
    secondary: AppTokens.accent,
    surface: AppTokens.surface,
  );

  final baseText = GoogleFonts.nunitoTextTheme();
  final displayText = GoogleFonts.poppinsTextTheme();

  final textTheme = baseText.copyWith(
    displayLarge: displayText.displayLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTokens.primaryDark),
    displayMedium: displayText.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTokens.primaryDark),
    displaySmall: displayText.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: AppTokens.primaryDark),
    headlineLarge: displayText.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTokens.primaryDark),
    headlineMedium: displayText.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTokens.primaryDark),
    headlineSmall: displayText.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: AppTokens.primaryDark),
    titleLarge: displayText.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppTokens.primaryDark),
    titleMedium: displayText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: displayText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: displayText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppTokens.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppTokens.background,
      foregroundColor: AppTokens.primaryDark,
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
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.brMd),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTokens.primary,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: AppTokens.primary.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.brMd),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTokens.primary,
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
        borderSide: BorderSide(color: AppTokens.primaryDark.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTokens.brMd,
        borderSide: BorderSide(color: AppTokens.primaryDark.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTokens.brMd,
        borderSide: const BorderSide(color: AppTokens.primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppTokens.tint,
      selectedColor: AppTokens.primary,
      labelStyle: textTheme.labelMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      side: BorderSide.none,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppTokens.surface,
      indicatorColor: AppTokens.tint,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.brMd),
    ),
    dividerTheme: DividerThemeData(
      color: AppTokens.primaryDark.withValues(alpha: 0.08),
    ),
  );
}
