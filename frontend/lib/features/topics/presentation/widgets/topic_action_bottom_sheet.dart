import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/topic_models.dart';

/// Bottom sheet with actions for a selected topic.
class TopicActionBottomSheet extends StatelessWidget {
  const TopicActionBottomSheet({
    super.key,
    required this.topic,
    this.onPractice,
  });

  final TopicItem topic;
  final VoidCallback? onPractice;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${topic.subject} · ${topic.completionPercentage.toStringAsFixed(0)}% complete',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),
            _ActionTile(
              icon: Icons.play_circle_fill,
              color: AppColors.primary,
              label: 'Practice Exam',
              subtitle: 'Generate a focused quiz on this topic',
              onTap: () {
                Navigator.pop(context);
                onPractice?.call();
              },
            ),
            if (topic.attemptsCount > 0)
              _ActionTile(
                icon: Icons.history,
                color: AppColors.accent,
                label: 'View Attempt History',
                subtitle:
                    '${topic.attemptsCount} previous attempt${topic.attemptsCount > 1 ? 's' : ''}',
                onTap: () {
                  Navigator.pop(context);
                  context.push('${RouteNames.exam}/${RouteNames.examHistory}');
                },
              ),
            _ActionTile(
              icon: Icons.lightbulb,
              color: AppColors.warning,
              label: 'Study Notes',
              subtitle: 'Get AI-generated notes for this topic',
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.studyCompanion);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
