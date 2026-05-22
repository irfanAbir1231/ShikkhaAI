import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/color_tokens.dart';

import '../providers/exam_provider.dart';

/// Segmented linear progress bar showing answered / marked / unanswered.
class ExamProgressBar extends ConsumerWidget {
  const ExamProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(examSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final total = session.totalQuestions;
    if (total == 0) return const SizedBox.shrink();

    final answered = session.answeredCount;
    final marked = session.markedCount;
    final unanswered = total - answered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              if (answered > 0)
                Expanded(
                  flex: answered,
                  child: Container(
                    height: 8,
                    color: AppColors.success,
                  ),
                ),
              if (marked > 0)
                Expanded(
                  flex: marked,
                  child: Container(
                    height: 8,
                    color: AppColors.warning,
                  ),
                ),
              if (unanswered > 0)
                Expanded(
                  flex: unanswered,
                  child: Container(
                    height: 8,
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _LegendDot(
              color: AppColors.success,
              label: '$answered Answered',
            ),
            _LegendDot(
              color: AppColors.warning,
              label: '$marked Marked',
            ),
            _LegendDot(
              color: AppColors.divider,
              label: '$unanswered Left',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
