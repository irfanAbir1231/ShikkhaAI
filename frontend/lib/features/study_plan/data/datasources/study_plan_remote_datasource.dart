import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../models/study_plan_models.dart';

/// Remote data source for Study Plan generation API.
///
/// Backend contract: `POST /study-plan/generate` → envelope `data` is a
/// [StudyPlan] JSON.
class StudyPlanRemoteDataSource {
  StudyPlanRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<StudyPlan> generatePlan({
    required int studentId,
    required DateTime examDate,
    required int dailyMinutes,
    required List<String> weakSubjects,
    required String classLevel,
    String? subject,
  }) async {
    final data = await _apiService.post(
      ApiConstants.studyPlanGenerate,
      data: {
        'student_id': studentId,
        'exam_date': examDate.toIso8601String(),
        'daily_minutes': dailyMinutes,
        'weak_subjects': weakSubjects,
        'class_level': classLevel,
        if (subject != null) 'subject': subject,
      },
    );
    return StudyPlan.fromJson(data as Map<String, dynamic>);
  }

  /// Optional: persist a single task's progress to backend.
  Future<void> updateTaskProgress({
    required String taskId,
    required bool isCompleted,
    required int actualMinutesSpent,
  }) async {
    await _apiService.post(
      '${ApiConstants.studyPlanById}/tasks/$taskId${ApiConstants.studyPlanTaskProgressSuffix}',
      data: {
        'is_completed': isCompleted,
        'actual_minutes_spent': actualMinutesSpent,
      },
    );
  }
}
