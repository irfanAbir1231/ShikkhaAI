import 'package:flutter/material.dart';

import '../../theme/color_tokens.dart';

/// Consistent icon wrapper with optional circular background.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(8),
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.primary;

    Widget child = Icon(icon, size: size, color: iconColor);

    if (backgroundColor != null) {
      child = Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: child,
      );
    }

    return child;
  }
}

/// Pre-defined status icons with semantic colors.
class StatusIcon extends StatelessWidget {
  const StatusIcon.success({super.key, this.size = 24})
      : icon = Icons.check_circle_rounded,
        color = AppColors.success;

  const StatusIcon.warning({super.key, this.size = 24})
      : icon = Icons.warning_amber_rounded,
        color = AppColors.warning;

  const StatusIcon.error({super.key, this.size = 24})
      : icon = Icons.error_rounded,
        color = AppColors.danger;

  const StatusIcon.info({super.key, this.size = 24})
      : icon = Icons.info_rounded,
        color = AppColors.accent;

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppIcon(
      icon: icon,
      size: size,
      color: color,
    );
  }
}
