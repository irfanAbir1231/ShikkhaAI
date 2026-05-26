import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/exam_result_model.dart';
import '../providers/exam_provider.dart';
import '../widgets/answer_review_card.dart';
import '../widgets/exam_result_summary.dart';
import '../widgets/marks_prediction_card.dart';
import '../widgets/weak_topics_list.dart';

/// Screen displaying exam results with analysis and review.
class ExamResultScreen extends ConsumerStatefulWidget {
  const ExamResultScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  ConsumerState<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends ConsumerState<ExamResultScreen> {
  ExamResult? _result;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResult();
    });
  }

  void _loadResult() {
    final fromRepo = ref
        .read(examRepositoryProvider)
        .getResultByAttemptId(widget.attemptId);
    final current = ref.read(currentResultProvider);

    if (current != null && current.attemptId == widget.attemptId) {
      setState(() {
        _result = current;
        _loaded = true;
      });
    } else if (fromRepo != null) {
      setState(() {
        _result = fromRepo;
        _loaded = true;
      });
    } else {
      setState(() => _loaded = true);
    }
  }

  void _retryExam() {
    if (_result == null) return;
    final session = ref
        .read(examRepositoryProvider)
        .getSessionById(_result!.examId);
    if (session != null) {
      ref.read(examSessionProvider.notifier).startExam(session.config);
      final newSession = ref.read(examSessionProvider);
      if (newSession != null) {
        context.push('/exam/session/${newSession.examId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    if (result == null && !_loaded) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Exam Result'),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (result == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Exam Result'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 16),
              const Text(
                'Result not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Exam Result',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedFadeSlide(
                    child: ExamResultSummary(result: result),
                  ),
                  const SizedBox(height: 20),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 100),
                    child: MarksPredictionCard(result: result),
                  ),
                  const SizedBox(height: 24),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 200),
                    child: WeakTopicsList(weakTopics: result.weakTopics),
                  ),
                  const SizedBox(height: 24),
                  // Answer review would need the questions - fetch from session
                  _buildAnswerReview(result),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            border: Border(
              top: BorderSide(color: AppColors.divider),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Home'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _retryExam,
                  icon: const Icon(Icons.replay),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerReview(ExamResult result) {
    final session = ref.read(examRepositoryProvider).getSessionById(result.examId);
    if (session == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Text(
          'Answer review not available for this attempt.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Defensive: warn if some answers appear to be missing from local storage
    final answeredCount = session.answers.length;
    final hasMissingAnswers = answeredCount < session.totalQuestions;

    return AnimatedFadeSlide(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMissingAnswers)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Some answers may not be displayed ($answeredCount/${session.totalQuestions} saved locally).',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.warning,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          AnswerReviewCard(
            questions: session.questions,
            result: result,
            userAnswers: session.answers,
          ),
        ],
      ),
    );
  }
}
