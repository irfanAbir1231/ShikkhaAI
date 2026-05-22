import 'package:flutter/material.dart';

import '../../../../theme/color_tokens.dart';

/// Small chip showing "Adaptive" with spark icon.
class AdaptiveDifficultyBadge extends StatelessWidget {
  const AdaptiveDifficultyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_fix_high,
            color: AppColors.primary,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            'Adaptive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
