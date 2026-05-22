import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dashboard_models.dart';
import '../../data/services/mock_dashboard_service.dart';

/// Async provider that fetches dashboard analytics.
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  return MockDashboardService.fetchDashboard();
});
