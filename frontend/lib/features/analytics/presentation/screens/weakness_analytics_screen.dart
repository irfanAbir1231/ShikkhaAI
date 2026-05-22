import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/molecules/app_loading_indicator.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../common_widgets/organisms/error_state.dart';
import '../../../../theme/color_tokens.dart';
import '../providers/analytics_provider.dart';
import '../widgets/animated_stat_card.dart';
import '../widgets/improvement_line_chart.dart';
import '../widgets/performance_heatmap.dart';
import '../widgets/practice_suggestions_card.dart';
import '../widgets/streak_calendar.dart';
import '../widgets/topic_accuracy_radar_chart.dart';
import '../widgets/weak_chapters_list.dart';

/// Comprehensive weakness analytics dashboard.
class WeaknessAnalyticsScreen extends ConsumerWidget {
  const WeaknessAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(analyticsSummaryProvider);
    final selectedRange = ref.watch(analyticsTimeRangeProvider);

    return Scaffold(
      body: asyncData.when(
        data: (summary) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Weakness Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                            label: 'Avg Accuracy',
                            icon: Icons.percent,
                            suffix: '%',
                            color: _accuracyColor(summary.averageAccuracy),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedStatCard(
                            value: summary.weakChapters.length.toDouble(),
                            label: 'Weak Chapters',
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedStatCard(
                            value: summary.streakData.currentStreak.toDouble(),
                            label: 'Day Streak',
                            icon: Icons.local_fire_department,
                            suffix: 'd',
                            color: AppColors.warning,
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
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 400),
                  child: WeakChaptersList(chapters: summary.weakChapters),
                ),
                const SizedBox(height: 24),
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 500),
                  child: PracticeSuggestionsCard(
                    suggestions: summary.practiceSuggestions,
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 600),
                  child: StreakCalendar(data: summary.streakData),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ],
        ),
        loading: () => const Scaffold(
          appBar: CustomAppBar(
            title: 'Weakness Analytics',
            showGradient: true,
          ),
          body: Center(child: AppLoadingIndicator(message: 'Loading analytics...')),
        ),
        error: (err, stack) => Scaffold(
          appBar: const CustomAppBar(
            title: 'Weakness Analytics',
            showGradient: true,
          ),
          body: ErrorState(
            message: 'Failed to load analytics',
            onRetry: () => ref.invalidate(analyticsSummaryProvider),
          ),
        ),
      ),
    );
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 80) return AppColors.success;
    if (accuracy >= 60) return AppColors.warning;
    return AppColors.danger;
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
    final ranges = [
      (AnalyticsTimeRange.last7Days, 'Last 7 Days'),
      (AnalyticsTimeRange.last30Days, 'Last 30 Days'),
      (AnalyticsTimeRange.last90Days, 'Last 90 Days'),
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
              selectedColor: AppColors.primary,
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
                      ? AppColors.primary
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
