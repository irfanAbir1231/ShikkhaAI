import 'package:flutter/material.dart';

import 'color_tokens.dart';

/// Shared gradient definitions — now solid colors for backward compat.
class AppGradients {
  const AppGradients._();

  // Hero — solid primary.
  static const LinearGradient hero = LinearGradient(
    colors: [AppColors.primary, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle white card sheen — solid cardBg.
  static const LinearGradient cardShine = LinearGradient(
    colors: [AppColors.cardBg, AppColors.cardBg],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Success — solid green.
  static const LinearGradient success = LinearGradient(
    colors: [AppColors.success, AppColors.success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warning / progress — solid yellow.
  static const LinearGradient warning = LinearGradient(
    colors: [AppColors.warning, AppColors.warning],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Danger — solid orange-red.
  static const LinearGradient danger = LinearGradient(
    colors: [AppColors.danger, AppColors.danger],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
