import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFFF6F4F1);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1D1B1A);
  static const muted = Color(0xFF5E5955);
  static const border = Color(0xFFE4DFDA);
  static const fieldBorder = Color(0xFFD9D3CD);
  static const subtle = Color(0xFFF0ECE8);

  static const primary = Color(0xFFB42318);
  static const primaryDark = Color(0xFF8A1A12);
  static const primarySoft = Color(0xFFFDECEA);

  static const success = Color(0xFF1F6F4A);
  static const successDark = Color(0xFF17573A);
  static const successSoft = Color(0xFFE6F2EC);

  static const info = Color(0xFF1F4F8A);
  static const infoSoft = Color(0xFFE8F0FA);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.fieldBorder),
  );

  return base.copyWith(
    textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
