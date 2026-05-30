import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../models/analytics_models.dart';

/// Remote data source for analytics API.
///
/// Backend contract: `GET /student/{id}/analytics` → envelope `data` is an
/// [AnalyticsSummary] JSON.
class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<AnalyticsSummary> fetchAnalytics(int studentId) async {
    final data = await _apiService.get(
      '${ApiConstants.studentById}/$studentId${ApiConstants.studentAnalyticsSuffix}',
    );
    return AnalyticsSummary.fromJson(data as Map<String, dynamic>);
  }
}
