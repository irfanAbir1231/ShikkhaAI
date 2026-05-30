import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common_widgets/atoms/shimmer_box.dart';
import '../../../study_companion/presentation/widgets/markdown_message_card.dart';
import '../providers/note_provider.dart';

class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final String noteId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This will remove the note from your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(noteRepositoryProvider).deleteNote(noteId);
    ref.read(notesRefreshProvider.notifier).state++;
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNote = ref.watch(noteDetailProvider(noteId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: asyncNote.when(
          data: (note) => Text(
            note?.title ?? 'Note',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => const ShimmerBox(width: 180, height: 20, borderRadius: 4),
          error: (_, __) => const Text('Note'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: asyncNote.when(
        data: (note) {
          if (note == null) {
            return _NotFoundBody(onRetry: () {
              ref.invalidate(noteDetailProvider(noteId));
            });
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownMessageCard(data: note.content),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Topic: ${note.topic}')),
                    if (note.subject != null) Chip(label: Text(note.subject!)),
                    if (note.classLevel != null)
                      Chip(label: Text(note.classLevel!)),
                    Chip(label: Text('Source: ${note.source}')),
                    Chip(
                      label: Text(
                        DateFormat.yMMMd().add_jm().format(note.createdAt),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Saved to your library',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
        loading: () => const _SkeletonBody(),
        error: (err, _) => _ErrorBody(
          message: err.toString(),
          onRetry: () => ref.invalidate(noteDetailProvider(noteId)),
        ),
      ),
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(height: 120, borderRadius: 12),
          const SizedBox(height: 16),
          const ShimmerBox(height: 16),
          const SizedBox(height: 8),
          const ShimmerBox(height: 16, width: 240),
          const SizedBox(height: 8),
          const ShimmerBox(height: 16, width: 180),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              4,
              (_) => const ShimmerBox(width: 80, height: 32, borderRadius: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotFoundBody extends StatelessWidget {
  const _NotFoundBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Note not found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This note may have been deleted or is not available.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
