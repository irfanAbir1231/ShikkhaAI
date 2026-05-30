import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/color_tokens.dart';
import '../../../exam/presentation/providers/exam_provider.dart';
import '../../../../routing/route_names.dart';
import '../../data/models/study_plan_models.dart';
import '../providers/study_timer_provider.dart';
import 'practice_exam_prompt_dialog.dart';
import 'task_completion_dialog.dart';

/// Full-screen study session timer.
///
/// Push via `showStudyTimer(context, task)` to open.
class StudyTimerScreen extends ConsumerStatefulWidget {
  const StudyTimerScreen({super.key, required this.task});

  final StudyTask task;

  @override
  ConsumerState<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends ConsumerState<StudyTimerScreen> {
  bool _completionShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(studyTimerProvider);
      // Start only if not already running this task.
      if (state.phase == StudyTimerPhase.idle ||
          state.task?.id != widget.task.id) {
        ref.read(studyTimerProvider.notifier).startTask(widget.task);
      }
    });
  }

  String _fmt(int totalSeconds) {
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Color _bgFor(int remaining, int total, ColorScheme scheme) {
    if (total == 0) return scheme.primaryContainer;
    final ratio = remaining / total;
    if (ratio > 0.5) return AppColors.successSoft;
    if (ratio > 0.25) return AppColors.warningSoft;
    if (ratio > 0.1) return AppColors.primarySoft;
    return AppColors.dangerSoft;
  }

  Future<void> _handleFinishFlow({required bool autoTriggered}) async {
    if (_completionShown) return;
    _completionShown = true;

    final state = ref.read(studyTimerProvider);
    final task = state.task ?? widget.task;
    final elapsedMinutes = (state.elapsedSeconds / 60).ceil();

    final action = await showDialog<TaskCompletionAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskCompletionDialog(
        task: task,
        elapsedMinutes: elapsedMinutes,
      ),
    );

    if (!mounted) return;

    switch (action) {
      case TaskCompletionAction.addTenMinutes:
        _completionShown = false;
        ref.read(studyTimerProvider.notifier).addTenMinutes();
        break;
      case TaskCompletionAction.markDone:
        await ref
            .read(studyTimerProvider.notifier)
            .finish(markComplete: true);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => PracticeExamPromptDialog(
            topic: task.topic,
            subject: task.subject,
            onYes: () => _navigateToExamConfig(task),
            onNo: () {},
          ),
        );
        if (!mounted) return;
        ref.read(studyTimerProvider.notifier).discard();
        context.pop();
        break;
      case TaskCompletionAction.cancel:
      case null:
        _completionShown = false;
        // Resume if still time on clock, else dismiss without marking complete.
        final s = ref.read(studyTimerProvider);
        if (s.remainingSeconds > 0 && autoTriggered == false) {
          ref.read(studyTimerProvider.notifier).resume();
        } else {
          await ref
              .read(studyTimerProvider.notifier)
              .finish(markComplete: false);
          if (!mounted) return;
          ref.read(studyTimerProvider.notifier).discard();
          context.pop();
        }
        break;
    }
  }

  void _navigateToExamConfig(StudyTask task) {
    final notifier = ref.read(examConfigProvider.notifier);
    final current = ref.read(examConfigProvider);
    notifier.state = current.copyWith(
      subject: task.subject,
      topic: task.topic,
    );
    context.go('${RouteNames.exam}/${RouteNames.examConfig}');
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(studyTimerProvider);

    // Auto-trigger completion when timer hits 0.
    ref.listen<StudyTimerState>(studyTimerProvider, (prev, next) {
      if (next.phase == StudyTimerPhase.finished &&
          next.remainingSeconds == 0 &&
          !_completionShown) {
        _handleFinishFlow(autoTriggered: true);
      }
    });

    final scheme = Theme.of(context).colorScheme;
    final task = timer.task ?? widget.task;
    final totalSeconds = task.durationMinutes * 60;
    final progress = totalSeconds == 0
        ? 0.0
        : (1.0 - (timer.remainingSeconds / totalSeconds)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _bgFor(timer.remainingSeconds, totalSeconds, scheme),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(studyTimerProvider.notifier).discard();
            context.pop();
          },
        ),
        title: Text(task.title, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${task.subject} • ${task.topic}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress.toDouble(),
                        strokeWidth: 10,
                        backgroundColor:
                            scheme.primary.withValues(alpha: 0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scheme.primary),
                      ),
                    ),
                    Text(
                      _fmt(timer.remainingSeconds),
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontFeatures: const [
                        FontFeature.tabularFigures()
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (timer.phase == StudyTimerPhase.running)
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          ref.read(studyTimerProvider.notifier).pause(),
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                    )
                  else if (timer.phase == StudyTimerPhase.paused)
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          ref.read(studyTimerProvider.notifier).resume(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume'),
                    ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _handleFinishFlow(autoTriggered: false),
                    icon: const Icon(Icons.flag),
                    label: const Text('Finish Early'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Elapsed: ${_fmt(timer.elapsedSeconds)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the study timer as a full-screen modal.
Future<void> showStudyTimer(BuildContext context, StudyTask task) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => StudyTimerScreen(task: task),
    ),
  );
}
