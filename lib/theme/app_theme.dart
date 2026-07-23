import 'package:flutter/material.dart';

/// FCL Beef Field Data — locked palette (see beef-field-app-spec.md).
/// Black / light black surfaces, green primary, orange for errors.
class AppColors {
  AppColors._();

  static const background = Color(0xFF141414);
  static const surface = Color(0xFF1E1E1E);
  static const inputFill = Color(0xFF242424);
  static const inputBorder = Color(0xFF383838);

  static const textPrimary = Color(0xFFEDEDED);
  static const textSecondary = Color(0xFFA8A8A8);
  static const textMuted = Color(0xFF8A8A8A);

  static const green = Color(0xFF2E7D32);
  static const greenLight = Color(0xFF7BC67E);
  static const greenDark = Color(0xFF1E4620);

  static const orange = Color(0xFFE05B4D);
}

ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: 0.8),
      );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.green,
      secondary: AppColors.greenLight,
      surface: AppColors.surface,
      error: AppColors.orange,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      errorStyle: const TextStyle(color: AppColors.orange, fontSize: 12),
      enabledBorder: border(AppColors.inputBorder),
      focusedBorder: border(AppColors.green),
      errorBorder: border(AppColors.orange),
      focusedErrorBorder: border(AppColors.orange),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.greenLight),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.greenLight),
  );
}