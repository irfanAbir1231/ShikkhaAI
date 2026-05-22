import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../common_widgets/organisms/empty_state.dart';

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
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        body: const TabBarView(
          children: [
            EmptyState(
              icon: Icons.bookmark_border,
              title: 'No Saved Notes',
              message: 'Notes you save from AI explanations will appear here.',
            ),
            EmptyState(
              icon: Icons.quiz_outlined,
              title: 'No Saved Quizzes',
              message: 'Quizzes you save will appear here for offline practice.',
            ),
          ],
        ),
      ),
    );
  }
}
