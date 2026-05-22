import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/color_tokens.dart';
import '../../data/models/exam_enums.dart';
import '../providers/exam_provider.dart';

/// Horizontal scrollable numbered pills for question navigation.
class QuestionNavigationGrid extends ConsumerWidget {
  const QuestionNavigationGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(examSessionProvider);
    if (session == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  ...List.generate(session.totalQuestions, (index) {
                    final question = session.questions[index];
                    final status = session.getStatusFor(question.id);
                    final isCurrent = index == session.currentQuestionIndex;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuestionPill(
                        number: index + 1,
                        status: status,
                        isCurrent: isCurrent,
                        onTap: () => ref
                            .read(examSessionProvider.notifier)
                            .navigateToQuestion(index),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionPill extends StatelessWidget {
  const _QuestionPill({
    required this.number,
    required this.status,
    required this.isCurrent,
    required this.onTap,
  });

  final int number;
  final QuestionStatus status;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = switch (status) {
      QuestionStatus.answered => AppColors.success,
      QuestionStatus.markedForReview => AppColors.warning,
      QuestionStatus.unanswered => AppColors.cardBg,
    };

    final textColor = switch (status) {
      QuestionStatus.answered => Colors.white,
      QuestionStatus.markedForReview => Colors.white,
      QuestionStatus.unanswered => AppColors.textSecondary,
    };

    final borderColor = isCurrent
        ? AppColors.primary
        : status == QuestionStatus.unanswered
            ? AppColors.divider
            : bgColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isCurrent ? 3 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
