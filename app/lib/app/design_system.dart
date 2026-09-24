import 'package:flutter/material.dart';

/// Shared visual tokens for the Flutter client. Keep app/README.md in sync.
abstract final class AppColors {
  static const primary = Color(0xFF005BAA);
  static const primaryDark = Color(0xFF004080);
  static const accent = Color(0xFFCE1126);
  static const background = Color(0xFFF2F5F9);
  static const splashBackground = Color(0xFFF7F9FC);
  static const splashPrimary = Color(0xFF2457A6);
  static const splashAccent = Color(0xFF2A8C82);
  static const splashInk = Color(0xFF172033);
  static const card = Colors.white;
  static const border = Color(0xFFD4DDE8);
  static const ink = Color(0xFF0F1F2E);
  static const muted = Color(0xFF64748B);
  static const accessible = Color(0xFF008A5B);
  static const partial = Color(0xFFB45309);
  static const barrier = Color(0xFFB42318);
  static const unknown = Color(0xFF667085);
}

abstract final class AppDesign {
  static const cardRadius = 20.0;
  static const controlRadius = 14.0;
  static const horizontalPadding = 16.0;
  static const minTouchTarget = 48.0;

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.card,
      onSurface: AppColors.ink,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}
