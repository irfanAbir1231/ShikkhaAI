import 'package:flutter/material.dart';

import '../../data/models/study_plan_models.dart';

/// Result of the completion dialog.
enum TaskCompletionAction { addTenMinutes, markDone, cancel }

class TaskCompletionDialog extends StatelessWidget {
  const TaskCompletionDialog({
    super.key,
    required this.task,
    required this.elapsedMinutes,
  });

  final StudyTask task;
  final int elapsedMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Session Complete!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You studied ${task.subject} — ${task.topic} for $elapsedMinutes minutes.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('Planned: ${task.durationMinutes} min')),
              Chip(label: Text('Actual: $elapsedMinutes min')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(TaskCompletionAction.cancel),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pop(TaskCompletionAction.addTenMinutes),
          child: const Text('+10 Minutes'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pop(TaskCompletionAction.markDone),
          child: const Text('Mark as Done'),
        ),
      ],
    );
  }
}
