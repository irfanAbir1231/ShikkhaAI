import 'package:flutter/material.dart';

import '../../../../common_widgets/animations/animated_scale_tap.dart';
import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../theme/neu_decoration.dart';
import '../../data/models/dashboard_models.dart';
import 'section_header.dart';

/// AI-powered personalized recommendations.
class AIRecommendationsSection extends StatelessWidget {
  const AIRecommendationsSection({super.key, required this.recommendations});

  final List<AIRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: AppLocalizations.of(context).dashAiRecommendations),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: recommendations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final rec = recommendations[index];
            return AnimatedScaleTap(
              onTap: () {},
              child: AppCard(
                margin: EdgeInsets.zero,
                border: Border.all(
                  color: _priorityColor(rec.priority).withValues(alpha: 0.3),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: NeuDecoration.colored(
                        color: _typeColor(rec.type),
                        radius: 12,
                      ),
                      child: Icon(
                        _typeIcon(rec.type),
                        color: _typeColor(rec.type) == AppColors.warning
                            ? AppColors.textPrimary
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rec.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PriorityBadge(priority: rec.priority),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            rec.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _typeIcon(RecommendationType type) {
    return switch (type) {
      RecommendationType.study => Icons.menu_book,
      RecommendationType.practice => Icons.fitness_center,
      RecommendationType.review => Icons.replay,
      RecommendationType.challenge => Icons.emoji_events,
    };
  }

  Color _typeColor(RecommendationType type) {
    return switch (type) {
      RecommendationType.study => AppColors.primary,
      RecommendationType.practice => AppColors.success,
      RecommendationType.review => AppColors.warning,
      RecommendationType.challenge => AppColors.danger,
    };
  }

  Color _priorityColor(RecommendationPriority priority) {
    return switch (priority) {
      RecommendationPriority.high => AppColors.danger,
      RecommendationPriority.medium => AppColors.warning,
      RecommendationPriority.low => AppColors.success,
    };
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final RecommendationPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      RecommendationPriority.high => AppColors.danger,
      RecommendationPriority.medium => AppColors.warning,
      RecommendationPriority.low => AppColors.success,
    };

    final l10n = AppLocalizations.of(context);
    final label = switch (priority) {
      RecommendationPriority.high => l10n.priorityHigh,
      RecommendationPriority.medium => l10n.priorityMedium,
      RecommendationPriority.low => l10n.priorityLow,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
