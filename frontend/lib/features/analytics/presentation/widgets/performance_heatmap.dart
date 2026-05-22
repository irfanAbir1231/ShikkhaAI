import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/color_tokens.dart';
import '../../../../common_widgets/molecules/app_card.dart';
import '../../data/models/analytics_models.dart';

/// Performance heatmap showing daily activity and scores over the last 30 days.
class PerformanceHeatmap extends StatelessWidget {
  const PerformanceHeatmap({super.key, required this.data});

  final DailyStreakData data;

  @override
  Widget build(BuildContext context) {
    final days = data.last30Days;
    // Group into weeks (rows)
    final weeks = <List<DailyActivity>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7 > days.length ? days.length : i + 7));
    }

    final weekDayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Performance Heatmap',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LegendItem(color: _scoreColor(85), label: 'High'),
                  _LegendItem(color: _scoreColor(65), label: 'Mid'),
                  _LegendItem(color: _scoreColor(45), label: 'Low'),
                  _LegendItem(color: _scoreColor(null), label: 'None'),
                ],
              ),
              const SizedBox(height: 12),
              // Heatmap grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weekday labels
                  Column(
                    children: weekDayLabels
                        .map(
                          (label) => SizedBox(
                            height: 28,
                            width: 20,
                            child: Center(
                              child: Text(
                                label,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(width: 8),
                  // Grid
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: days.map((day) {
                        return _HeatmapCell(day: day);
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Month labels
              Row(
                children: _monthLabels(days).map((label) {
                  return Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _monthLabels(List<DailyActivity> days) {
    final labels = <String>[];
    final seenMonths = <int>{};
    for (final day in days) {
      final month = day.date.month;
      if (!seenMonths.contains(month)) {
        seenMonths.add(month);
        labels.add(DateFormat('MMM').format(day.date));
      }
    }
    return labels;
  }

  static Color _scoreColor(double? score) {
    if (score == null) return AppColors.divider.withValues(alpha: 0.5);
    if (score >= 80) return AppColors.success;
    if (score >= 60) return const Color(0xFF84CC16); // lime
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.day});

  final DailyActivity day;

  @override
  Widget build(BuildContext context) {
    final color = PerformanceHeatmap._scoreColor(day.performanceScore);

    return Tooltip(
      message: day.isActive
          ? '${DateFormat('MMM d').format(day.date)}: '
              '${day.performanceScore?.toStringAsFixed(0) ?? 0}% '
              '(${day.questionsAnswered ?? 0} Qs, ${day.studyMinutes ?? 0} min)'
          : '${DateFormat('MMM d').format(day.date)}: No activity',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
