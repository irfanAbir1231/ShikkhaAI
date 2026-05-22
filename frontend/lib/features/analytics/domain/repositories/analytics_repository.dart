import '../../data/models/analytics_models.dart';
import '../../data/services/mock_analytics_service.dart';
import 'analytics_repository_interface.dart';

/// Concrete analytics repository backed by mock service.
///
/// Ready to swap to a remote datasource when the backend analytics
/// endpoints are available.
class AnalyticsRepository implements AnalyticsRepositoryInterface {
  const AnalyticsRepository();

  @override
  Future<AnalyticsSummary> fetchAnalytics() =>
      MockAnalyticsService.fetchAnalytics();

  @override
  Future<List<TopicAccuracy>> getTopicAccuracy() async {
    final summary = await MockAnalyticsService.fetchAnalytics();
    return summary.topicAccuracy;
  }

  @override
  Future<List<WeakChapter>> getWeakChapters() async {
    final summary = await MockAnalyticsService.fetchAnalytics();
    return summary.weakChapters;
  }

  @override
  Future<List<ImprovementPoint>> getImprovementHistory() async {
    final summary = await MockAnalyticsService.fetchAnalytics();
    return summary.improvementHistory;
  }

  @override
  Future<DailyStreakData> getStreakData() async {
    final summary = await MockAnalyticsService.fetchAnalytics();
    return summary.streakData;
  }

  @override
  Future<List<PracticeSuggestion>> getPracticeSuggestions() async {
    final summary = await MockAnalyticsService.fetchAnalytics();
    return summary.practiceSuggestions;
  }
}
