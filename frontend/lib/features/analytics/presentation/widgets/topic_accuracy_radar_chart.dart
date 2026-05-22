import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/analytics_models.dart';

/// Radar chart visualizing topic accuracy across multiple dimensions.
class TopicAccuracyRadarChart extends StatelessWidget {
  const TopicAccuracyRadarChart({super.key, required this.data});

  final List<TopicAccuracy> data;

  @override
  Widget build(BuildContext context) {
    final sorted = [...data]..sort((a, b) => b.accuracy.compareTo(a.accuracy));
    final displayData = sorted.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Topic Accuracy Radar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              const _LegendDot(color: AppColors.primary, label: 'Your Score'),
              const SizedBox(width: 12),
              const _LegendDot(color: AppColors.divider, label: 'Benchmark'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 280,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                radarBorderData: const BorderSide(
                  color: AppColors.divider,
                  width: 1,
                ),
                gridBorderData: const BorderSide(
                  color: AppColors.divider,
                  width: 0.5,
                ),
                tickBorderData: const BorderSide(
                  color: AppColors.divider,
                  width: 0.5,
                ),
                ticksTextStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                tickCount: 5,
                titleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                getTitle: (index, angle) {
                  if (index < 0 || index >= displayData.length) {
                    return const RadarChartTitle(text: '');
                  }
                  return RadarChartTitle(
                    text: displayData[index].topic,
                  );
                },
                dataSets: [
                  // Benchmark ring at 75%
                  RadarDataSet(
                    dataEntries: displayData
                        .map((_) => const RadarEntry(value: 75))
                        .toList(),
                    borderColor: AppColors.divider,
                    fillColor: Colors.transparent,
                    borderWidth: 1,
                    entryRadius: 0,
                  ),
                  // Actual scores
                  RadarDataSet(
                    dataEntries: displayData
                        .map((t) => RadarEntry(value: t.accuracy))
                        .toList(),
                    borderColor: AppColors.primary,
                    fillColor: AppColors.primary.withValues(alpha: 0.15),
                    borderWidth: 2.5,
                    entryRadius: 4,
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 400),
            ),
          ),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
