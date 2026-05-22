import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/analytics_models.dart';
import '../../domain/repositories/analytics_repository.dart';

/// Analytics repository provider.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => const AnalyticsRepository(),
);

/// Selected time range for analytics filtering.
enum AnalyticsTimeRange { last7Days, last30Days, last90Days }

/// Currently selected time range.
final analyticsTimeRangeProvider = StateProvider<AnalyticsTimeRange>(
  (ref) => AnalyticsTimeRange.last30Days,
);

/// Main analytics data provider.
final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>(
  (ref) => ref.watch(analyticsRepositoryProvider).fetchAnalytics(),
);

/// Filtered topic accuracy based on selected time range.
final filteredTopicAccuracyProvider = Provider<AsyncValue<List<TopicAccuracy>>>(
  (ref) {
    final asyncSummary = ref.watch(analyticsSummaryProvider);
    return asyncSummary.when(
      data: (summary) => AsyncValue.data(summary.topicAccuracy),
      loading: () => const AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    );
  },
);

/// Filtered weak chapters.
final filteredWeakChaptersProvider = Provider<AsyncValue<List<WeakChapter>>>(
  (ref) {
    final asyncSummary = ref.watch(analyticsSummaryProvider);
    return asyncSummary.when(
      data: (summary) => AsyncValue.data(summary.weakChapters),
      loading: () => const AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    );
  },
);

/// Filtered improvement history.
final filteredImprovementProvider = Provider<AsyncValue<List<ImprovementPoint>>>(
  (ref) {
    final range = ref.watch(analyticsTimeRangeProvider);
    final asyncSummary = ref.watch(analyticsSummaryProvider);
    return asyncSummary.when(
      data: (summary) {
        final now = DateTime.now();
        final days = switch (range) {
          AnalyticsTimeRange.last7Days => 7,
          AnalyticsTimeRange.last30Days => 30,
          AnalyticsTimeRange.last90Days => 90,
        };
        final cutoff = now.subtract(Duration(days: days));
        final filtered = summary.improvementHistory
            .where((p) => p.date.isAfter(cutoff))
            .toList();
        return AsyncValue.data(filtered);
      },
      loading: () => const AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    );
  },
);
