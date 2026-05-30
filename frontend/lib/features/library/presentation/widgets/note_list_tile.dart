import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/note_model.dart';

class NoteListTile extends StatelessWidget {
  const NoteListTile({super.key, required this.note, this.onDelete});

  final NoteModel note;
  final VoidCallback? onDelete;

  IconData _sourceIcon() {
    switch (note.source) {
      case 'study_companion':
        return Icons.chat_bubble_outline;
      case 'practice':
        return Icons.fitness_center;
      case 'topic_notes':
        return Icons.menu_book_outlined;
      default:
        return Icons.bookmark_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat.MMMd().add_jm().format(note.createdAt);
    return ListTile(
      leading: Icon(_sourceIcon(), color: theme.colorScheme.primary),
      title: Text(
        note.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        '${note.topic} • $date',
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      onTap: () => context.push('/library/note/${note.id}'),
    );
  }
}
