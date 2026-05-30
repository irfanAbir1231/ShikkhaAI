import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../library/data/datasources/note_local_datasource.dart';
import '../../data/datasources/exam_local_datasource.dart';
import '../../data/models/exam_config_model.dart';

import '../../data/models/exam_result_model.dart';
import '../../data/models/exam_session_model.dart';
import '../../data/repositories/exam_repository.dart';

// ------------------------------------------------------------------
// Repository
// ------------------------------------------------------------------
final examRepositoryProvider = Provider<ExamRepository>(
  (ref) {
    final sessionsBox = Hive.box<String>(StorageKeys.examSessionsBox);
    final resultsBox = Hive.box<String>(StorageKeys.examResultsBox);
    final notesBox = Hive.box<String>(StorageKeys.savedNotesBox);
    return ExamRepository(
      localDataSource: ExamLocalDataSource(
        sessionsBox: sessionsBox,
        resultsBox: resultsBox,
      ),
      noteLocalDataSource: NoteLocalDataSource(notesBox),
    );
  },
);

// ------------------------------------------------------------------
// Exam Config
// ------------------------------------------------------------------
final examConfigProvider = StateProvider<ExamConfig>(
  (ref) => ExamConfig.defaultConfig(),
);

// ------------------------------------------------------------------
// Exam History / Results
// ------------------------------------------------------------------
final examHistoryProvider =
    StateNotifierProvider<ExamHistoryNotifier, List<ExamResult>>(
  (ref) => ExamHistoryNotifier(
    ref.watch(examRepositoryProvider),
    ref,
  ),
);

class ExamHistoryNotifier extends StateNotifier<List<ExamResult>> {
  ExamHistoryNotifier(this._repo, this._ref) : super([]) {
    loadResults();
  }

  final ExamRepository _repo;
  final Ref _ref;

  int? get _currentStudentId {
    final student = _ref.read(authRepositoryProvider).currentStudent;
    return student?.id;
  }

  void loadResults() {
    final studentId = _currentStudentId;
    if (studentId == null) {
      state = [];
      return;
    }
    state = _repo.getResults(studentId: studentId);
  }

  Future<void> deleteResult(String attemptId) async {
    await _repo.deleteResult(attemptId);
    loadResults();
  }

  Future<void> clearAll() async {
    await _repo.clearAllResults();
    loadResults();
  }

  Map<String, dynamic> getStats() {
    final studentId = _currentStudentId;
    if (studentId == null) {
      return {
        'totalExams': 0,
        'averageScore': 0.0,
        'bestScore': 0.0,
        'totalTimeSeconds': 0,
      };
    }
    return _repo.getStats(studentId: studentId);
  }
}

// ------------------------------------------------------------------
// Active Exam Session
// ------------------------------------------------------------------
final examSessionProvider =
    StateNotifierProvider<ExamSessionNotifier, ExamSession?>(
  (ref) => ExamSessionNotifier(
    ref.watch(examRepositoryProvider),
    ref,
  ),
);

/// Tracks the current async operation (generate / submit) for UI overlays.
final examOperationProvider = StateProvider<AsyncValue<void>?>(
  (ref) => null,
);

class ExamSessionNotifier extends StateNotifier<ExamSession?> {
  ExamSessionNotifier(this._repo, this._ref) : super(null);

  final ExamRepository _repo;
  final Ref _ref;
  Timer? _timer;

  /// Generates and starts a new exam.
  Future<void> startExam(ExamConfig config) async {
    // Read directly from repository (Hive) to avoid stale provider cache.
    final student = _ref.read(authRepositoryProvider).currentStudent;
    if (student == null) {
      throw const ValidationFailure(
        message: 'Student not registered. Please register first.',
      );
    }

    _timer?.cancel();
    _ref.read(examOperationProvider.notifier).state =
        const AsyncValue.loading();

    try {
      final result = await _repo.generateExam(
        config,
        studentId: student.id,
      );

      result.when(
        success: (session) {
          state = session;
          _startTimer();
          _ref.read(examOperationProvider.notifier).state =
              const AsyncValue.data(null);
        },
        failure: (failure) {
          _ref.read(examOperationProvider.notifier).state =
              AsyncValue.error(failure.message, StackTrace.current);
          throw failure;
        },
      );
    } catch (e) {
      final message = e is Failure ? e.message : e.toString();
      _ref.read(examOperationProvider.notifier).state =
          AsyncValue.error(message, StackTrace.current);
      rethrow;
    }
  }

  /// Loads an existing in-progress session.
  void loadSession(String examId) {
    _timer?.cancel();
    final session = _repo.getSessionById(examId);
    if (session != null && !session.isSubmitted) {
      state = session;
      _startTimer();
    }
  }

  /// Records an answer for the current question.
  Future<void> answerQuestion(String questionId, String answer) async {
    if (state == null) return;
    state = state!.setAnswer(questionId, answer);
    await _repo.saveSession(state!);
  }

  /// Toggles mark-for-review on a question.
  void markForReview(String questionId) {
    if (state == null) return;
    state = state!.markForReview(questionId);
    _repo.saveSession(state!);
  }

  /// Navigates to a specific question index.
  void navigateToQuestion(int index) {
    if (state == null) return;
    state = state!.navigateToQuestion(index);
  }

  /// Submits the exam and returns the result.
  Future<ExamResult?> submitExam() async {
    if (state == null) return null;

    final student = _ref.read(authRepositoryProvider).currentStudent;
    if (student == null) {
      throw const ValidationFailure(
        message: 'Student not registered. Please register first.',
      );
    }

    _timer?.cancel();
    state = state!.submit();
    _ref.read(examOperationProvider.notifier).state =
        const AsyncValue.loading();

    try {
      final result = await _repo.submitExam(
        state!,
        studentId: student.id,
      );

      return result.when(
        success: (examResult) async {
          _ref.read(examHistoryProvider.notifier).loadResults();
          _ref.read(currentResultProvider.notifier).state = examResult;
          _ref.read(examOperationProvider.notifier).state =
              const AsyncValue.data(null);
          // Ensure the submitted session is persisted with all answers
          if (state != null) {
            await _repo.saveSession(state!);
          }
          return examResult;
        },
        failure: (failure) {
          _ref.read(examOperationProvider.notifier).state =
              AsyncValue.error(failure.message, StackTrace.current);
          throw failure;
        },
      );
    } catch (e) {
      final message = e is Failure ? e.message : e.toString();
      _ref.read(examOperationProvider.notifier).state =
          AsyncValue.error(message, StackTrace.current);
      rethrow;
    }
  }

  /// Cancels the exam without submitting.
  void cancelExam() {
    _timer?.cancel();
    state = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == null || state!.isSubmitted) {
        _timer?.cancel();
        return;
      }
      if (state!.timeRemainingSeconds <= 0) {
        _timer?.cancel();
        submitExam().catchError((Object _) => null);
        return;
      }
      state = state!.tickTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ------------------------------------------------------------------
// Current Result (most recent)
// ------------------------------------------------------------------
final currentResultProvider = StateProvider<ExamResult?>((ref) => null);

// ------------------------------------------------------------------
// Timer display — derived from session
// ------------------------------------------------------------------
final examTimerProvider = Provider.family<String, int?>((ref, totalSeconds) {
  final session = ref.watch(examSessionProvider);
  if (session == null) return '00:00';

  final remaining = session.timeRemainingSeconds;
  final hours = remaining ~/ 3600;
  final minutes = (remaining % 3600) ~/ 60;
  final seconds = remaining % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
});

// ------------------------------------------------------------------
// Timer color — derived from session
// ------------------------------------------------------------------
final examTimerColorProvider = Provider<Color>((ref) {
  final session = ref.watch(examSessionProvider);
  if (session == null) return AppColors.success;

  final remaining = session.timeRemainingSeconds;
  final total = session.config.timeLimitMinutes * 60;
  if (total == 0) return AppColors.success;

  final ratio = remaining / total;
  if (remaining <= 300) return AppColors.danger; // last 5 min
  if (ratio < 0.25) return AppColors.primary;
  if (ratio < 0.5) return AppColors.warning;
  return AppColors.success;
});

// ------------------------------------------------------------------
// Timer progress (0.0 to 1.0)
// ------------------------------------------------------------------
final examTimerProgressProvider = Provider<double>((ref) {
  final session = ref.watch(examSessionProvider);
  if (session == null) return 1.0;

  final total = session.config.timeLimitMinutes * 60;
  if (total == 0) return 1.0;

  final remaining = session.timeRemainingSeconds;
  return (remaining / total).clamp(0.0, 1.0);
});
