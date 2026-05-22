import 'package:flutter/material.dart';

import '../../../../theme/color_tokens.dart';
import '../../data/models/explanation_mode.dart';

/// Small inline badge showing which explanation mode was used.
class ModeBadge extends StatelessWidget {
  const ModeBadge({
    super.key,
    required this.mode,
  });

  final ExplanationMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            mode.icon,
            size: 10,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            mode.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
