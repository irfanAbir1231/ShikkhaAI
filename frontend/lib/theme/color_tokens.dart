import 'package:flutter/material.dart';

/// Semantic color tokens — warm wood-brown palette.
///
/// Pure white surfaces, wood-brown primary accents, green success, yellow
/// warnings, and dark grey/black for text.
class AppColors {
  const AppColors._();

  // Primary — warm wood-brown used for CTAs and accents.
  static const Color primary = Color(0xFFA0522D);
  static const Color primaryDark = Color(0xFF6B3E1F);
  static const Color primaryLight = Color(0xFFC19A6B);
  // Soft wood background overlay (faint shapes / tinted plates).
  static const Color primarySoft = Color(0xFFF5E6D3);
  // Even fainter wash for large background accents.
  static const Color primaryWash = Color(0xFFFAF0E6);
  static const Color accent = Color(0xFFFBC02D);

  // Secondary — green used for success and secondary actions.
  static const Color secondary = Color(0xFF43A047);
  static const Color secondarySoft = Color(0xFFE8F5E9);

  // Status colors
  static const Color success = Color(0xFF43A047); // vibrant green badges
  static const Color successSoft = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFD600); // gold/yellow progress
  static const Color warningSoft = Color(0xFFFFF8D6);
  static const Color danger = Color(0xFFE64A19);
  static const Color dangerSoft = Color(0xFFFBE9E7);

  // Light theme surfaces — pure white.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111418); // near-black
  static const Color textSecondary = Color(0xFF6B7280); // muted grey
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFECEFF1);

  // Dark theme surfaces (kept for ThemeData.dark contract).
  static const Color surfaceDark = Color(0xFF0F1115);
  static const Color cardBgDark = Color(0xFF1A1D23);
  static const Color textPrimaryDark = Color(0xFFF5F7FA);
  static const Color textSecondaryDark = Color(0xFF9AA3B2);
  static const Color dividerDark = Color(0xFF2A2F38);

  // Neu tokens kept for compat; flattened toward subtle elevation.
  static const Color neuHighlight = Color(0xFFFFFFFF);
  static const Color neuShadow = Color(0xFFD8DEE6);
  static const Color neuShadowSoft = Color(0x14000000);
  static const Color neuInsetLight = Color(0xFFF7F9FC);
  static const Color neuInsetDark = Color(0xFFE5E9EF);

  static const Color neuHighlightDark = Color(0xFF22262E);
  static const Color neuShadowDeep = Color(0xFF05070A);
  static const Color neuInsetLightDark = Color(0xFF1F232B);
  static const Color neuInsetDarkDark = Color(0xFF0A0C10);

  // Utility
  static const Color overlay = Color(0x66000000);
  static const Color shimmerBase = Color(0xFFEFF2F5);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
}
