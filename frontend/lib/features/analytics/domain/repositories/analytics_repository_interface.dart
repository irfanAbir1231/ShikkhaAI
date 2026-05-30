import '../../data/models/analytics_models.dart';

/// Abstract contract for analytics data access.
abstract class AnalyticsRepositoryInterface {
  /// Fetch complete analytics snapshot for a student.
  Future<AnalyticsSummary> fetchAnalytics(int studentId);

  /// Get topic accuracy breakdown.
  Future<List<TopicAccuracy>> getTopicAccuracy(int studentId);

  /// Get weak chapters ordered by weakness rank.
  Future<List<WeakChapter>> getWeakChapters(int studentId);

  /// Get improvement history over time.
  Future<List<ImprovementPoint>> getImprovementHistory(int studentId);

  /// Get streak and daily activity data.
  Future<DailyStreakData> getStreakData(int studentId);

  /// Get personalized practice suggestions.
  Future<List<PracticeSuggestion>> getPracticeSuggestions(int studentId);
}
