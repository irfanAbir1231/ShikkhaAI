import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/color_tokens.dart';
import '../providers/exam_provider.dart';

/// Animated countdown timer with color transitions.
class ExamTimer extends ConsumerWidget {
  const ExamTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeString = ref.watch(examTimerProvider(null));
    final color = ref.watch(examTimerColorProvider);
    final progress = ref.watch(examTimerProgressProvider);

    final isUrgent = color == AppColors.danger;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: AlwaysStoppedAnimation(isUrgent ? 1.0 : 0.0),
            builder: (context, child) {
              return Icon(
                Icons.timer_outlined,
                color: color,
                size: 20,
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
