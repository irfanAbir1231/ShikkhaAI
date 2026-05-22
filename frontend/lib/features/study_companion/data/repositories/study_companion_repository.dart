import '../../domain/repositories/study_companion_repository_interface.dart';
import '../datasources/study_companion_local_datasource.dart';
import '../models/chat_session_model.dart';
import '../models/explanation_mode.dart';
import '../services/mock_study_companion_service.dart';

/// Concrete repository coordinating mock AI service and local Hive cache.
class StudyCompanionRepository implements StudyCompanionRepositoryInterface {
  StudyCompanionRepository({
    required StudyCompanionLocalDataSource localDataSource,
    MockStudyCompanionService? mockService,
  })  : _local = localDataSource,
        _service = mockService ?? MockStudyCompanionService();

  final StudyCompanionLocalDataSource _local;
  final MockStudyCompanionService _service;

  @override
  Stream<String> sendMessage({
    required String query,
    required ExplanationMode mode,
    String? fileName,
  }) {
    return _service.generateResponse(
      query: query,
      mode: mode,
      fileName: fileName,
    );
  }

  @override
  List<ChatSession> getChatHistory() => _local.getSessions();

  @override
  ChatSession? getSessionById(String id) => _local.getSessionById(id);

  @override
  Future<void> saveSession(ChatSession session) => _local.saveSession(session);

  @override
  Future<void> deleteSession(String id) => _local.deleteSession(id);

  @override
  Future<void> clearAllSessions() => _local.clearAllSessions();

  @override
  ExplanationMode getLastUsedMode() => _local.getLastUsedMode();

  @override
  Future<void> setLastUsedMode(ExplanationMode mode) =>
      _local.setLastUsedMode(mode);
}
