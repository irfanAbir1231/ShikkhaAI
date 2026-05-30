import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../../library/data/datasources/note_local_datasource.dart';
import '../../domain/repositories/exam_repository_interface.dart';
import '../datasources/exam_local_datasource.dart';
import '../datasources/exam_remote_datasource.dart';
import '../models/exam_config_model.dart';
import '../models/exam_result_model.dart';
import '../models/exam_session_model.dart';

/// Concrete repository coordinating remote API and local persistence.
class ExamRepository implements ExamRepositoryInterface {
  ExamRepository({
    required ExamLocalDataSource localDataSource,
    ExamRemoteDataSource? remoteDataSource,
    NoteLocalDataSource? noteLocalDataSource,
  })  : _local = localDataSource,
        _remote = remoteDataSource ?? ExamRemoteDataSource(),
        _noteLocal = noteLocalDataSource;

  final ExamLocalDataSource _local;
  final ExamRemoteDataSource _remote;
  final NoteLocalDataSource? _noteLocal;

  @override
  Future<Result<ExamSession>> generateExam(
    ExamConfig config, {
    required int studentId,
  }) async {
    try {
      final session = await _remote.generateExam(config, studentId);
      await _local.saveSession(session);
      return Result.success(session);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamResult>> submitExam(
    ExamSession session, {
    required int studentId,
  }) async {
    try {
      final result = await _remote.submitExam(session, studentId);
      // Cache generated notes immediately so NoteDetailScreen shows fresh content
      if (_noteLocal != null) {
        for (final note in result.generatedNotes) {
          await _noteLocal.saveNote(note);
        }
      }
      await _local.saveResult(result);
      await _local.saveSession(session.submit());
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<void> saveSession(ExamSession session) => _local.saveSession(session);

  @override
  List<ExamSession> getSessions() => _local.getSessions();

  @override
  ExamSession? getSessionById(String examId) => _local.getSessionById(examId);

  @override
  Future<void> deleteSession(String examId) => _local.deleteSession(examId);

  @override
  Future<void> clearAllSessions() => _local.clearAllSessions();

  @override
  Future<void> saveResult(ExamResult result) => _local.saveResult(result);

  @override
  List<ExamResult> getResults({required int studentId}) => _local.getResults(studentId: studentId);

  @override
  ExamResult? getResultByAttemptId(String attemptId) =>
      _local.getResultByAttemptId(attemptId);

  @override
  ExamResult? getResultByExamId(String examId) =>
      _local.getResultByExamId(examId);

  @override
  Future<void> deleteResult(String attemptId) =>
      _local.deleteResult(attemptId);

  @override
  Future<void> clearAllResults() => _local.clearAllResults();

  @override
  Map<String, dynamic> getStats({required int studentId}) => _local.getStats(studentId: studentId);
}
