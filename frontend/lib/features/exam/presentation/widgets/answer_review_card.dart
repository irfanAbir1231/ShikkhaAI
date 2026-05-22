import 'package:flutter/material.dart';

import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/exam_question_model.dart';
import '../../data/models/exam_result_model.dart';

/// Color-coded review list of all questions with user vs correct answers.
class AnswerReviewCard extends StatelessWidget {
  const AnswerReviewCard({
    super.key,
    required this.questions,
    required this.result,
  });

  final List<ExamQuestion> questions;
  final ExamResult result;

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
  });

  final int index;
  final ExamQuestion question;
  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    final feedback = result.shortAnswerFeedback
        .firstWhere((f) => f.questionId == question.id, orElse: () {
      return const ShortAnswerFeedback(
        questionId: '',
        status: 'unknown',
        feedback: '',
        awardedMarks: 0,
      );
    });

    final isCorrect = feedback.status == 'correct' ||
        (question.isMcq && feedback.status == 'unknown');
    final isPartial = feedback.status == 'partial';
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
                      value: feedback.status == 'unknown' && question.isMcq
                          ? 'Not answered'
                          : feedback.questionId.isEmpty
                              ? 'Not answered'
                              : 'See below',
                      color: AppColors.textSecondary,
                    ),
                    if (question.correctAnswer != null &&
                        question.correctAnswer!.isNotEmpty)
                      _AnswerRow(
                        label: 'Correct Answer:',
                        value: question.correctAnswer!,
                        color: AppColors.success,
                      ),
                    if (feedback.awardedMarks > 0 || feedback.status != 'unknown')
                      _AnswerRow(
                        label: 'Marks:',
                        value: '${feedback.awardedMarks.toStringAsFixed(1)} / ${question.marks}',
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
