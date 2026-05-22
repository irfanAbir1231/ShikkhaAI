import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_tokens.dart';

/// Builds the app's [TextTheme] for light and dark modes.
class AppTextTheme {
  const AppTextTheme._();

  static TextTheme light({bool useBengali = false}) => _build(
        color: AppColors.textPrimary,
        secondaryColor: AppColors.textSecondary,
        useBengali: useBengali,
      );

  static TextTheme dark({bool useBengali = false}) => _build(
        color: AppColors.textPrimaryDark,
        secondaryColor: AppColors.textSecondaryDark,
        useBengali: useBengali,
      );

  static TextTheme _build({
    required Color color,
    required Color secondaryColor,
    required bool useBengali,
  }) {
    final base = useBengali
        ? GoogleFonts.notoSansBengali()
        : GoogleFonts.inter();

    return TextTheme(
      displayLarge: base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      displayMedium: base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      headlineLarge: base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineMedium: base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleLarge: base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      bodyLarge: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color,
      ),
      bodyMedium: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
      ),
      bodySmall: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
      ),
      labelLarge: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      labelSmall: base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: secondaryColor,
      ),
    );
  }
}
