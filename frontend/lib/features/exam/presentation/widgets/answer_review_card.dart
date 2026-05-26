import 'package:flutter/material.dart';

import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/exam_answer_model.dart';
import '../../data/models/exam_question_model.dart';
import '../../data/models/exam_result_model.dart';

/// Color-coded review list of all questions with user vs correct answers.
class AnswerReviewCard extends StatelessWidget {
  const AnswerReviewCard({
    super.key,
    required this.questions,
    required this.result,
    this.userAnswers = const {},
  });

  final List<ExamQuestion> questions;
  final ExamResult result;
  final Map<String, ExamAnswer> userAnswers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Answer Review',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return _ReviewItem(
            index: index + 1,
            question: question,
            result: result,
            userAnswers: userAnswers,
          );
        }),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({
    required this.index,
    required this.question,
    required this.result,
    required this.userAnswers,
  });

  final int index;
  final ExamQuestion question;
  final ExamResult result;
  final Map<String, ExamAnswer> userAnswers;

  @override
  Widget build(BuildContext context) {
    final shortFeedback = result.shortAnswerFeedback
        .firstWhere((f) => f.questionId == question.id, orElse: () {
      return const ShortAnswerFeedback(
        questionId: '',
        status: 'unknown',
        feedback: '',
        awardedMarks: 0,
      );
    });

    // Primary source for MCQ review: backend's per-question feedback.
    // This avoids depending on fragile local session storage.
    final mcqFeedback = result.mcqFeedback
        .firstWhere((f) => f.questionId == question.id, orElse: () {
      return const McqFeedback(
        questionId: '',
        correct: false,
        correctAnswer: '',
        submittedAnswer: '',
      );
    });

    // Fallback to local session answers if backend feedback is missing
    // (e.g. for exams taken before this update).
    final String userAnswer;
    final String correctAnswer;
    final bool isCorrect;
    final bool isPartial;

    if (question.isMcq) {
      if (mcqFeedback.questionId.isNotEmpty) {
        // Use backend feedback as primary source
        userAnswer = mcqFeedback.submittedAnswer;
        correctAnswer = mcqFeedback.correctAnswer;
        isCorrect = mcqFeedback.correct;
        isPartial = false;
      } else {
        // Fallback to local session + question.correctAnswer
        final submitted = userAnswers[question.id]?.answer ?? '';
        userAnswer = submitted;
        correctAnswer = question.correctAnswer ?? '';
        isCorrect = _evaluateMcqLocal(
          submitted: submitted,
          expected: correctAnswer,
          options: question.options,
        );
        isPartial = false;
      }
    } else {
      // Short answer / CQ: use local session + backend short-answer feedback
      userAnswer = userAnswers[question.id]?.answer ?? '';
      correctAnswer = question.correctAnswer ?? '';
      isCorrect = shortFeedback.status == 'correct';
      isPartial = shortFeedback.status == 'partial';
    }

    final statusColor = isCorrect
        ? AppColors.success
        : isPartial
            ? AppColors.warning
            : AppColors.danger;

    final statusIcon = isCorrect
        ? Icons.check_circle
        : isPartial
            ? Icons.adjust
            : Icons.cancel;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q$index: ${question.prompt.substring(0, question.prompt.length > 80 ? 80 : question.prompt.length)}${question.prompt.length > 80 ? '...' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AnswerRow(
                      label: 'Your Answer:',
                      value: userAnswer.isEmpty ? 'Not answered' : userAnswer,
                      color: AppColors.textSecondary,
                    ),
                    if (correctAnswer.isNotEmpty)
                      _AnswerRow(
                        label: 'Correct Answer:',
                        value: correctAnswer,
                        color: AppColors.success,
                      ),
                    if (question.isMcq)
                      _AnswerRow(
                        label: 'Marks:',
                        value: '${isCorrect ? question.marks : 0} / ${question.marks}',
                        color: statusColor,
                      )
                    else if (shortFeedback.awardedMarks > 0 ||
                        shortFeedback.status != 'unknown')
                      _AnswerRow(
                        label: 'Marks:',
                        value: '${shortFeedback.awardedMarks.toStringAsFixed(1)} / ${question.marks}',
                        color: statusColor,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (question.explanation != null &&
              question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                question.explanation!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Local fallback evaluation when backend mcq_feedback is not available.
  static bool _evaluateMcqLocal({
    required String submitted,
    required String expected,
    required List<String> options,
  }) {
    final sub = submitted.trim();
    final exp = expected.trim().toUpperCase();
    if (sub.isEmpty) return false;
    if (sub.toUpperCase() == exp) return true;

    if (exp.length == 1 && {'A', 'B', 'C', 'D'}.contains(exp)) {
      if (sub.toUpperCase().startsWith('$exp.') ||
          sub.toUpperCase().startsWith('$exp ')) {
        return true;
      }
      if (options.isNotEmpty) {
        final correctIndex = exp.codeUnitAt(0) - 'A'.codeUnitAt(0);
        if (correctIndex >= 0 && correctIndex < options.length) {
          return sub.toUpperCase() == options[correctIndex].trim().toUpperCase();
        }
      }
    }
    return false;
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
