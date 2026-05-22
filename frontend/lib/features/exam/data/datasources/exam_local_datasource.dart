

import 'package:hive/hive.dart';


import '../models/exam_result_model.dart';
import '../models/exam_session_model.dart';

/// Hive-based local persistence for exam sessions and results.
class ExamLocalDataSource {
  const ExamLocalDataSource({
    required Box<String> sessionsBox,
    required Box<String> resultsBox,
  })  : _sessionsBox = sessionsBox,
        _resultsBox = resultsBox;

  final Box<String> _sessionsBox;
  final Box<String> _resultsBox;

  // Sessions

  Future<void> saveSession(ExamSession session) async {
    await _sessionsBox.put(session.examId, session.toJsonString());
  }

  List<ExamSession> getSessions() {
    return _sessionsBox.values
        .map((json) => ExamSession.fromJsonString(json))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  ExamSession? getSessionById(String examId) {
    final json = _sessionsBox.get(examId);
    if (json == null) return null;
    return ExamSession.fromJsonString(json);
  }

  Future<void> deleteSession(String examId) async {
    await _sessionsBox.delete(examId);
  }

  Future<void> clearAllSessions() async {
    await _sessionsBox.clear();
  }

  // Results

  Future<void> saveResult(ExamResult result) async {
    await _resultsBox.put(result.attemptId, result.toJsonString());
  }

  List<ExamResult> getResults() {
    return _resultsBox.values
        .map((json) => ExamResult.fromJsonString(json))
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  ExamResult? getResultByAttemptId(String attemptId) {
    final json = _resultsBox.get(attemptId);
    if (json == null) return null;
    return ExamResult.fromJsonString(json);
  }

  ExamResult? getResultByExamId(String examId) {
    try {
      return _resultsBox.values
          .map((json) => ExamResult.fromJsonString(json))
          .firstWhere((r) => r.examId == examId);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteResult(String attemptId) async {
    await _resultsBox.delete(attemptId);
  }

  Future<void> clearAllResults() async {
    await _resultsBox.clear();
  }

  /// Stats for the exam shell screen.
  Map<String, dynamic> getStats() {
    final results = getResults();
    if (results.isEmpty) {
      return {
        'totalExams': 0,
        'averageScore': 0.0,
        'bestScore': 0.0,
        'totalTimeSeconds': 0,
      };
    }

    final scores = results.map((r) => r.scorePercentage).toList();
    final totalTime = results.fold<int>(
      0,
      (sum, r) => sum + r.timeTakenSeconds,
    );

    return {
      'totalExams': results.length,
      'averageScore': scores.reduce((a, b) => a + b) / scores.length,
      'bestScore': scores.reduce((a, b) => a > b ? a : b),
      'totalTimeSeconds': totalTime,
    };
  }
}
