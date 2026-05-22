import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
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
      setState(() => _result = current);
    } else if (fromRepo != null) {
      setState(() => _result = fromRepo);
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

    if (result == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Exam Result'),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
      return const SizedBox.shrink();
    }

    return AnimatedFadeSlide(
      delay: const Duration(milliseconds: 300),
      child: AnswerReviewCard(
        questions: session.questions,
        result: result,
      ),
    );
  }
}
