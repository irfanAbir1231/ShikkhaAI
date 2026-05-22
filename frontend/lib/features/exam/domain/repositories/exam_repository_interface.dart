import '../../../../core/utils/result.dart';
import '../../data/models/exam_config_model.dart';
import '../../data/models/exam_result_model.dart';
import '../../data/models/exam_session_model.dart';

/// Abstract contract for exam operations.
abstract class ExamRepositoryInterface {
  /// Generates a new exam session based on the given config.
  Future<Result<ExamSession>> generateExam(
    ExamConfig config, {
    required int studentId,
  });

  /// Submits an exam and returns graded results.
  Future<Result<ExamResult>> submitExam(
    ExamSession session, {
    required int studentId,
  });

  /// Persists an in-progress session to local storage.
  Future<void> saveSession(ExamSession session);

  /// Retrieves all saved sessions.
  List<ExamSession> getSessions();

  /// Retrieves a specific session by ID.
  ExamSession? getSessionById(String examId);

  /// Deletes a session.
  Future<void> deleteSession(String examId);

  /// Clears all saved sessions.
  Future<void> clearAllSessions();

  /// Persists a graded result to local storage.
  Future<void> saveResult(ExamResult result);

  /// Retrieves all graded results.
  List<ExamResult> getResults();

  /// Retrieves a specific result by attempt ID.
  ExamResult? getResultByAttemptId(String attemptId);

  /// Retrieves a result by exam ID.
  ExamResult? getResultByExamId(String examId);

  /// Deletes a result.
  Future<void> deleteResult(String attemptId);

  /// Clears all results.
  Future<void> clearAllResults();

  /// Gets aggregate statistics for the exam shell screen.
  Map<String, dynamic> getStats();
}
