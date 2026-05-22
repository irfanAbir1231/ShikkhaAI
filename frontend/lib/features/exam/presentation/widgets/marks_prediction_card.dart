import 'package:flutter/material.dart';

import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../theme/gradients.dart';
import '../../data/models/exam_result_model.dart';

/// Gradient card showing predicted marks based on readiness score.
class MarksPredictionCard extends StatelessWidget {
  const MarksPredictionCard({super.key, required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    final predicted = result.predictedMarks;
    final confidence = result.predictionConfidence;
    final readiness = result.readinessScore;

    return AppCard(
      padding: const EdgeInsets.all(20),
      gradient: AppGradients.cardShine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Marks Prediction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                predicted.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ ${result.totalMarks}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Badge(
                label: '$confidence Confidence',
                color: confidence == 'High'
                    ? AppColors.success
                    : confidence == 'Medium'
                        ? AppColors.warning
                        : AppColors.danger,
              ),
              const SizedBox(width: 8),
              _Badge(
                label: 'Readiness: ${readiness.toStringAsFixed(1)}%',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Based on your current performance and consistency across topics.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
