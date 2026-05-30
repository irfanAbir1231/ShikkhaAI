import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/models/dashboard_models.dart';

/// Async provider that fetches dashboard analytics from the real API.
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final student = ref.watch(studentProvider);
  if (student == null) {
    throw Exception('Not authenticated');
  }
  final remote = DashboardRemoteDataSource();
  return remote.fetchDashboard(student.id);
});
