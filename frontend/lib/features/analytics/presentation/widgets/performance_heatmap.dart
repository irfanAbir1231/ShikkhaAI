import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/color_tokens.dart';
import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/analytics_models.dart';

/// Performance heatmap showing daily activity and scores over the last 30 days.
class PerformanceHeatmap extends StatelessWidget {
  const PerformanceHeatmap({super.key, required this.data});

  final DailyStreakData data;

  @override
  Widget build(BuildContext context) {
    final days = data.last30Days;
    final l10n = AppLocalizations.of(context);

    if (days.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.heatmapTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.heatmapNoActivity,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.heatmapNoActivityDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final weekDayLabels = l10n.analyticsWeekdayInitialsSun.split(',');

    // Build column-oriented grid (GitHub-style): each column is one week,
    // days flow top-to-bottom (Sunday -> Saturday).
    final columns = _buildColumns(days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.heatmapTitle,
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
                  _LegendItem(color: _scoreColor(85), label: l10n.legendHigh),
                  _LegendItem(color: _scoreColor(65), label: l10n.legendMid),
                  _LegendItem(color: _scoreColor(45), label: l10n.legendLow),
                  _LegendItem(color: _scoreColor(null), label: l10n.legendNone),
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
                  // Grid columns
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: columns.map((column) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Column(
                              children: column.map((day) {
                                if (day == null) {
                                  return const SizedBox(
                                    width: 28,
                                    height: 28,
                                  );
                                }
                                return _HeatmapCell(day: day);
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
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

  /// Organises [days] into week-columns (Sun->Sat top-to-bottom).
  /// Partial first/last weeks are padded with `null` placeholders.
  List<List<DailyActivity?>> _buildColumns(List<DailyActivity> days) {
    if (days.isEmpty) return [];

    final columns = <List<DailyActivity?>>[];
    var currentColumn = List<DailyActivity?>.filled(7, null);
    var currentRow = days.first.date.weekday % 7; // Sunday=0, Monday=1, ...

    for (final day in days) {
      final row = day.date.weekday % 7;

      // If we wrapped past Saturday, start a new column
      if (row < currentRow) {
        columns.add(currentColumn);
        currentColumn = List<DailyActivity?>.filled(7, null);
      }

      currentColumn[row] = day;
      currentRow = row;
    }

    // Don't forget the last column
    columns.add(currentColumn);
    return columns;
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
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.primaryLight;
    return AppColors.primaryDark;
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.day});

  final DailyActivity day;

  @override
  Widget build(BuildContext context) {
    final color = day.isActive
        ? PerformanceHeatmap._scoreColor(day.performanceScore)
        : PerformanceHeatmap._scoreColor(null);

    return Tooltip(
      message: day.isActive
          ? '${DateFormat('MMM d').format(day.date)}: '
              '${day.performanceScore?.toStringAsFixed(0) ?? 0}% '
              '(${day.questionsAnswered ?? 0} Qs, ${day.studyMinutes ?? 0} min)'
          : '${DateFormat('MMM d').format(day.date)}: ${AppLocalizations.of(context).heatmapNoActivityDay}',
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
