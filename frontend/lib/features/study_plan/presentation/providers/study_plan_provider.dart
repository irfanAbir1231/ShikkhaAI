import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../data/datasources/study_plan_local_datasource.dart';
import '../../data/models/study_plan_models.dart';
import '../../domain/repositories/study_plan_repository.dart';

// ------------------------------------------------------------------
// Repository
// ------------------------------------------------------------------
final studyPlanRepositoryProvider = Provider<StudyPlanRepository>(
  (ref) => StudyPlanRepository(
    localDataSource: StudyPlanLocalDataSource(
      plansBox: Hive.box<String>(StorageKeys.studyPlansBox),
    ),
  ),
);

// ------------------------------------------------------------------
// All Plans
// ------------------------------------------------------------------
final studyPlansProvider =
    StateNotifierProvider<StudyPlansNotifier, List<StudyPlan>>(
  (ref) => StudyPlansNotifier(ref.watch(studyPlanRepositoryProvider)),
);

class StudyPlansNotifier extends StateNotifier<List<StudyPlan>> {
  StudyPlansNotifier(this._repo) : super([]) {
    loadPlans();
  }

  final StudyPlanRepository _repo;

  Future<void> loadPlans() async {
    state = await _repo.getPlans();
  }

  Future<StudyPlan> createPlan(StudyPlanConfig config) async {
    final plan = await _repo.createPlan(config);
    state = [plan, ...state];
    return plan;
  }

  Future<void> updateTaskCompletion(
    String planId,
    String dayDate,
    String taskId,
    bool isCompleted,
  ) async {
    final updated = await _repo.updateTaskCompletion(
      planId,
      dayDate,
      taskId,
      isCompleted,
    );
    state = state.map((p) => p.id == planId ? updated : p).toList();
  }

  Future<void> updateTask(
    String planId,
    String dayDate,
    StudyTask updatedTask,
  ) async {
    final updated = await _repo.updateTask(planId, dayDate, updatedTask);
    state = state.map((p) => p.id == planId ? updated : p).toList();
  }

  Future<void> deletePlan(String id) async {
    await _repo.deletePlan(id);
    state = state.where((p) => p.id != id).toList();
  }
}

// ------------------------------------------------------------------
// Active Plan
// ------------------------------------------------------------------
final activePlanProvider = Provider<StudyPlan?>((ref) {
  final plans = ref.watch(studyPlansProvider);
  return plans.where((p) => p.isActive).firstOrNull;
});

// ------------------------------------------------------------------
// Selected Calendar Date
// ------------------------------------------------------------------
final selectedPlanDateProvider = StateProvider<DateTime>(
  (ref) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  },
);

// ------------------------------------------------------------------
// Selected Day Schedule
// ------------------------------------------------------------------
final selectedDayScheduleProvider = Provider<StudyDay?>((ref) {
  final plan = ref.watch(activePlanProvider);
  final selectedDate = ref.watch(selectedPlanDateProvider);
  if (plan == null) return null;

  try {
    return plan.days.firstWhere(
      (d) => _isSameDay(d.date, selectedDate),
    );
  } catch (_) {
    return null;
  }
});

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
