import '../../data/models/analytics_models.dart';

/// Abstract contract for analytics data access.
abstract class AnalyticsRepositoryInterface {
  /// Fetch complete analytics snapshot.
  Future<AnalyticsSummary> fetchAnalytics();

  /// Get topic accuracy breakdown.
  Future<List<TopicAccuracy>> getTopicAccuracy();

  /// Get weak chapters ordered by weakness rank.
  Future<List<WeakChapter>> getWeakChapters();

  /// Get improvement history over time.
  Future<List<ImprovementPoint>> getImprovementHistory();

  /// Get streak and daily activity data.
  Future<DailyStreakData> getStreakData();

  /// Get personalized practice suggestions.
  Future<List<PracticeSuggestion>> getPracticeSuggestions();
}
