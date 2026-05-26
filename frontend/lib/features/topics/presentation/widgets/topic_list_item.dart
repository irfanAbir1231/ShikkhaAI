import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../exam/presentation/providers/exam_provider.dart';
import '../../data/models/topic_models.dart';
import 'topic_action_bottom_sheet.dart';

/// Individual topic row inside an expanded subject card.
class TopicListItem extends ConsumerWidget {
  const TopicListItem({super.key, required this.topic});
  final TopicItem topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = topic.isCompleted;
    final isAttempted = topic.attemptsCount > 0;

    return InkWell(
      onTap: () => _showTopicActions(context, ref, topic),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : isAttempted
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle
                    : isAttempted
                        ? Icons.trending_up
                        : Icons.circle_outlined,
                color: isCompleted
                    ? AppColors.success
                    : isAttempted
                        ? AppColors.warning
                        : Colors.grey,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Topic name + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isAttempted ? null : Colors.grey.shade600,
                    ),
                  ),
                  if (isAttempted) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (topic.completionPercentage / 100).clamp(0, 1),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          isCompleted ? AppColors.success : AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${topic.completionPercentage.toStringAsFixed(0)}% '
                      '· ${topic.attemptsCount} '
                      'attempt${topic.attemptsCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ] else
                    Text(
                      'Not started yet',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            // Action button
            TextButton(
              onPressed: () => _startPractice(context, ref, topic),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(isAttempted ? 'Practice' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopicActions(BuildContext context, WidgetRef ref, TopicItem topic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TopicActionBottomSheet(
        topic: topic,
        onPractice: () => _startPractice(context, ref, topic),
      ),
    );
  }

  void _startPractice(BuildContext context, WidgetRef ref, TopicItem topic) {
    // Pre-fill exam config with this topic and navigate to exam config
    final currentConfig = ref.read(examConfigProvider);
    ref.read(examConfigProvider.notifier).state = currentConfig.copyWith(
      subject: topic.subject,
      topic: topic.name,
    );
    context.push('${RouteNames.exam}/${RouteNames.examConfig}');
  }
}
