import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_tokens.dart';
import 'text_theme.dart';
import 'widget_themes.dart';

/// Factory for light and dark [ThemeData].
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      textTheme: AppTextTheme.light(),
      cardTheme: AppWidgetThemes.cardTheme(),
      elevatedButtonTheme: AppWidgetThemes.elevatedButtonTheme(),
      outlinedButtonTheme: AppWidgetThemes.outlinedButtonTheme(),
      inputDecorationTheme: AppWidgetThemes.inputDecorationTheme(),
      appBarTheme: AppWidgetThemes.appBarTheme(),
      bottomNavigationBarTheme: AppWidgetThemes.bottomNavTheme(),
      chipTheme: AppWidgetThemes.chipTheme(),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );

    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.danger,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      textTheme: AppTextTheme.dark(),
      cardTheme: AppWidgetThemes.cardTheme(isDark: true),
      elevatedButtonTheme: AppWidgetThemes.elevatedButtonTheme(isDark: true),
      outlinedButtonTheme: AppWidgetThemes.outlinedButtonTheme(isDark: true),
      inputDecorationTheme: AppWidgetThemes.inputDecorationTheme(isDark: true),
      appBarTheme: AppWidgetThemes.appBarTheme(isDark: true),
      bottomNavigationBarTheme: AppWidgetThemes.bottomNavTheme(isDark: true),
      chipTheme: AppWidgetThemes.chipTheme(isDark: true),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
    );

    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
    );
  }
}
