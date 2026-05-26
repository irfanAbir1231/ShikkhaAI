import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/topics_local_datasource.dart';
import '../../data/models/topic_models.dart';
import '../../domain/repositories/topics_repository.dart';

// ------------------------------------------------------------------
// Repository
// ------------------------------------------------------------------
final topicsRepositoryProvider = Provider<TopicsRepository>((ref) {
  final topicsBox = Hive.box<String>(StorageKeys.topicsBox);
  return TopicsRepository(
    localDataSource: TopicsLocalDataSource(topicsBox: topicsBox),
  );
});

// ------------------------------------------------------------------
// Topics overview
// ------------------------------------------------------------------
final topicsOverviewProvider = FutureProvider<TopicsOverview>((ref) async {
  final repo = ref.read(topicsRepositoryProvider);
  final student = ref.watch(studentProvider);
  if (student == null) {
    throw Exception('Student not authenticated');
  }

  final result = await repo.getTopicsOverview(student.id);
  return result.when(
    success: (overview) => overview,
    failure: (failure) => throw Exception(failure.message),
  );
});

// ------------------------------------------------------------------
// Subject filter
// ------------------------------------------------------------------
final selectedSubjectFilterProvider = StateProvider<String?>((ref) => null);

final filteredSubjectsProvider = Provider<AsyncValue<List<SubjectTopics>>>((ref) {
  final overviewAsync = ref.watch(topicsOverviewProvider);
  final filter = ref.watch(selectedSubjectFilterProvider);

  return overviewAsync.whenData((overview) {
    if (filter == null) return overview.subjects;
    return overview.subjects
        .where((s) => s.subject.toLowerCase() == filter.toLowerCase())
        .toList();
  });
});
