import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';

/// Home tab shell — shows greeting, quick actions, today's focus, and a hero CTA.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analyticsAsync = ref.watch(analyticsSummaryProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      appBar: CustomAppBar(
        title: l10n.appName,
        showGradient: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AvatarButton(
              onTap: () => context.push(RouteNames.settings),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          physics: const BouncingScrollPhysics(),
          children: [
            AnimatedFadeSlide(
              child: Text(
                l10n.homeGreeting,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedFadeSlide(
              delay: const Duration(milliseconds: 80),
              child: Text(
                l10n.homeSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 22),

            // Hero plate — featured CTA
            AnimatedFadeSlide(
              delay: const Duration(milliseconds: 140),
              child: _HeroPlate(
                onTap: () => context.push(RouteNames.studyCompanion),
              ),
            ),
            const SizedBox(height: 24),

            AnimatedFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: Text(
                l10n.homeQuickActions,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.0,
              children: [
                _staggered(0, _QuickActionCard(
                  icon: Icons.auto_stories_rounded,
                  label: l10n.drawerStudyCompanion,
                  subtitle: l10n.homeActionStudySubtitle,
                  color: AppColors.primary,
                  onTap: () => context.push(RouteNames.studyCompanion),
                )),
                _staggered(1, _QuickActionCard(
                  icon: Icons.edit_note_rounded,
                  label: l10n.drawerSmartExam,
                  subtitle: l10n.homeActionExamSubtitle,
                  color: AppColors.accent,
                  onTap: () => context.push(RouteNames.exam),
                )),
                _staggered(2, _QuickActionCard(
                  icon: Icons.analytics_rounded,
                  label: l10n.drawerAnalytics,
                  subtitle: l10n.homeActionAnalyticsSubtitle,
                  color: AppColors.warning,
                  onTap: () => context
                      .push('${RouteNames.home}/${RouteNames.analytics}'),
                )),
                _staggered(3, _QuickActionCard(
                  icon: Icons.calendar_month_rounded,
                  label: l10n.drawerStudyPlan,
                  subtitle: l10n.homeActionPlanSubtitle,
                  color: AppColors.success,
                  onTap: () => context.push(RouteNames.plan),
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Today's Focus — top weak topic from analytics
            AnimatedFadeSlide(
              delay: const Duration(milliseconds: 600),
              child: analyticsAsync.when(
                data: (summary) => summary.weakChapters.isEmpty
                    ? const _AllCaughtUpCard()
                    : _TodaysFocusCard(
                        chapter: summary.weakChapters.first,
                      ),
                loading: () => const _LoadingFocusCard(),
                error: (err, _) => _ErrorFocusCard(message: err.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _staggered(int index, Widget child) => AnimatedFadeSlide(
        delay: Duration(milliseconds: 250 + index * 90),
        offset: const Offset(0, 18),
        child: child,
      );
}

// ------------------------------------------------------------------
// Today's Focus Card
// ------------------------------------------------------------------
class _TodaysFocusCard extends StatelessWidget {
  const _TodaysFocusCard({required this.chapter});

  final dynamic chapter; // WeakChapter

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final barColor = _accuracyColor(chapter.accuracy);

    return GestureDetector(
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
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neuShadow.withValues(alpha: 0.2),
              offset: const Offset(0, 6),
              blurRadius: 16,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.track_changes,
                        size: 14,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).homeTodaysFocus,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B3E1F),
                    borderRadius: BorderRadius.circular(8),
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
              ],
            ),
            const SizedBox(height: 14),
            Text(
              chapter.chapterName,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              chapter.subject,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: chapter.accuracy / 100,
                minHeight: 8,
                backgroundColor: AppColors.primarySoft.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).homeAccuracyPercent(
                      chapter.accuracy.toStringAsFixed(0)),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).homePracticeNow,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.primaryDark,
                    ),
                  ],
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
// All Caught Up Card (shown when no weak topics)
// ------------------------------------------------------------------
class _AllCaughtUpCard extends StatelessWidget {
  const _AllCaughtUpCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).homeAllCaughtUp,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).homeAllCaughtUpSubtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Existing widgets (unchanged)
// ------------------------------------------------------------------
class _HeroPlate extends StatefulWidget {
  const _HeroPlate({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_HeroPlate> createState() => _HeroPlateState();
}

class _HeroPlateState extends State<_HeroPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 180),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, _) {
          final t = _press.value;
          return Transform.scale(
            scale: 1 - 0.018 * t,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB87A4B),
                    Color(0xFF8B5A2B),
                    Color(0xFF6B3E1F),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: const Color(0xFFC19A6B).withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B3E1F).withValues(alpha: 0.4 * (1 - 0.5 * t)),
                    offset: Offset(0, 4 * (1 - 0.5 * t)),
                    blurRadius: 10 * (1 - 0.5 * t),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: const Color(0xFFC19A6B).withValues(alpha: 0.2 * (1 - 0.5 * t)),
                    offset: Offset(0, -2 * (1 - 0.5 * t)),
                    blurRadius: 4 * (1 - 0.5 * t),
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 130,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).homeContinueWithAi,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context).homeHeroSubtitle,
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 160),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, _) {
          final t = _press.value;
          return Transform.scale(
            scale: 1 - 0.02 * t,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB87A4B),
                    Color(0xFF8B5A2B),
                    Color(0xFF6B3E1F),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: const Color(0xFFC19A6B).withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B3E1F)
                        .withValues(alpha: 0.35 * (1 - 0.5 * t)),
                    offset: Offset(0, 4 * (1 - 0.5 * t)),
                    blurRadius: 10 * (1 - 0.5 * t),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: const Color(0xFFC19A6B)
                        .withValues(alpha: 0.2 * (1 - 0.5 * t)),
                    offset: Offset(0, -2 * (1 - 0.5 * t)),
                    blurRadius: 4 * (1 - 0.5 * t),
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned(
                      right: -16,
                      bottom: -16,
                      child: Icon(
                        widget.icon,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.85),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingFocusCard extends StatelessWidget {
  const _LoadingFocusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Loading today\'s focus...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorFocusCard extends StatelessWidget {
  const _ErrorFocusCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.danger,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Could not load focus data. Please check your connection.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}
