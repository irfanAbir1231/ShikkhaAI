import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/atoms/app_button.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/exam_question_model.dart';
import '../../data/models/exam_answer_model.dart';
import '../../data/models/exam_enums.dart';
import '../providers/exam_provider.dart';
import '../widgets/cq_answer_input.dart';
import '../widgets/exam_timer.dart';
import '../widgets/mcq_options.dart';
import '../widgets/progress_indicator_bar.dart';
import '../widgets/question_card.dart';
import '../widgets/question_navigation_grid.dart';
import '../widgets/short_answer_input.dart';

/// Full-screen immersive exam taking experience.
class ExamSessionScreen extends ConsumerStatefulWidget {
  const ExamSessionScreen({super.key, required this.examId});

  final String examId;

  @override
  ConsumerState<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends ConsumerState<ExamSessionScreen> {
  bool _showFeedback = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Ensure session is loaded
    final session = ref.read(examSessionProvider);
    if (session == null || session.examId != widget.examId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(examSessionProvider.notifier).loadSession(widget.examId);
      });
    }
  }

  void _showSubmitDialog() {
    final session = ref.read(examSessionProvider);
    if (session == null) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: Text(
          'You have answered ${session.answeredCount} out of ${session.totalQuestions} questions. Are you sure you want to submit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            child: const Text(
              'Submit',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitExam() async {
    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(examSessionProvider.notifier).submitExam();
      if (result != null && mounted) {
        context.push('/exam/result/${result.attemptId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: \$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(examSessionProvider);

    if (session == null || _isSubmitting) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final question = session.currentQuestion;
    if (question == null) {
      return const Scaffold(
        body: Center(child: Text('No questions available')),
      );
    }

    final currentAnswer = session.getAnswerFor(question.id);
    final isFirst = session.currentQuestionIndex == 0;
    final isLast = session.currentQuestionIndex == session.totalQuestions - 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const ExamTimer(),
            const Spacer(),
            Text(
              '${session.currentQuestionIndex + 1} / ${session.totalQuestions}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _showSubmitDialog,
            child: const Text(
              'Submit',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(36),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExamProgressBar(),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  QuestionCard(
                    question: question,
                    questionNumber: session.currentQuestionIndex + 1,
                    totalQuestions: session.totalQuestions,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildAnswerInput(question, currentAnswer),
                  ),
                  if (session.config.examType == ExamType.practice) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showFeedback = !_showFeedback),
                        icon: Icon(
                          _showFeedback ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        label: Text(_showFeedback ? 'Hide Answer' : 'Check Answer'),
                      ),
                    ),
                    if (_showFeedback && question.explanation != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Explanation',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.explanation!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                              if (question.correctAnswer != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Correct Answer: ${question.correctAnswer}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              border: Border(
                top: BorderSide(color: AppColors.divider),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Previous',
                      variant: AppButtonVariant.secondary,
                      onPressed: isFirst
                          ? null
                          : () => ref
                              .read(examSessionProvider.notifier)
                              .navigateToQuestion(
                                session.currentQuestionIndex - 1,
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: isLast ? 'Submit' : 'Next',
                      onPressed: () {
                        if (isLast) {
                          _showSubmitDialog();
                        } else {
                          ref
                              .read(examSessionProvider.notifier)
                              .navigateToQuestion(
                                session.currentQuestionIndex + 1,
                              );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const QuestionNavigationGrid(),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(ExamQuestion question, ExamAnswer? currentAnswer) {
    switch (question.type) {
      case QuestionType.mcq:
        return McqOptions(
          question: question,
          selectedAnswer: currentAnswer?.answer,
          onSelect: (answer) => ref
              .read(examSessionProvider.notifier)
              .answerQuestion(question.id, answer),
          showFeedback: _showFeedback,
        );
      case QuestionType.shortAnswer:
        return ShortAnswerInput(
          initialValue: currentAnswer?.answer ?? '',
          onChanged: (text) => ref
              .read(examSessionProvider.notifier)
              .answerQuestion(question.id, text),
        );
      case QuestionType.cq:
        // Parse existing answers from JSON string or empty map
        final existing = <String, String>{};
        if (currentAnswer != null && currentAnswer.answer.isNotEmpty) {
          try {
            final parts = currentAnswer.answer.split('|');
            for (final part in parts) {
              final kv = part.split(':');
              if (kv.length == 2) {
                existing[kv[0]] = kv[1];
              }
            }
          } catch (_) {
            // ignore parse errors
          }
        }
        return CqAnswerInput(
          subParts: question.subParts ?? const [],
          answers: existing,
          onChanged: (answers) {
            final encoded = answers.entries
                .map((e) => '${e.key}:${e.value}')
                .join('|');
            ref
                .read(examSessionProvider.notifier)
                .answerQuestion(question.id, encoded);
          },
        );
    }
  }
}
