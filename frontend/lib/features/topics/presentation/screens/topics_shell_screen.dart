import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common_widgets/organisms/app_bar.dart';
import '../providers/topics_provider.dart';
import '../widgets/subject_filter_chips.dart';
import '../widgets/subject_topics_card.dart';
import '../widgets/topics_error_widget.dart';
import '../widgets/topics_overall_progress_card.dart';
import '../widgets/topics_skeleton_loader.dart';

/// Root screen for the Topics tab.
///
/// Shows an overall progress header, subject filter chips, and expandable
/// subject cards that list every topic with its completion status.
class TopicsShellScreen extends ConsumerWidget {
  const TopicsShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(topicsOverviewProvider);
    final filteredSubjects = ref.watch(filteredSubjectsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Topics'),
      body: overviewAsync.when(
        loading: () => const TopicsSkeletonLoader(),
        error: (err, _) => TopicsErrorWidget(
          onRetry: () => ref.invalidate(topicsOverviewProvider),
        ),
        data: (overview) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TopicsOverallProgressCard(
                totalTopics: overview.totalTopics,
                completedTopics: overview.completedTopics,
                overallPercentage: overview.overallCompletionPercentage,
              ),
            ),
            SliverToBoxAdapter(
              child: SubjectFilterChips(
                subjects:
                    overview.subjects.map((s) => s.subject).toList(),
                selected: ref.watch(selectedSubjectFilterProvider),
                onSelected: (subject) =>
                    ref.read(selectedSubjectFilterProvider.notifier).state =
                        subject,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
              sliver: filteredSubjects.when(
                loading: () => const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: TopicsErrorWidget(
                    onRetry: () => ref.invalidate(topicsOverviewProvider),
                  ),
                ),
                data: (subjects) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subjectTopics = subjects[index];
                      return SubjectTopicsCard(
                        subjectTopics: subjectTopics,
                      );
                    },
                    childCount: subjects.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
