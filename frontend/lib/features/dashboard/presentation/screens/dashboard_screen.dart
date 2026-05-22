import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../theme/color_tokens.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/ai_recommendations_section.dart';
import '../widgets/daily_streak_card.dart';
import '../widgets/improvement_graph.dart';
import '../widgets/readiness_score_card.dart';
import '../widgets/recent_quizzes_list.dart';
import '../widgets/topic_accuracy_chart.dart';
import '../widgets/weak_subjects_section.dart';

/// Production-ready analytics dashboard with charts, stats, and AI insights.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Analytics',
        showGradient: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.insights,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: asyncData.when(
        data: (data) => _DashboardContent(data: data),
        loading: () => const _DashboardSkeleton(),
        error: (err, stack) => _DashboardError(message: err.toString()),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        // Riverpod will auto-refresh when the provider is invalidated.
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedFadeSlide(
              delay: const Duration(milliseconds: 100),
              child: ReadinessScoreCard(data: data.readiness),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: WeakSubjectsSection(subjects: data.weakSubjects),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedFadeSlide(
              delay: const Duration(milliseconds: 300),
              child: DailyStreakCard(data: data.streak),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedFadeSlide(
              delay: const Duration(milliseconds: 400),
              child: ImprovementGraph(data: data.improvement),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedFadeSlide(
              delay: const Duration(milliseconds: 500),
              child: TopicAccuracyChart(data: data.topicAccuracy),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedFadeSlide(
              delay: const Duration(milliseconds: 600),
              child: RecentQuizzesList(quizzes: data.recentQuizzes),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedFadeSlide(
              delay: const Duration(milliseconds: 700),
              child: AIRecommendationsSection(
                recommendations: data.recommendations,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.shimmerBase;
    final highlightColor = AppColors.shimmerHighlight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          _skeletonCard(height: 280),
          _skeletonHeader(),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          _skeletonCard(height: 180),
          _skeletonHeader(),
          _skeletonCard(height: 240),
          _skeletonHeader(),
          _skeletonCard(height: 240),
          _skeletonHeader(),
          _skeletonCard(height: 100),
          _skeletonHeader(),
          _skeletonCard(height: 120),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _skeletonCard({required double height}) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _skeletonHeader() {
    return Container(
      height: 24,
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
