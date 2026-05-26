import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../theme/color_tokens.dart';

/// Header card showing overall topic completion stats.
class TopicsOverallProgressCard extends StatelessWidget {
  const TopicsOverallProgressCard({
    super.key,
    required this.totalTopics,
    required this.completedTopics,
    required this.overallPercentage,
  });

  final int totalTopics;
  final int completedTopics;
  final double overallPercentage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 40,
                lineWidth: 8,
                percent: (overallPercentage / 100).clamp(0, 1),
                progressColor: AppColors.primary,
                backgroundColor: Colors.grey.shade200,
                circularStrokeCap: CircularStrokeCap.round,
                center: Text(
                  '${overallPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedTopics of $totalTopics topics completed',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      overallPercentage >= 60
                          ? 'Great progress! Keep it up.'
                          : 'Focus on your weak topics to improve.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
