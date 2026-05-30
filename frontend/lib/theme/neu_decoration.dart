import 'package:flutter/material.dart';

import 'color_tokens.dart';

/// Flat / minimalist decoration helpers.
///
/// Originally a neumorphic helper; rewritten for the minimalist palette —
/// pure white surfaces with subtle single-direction shadows and 1px hairline
/// borders. API preserved so existing call sites compile unchanged.
class NeuDecoration {
  const NeuDecoration._();

  /// Raised plate — white card with soft shadow.
  static BoxDecoration raised({
    bool isDark = false,
    double radius = 16,
    Color? color,
    double depth = 1.0,
    Gradient? gradient,
  }) {
    final base = color ?? (isDark ? AppColors.cardBgDark : AppColors.cardBg);
    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.05 * depth);

    return BoxDecoration(
      color: gradient == null ? base : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? AppColors.dividerDark : AppColors.divider,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: shadow,
          offset: Offset(0, 4 * depth),
          blurRadius: 12 * depth,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Inset well — recessed surface (inputs, selected tabs).
  static BoxDecoration inset({
    bool isDark = false,
    double radius = 12,
    Color? color,
  }) {
    final base =
        color ?? (isDark ? AppColors.neuInsetDarkDark : AppColors.neuInsetLight);
    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? AppColors.dividerDark : AppColors.divider,
        width: 1,
      ),
    );
  }

  /// Solid color plate with subtle border and directional shadow.
  static BoxDecoration colored({
    required Color color,
    double radius = 16,
    double depth = 1.0,
  }) {
    final lighter = Color.lerp(color, Colors.white, 0.35)!;
    final darker = Color.lerp(color, Colors.black, 0.25)!;
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: lighter,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: darker.withValues(alpha: 0.45 * depth),
          offset: Offset(0, 4 * depth),
          blurRadius: 10 * depth,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: lighter.withValues(alpha: 0.25 * depth),
          offset: Offset(0, -2 * depth),
          blurRadius: 4 * depth,
          spreadRadius: -1,
        ),
      ],
    );
  }

  /// Soft floating plate — app bars / nav bars (lighter depth).
  static BoxDecoration floating({
    bool isDark = false,
    double radius = 20,
    Color? color,
  }) {
    final base = color ?? (isDark ? AppColors.cardBgDark : AppColors.cardBg);
    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: (isDark ? Colors.black : Colors.black).withValues(
            alpha: isDark ? 0.45 : 0.04,
          ),
          offset: const Offset(0, 2),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );
  }
}
