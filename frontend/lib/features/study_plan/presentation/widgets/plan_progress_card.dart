import 'package:flutter/material.dart';

import '../../../../theme/gradients.dart';
import '../../data/models/study_plan_models.dart';

/// Circular progress card with plan stats.
class PlanProgressCard extends StatelessWidget {
  const PlanProgressCard({super.key, required this.plan});

  final StudyPlan plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final daysLeft = plan.config.daysUntilExam;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.transparent),
                ),
                CircularProgressIndicator(
                  value: plan.progressPercentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${plan.progressPercentage.toStringAsFixed(0)}%',
                    style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  daysLeft > 0 ? '$daysLeft days until exam' : 'Exam day!',
                  style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                _StatRow(
                  icon: Icons.check_circle,
                  label: '${plan.completedTasksCount}/${plan.totalTasksCount} tasks',
                  textTheme: textTheme,
                ),
                const SizedBox(height: 4),
                _StatRow(
                  icon: Icons.schedule,
                  label: '${plan.totalStudyHours} hours total',
                  textTheme: textTheme,
                ),
                const SizedBox(height: 4),
                _StatRow(
                  icon: Icons.trending_up,
                  label: '${plan.config.dailyStudyMinutes} min/day',
                  textTheme: textTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
        ),
      ],
    );
  }
}
