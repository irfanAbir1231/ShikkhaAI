import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common_widgets/animations/animated_scale_tap.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/exam_question_model.dart';

/// MCQ option buttons with selection state.
class McqOptions extends ConsumerWidget {
  const McqOptions({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onSelect,
    this.showFeedback = false,
  });

  final ExamQuestion question;
  final String? selectedAnswer;
  final ValueChanged<String> onSelect;
  final bool showFeedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ['A', 'B', 'C', 'D'];

    return Column(
      children: [
        for (var i = 0; i < question.options.length; i++) ...[
          _OptionTile(
            label: labels[i],
            text: question.options[i],
            isSelected: selectedAnswer == question.options[i],
            isCorrect: showFeedback &&
                question.options[i] == question.correctAnswer,
            isWrong: showFeedback &&
                selectedAnswer == question.options[i] &&
                selectedAnswer != question.correctAnswer,
            onTap: () => onSelect(question.options[i]),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.cardBg;
    Color borderColor = AppColors.divider;
    Color textColor = AppColors.textPrimary;
    Color labelBgColor = AppColors.surface;
    Color labelTextColor = AppColors.textSecondary;

    if (isCorrect) {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      borderColor = AppColors.success;
      textColor = AppColors.success;
      labelBgColor = AppColors.success;
      labelTextColor = Colors.white;
    } else if (isWrong) {
      bgColor = AppColors.danger.withValues(alpha: 0.1);
      borderColor = AppColors.danger;
      textColor = AppColors.danger;
      labelBgColor = AppColors.danger;
      labelTextColor = Colors.white;
    } else if (isSelected) {
      bgColor = AppColors.primary.withValues(alpha: 0.1);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
      labelBgColor = AppColors.primary;
      labelTextColor = Colors.white;
    }

    return AnimatedScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: labelBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: labelTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
            if (isCorrect)
              const Icon(Icons.check_circle, color: AppColors.success, size: 22)
            else if (isWrong)
              const Icon(Icons.cancel, color: AppColors.danger, size: 22)
            else if (isSelected)
              const Icon(Icons.radio_button_checked, color: AppColors.primary, size: 22)
            else
              const Icon(Icons.radio_button_off, color: AppColors.divider, size: 22),
          ],
        ),
      ),
    );
  }
}
