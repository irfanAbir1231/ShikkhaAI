import '../../../../core/network/api_service.dart';
import '../models/topic_models.dart';

/// Remote data source for topics API calls.
class TopicsRemoteDataSource {
  TopicsRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Fetches the student's topic completion overview.
  /// Calls GET /student/{studentId}/topics
  Future<TopicsOverview> fetchTopicsOverview(int studentId) async {
    final data = await _apiService.get('/student/$studentId/topics');
    return TopicsOverview.fromJson(data as Map<String, dynamic>);
  }
}
