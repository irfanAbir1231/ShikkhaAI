import '../../data/datasources/analytics_remote_datasource.dart';
import '../../data/models/analytics_models.dart';
import 'analytics_repository_interface.dart';

/// Concrete analytics repository backed by the remote API.
class AnalyticsRepository implements AnalyticsRepositoryInterface {
  const AnalyticsRepository();

  @override
  Future<AnalyticsSummary> fetchAnalytics(int studentId) =>
      AnalyticsRemoteDataSource().fetchAnalytics(studentId);

  @override
  Future<List<TopicAccuracy>> getTopicAccuracy(int studentId) async {
    final summary = await AnalyticsRemoteDataSource().fetchAnalytics(studentId);
    return summary.topicAccuracy;
  }

  @override
  Future<List<WeakChapter>> getWeakChapters(int studentId) async {
    final summary = await AnalyticsRemoteDataSource().fetchAnalytics(studentId);
    return summary.weakChapters;
  }

  @override
  Future<List<ImprovementPoint>> getImprovementHistory(int studentId) async {
    final summary = await AnalyticsRemoteDataSource().fetchAnalytics(studentId);
    return summary.improvementHistory;
  }

  @override
  Future<DailyStreakData> getStreakData(int studentId) async {
    final summary = await AnalyticsRemoteDataSource().fetchAnalytics(studentId);
    return summary.streakData;
  }

  @override
  Future<List<PracticeSuggestion>> getPracticeSuggestions(int studentId) async {
    final summary = await AnalyticsRemoteDataSource().fetchAnalytics(studentId);
    return summary.practiceSuggestions;
  }
}
