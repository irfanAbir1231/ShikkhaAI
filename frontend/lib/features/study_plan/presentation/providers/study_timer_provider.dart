import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/study_plan_models.dart';
import 'study_plan_provider.dart';

/// Phase of the study timer.
enum StudyTimerPhase { idle, running, paused, finished }

/// Plain-data timer state (no freezed dependency).
class StudyTimerState {
  const StudyTimerState({
    required this.phase,
    this.task,
    this.remainingSeconds = 0,
    this.elapsedSeconds = 0,
    this.startedAt,
  });

  final StudyTimerPhase phase;
  final StudyTask? task;
  final int remainingSeconds;
  final int elapsedSeconds;
  final DateTime? startedAt;

  static const idle = StudyTimerState(phase: StudyTimerPhase.idle);

  StudyTimerState copyWith({
    StudyTimerPhase? phase,
    StudyTask? task,
    int? remainingSeconds,
    int? elapsedSeconds,
    DateTime? startedAt,
  }) {
    return StudyTimerState(
      phase: phase ?? this.phase,
      task: task ?? this.task,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

class StudyTimerNotifier extends StateNotifier<StudyTimerState> {
  StudyTimerNotifier(this._ref) : super(StudyTimerState.idle);

  final Ref _ref;
  Timer? _ticker;

  void startTask(StudyTask task) {
    _ticker?.cancel();
    state = StudyTimerState(
      phase: StudyTimerPhase.running,
      task: task,
      remainingSeconds: task.durationMinutes * 60,
      elapsedSeconds: 0,
      startedAt: DateTime.now(),
    );
    _persistStart(task);
    _startTicking();
  }

  void pause() {
    if (state.phase != StudyTimerPhase.running) return;
    _ticker?.cancel();
    state = state.copyWith(phase: StudyTimerPhase.paused);
  }

  void resume() {
    if (state.phase != StudyTimerPhase.paused) return;
    state = state.copyWith(phase: StudyTimerPhase.running);
    _startTicking();
  }

  void addTenMinutes() {
    state = state.copyWith(remainingSeconds: state.remainingSeconds + 600);
    if (state.phase == StudyTimerPhase.finished) {
      state = state.copyWith(phase: StudyTimerPhase.running);
      _startTicking();
    }
  }

  /// User pressed "Finish Early" or timer hit 0. Caller decides whether to
  /// mark the task complete via [markComplete].
  Future<void> finish({required bool markComplete}) async {
    _ticker?.cancel();
    final task = state.task;
    final elapsedMinutes = (state.elapsedSeconds / 60).ceil();
    state = state.copyWith(phase: StudyTimerPhase.finished);
    if (task != null) {
      await _persistFinish(task, elapsedMinutes, markComplete: markComplete);
    }
  }

  void discard() {
    _ticker?.cancel();
    state = StudyTimerState.idle;
  }

  void _startTicking() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase != StudyTimerPhase.running) return;
      if (state.remainingSeconds <= 1) {
        _ticker?.cancel();
        state = state.copyWith(
          remainingSeconds: 0,
          elapsedSeconds: state.elapsedSeconds + 1,
          phase: StudyTimerPhase.finished,
        );
      } else {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
          elapsedSeconds: state.elapsedSeconds + 1,
        );
      }
    });
  }

  Future<void> _persistStart(StudyTask task) async {
    final plan = _ref.read(activePlanProvider);
    if (plan == null) return;
    if (task.startedAt != null) return;
    final updated = task.copyWith(startedAt: DateTime.now());
    await _ref.read(studyPlansProvider.notifier).updateTask(
          plan.id,
          task.scheduledDate.toIso8601String(),
          updated,
        );
  }

  Future<void> _persistFinish(
    StudyTask task,
    int actualMinutes, {
    required bool markComplete,
  }) async {
    final plan = _ref.read(activePlanProvider);
    if (plan == null) return;
    final updated = task.copyWith(
      actualMinutesSpent: (task.actualMinutesSpent) + actualMinutes,
      startedAt: task.startedAt ?? state.startedAt ?? DateTime.now(),
      completedAt: markComplete ? DateTime.now() : task.completedAt,
      isCompleted: markComplete ? true : task.isCompleted,
    );
    await _ref.read(studyPlansProvider.notifier).updateTask(
          plan.id,
          task.scheduledDate.toIso8601String(),
          updated,
        );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final studyTimerProvider =
    StateNotifierProvider<StudyTimerNotifier, StudyTimerState>(
  (ref) => StudyTimerNotifier(ref),
);
