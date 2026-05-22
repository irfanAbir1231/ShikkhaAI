import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/color_tokens.dart';
import '../../data/models/study_plan_models.dart';
import '../providers/study_plan_provider.dart';

/// Timeline view of tasks for a selected day.
class DailyScheduleTimeline extends ConsumerWidget {
  const DailyScheduleTimeline({super.key, required this.day});

  final StudyDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    if (day.isRestDay) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.divider.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.weekend,
              size: 40,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Rest Day',
              style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Take a break and recharge for tomorrow!',
              style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (day.tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No tasks scheduled for this day.',
          style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${day.tasks.length} Tasks · ${day.totalMinutes} min',
                style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '${day.completedTasks}/${day.tasks.length} done',
                style: textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        ...day.tasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          final isLast = index == day.tasks.length - 1;

          return _TimelineItem(
            task: task,
            isLast: isLast,
            onToggle: (completed) {
              final plan = ref.read(activePlanProvider);
              if (plan == null) return;
              ref
                  .read(studyPlansProvider.notifier)
                  .updateTaskCompletion(
                    plan.id,
                    day.date.toIso8601String(),
                    task.id,
                    completed,
                  );
            },
          );
        }),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.task,
    required this.isLast,
    required this.onToggle,
  });

  final StudyTask task;
  final bool isLast;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? AppColors.success
                      : task.type.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cardBg,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (task.isCompleted ? AppColors.success : task.type.color)
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.divider.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Task content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                        ),
                      ),
                      Checkbox(
                        value: task.isCompleted,
                        onChanged: (v) => onToggle(v ?? false),
                        activeColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        task.type.icon,
                        size: 14,
                        color: task.type.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.type.label,
                        style: textTheme.bodySmall?.copyWith(
                              color: task.type.color,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.durationMinutes} min',
                        style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          task.subject,
                          style: textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
