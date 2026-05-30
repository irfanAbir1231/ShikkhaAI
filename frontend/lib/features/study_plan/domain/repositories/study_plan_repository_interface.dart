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

  /// Replace a single task with an updated copy (preserves all fields, not
  /// just `isCompleted`). Used by the study timer to persist
  /// `actualMinutesSpent`, `startedAt`, `completedAt`.
  Future<StudyPlan> updateTask(
    String planId,
    String dayDate,
    StudyTask updatedTask,
  );

  /// Update an entire plan.
  Future<void> updatePlan(StudyPlan plan);

  /// Delete a plan.
  Future<void> deletePlan(String id);
}
