import 'package:flutter/material.dart';

class PracticeExamPromptDialog extends StatelessWidget {
  const PracticeExamPromptDialog({
    super.key,
    required this.topic,
    required this.subject,
    required this.onYes,
    required this.onNo,
  });

  final String topic;
  final String subject;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Practice Exam?'),
      content: Text(
        'Would you like to take a practice exam on $topic?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNo();
          },
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onYes();
          },
          child: const Text("Yes, Let's Go!"),
        ),
      ],
    );
  }
}
