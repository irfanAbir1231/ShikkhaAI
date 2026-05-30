import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';

import '../../data/models/analytics_models.dart';

/// Expandable list of weak chapters with actionable insights.
class WeakChaptersList extends StatelessWidget {
  const WeakChaptersList({super.key, required this.chapters});

  final List<WeakChapter> chapters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context).weakChaptersDetected,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 8),
        ...chapters.asMap().entries.map((entry) {
          final index = entry.key;
          final chapter = entry.value;
          return _WeakChapterCard(
            chapter: chapter,
            index: index,
          );
        }),
      ],
    );
  }
}

class _WeakChapterCard extends StatelessWidget {
  const _WeakChapterCard({required this.chapter, required this.index});

  final WeakChapter chapter;
  final int index;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final barColor = _accuracyColor(chapter.accuracy);
    final trendColor = chapter.isImproving
        ? AppColors.success
        : (chapter.isDeclining ? AppColors.primaryDark : AppColors.textSecondary);
    final trendIcon = chapter.isImproving
        ? Icons.trending_up_rounded
        : (chapter.isDeclining
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: wood badge + title + trend
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF8B5A2B),
                ),
                child: Center(
                  child: Text(
                    '#${chapter.weaknessRank}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.chapterName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      chapter.subject,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${chapter.trend.abs().toStringAsFixed(0)}%',
                    style: textTheme.bodySmall?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Accuracy bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: chapter.accuracy / 100,
              minHeight: 8,
              backgroundColor: AppColors.primarySoft.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.homeAccuracyPercent(chapter.accuracy.toStringAsFixed(0)),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                l10n.minutesSpent(chapter.timeSpentMinutes),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Related topics — wood-themed chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chapter.relatedTopics.map((topic) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryWash,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  topic,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Suggested action — warm cream tip box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primaryDark,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    chapter.suggestedAction,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Action button — wood textured
          SizedBox(
            width: double.infinity,
            height: 44,
            child: GestureDetector(
              onTap: () {
                context.push(
                  '${RouteNames.exam}/${RouteNames.examConfig}',
                  extra: {
                    'subject': chapter.subject,
                    'topic': chapter.chapterName,
                    'difficulty': 'easy',
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFB87A4B), Color(0xFF8B5A2B), Color(0xFF6B3E1F)],
                  ),
                  border: Border.all(
                    color: const Color(0xFFC19A6B).withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B3E1F).withValues(alpha: 0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.homePracticeNow,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 80) return AppColors.success;
    if (accuracy >= 60) return AppColors.primary;
    return AppColors.primaryDark;
  }
}
