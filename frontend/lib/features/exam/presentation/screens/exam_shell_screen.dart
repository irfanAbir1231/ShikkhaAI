import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../common_widgets/organisms/empty_state.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';

import '../../../analytics/data/models/analytics_models.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../analytics/presentation/widgets/practice_suggestions_card.dart';
import '../../data/models/exam_result_model.dart';
import '../providers/exam_provider.dart';
import '../widgets/adaptive_difficulty_badge.dart';

/// Exam tab shell — lists past exams, shows stats, weak topics, practice
/// suggestions, and allows starting a new exam.
class ExamShellScreen extends ConsumerWidget {
  const ExamShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(examHistoryProvider);
    final stats = ref.read(examHistoryProvider.notifier).getStats();
    final analyticsAsync = ref.watch(analyticsSummaryProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.drawerSmartExam,
        showGradient: true,
        actions: const [
          _HistoryButton(),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      AdaptiveDifficultyBadge(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StatsRow(stats: stats),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // ── Weak Topics ──
          SliverToBoxAdapter(
            child: analyticsAsync.when(
              data: (summary) => summary.weakChapters.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.examFocusWeakTopics,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: summary.weakChapters.take(5).length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final chapter = summary.weakChapters[index];
                              return _WeakTopicCompactCard(
                                chapter: chapter,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          // ── Start New Exam CTA ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StartExamCard(
                onTap: () => context.push('/exam/config'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // ── Personalized Practice ──
          SliverToBoxAdapter(
            child: analyticsAsync.when(
              data: (summary) => summary.practiceSuggestions.isEmpty
                  ? const SizedBox.shrink()
                  : AnimatedFadeSlide(
                      delay: const Duration(milliseconds: 200),
                      child: PracticeSuggestionsCard(
                        suggestions: summary.practiceSuggestions,
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // ── Recent Exams ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.examRecentExams,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (history.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.edit_note_outlined,
                title: l10n.examNoExamsTitle,
                message: l10n.examNoExamsMsg,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final result = history[index];
                    return AnimatedFadeSlide(
                      delay: Duration(milliseconds: index * 80),
                      child: _ExamResultCard(
                        result: result,
                        onTap: () => context.push(
                          '/exam/result/${result.attemptId}',
                        ),
                      ),
                    );
                  },
                  childCount: history.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exam/config'),
        icon: const Icon(Icons.add),
        label: Text(l10n.examNewExam),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ------------------------------------------------------------------
// Weak Topic Compact Card
// ------------------------------------------------------------------
class _WeakTopicCompactCard extends StatelessWidget {
  const _WeakTopicCompactCard({required this.chapter});

  final WeakChapter chapter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final barColor = _accuracyColor(chapter.accuracy);

    return SizedBox(
      width: 220,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () {
          context.push(
            '/exam/config',
            extra: {
              'subject': chapter.subject,
              'topic': chapter.chapterName,
              'difficulty': 'easy',
            },
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF8B5A2B),
                  ),
                  child: Center(
                    child: Text(
                      '#${chapter.weaknessRank}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.chapterName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        chapter.subject,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: chapter.accuracy / 100,
                minHeight: 6,
                backgroundColor: AppColors.primarySoft.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)
                      .homeAccuracyPercent(chapter.accuracy.toStringAsFixed(0)),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context).examPracticeChip,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 80) return AppColors.success;
    if (accuracy >= 60) return AppColors.primary;
    return AppColors.primaryDark;
  }
}

// ------------------------------------------------------------------
// Existing helper widgets (unchanged except for formatting)
// ------------------------------------------------------------------
class _HistoryButton extends StatelessWidget {
  const _HistoryButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.history),
      onPressed: () => context.push('/exam/history'),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.assignment_turned_in_outlined,
            value: '${stats['totalExams'] ?? 0}',
            label: l10n.examStatExams,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            value: '${(stats['averageScore'] ?? 0.0).toStringAsFixed(1)}%',
            label: l10n.examStatAvgScore,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_outlined,
            value: '${(stats['bestScore'] ?? 0.0).toStringAsFixed(1)}%',
            label: l10n.examStatBest,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartExamCard extends StatelessWidget {
  const _StartExamCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB87A4B), Color(0xFF8B5A2B), Color(0xFF6B3E1F)],
          ),
          border: Border.all(
            color: const Color(0xFFC19A6B).withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B3E1F).withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).examStartNewTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context).examStartNewSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamResultCard extends StatelessWidget {
  const _ExamResultCard({required this.result, required this.onTap});

  final ExamResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scoreColor = result.scorePercentage >= 60
        ? AppColors.success
        : result.scorePercentage >= 40
            ? AppColors.warning
            : AppColors.danger;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                result.grade,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.subject} \u2014 ${result.topic}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.difficulty} \u2022 ${result.formattedTimeTaken}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.scorePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${result.obtainedMarks.toStringAsFixed(0)}/${result.totalMarks}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
