import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../models/dashboard_models.dart';

/// Remote data source for dashboard API.
///
/// Backend contract: `GET /student/{id}/dashboard` → envelope `data` is a
/// [DashboardData] JSON. Until backend ships, callers should keep using
/// `MockDashboardService` via the repository.
class DashboardRemoteDataSource {
  DashboardRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<DashboardData> fetchDashboard(int studentId) async {
    final data = await _apiService.get(
      '${ApiConstants.studentById}/$studentId${ApiConstants.studentDashboardSuffix}',
    );
    return DashboardData.fromJson(data as Map<String, dynamic>);
  }
}
