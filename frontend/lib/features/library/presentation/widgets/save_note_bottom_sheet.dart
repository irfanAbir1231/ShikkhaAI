import 'package:flutter/material.dart';

/// Bottom sheet to confirm/edit title and topic before saving a note.
class SaveNoteBottomSheet extends StatefulWidget {
  const SaveNoteBottomSheet({
    super.key,
    required this.defaultTitle,
    required this.defaultTopic,
    required this.onSave,
  });

  final String defaultTitle;
  final String defaultTopic;
  final void Function(String title, String topic) onSave;

  @override
  State<SaveNoteBottomSheet> createState() => _SaveNoteBottomSheetState();
}

class _SaveNoteBottomSheetState extends State<SaveNoteBottomSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _topicCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.defaultTitle);
    _topicCtrl = TextEditingController(text: widget.defaultTopic);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + insets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Save as Note',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicCtrl,
            decoration: const InputDecoration(
              labelText: 'Topic',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final title = _titleCtrl.text.trim();
                    final topic = _topicCtrl.text.trim();
                    if (title.isEmpty || topic.isEmpty) return;
                    widget.onSave(title, topic);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
