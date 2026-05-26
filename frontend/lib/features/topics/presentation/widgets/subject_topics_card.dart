import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../theme/color_tokens.dart';
import '../../data/models/topic_models.dart';
import '_subject_helpers.dart';
import 'topic_list_item.dart';

/// Expandable card for a subject showing its topics and aggregate stats.
class SubjectTopicsCard extends StatefulWidget {
  const SubjectTopicsCard({super.key, required this.subjectTopics});
  final SubjectTopics subjectTopics;

  @override
  State<SubjectTopicsCard> createState() => _SubjectTopicsCardState();
}

class _SubjectTopicsCardState extends State<SubjectTopicsCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.subjectTopics;
    final color = subjectColor(s.subject);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row (always visible)
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(subjectIcon(s.subject), color: color, size: 20),
            ),
            title: Text(
              s.subject,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${s.completedCount}/${s.totalCount} completed',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularPercentIndicator(
                  radius: 18,
                  lineWidth: 4,
                  percent: (s.overallCompletionPercentage / 100).clamp(0, 1),
                  progressColor: color,
                  backgroundColor: Colors.grey.shade200,
                  circularStrokeCap: CircularStrokeCap.round,
                  center: Text(
                    '${s.overallCompletionPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down, size: 20),
                ),
              ],
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          // Expandable topic list
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: s.topics
                    .map((topic) => TopicListItem(topic: topic))
                    .toList(),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
