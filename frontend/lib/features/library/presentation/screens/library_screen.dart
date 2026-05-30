import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../common_widgets/organisms/empty_state.dart';
import '../providers/note_provider.dart';
import '../widgets/note_list_tile.dart';

/// Offline library — saved notes and quizzes.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Library',
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Notes'),
              Tab(text: 'Quizzes'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
        ),
        body: const TabBarView(
          children: [
            _NotesTab(),
            EmptyState(
              icon: Icons.quiz_outlined,
              title: 'No Saved Quizzes',
              message:
                  'Quizzes you save will appear here for offline practice.',
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesTab extends ConsumerWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Failed to load notes')),
      data: (notes) {
        if (notes.isEmpty) {
          return const EmptyState(
            icon: Icons.bookmark_border,
            title: 'No Saved Notes',
            message:
                'Notes you save from AI explanations or practice suggestions will appear here.',
          );
        }
        final grouped = groupBy(notes, (n) => n.topic);
        final topics = grouped.keys.toList();
        return RefreshIndicator(
          onRefresh: () async {
            ref.read(notesRefreshProvider.notifier).state++;
            await ref.read(notesProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final topicNotes = grouped[topic]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      topic,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  ...topicNotes.map(
                    (note) => NoteListTile(
                      note: note,
                      onDelete: () async {
                        await ref
                            .read(noteRepositoryProvider)
                            .deleteNote(note.id);
                        ref.read(notesRefreshProvider.notifier).state++;
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
