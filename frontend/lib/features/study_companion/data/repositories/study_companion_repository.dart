import 'dart:async';
import 'dart:math';

import '../../domain/repositories/study_companion_repository_interface.dart';
import '../datasources/study_companion_local_datasource.dart';
import '../datasources/study_companion_remote_datasource.dart';
import '../models/chat_session_model.dart';
import '../models/explanation_mode.dart';

/// Concrete repository coordinating remote AI service and local Hive cache.
class StudyCompanionRepository implements StudyCompanionRepositoryInterface {
  StudyCompanionRepository({
    required StudyCompanionLocalDataSource localDataSource,
    StudyCompanionRemoteDataSource? remoteDataSource,
  })  : _local = localDataSource,
        _remote = remoteDataSource ?? StudyCompanionRemoteDataSource();

  final StudyCompanionLocalDataSource _local;
  final StudyCompanionRemoteDataSource _remote;
  final _random = Random();

  @override
  Stream<String> sendMessage({
    required String query,
    required ExplanationMode mode,
    String? fileName,
    required int studentId,
    required String subject,
    required String classLevel,
  }) async* {
    // Simulate initial network delay (0.8–1.5 seconds)
    await Future.delayed(
      Duration(milliseconds: 800 + _random.nextInt(700)),
    );

    String fullResponse;
    try {
      final data = await _remote.ask(
        studentId: studentId,
        message: query,
        mode: mode.name,
        subject: subject,
        classLevel: classLevel,
        pdfContext: fileName,
      );
      fullResponse = data['response'] as String? ?? '';
      if (fullResponse.isEmpty) {
        fullResponse = 'Sorry, I could not generate a response. Please try again.';
      }
    } catch (e) {
      fullResponse =
          '**Unable to connect to the study companion.**\n\n'
          'Please check your internet connection and try again.\n\n'
          '_Error: ${e.toString()}_';
    }

    // Stream word-by-word to preserve the existing typing UX
    final words = fullResponse.split(' ');
    var buffer = '';
    for (var i = 0; i < words.length; i++) {
      buffer += '${i == 0 ? '' : ' '}${words[i]}';
      yield buffer;
      final word = words[i];
      final baseDelay = word.endsWith('.') || word.endsWith('?') || word.endsWith('!')
          ? 80
          : word.endsWith(',') || word.endsWith(':') || word.endsWith(';')
              ? 50
              : 30;
      await Future.delayed(
        Duration(milliseconds: baseDelay + _random.nextInt(20)),
      );
    }
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
