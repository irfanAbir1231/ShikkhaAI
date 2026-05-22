import '../../data/datasources/study_plan_local_datasource.dart';
import '../../data/models/study_plan_models.dart';
import '../../data/services/mock_study_plan_service.dart';
import 'study_plan_repository_interface.dart';

/// Concrete study plan repository.
class StudyPlanRepository implements StudyPlanRepositoryInterface {
  const StudyPlanRepository({required StudyPlanLocalDataSource localDataSource})
      : _local = localDataSource;

  final StudyPlanLocalDataSource _local;

  @override
  Future<StudyPlan> createPlan(StudyPlanConfig config) async {
    final plan = MockStudyPlanService.generatePlan(config);
    await _local.savePlan(plan);
    return plan;
  }

  @override
  Future<List<StudyPlan>> getPlans() async => _local.getPlans();

  @override
  Future<StudyPlan?> getPlanById(String id) async => _local.getPlanById(id);

  @override
  Future<StudyPlan> updateTaskCompletion(
    String planId,
    String dayDate,
    String taskId,
    bool isCompleted,
  ) async {
    final plan = _local.getPlanById(planId);
    if (plan == null) throw Exception('Plan not found');

    final targetDate = DateTime.parse(dayDate);
    final updatedDays = plan.days.map((day) {
      if (_isSameDay(day.date, targetDate)) {
        final updatedTasks = day.tasks.map((task) {
          if (task.id == taskId) {
            return task.copyWith(isCompleted: isCompleted);
          }
          return task;
        }).toList();
        return day.copyWith(tasks: updatedTasks);
      }
      return day;
    }).toList();

    final updatedPlan = plan.copyWith(days: updatedDays);
    await _local.savePlan(updatedPlan);
    return updatedPlan;
  }

  @override
  Future<void> updatePlan(StudyPlan plan) async {
    await _local.savePlan(plan);
  }

  @override
  Future<void> deletePlan(String id) async {
    await _local.deletePlan(id);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
