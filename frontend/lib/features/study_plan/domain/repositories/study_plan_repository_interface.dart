import '../../data/models/study_plan_models.dart';

/// Abstract contract for study plan operations.
abstract class StudyPlanRepositoryInterface {
  /// Create a new study plan from config.
  Future<StudyPlan> createPlan(StudyPlanConfig config);

  /// Get all saved plans.
  Future<List<StudyPlan>> getPlans();

  /// Get a plan by ID.
  Future<StudyPlan?> getPlanById(String id);

  /// Update task completion status.
  Future<StudyPlan> updateTaskCompletion(
    String planId,
    String dayDate,
    String taskId,
    bool isCompleted,
  );

  /// Update an entire plan.
  Future<void> updatePlan(StudyPlan plan);

  /// Delete a plan.
  Future<void> deletePlan(String id);
}
