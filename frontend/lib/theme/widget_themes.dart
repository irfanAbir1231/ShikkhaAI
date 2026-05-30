import 'package:flutter/material.dart';

import 'color_tokens.dart';

/// Widget-level theme configurations — minimalist flat surfaces.
class AppWidgetThemes {
  const AppWidgetThemes._();

  static CardThemeData cardTheme({bool isDark = false}) => CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.cardBgDark : AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.divider,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: Colors.black.withValues(alpha: 0.04),
      );

  static ElevatedButtonThemeData elevatedButtonTheme({bool isDark = false}) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      );

  static OutlinedButtonThemeData outlinedButtonTheme({bool isDark = false}) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          foregroundColor: AppColors.primary,
          backgroundColor: isDark ? AppColors.cardBgDark : AppColors.cardBg,
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.divider,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static InputDecorationTheme inputDecorationTheme({bool isDark = false}) {
    final borderColor = isDark ? AppColors.dividerDark : AppColors.divider;
    final fillColor = isDark ? AppColors.neuInsetDarkDark : Colors.white;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static AppBarTheme appBarTheme({bool isDark = false}) => AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        foregroundColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      );

  static BottomNavigationBarThemeData bottomNavTheme({bool isDark = false}) =>
      BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.cardBgDark : AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor:
            isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );

  static ChipThemeData chipTheme({bool isDark = false}) => ChipThemeData(
        backgroundColor: isDark ? AppColors.cardBgDark : AppColors.primarySoft,
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : Colors.transparent,
          ),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );
}
