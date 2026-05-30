import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/molecules/app_loading_indicator.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../common_widgets/organisms/error_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';

import '../providers/analytics_provider.dart';
import '../widgets/animated_stat_card.dart';
import '../widgets/improvement_line_chart.dart';
import '../widgets/performance_heatmap.dart';
import '../widgets/streak_calendar.dart';
import '../widgets/topic_accuracy_radar_chart.dart';

/// Comprehensive weakness analytics dashboard.
/// Purely observational — charts, stats, and calendars only.
/// Actionable practice content lives in the Exam tab.
class WeaknessAnalyticsScreen extends ConsumerWidget {
  const WeaknessAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(analyticsSummaryProvider);
    final selectedRange = ref.watch(analyticsTimeRangeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: asyncData.when(
        data: (summary) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  l10n.analyticsTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB87A4B), Color(0xFF8B5A2B), Color(0xFF6B3E1F)],
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        Icons.analytics_outlined,
                        size: 80,
                        color: Colors.white12,
                      ),
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => ref.invalidate(analyticsSummaryProvider),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Time range selector
                  _TimeRangeSelector(
                    selected: selectedRange,
                    onChanged: (range) {
                      ref.read(analyticsTimeRangeProvider.notifier).state =
                          range;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: AnimatedStatCard(
                            value: summary.averageAccuracy,
                            label: l10n.analyticsAvgAccuracy,
                            icon: Icons.percent,
                            suffix: '%',
                            color: _accuracyColor(summary.averageAccuracy),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedStatCard(
                            value: summary.weakChapters.length.toDouble(),
                            label: l10n.analyticsWeakChapters,
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedStatCard(
                            value: summary.streakData.currentStreak.toDouble(),
                            label: l10n.analyticsDayStreakLabel,
                            icon: Icons.local_fire_department,
                            suffix: 'd',
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Charts and lists with staggered animations
            SliverList(
              delegate: SliverChildListDelegate([
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 100),
                  child: TopicAccuracyRadarChart(
                    data: summary.topicAccuracy,
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 200),
                  child: PerformanceHeatmap(data: summary.streakData),
                ),
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, child) {
                    final improvementAsync = ref.watch(
                      filteredImprovementProvider,
                    );
                    return improvementAsync.when(
                      data: (data) => AnimatedFadeSlide(
                        delay: const Duration(milliseconds: 300),
                        child: ImprovementLineChart(data: data),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // CTA banner pointing to Exam tab for practice
                if (summary.weakChapters.isNotEmpty)
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PracticeCtaBanner(
                        weakChapterCount: summary.weakChapters.length,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 500),
                  child: StreakCalendar(data: summary.streakData),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ],
        ),
        loading: () => Scaffold(
          appBar: CustomAppBar(
            title: l10n.analyticsTitle,
            showGradient: true,
          ),
          body: Center(child: AppLoadingIndicator(message: l10n.analyticsLoading)),
        ),
        error: (err, stack) => Scaffold(
          appBar: CustomAppBar(
            title: l10n.analyticsTitle,
            showGradient: true,
          ),
          body: ErrorState(
            message: l10n.analyticsLoadFailed,
            onRetry: () => ref.invalidate(analyticsSummaryProvider),
          ),
        ),
      ),
    );
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 80) return AppColors.success;
    if (accuracy >= 60) return AppColors.primary;
    return AppColors.primaryDark;
  }
}

/// Subtle banner that nudges users toward the Exam tab to practice
/// their weak topics.
class _PracticeCtaBanner extends StatelessWidget {
  const _PracticeCtaBanner({required this.weakChapterCount});

  final int weakChapterCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => context.go(RouteNames.exam),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryWash,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: AppColors.primaryDark,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.analyticsReadyToImprove,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.analyticsWeakTopicsWaiting(weakChapterCount),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal chip selector for time ranges.
class _TimeRangeSelector extends StatelessWidget {
  const _TimeRangeSelector({
    required this.selected,
    required this.onChanged,
  });

  final AnalyticsTimeRange selected;
  final ValueChanged<AnalyticsTimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ranges = [
      (AnalyticsTimeRange.last7Days, l10n.analyticsLast7Days),
      (AnalyticsTimeRange.last30Days, l10n.analyticsLast30Days),
      (AnalyticsTimeRange.last90Days, l10n.analyticsLast90Days),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ranges.map((item) {
          final isSelected = selected == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item.$2),
              selected: isSelected,
              onSelected: (_) => onChanged(item.$1),
              selectedColor: AppColors.primaryDark,
              backgroundColor: AppColors.cardBg,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.divider,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        }).toList(),
      ),
    );
  }
}
